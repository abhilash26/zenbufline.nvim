local plugin_loaded = false
local default_options = require("zenbufline.default_options")
local o = {}
local sections_cache = {}

-- Cache frequently used globals
local api = vim.api

local get_hl = function(hl)
  return string.format("%%#%s#", hl)
end

M = {}

M.define_highlights = function()
  local status = api.nvim_get_hl(0, { name = "StatusLine" })
  local normal = api.nvim_get_hl(0, { name = "Normal" })
  local comment = api.nvim_get_hl(0, { name = "Comment" })
  local hls = {
    ["ZenbuflineBuffer"] = { link = "StatusLine" },
    ["ZenbuflineNormal"] = { fg = normal.bg, bg = status.bg },
    ["ZenbuflineInactive"] = {
      fg = comment.fg,
      bg = normal.bg,
      bold = o.inactive.bold,
      italic = o.inactive.italic,
    },
    ["ZenbuflineActive"] = {
      fg = normal.fg,
      bg = normal.bg,
      bold = o.active.bold,
      italic = o.active.italic,
    },
  }
  for hl, options in pairs(hls) do
    api.nvim_set_hl(0, hl, options)
  end
end

M.set_tabline = vim.schedule_wrap(function()
  local line_parts = {}
  table.insert(line_parts, sections_cache["bg"])
  for _, buf in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted then
      if vim.tbl_contains(o.exclude_fts, vim.bo[buf].ft) then
        goto continue
      end
      local modified = vim.bo[buf].modified and o.modified or ""
      local fname = vim.fn.fnamemodify(api.nvim_buf_get_name(buf), ":t");
      local is_active = buf == api.nvim_get_current_buf()
      table.insert(line_parts,
        string.format("%s%s%s%s%s",
          sections_cache["left"],
          is_active and sections_cache["active"] or sections_cache["inactive"],
          string.format(" %s%s ", fname, modified),
          sections_cache["right"],
          sections_cache["bg"]
        ))
    end
    ::continue::
  end
  vim.o.tabline = table.concat(line_parts, " ")
end)

M.cache_sections = function()
  sections_cache["left"] = string.format("%s%s", get_hl("ZenbuflineNormal"), o.left)
  sections_cache["right"] = string.format("%s%s", get_hl("ZenbuflineNormal"), o.right)
  sections_cache["active"] = get_hl("ZenbuflineActive")
  sections_cache["inactive"] = get_hl("ZenbuflineInactive")
  sections_cache["bg"] = get_hl("ZenbuflineBuffer")
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
    desc = "set tabline"
  })
  api.nvim_create_autocmd({ "ColorScheme" }, {
    group = augroup,
    callback = M.define_highlights,
    desc = "update highlights"
  })
end

M.setup = function(opts)
  if plugin_loaded then return else plugin_loaded = true end
  M.merge_config(opts)
  M.create_autocommands()
  M.define_highlights()
  M.cache_sections()
end

return M
