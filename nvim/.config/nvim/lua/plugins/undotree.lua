return {
  "mbbill/undotree",

  config = function()
    vim.keymap.set("n", "<leader>Z", vim.cmd.UndotreeToggle)
  end,
}
