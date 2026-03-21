-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Use Enter for command mode
vim.keymap.set("n", "<CR>", ":", { desc = "Command Mode", remap = false })

-- Use i3 movements
vim.keymap.set({ "n", "x" }, "j", "<Left>")
vim.keymap.set({ "n", "x" }, "k", "<Down>")
vim.keymap.set({ "n", "x" }, "l", "<Up>")
vim.keymap.set({ "n", "x" }, ";", "<Right>")
vim.keymap.set({ "n", "x" }, "h", "<nop>")

vim.keymap.set("n", "<C-j>", "<C-w>h", { desc = "Go to Left Window", remap = true })
vim.keymap.set("n", "<C-k>", "<C-w>j", { desc = "Go to Lower Window", remap = true })
vim.keymap.set("n", "<C-;>", "<C-w>l", { desc = "Go to Right Window", remap = true })
vim.keymap.set("n", "<C-l>", "<C-w>k", { desc = "Go to Upper Window", remap = true })
vim.keymap.set("n", "<C-h>", "<nop>")

vim.keymap.set("n", "<A-k>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-l>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-l>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-k>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-l>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

vim.keymap.del("n", "<S-h>")
vim.keymap.set("n", "<S-j>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", ":", "<cmd>bnext<cr>", { desc = "Next Buffer", remap = false })
vim.keymap.del("n", "<S-l>")
