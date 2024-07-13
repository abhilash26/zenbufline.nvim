local plugin_loaded = false
local default_options = require("zenbufline.config")
local o = default_options
local cache = {}
local hls = {}
local line_part = {}

-- Cache frequently used globals
local api = vim.api

M = {}

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
	}
	for key, value in pairs(hls) do
		api.nvim_set_hl(0, key, value.hl)
		hls[key]["txt"] = string.format("%%#%s#", key)
	end
end

M.set_tabline = vim.schedule_wrap(function()
	local tabline_parts = {}
	local cur_buf = api.nvim_get_current_buf()

	for _, buf in ipairs(api.nvim_list_bufs()) do
		local bo = vim.bo[buf]
		if api.nvim_buf_is_valid(buf) and bo.buflisted then
			line_part[5] = bo.modified and o.modified or ""
			line_part[3] = cache[(buf == cur_buf) and "active" or "inactive"]
			if bo.ft == "" then
				line_part[4] = " New "
			else
				local fname = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
				line_part[4] = " " .. fname .. " "
			end
			tabline_parts[#tabline_parts + 1] = table.concat(line_part, "")
		end
	end
	vim.o.tabline = table.concat(tabline_parts, " ")
end)

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

	-- create statusline
	api.nvim_create_autocmd({ "BufEnter", "BufLeave", "BufDelete", "BufModifiedSet" }, {
		group = augroup,
		callback = M.set_tabline,
		desc = "set tabline",
	})
	api.nvim_create_autocmd({ "ColorScheme" }, {
		group = augroup,
		callback = M.define_highlights,
		desc = "update highlights",
	})
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
