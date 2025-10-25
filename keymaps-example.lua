-- Example keymaps for zenbufline.nvim
-- Add these to your init.lua or keymaps configuration file

local zenbufline = require('zenbufline')

-- Buffer navigation
vim.keymap.set('n', '<Tab>', zenbufline.next_buffer, {
  desc = 'Next buffer',
  silent = true
})

vim.keymap.set('n', '<S-Tab>', zenbufline.prev_buffer, {
  desc = 'Previous buffer',
  silent = true
})

-- Buffer management
vim.keymap.set('n', '<leader>bc', zenbufline.close_current_buffer, {
  desc = 'Close current buffer',
  silent = true
})

-- Jump to specific buffer by index (1-9)
for i = 1, 9 do
  vim.keymap.set('n', '<leader>' .. i, function()
    zenbufline.goto_buffer(i)
  end, {
    desc = 'Go to buffer ' .. i,
    silent = true
  })
end

-- Alternative: Use Alt+number for quick access
for i = 1, 9 do
  vim.keymap.set('n', '<M-' .. i .. '>', function()
    zenbufline.goto_buffer(i)
  end, {
    desc = 'Go to buffer ' .. i,
    silent = true
  })
end

-- Alternative navigation with Ctrl+h/l (vim-style)
vim.keymap.set('n', '<C-l>', zenbufline.next_buffer, {
  desc = 'Next buffer',
  silent = true
})

vim.keymap.set('n', '<C-h>', zenbufline.prev_buffer, {
  desc = 'Previous buffer',
  silent = true
})

-- Alternative with arrow keys
vim.keymap.set('n', '<leader><Right>', zenbufline.next_buffer, {
  desc = 'Next buffer',
  silent = true
})

vim.keymap.set('n', '<leader><Left>', zenbufline.prev_buffer, {
  desc = 'Previous buffer',
  silent = true
})

