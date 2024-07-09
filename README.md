# zenbufline.nvim
A minimal lua based buffer line for neovim

### 🚧 WIP 🚧

## Requirements
* Requires neovim version >= 0.10
* `vim.opt.showtabline=2` in your init.lua for bufferlin.
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
## Minimum Configuration
```lua
require("zenbufline").setup()
```
### Click to see default configuration
 Default configuration is here [options](https://github.com/abhilash26/zenbufline.nvim/blob/main/lua/zenbufline/default_options.lua)
