-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

local opt = vim.opt

opt.scrolloff = 10 -- Lines of context
opt.cursorline = false -- Disable full line highlight
vim.g.root_spec = "cwd" -- File search and grep only from launch directory
