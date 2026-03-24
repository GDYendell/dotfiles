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

vim.keymap.set("n", "<C-j>", "<C-w>h", { desc = "Go to Left Window", remap = false })
vim.keymap.set("n", "<C-k>", "<C-w>j", { desc = "Go to Lower Window", remap = false })
vim.keymap.set("n", "<C-l>", "<C-w>k", { desc = "Go to Upper Window", remap = false })
vim.keymap.set("n", "<C-;>", "<C-w>l", { desc = "Go to Right Window", remap = false })
vim.keymap.set("n", "<C-h>", "<nop>")

vim.keymap.set("n", "<M-Down>", "<cmd>m .+1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<M-Up>", "<cmd>m .-2<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<M-Down>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<M-Up>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<M-Down>", ":m '>+1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<M-Up>", ":m '<-2<cr>gv=gv", { desc = "Move Up" })

vim.keymap.del("n", "<S-h>")
vim.keymap.set("n", "<S-j>", "<cmd>bprevious<cr>", { desc = "Prev Buffer" })
vim.keymap.set("n", ":", "<cmd>bnext<cr>", { desc = "Next Buffer", remap = false })
vim.keymap.del("n", "<S-l>")

-- Move current buffer to a neighboring window, creating a split if none exists
local function move_to_split(direction)
  local buf = vim.api.nvim_get_current_buf()
  local dir = ({ left = "h", right = "l", up = "k", down = "j" })[direction]
  local split_cmds = { left = "leftabove vsp", right = "rightbelow vsp", up = "leftabove sp", down = "rightbelow sp" }

  -- Switch original window away from buf first
  local ok = pcall(vim.cmd, "b#")
  if not ok then vim.cmd("close") return end

  -- Go to target window (create split if no neighbor; split puts focus in new window)
  if vim.fn.winnr(dir) == vim.fn.winnr() then
    vim.cmd(split_cmds[direction])
  else
    vim.cmd("wincmd " .. dir)
  end

  vim.api.nvim_win_set_buf(0, buf)
end

vim.keymap.set("n", "<F8>", "<cmd>lua vim.diagnostic.goto_next()<cr>", { desc = "Next Diagnostic" })
vim.keymap.set("n", "<S-F8>", "<cmd>lua vim.diagnostic.goto_prev()<cr>", { desc = "Prev Diagnostic" })

vim.keymap.set("n", "<leader>bj", function() move_to_split("left") end, { desc = "Move Buffer Left" })
vim.keymap.set("n", "<leader>bk", function() move_to_split("down") end, { desc = "Move Buffer Down" })
vim.keymap.set("n", "<leader>bl", function() move_to_split("up") end, { desc = "Move Buffer Up" })
vim.keymap.set("n", "<leader>b;", function() move_to_split("right") end, { desc = "Move Buffer Right" })

-- Swap lowercase/uppercase for setting marks: lowercase = global, uppercase = local
local low = function(i) return string.char(97+i) end
local upp = function(i) return string.char(65+i) end

for i=0,25 do vim.keymap.set("n", "m"..low(i), "m"..upp(i)) end
for i=0,25 do vim.keymap.set("n", "m"..upp(i), "m"..low(i)) end

-- Jump to mark: swap lower/upper (so lowercase = global), and switch to existing window if open
local function jump_to_mark(use_exact_pos)
  local mark = vim.fn.getcharstr()
  if mark:match("^[a-z]$") then
    mark = mark:upper()
  elseif mark:match("^[A-Z]$") then
    mark = mark:lower()
  end

  local pos = vim.fn.getpos("'" .. mark)
  local bufnr = pos[1]

  local winid = bufnr ~= 0 and vim.fn.bufwinid(bufnr) or -1
  if winid ~= -1 then
    vim.fn.win_gotoid(winid)
    vim.api.nvim_win_set_cursor(winid, { pos[2], pos[3] })
    if not use_exact_pos then vim.cmd("normal! ^") end
  else
    vim.cmd("normal! " .. (use_exact_pos and "`" or "'") .. mark)
  end
end

vim.keymap.set("n", "'", function() jump_to_mark(false) end, { desc = "Jump to Mark (line)" })
vim.keymap.set("n", "`", function() jump_to_mark(true) end, { desc = "Jump to Mark (exact)" })

vim.keymap.set("n", "<leader>md", function()
  local mark = vim.fn.getcharstr()
  if mark:match("^[a-z]$") then mark = mark:upper()
  elseif mark:match("^[A-Z]$") then mark = mark:lower() end
  vim.cmd("delmarks " .. mark)
end, { desc = "Delete Mark <char>" })

vim.keymap.set("n", "<leader>mD", "<cmd>delmarks A-Z<cr>", { desc = "Delete All Marks" })
vim.keymap.set("n", "<leader>mf", "<cmd>FzfLua marks<cr>", { desc = "Find Marks" })
