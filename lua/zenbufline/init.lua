local plugin_loaded = false
local default_options = require("zenbufline.config")
local o = default_options
local cache = {}
local hls = {}
local line_part = {}

-- Cache frequently used globals
local api = vim.api
local fn = vim.fn

-- Buffer cache for performance
local buffer_cache = {
	list = {}, -- ordered list of buffer numbers
	metadata = {}, -- buf_num -> {name, modified}
	dirty = true, -- needs rebuild
}

-- Debouncing
local update_pending = false
local update_timer = nil

M = {}

-- Performance: Cache buffer list
local function rebuild_buffer_cache()
	local new_list = {}
	local cur_buf = api.nvim_get_current_buf()

	for _, buf in ipairs(api.nvim_list_bufs()) do
		if api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
			new_list[#new_list + 1] = buf

			-- Update metadata
			local name = api.nvim_buf_get_name(buf)
			local fname = name ~= "" and fn.fnamemodify(name, ":t") or "New"
			buffer_cache.metadata[buf] = {
				name = fname,
				modified = vim.bo[buf].modified,
				is_current = buf == cur_buf,
			}
		end
	end

	buffer_cache.list = new_list
	buffer_cache.dirty = false
end

-- Mouse click handler: Switch to buffer
M.handle_click = function(buf_num, clicks, button, modifiers)
	buf_num = tonumber(buf_num)
	if buf_num and api.nvim_buf_is_valid(buf_num) then
		api.nvim_set_current_buf(buf_num)
	end
end

-- Mouse click handler: Close buffer
M.close_buffer_click = function(buf_num, clicks, button, modifiers)
	buf_num = tonumber(buf_num)
	if not buf_num or not api.nvim_buf_is_valid(buf_num) then
		return
	end

	-- Check if buffer is modified
	if vim.bo[buf_num].modified and not o.force_close_modified then
		vim.notify("Buffer has unsaved changes. Save before closing.", vim.log.levels.WARN)
		return
	end

	-- If this is the current buffer, switch to another before closing
	if buf_num == api.nvim_get_current_buf() then
		M.next_buffer()
	end

	-- Delete buffer
	local ok = pcall(api.nvim_buf_delete, buf_num, { force = o.force_close_modified })
	if not ok then
		vim.notify("Failed to close buffer " .. buf_num, vim.log.levels.ERROR)
	end
end

-- Buffer navigation: Next buffer
M.next_buffer = function()
	if buffer_cache.dirty then
		rebuild_buffer_cache()
	end

	local list = buffer_cache.list
	if #list <= 1 then
		return
	end

	local cur_buf = api.nvim_get_current_buf()
	local cur_idx = nil

	for i, buf in ipairs(list) do
		if buf == cur_buf then
			cur_idx = i
			break
		end
	end

	if cur_idx then
		local next_idx = (cur_idx % #list) + 1
		api.nvim_set_current_buf(list[next_idx])
	end
end

-- Buffer navigation: Previous buffer
M.prev_buffer = function()
	if buffer_cache.dirty then
		rebuild_buffer_cache()
	end

	local list = buffer_cache.list
	if #list <= 1 then
		return
	end

	local cur_buf = api.nvim_get_current_buf()
	local cur_idx = nil

	for i, buf in ipairs(list) do
		if buf == cur_buf then
			cur_idx = i
			break
		end
	end

	if cur_idx then
		local prev_idx = cur_idx == 1 and #list or cur_idx - 1
		api.nvim_set_current_buf(list[prev_idx])
	end
end

-- Buffer navigation: Go to specific buffer by index
M.goto_buffer = function(index)
	if buffer_cache.dirty then
		rebuild_buffer_cache()
	end

	local list = buffer_cache.list
	if index >= 1 and index <= #list then
		api.nvim_set_current_buf(list[index])
	end
end

-- Close current buffer intelligently
M.close_current_buffer = function()
	local buf = api.nvim_get_current_buf()

	-- Check if buffer is modified
	if vim.bo[buf].modified and not o.force_close_modified then
		vim.notify("Buffer has unsaved changes. Save before closing.", vim.log.levels.WARN)
		return
	end

	-- Switch to next buffer if there are others
	if #buffer_cache.list > 1 then
		M.next_buffer()
	end

	-- Delete buffer
	pcall(api.nvim_buf_delete, buf, { force = o.force_close_modified })
end

M.define_highlights = function()
	local status = api.nvim_get_hl(0, { name = "StatusLine" })
	local normal = api.nvim_get_hl(0, { name = "Normal" })
	local comment = api.nvim_get_hl(0, { name = "Comment" })

	hls = {
		["ZenbuflineBuffer"] = { hl = { link = "StatusLine" } },
		["ZenbuflineNormal"] = { hl = { fg = normal.bg, bg = status.bg } },
		["ZenbuflineInactive"] = {
			hl = {
				fg = comment.fg,
				bg = normal.bg,
				bold = o.inactive.bold,
				italic = o.inactive.italic,
			},
		},
		["ZenbuflineActive"] = {
			hl = {
				fg = normal.fg,
				bg = normal.bg,
				bold = o.active.bold,
				italic = o.active.italic,
			},
		},
		["ZenbuflineClose"] = {
			hl = {
				fg = comment.fg,
				bg = normal.bg,
			},
		},
	}
	for key, value in pairs(hls) do
		api.nvim_set_hl(0, key, value.hl)
		hls[key]["txt"] = string.format("%%#%s#", key)
	end
end

-- Optimized tabline rendering with mouse support
M.set_tabline = function()
	-- Rebuild cache if dirty
	if buffer_cache.dirty then
		rebuild_buffer_cache()
	end

	local list = buffer_cache.list
	if #list == 0 then
		vim.o.tabline = ""
		return
	end

	local cur_buf = api.nvim_get_current_buf()

	-- Pre-allocate table for better performance
	local tabline_parts = {}
	local parts_count = 0

	-- Calculate visible buffers if truncation is needed
	local visible_bufs = list
	local show_overflow = false

	if o.max_visible_buffers > 0 and #list > o.max_visible_buffers then
		show_overflow = true
		-- Find current buffer index
		local cur_idx = 1
		for i, buf in ipairs(list) do
			if buf == cur_buf then
				cur_idx = i
				break
			end
		end

		-- Calculate visible range centered on current buffer
		local half = math.floor(o.max_visible_buffers / 2)
		local start_idx = math.max(1, cur_idx - half)
		local end_idx = math.min(#list, start_idx + o.max_visible_buffers - 1)

		-- Adjust if at end
		if end_idx - start_idx + 1 < o.max_visible_buffers then
			start_idx = math.max(1, end_idx - o.max_visible_buffers + 1)
		end

		visible_bufs = {}
		for i = start_idx, end_idx do
			visible_bufs[#visible_bufs + 1] = list[i]
		end
	end

	-- Add left overflow indicator
	if show_overflow and visible_bufs[1] ~= list[1] then
		parts_count = parts_count + 1
		tabline_parts[parts_count] = cache["bg"] .. " « "
	end

	-- Build buffer display strings
	for _, buf in ipairs(visible_bufs) do
		local meta = buffer_cache.metadata[buf]
		if meta then
			local is_current = buf == cur_buf
			local hl = is_current and cache["active"] or cache["inactive"]

			-- Modified indicator
			local modified_str = meta.modified and o.modified or ""

			-- Build buffer string with mouse support
			parts_count = parts_count + 1

			-- Mouse click to switch buffer
			local click_start = string.format("%%%d@v:lua.require'zenbufline'.handle_click@", buf)
			local click_end = "%X"

			-- Close button with separate click handler
			local close_btn = ""
			if o.show_close_button then
				close_btn = string.format(
					" %%#ZenbuflineClose%%%%%d@v:lua.require'zenbufline'.close_buffer_click@%s%%X",
					buf,
					o.close_icon
				)
			end

			-- Combine parts
			tabline_parts[parts_count] = string.format(
				"%s%s%s %s%s%s%s%s ",
				cache["bg"],
				cache["left"],
				click_start,
				hl,
				meta.name,
				modified_str,
				click_end,
				cache["right"]
			)

			-- Add close button after buffer name
			if close_btn ~= "" then
				parts_count = parts_count + 1
				tabline_parts[parts_count] = close_btn
			end
		end
	end

	-- Add right overflow indicator
	if show_overflow and visible_bufs[#visible_bufs] ~= list[#list] then
		parts_count = parts_count + 1
		tabline_parts[parts_count] = cache["bg"] .. " » "
	end

	-- Add buffer count if enabled
	if o.show_buffer_count then
		parts_count = parts_count + 1
		tabline_parts[parts_count] = string.format("%s %%=%s [%d/%d] ", cache["bg"], cache["bg"], #list, #list)
	end

	vim.o.tabline = table.concat(tabline_parts, "")
end

-- Debounced version of set_tabline
local function schedule_update()
	if update_pending then
		return
	end

	update_pending = true

	-- Cancel existing timer
	if update_timer then
		update_timer:stop()
		update_timer:close()
		update_timer = nil
	end

	-- Schedule update
	update_timer = vim.defer_fn(function()
		M.set_tabline()
		update_pending = false
		update_timer = nil
	end, o.debounce_ms or 15)
end

M.cache_sections = function()
	local get_hl = function(hl)
		return hls[hl] and hls[hl].txt or string.format("%%#%s#", hl)
	end
	cache["left"] = string.format("%s%s", get_hl(o.left.hl), o.left.icon)
	cache["right"] = string.format("%s%s", get_hl(o.right.hl), o.right.icon)
	cache["active"] = get_hl(o.active.hl)
	cache["inactive"] = get_hl(o.inactive.hl)
	cache["bg"] = get_hl(o.hl)
	-- @stylua : ignore
	line_part = { cache["bg"], cache["left"], cache["inactive"], " New ", "", cache["right"], cache["bg"] }
end

M.merge_config = function(opts)
	-- prefer users config over default
	o = vim.tbl_deep_extend("force", default_options, opts or {})
end

M.create_autocommands = function()
	local augroup = api.nvim_create_augroup("Zenbufline", { clear = true })

	-- Buffer list changes - mark cache as dirty
	api.nvim_create_autocmd({ "BufAdd", "BufDelete" }, {
		group = augroup,
		callback = function()
			buffer_cache.dirty = true
			schedule_update()
		end,
		desc = "mark buffer cache dirty",
	})

	-- Buffer state changes - update display
	api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
		group = augroup,
		callback = function()
			buffer_cache.dirty = true
			schedule_update()
		end,
		desc = "update tabline on buffer switch",
	})

	-- Buffer modification state - update only if needed
	api.nvim_create_autocmd({ "BufModifiedSet" }, {
		group = augroup,
		callback = function(ev)
			local buf = ev.buf
			if buffer_cache.metadata[buf] then
				buffer_cache.metadata[buf].modified = vim.bo[buf].modified
				schedule_update()
			end
		end,
		desc = "update modified indicator",
	})

	-- Highlight updates
	api.nvim_create_autocmd({ "ColorScheme" }, {
		group = augroup,
		callback = function()
			M.define_highlights()
			M.cache_sections()
			schedule_update()
		end,
		desc = "update highlights",
	})

	-- Initial render
	vim.schedule(function()
		buffer_cache.dirty = true
		M.set_tabline()
	end)
end

M.setup = function(opts)
	if plugin_loaded then
		return
	end
	M.merge_config(opts)
	M.define_highlights()
	M.cache_sections()
	M.create_autocommands()
	plugin_loaded = true
end

return M
