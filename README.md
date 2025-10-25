# zenbufline.nvim
A minimal, performant lua-based buffer line for neovim with mouse support

![image](https://github.com/abhilash26/zenbufline.nvim/assets/28080925/1c25e6b0-04c4-4e57-975f-db5abfbac495)

## ✨ Features

- 🚀 **Excellent Performance**: Aggressive caching and debouncing for smooth operation even with 100+ buffers
- 🖱️ **Mouse Support**: Click to switch buffers, click close button to close buffers
- ⌨️ **Buffer Navigation**: Commands for next/previous buffer and jump to buffer by index
- 🎨 **Clean & Minimal**: Simple, distraction-free design
- ⚡ **Smart Truncation**: Automatically handles many buffers with overflow indicators
- 🎯 **Buffer Count Display**: Optional buffer count indicator (e.g., "3/10")

## Requirements
* Requires neovim version >= 0.10
* `vim.opt.showtabline=2` in your init.lua for bufferline
* Have a [nerd font installed](https://www.nerdfonts.com/font-downloads)

## Installation

### Lazy
```lua
{
  "abhilash26/zenbufline.nvim",
  event = { "BufReadPost", "BufNewFile" },
  opts = {}
},
```

### Pckr (Spiritual successor of packer)
```lua
{ "abhilash26/zenbufline.nvim",
  config = function()
    require("zenbufline").setup()
  end
};
```

## Configuration

### Minimum Configuration
```lua
require("zenbufline").setup()
```

### Full Configuration (with defaults)
```lua
require("zenbufline").setup({
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
  debounce_ms = 15, -- Debounce time for updates (lower = more responsive, higher = better performance)

  -- Mouse support
  show_close_button = true, -- Show clickable close button
  close_icon = "×", -- Icon for close button
  force_close_modified = false, -- Force close modified buffers without warning

  -- Display options
  max_visible_buffers = 0, -- Max buffers to show (0 = no limit)
  show_buffer_count = false, -- Show buffer count on right side
})
```

## Usage

### Mouse Controls
- **Left Click** on buffer name: Switch to that buffer
- **Left Click** on `×` button: Close that buffer

### Keyboard Commands

The plugin exposes the following functions for buffer navigation:

```lua
local zenbufline = require("zenbufline")

-- Navigate to next buffer
zenbufline.next_buffer()

-- Navigate to previous buffer
zenbufline.prev_buffer()

-- Jump to specific buffer by index (1-9)
zenbufline.goto_buffer(3)  -- Jump to 3rd buffer

-- Close current buffer intelligently (switches to next before closing)
zenbufline.close_current_buffer()
```

### Example Keymaps

Add these to your config to enable keyboard navigation:

```lua
-- Buffer navigation
vim.keymap.set('n', '<Tab>', function() require('zenbufline').next_buffer() end, { desc = 'Next buffer' })
vim.keymap.set('n', '<S-Tab>', function() require('zenbufline').prev_buffer() end, { desc = 'Previous buffer' })

-- Close current buffer
vim.keymap.set('n', '<leader>bc', function() require('zenbufline').close_current_buffer() end, { desc = 'Close buffer' })

-- Jump to specific buffer (1-9)
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, function() require('zenbufline').goto_buffer(i) end, { desc = 'Go to buffer ' .. i })
end
```

## Performance

- **Buffer Caching**: Maintains efficient buffer list cache, only rebuilding when necessary
- **Debouncing**: Batches rapid updates to avoid excessive redraws (configurable via `debounce_ms`)
- **Smart Updates**: Only updates affected buffers instead of rebuilding entire tabline
- **Memory Efficient**: ~1KB per buffer with aggressive caching

### Performance Targets
- ✅ <0.5ms update time for 10 buffers
- ✅ <2ms update time for 100 buffers
- ✅ Max 60-100 updates/second (debounced)
- ✅ No perceivable lag during normal operations

## Customization Tips

### Hide Close Button
```lua
require("zenbufline").setup({
  show_close_button = false,
})
```

### Limit Visible Buffers
Useful when you have many buffers open:
```lua
require("zenbufline").setup({
  max_visible_buffers = 10, -- Shows up to 10 buffers centered on current
})
```

### Show Buffer Count
```lua
require("zenbufline").setup({
  show_buffer_count = true, -- Shows "3/10" at the right
})
```

### Adjust Performance/Responsiveness
```lua
require("zenbufline").setup({
  debounce_ms = 5,  -- More responsive but slightly higher CPU
  -- or
  debounce_ms = 30, -- Better battery life, still very smooth
})
```

## Philosophy

zenbufline.nvim follows a minimalist philosophy:
- 🎯 **Focus on core functionality**: Buffer display and navigation
- 🚀 **Performance first**: Every line of code is optimized
- 🧘 **Minimal visual noise**: Clean, distraction-free interface
- 🔧 **Highly configurable**: But sane defaults out of the box

We explicitly **do not** support:
- ❌ Buffer groups/tabs
- ❌ Per-filetype icons
- ❌ LSP diagnostics integration
- ❌ Git status indicators
- ❌ Complex animations

If you need these features, consider [barbar.nvim](https://github.com/romgrk/barbar.nvim) or [bufferline.nvim](https://github.com/akinsho/bufferline.nvim).

## Troubleshooting

### Mouse clicks don't work
Make sure you have `set mouse=a` in your config.

### Buffers not showing
Ensure `vim.opt.showtabline=2` is set in your init.lua.

### Close button not visible
Check that your font supports the `×` character or change the `close_icon` option.

## Contributing

Contributions are welcome! Please keep the minimalist philosophy in mind:
- Focus on performance improvements
- Keep code simple and maintainable
- Add features only if they benefit 80%+ of users

## License

MIT License - see [LICENSE](LICENSE) for details
