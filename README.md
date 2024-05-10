# Notes

Setup steps nvim :  
Add `.config/nvim/lua/plugins/colorscheme.lua`

```lua
return {
  { "oxfist/night-owl.nvim" },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "night-owl",
    },
  },
}
```

Edit autocommands for auto toggle between relative and absolute line numbers
```lua
_G.toggle_line_numbering = function()
  if vim.wo.number and vim.fn.mode() ~= "i" then
    vim.wo.relativenumber = true
  else
    vim.wo.relativenumber = false
  end
end

-- Set up autocmd using Lua
vim.cmd([[
  augroup numbertoggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave,WinEnter * lua toggle_line_numbering()
    autocmd BufLeave,FocusLost,InsertEnter,WinLeave * set nornu
  augroup END
]])
```
