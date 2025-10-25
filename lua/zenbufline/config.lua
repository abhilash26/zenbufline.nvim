return {
	line_start = "",
	line_end = "",
	modified = " [+] ",
	hl = "ZenbuflineBuffer",
	left = {
		hl = "ZenbuflineNormal",
		icon = "",
	},
	right = {
		hl = "ZenbuflineNormal",
		icon = "",
	},
	active = {
		hl = "ZenbuflineActive",
		italic = false,
		bold = true,
	},
	inactive = {
		hl = "ZenBuflineInactive",
		italic = true,
		bold = false,
	},
	-- Performance options
	debounce_ms = 15, -- Debounce time in milliseconds for updates

	-- Mouse support options
	show_close_button = true, -- Show clickable close button for buffers
	close_icon = "×", -- Icon for close button
	force_close_modified = false, -- Force close modified buffers without warning

	-- Buffer display options
	max_visible_buffers = 0, -- Maximum buffers to show (0 = no limit)
	show_buffer_count = false, -- Show buffer count at the right (e.g., "3/10")
}
