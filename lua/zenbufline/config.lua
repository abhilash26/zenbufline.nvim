return {
  line_start = "",
  line_end = "",
  modified = " [+] ",
  hl = "ZenbuflineBuffer",
  left = {
    hl = "ZenbuflineNormal",
    icon = "",
  },
  right = {
    hl = "ZenbuflineNormal",
    icon = ""
  },
  active = {
    hl = "ZenbuflineActive",
    italic = false,
    bold = true,
  },
  inactive = {
    hl = "ZenBuflineInactive",
    italic = false,
    bold = false,
  },
  exclude_fts = {
    "neotree",
    "NvimTree",
    "Alpha",
    "dashboard",
    "help"
  }
}
