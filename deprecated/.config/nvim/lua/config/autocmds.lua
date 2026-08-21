-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here
-- Auto toggles relative and absolute line numbers depending on vim current mode

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
