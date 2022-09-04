# spaceless.nvim

Lua port of https://github.com/thirtythreeforty/lessspace.vim

Strip trailing whitespace as you are editing.

## Installation

[packer.nvim](https://github.com/wbthomason/packer.nvim):
```lua
use {
  'lewis6991/spaceless.nvim',
  config = function()
    require'spaceless'.setup({
      -- example config
      ignore_filetypes = { "markdown" }
    })
  end
}
```
