# Testing Guide for zenbufline.nvim

Quick guide to test all the new features and performance improvements.

## Prerequisites

1. Install the plugin in your neovim config
2. Ensure `vim.opt.showtabline=2` is set
3. Ensure `vim.opt.mouse='a'` is set for mouse support
4. Have a nerd font installed

## Basic Setup Test

```lua
-- In your init.lua
require("zenbufline").setup()
```

Expected: Bufferline appears at the top showing current buffer.

---

## Performance Tests

### Test 1: Many Buffers (Caching)
```vim
" Open many files
:args lua/**/*.lua
:args *.md
```

**Expected**:
- Smooth operation even with 20+ buffers
- No lag when switching between buffers
- Update time should feel instant

### Test 2: Rapid Buffer Switching (Debouncing)
```vim
" Quickly switch between buffers
:bnext
:bnext
:bnext
:bprev
:bprev
```

**Expected**:
- No excessive flashing
- Smooth, batched updates
- CPU usage stays low

### Test 3: Buffer Truncation
```lua
-- In config
require("zenbufline").setup({
  max_visible_buffers = 5,
})
```

Then open 10+ buffers.

**Expected**:
- Shows « on left if there are hidden buffers before current
- Shows » on right if there are hidden buffers after current
- Current buffer always visible and centered
- Can navigate through all buffers despite truncation

---

## Mouse Support Tests

### Test 4: Click to Switch Buffer
1. Open multiple buffers (`:e file1.txt`, `:e file2.txt`)
2. Move mouse to any buffer name in tabline
3. Click on it

**Expected**: Switches to that buffer immediately

### Test 5: Click to Close Buffer
1. Enable close button in config (default: enabled)
2. Open multiple buffers
3. Click on the × button next to any buffer name

**Expected**:
- Buffer closes
- If current buffer, switches to next before closing
- Remaining buffers still shown

### Test 6: Modified Buffer Warning
1. Open a buffer and make changes (don't save)
2. Click the × button

**Expected**:
- Warning notification: "Buffer has unsaved changes"
- Buffer NOT closed
- Can still switch to other buffers

---

## Navigation Command Tests

### Test 7: Next/Previous Buffer
```lua
-- Add keymaps (or run directly)
require('zenbufline').next_buffer()
require('zenbufline').prev_buffer()
```

**Expected**:
- Cycles through buffers in order
- Wraps around (last → first, first → last)
- Works smoothly with visual feedback

### Test 8: Go to Buffer by Index
```lua
-- Jump to 3rd buffer
require('zenbufline').goto_buffer(3)
```

**Expected**:
- Jumps directly to the 3rd buffer in the list
- Invalid indices are ignored gracefully
- Visual highlight updates immediately

### Test 9: Close Current Buffer
```lua
require('zenbufline').close_current_buffer()
```

**Expected**:
- Closes current buffer
- Automatically switches to next buffer first
- If last buffer, creates new empty buffer
- Modified buffers show warning (unless force_close_modified = true)

---

## Visual Tests

### Test 10: Buffer Count Display
```lua
require("zenbufline").setup({
  show_buffer_count = true,
})
```

**Expected**:
- Right side shows "[3/10]" format
- Updates when buffers are added/removed
- Properly aligned to the right

### Test 11: Custom Close Icon
```lua
require("zenbufline").setup({
  close_icon = "✖",
})
```

**Expected**:
- Close button shows ✖ instead of ×
- Still clickable and functional

### Test 12: Colorscheme Changes
```vim
:colorscheme desert
:colorscheme nord
:colorscheme gruvbox
```

**Expected**:
- Highlights update automatically
- Active/inactive buffers maintain proper contrast
- No errors in command line

---

## Edge Case Tests

### Test 13: Single Buffer
Close all buffers except one.

**Expected**:
- Bufferline still displays correctly
- No errors
- next/prev buffer commands do nothing (gracefully)

### Test 14: Terminal Buffers
```vim
:terminal
```

**Expected**:
- Terminal buffer appears in bufferline
- Can switch to/from it
- Close button works

### Test 15: Unnamed Buffers
```vim
:enew
:enew
```

**Expected**:
- Shows as "New" in bufferline
- Can switch between them
- Closing works properly

### Test 16: Long Filenames
Open files with very long names.

**Expected**:
- Names display without breaking layout
- Truncation works if enabled
- Still clickable

### Test 17: Fast Buffer Creation/Deletion
```vim
:args test{1..50}.txt
:argdo bdelete
```

**Expected**:
- Handles rapid changes smoothly
- No crashes or errors
- Cache updates correctly

---

## Configuration Tests

### Test 18: Disable Close Button
```lua
require("zenbufline").setup({
  show_close_button = false,
})
```

**Expected**:
- No × button shown
- More space for buffer names
- Everything else works

### Test 19: Force Close Modified
```lua
require("zenbufline").setup({
  force_close_modified = true,
})
```

**Expected**:
- Modified buffers close without warning
- Data loss possible (intended behavior)

### Test 20: Custom Debounce
```lua
require("zenbufline").setup({
  debounce_ms = 5,  -- Very responsive
})
```

**Expected**:
- More immediate updates
- Slightly higher CPU on rapid changes
- Still smooth overall

---

## Performance Benchmarking

### Manual Timing Test
```lua
-- Time an update
local start = vim.loop.hrtime()
require('zenbufline').set_tabline()
local elapsed = (vim.loop.hrtime() - start) / 1e6  -- Convert to ms
print(string.format("Update took: %.2fms", elapsed))
```

**Expected**:
- 10 buffers: <0.5ms
- 50 buffers: <2ms
- 100 buffers: <5ms

---

## Regression Tests

### Test 21: Old Config Still Works
```lua
-- Old-style minimal config
require("zenbufline").setup()
```

**Expected**:
- Works exactly as before
- All new features use sane defaults
- No breaking changes

### Test 22: Custom Highlights
```lua
require("zenbufline").setup({
  active = {
    bold = false,
    italic = true,
  },
  inactive = {
    bold = true,
    italic = false,
  },
})
```

**Expected**:
- Custom styling applies
- No conflicts with new features
- Updates on colorscheme change

---

## Success Criteria

✅ All mouse clicks work correctly
✅ Navigation commands cycle properly
✅ No lag with 50+ buffers
✅ Truncation displays correctly
✅ Close buffer handles modified files
✅ No errors in any test scenario
✅ Debouncing prevents excessive updates
✅ Cache improves performance noticeably

---

## Troubleshooting

### Mouse clicks don't work
- Check: `vim.opt.mouse='a'` is set
- Try: `:set mouse=a`

### Bufferline not visible
- Check: `vim.opt.showtabline=2` is set
- Try: `:set showtabline=2`

### Close button shows weird character
- Check: Nerd font is installed and active
- Try: Change `close_icon = "x"` (regular x)

### Performance still slow
- Check: How many buffers are open? (`:ls`)
- Try: Enable truncation (`max_visible_buffers = 10`)
- Try: Increase debounce (`debounce_ms = 30`)

### Errors on buffer close
- Check: Is buffer modified?
- Try: Set `force_close_modified = true` (loses changes!)
- Or: Save buffer first (`:w`)

---

## Reporting Issues

If any test fails, please report with:
1. Neovim version (`:version`)
2. Which test failed
3. Error messages if any (`:messages`)
4. Your configuration
5. Number of buffers open (`:ls`)

Happy testing! 🚀

