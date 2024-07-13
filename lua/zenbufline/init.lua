local plugin_loaded = false
local default_options = require("zenbufline.config")
local o = default_options
local cache = { left = "", right = "", active = "", inactive = "", bg = "" }
local hls = {
	["ZenbuflineBuffer"] = "%#ZenbuflineBuffer#",
	["ZenbuflineNormal"] = "%#ZenbuflineNormal#",
	["ZenbuflineInactive"] = "%#ZenbuflineInactive#",
	["ZenbuflineActive"] = "%#ZenbuflineActive#",
}

-- Cache frequently used globals
local api = vim.api

local get_hl = function(hl)
	return hls[hl] or string.format("%%#%s#", hl)
end

M = {}

M.define_highlights = function()
	local status = api.nvim_get_hl(0, { name = "StatusLine" })
	local normal = api.nvim_get_hl(0, { name = "Normal" })
	local comment = api.nvim_get_hl(0, { name = "Comment" })

	api.nvim_set_hl(0, "ZenbuflineBuffer", { link = "StatusLine" })
	api.nvim_set_hl(0, "ZenbuflineNormal", { fg = normal.bg, bg = status.bg })
	api.nvim_set_hl(
		0,
		"ZenbuflineInactive",
		{ fg = comment.fg, bg = normal.bg, bold = o.inactive.bold, italic = o.inactive.italic }
	)
	api.nvim_set_hl(
		0,
		"ZenbuflineActive",
		{ fg = normal.fg, bg = normal.bg, bold = o.active.bold, italic = o.active.italic }
	)
end

M.set_tabline = vim.schedule_wrap(function()
	local line_parts = { cache["bg"] }
	local cur_buf = api.nvim_get_current_buf()
	local exclude_fts = o.exclude_fts

	for _, buf in ipairs(api.nvim_list_bufs()) do
		local bo = vim.bo[buf]
		if api.nvim_buf_is_valid(buf) and bo.buflisted then
			if not vim.tbl_contains(exclude_fts, bo.ft) then
				local modified = bo.modified and o.modified or ""
				local fname = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t")
				line_parts[#line_parts + 1] = table.concat({
					cache["left"],
					cache[(buf == cur_buf) and "active" or "inactive"],
					string.format(" %s%s ", fname, modified),
					cache["right"],
					cache["bg"],
				}, "")
			end
		end
	end
	vim.o.tabline = table.concat(line_parts, " ")
end)

M.cache_sections = function()
	cache["left"] = string.format("%s%s", get_hl(o.left.hl), o.left.icon)
	cache["right"] = string.format("%s%s", get_hl(o.right.hl), o.right.icon)
	cache["active"] = get_hl(o.active.hl)
	cache["inactive"] = get_hl(o.inactive.hl)
	cache["bg"] = get_hl(o.hl)
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
	else
		plugin_loaded = true
	end
	M.merge_config(opts)
	M.create_autocommands()
	M.define_highlights()
	M.cache_sections()
end

return M
