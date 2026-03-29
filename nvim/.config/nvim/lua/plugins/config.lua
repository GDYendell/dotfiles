if true then
  return {
    -- Use dracula theme
    { "Mofiqul/dracula.nvim" },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "dracula",
      },
    },

    {
      "folke/trouble.nvim",
      opts = { use_diagnostic_signs = true },
    },

    { "nvim-mini/mini.surround", opts = {} },

    {
      "nvim-lualine/lualine.nvim",
      opts = function(_, opts)
        opts.sections.lualine_z = {
          function()
            return " "
          end,
        }
      end,
    },

    -- stylua: ignore start
    {
      "snacks.nvim",
      opts = {
        terminal = {
          win = {
            keys = {
              nav_h = { "<C-j>", function(self) return self:is_floating() and "<C-j>" or vim.schedule(function() vim.cmd.wincmd("h") end) end, desc = "Go to Left Window",  expr = true, mode = "t" },
              nav_j = { "<C-k>", function(self) return self:is_floating() and "<C-k>" or vim.schedule(function() vim.cmd.wincmd("j") end) end, desc = "Go to Lower Window", expr = true, mode = "t" },
              nav_k = { "<C-l>", function(self) return self:is_floating() and "<C-l>" or vim.schedule(function() vim.cmd.wincmd("k") end) end, desc = "Go to Upper Window",  expr = true, mode = "t" },
              nav_l = { "<C-;>", function(self) return self:is_floating() and "<C-;>" or vim.schedule(function() vim.cmd.wincmd("l") end) end, desc = "Go to Right Window", expr = true, mode = "t" },
            },
          },
        },
      },
    },
    -- stylua: ignore end

    {
      "folke/noice.nvim",
      opts = {
        presets = {
          lsp_doc_border = true,
        },
      },
    },

    {
      "saghen/blink.cmp",
      opts = {
        sources = {
          default = { "lsp", "path" },
        },
      },
    },

    -- add more treesitter parsers
    {
      "nvim-treesitter/nvim-treesitter",
      opts = {
        ensure_installed = {
          "bash",
          "html",
          "javascript",
          "json",
          "lua",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "regex",
          "tsx",
          "typescript",
          "vim",
          "yaml",
        },
      },
    },

    -- {
    --   "greggh/claude-code.nvim",
    --   dependencies = {
    --     "nvim-lua/plenary.nvim", -- Required for git operations
    --   },
    --   config = function()
    --     require("claude-code").setup({
    --       window = {
    --         position = "float",
    --         float = {
    --           width = "90%", -- Take up 90% of the editor width
    --           height = "90%", -- Take up 90% of the editor height
    --           row = "center", -- Center vertically
    --           col = "center", -- Center horizontally
    --           relative = "editor",
    --           border = "double", -- Use double border style
    --         },
    --       },
    --     })
    --   end,
    -- },
  }
end
