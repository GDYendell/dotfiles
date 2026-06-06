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

    {
      "nvim-neotest/neotest",
      opts = {
        floating = {
          border = "rounded",
        },
      },
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
        lazygit = {
          win = {
            border = "rounded",
          },
        },
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

    { "rickhowe/diffchar.vim" },

    {
      "pwntester/octo.nvim",
      cmd = "Octo",
      dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-tree/nvim-web-devicons",
      },
      opts = {
        picker = "fzf-lua",
      },
      init = function()
        vim.api.nvim_create_autocmd("ColorScheme", {
          pattern = "*",
          callback = function()
            vim.api.nvim_set_hl(0, "DiffAdd", { bg = "#1a3a1a", fg = "#50fa7b" })
            vim.api.nvim_set_hl(0, "DiffDelete", { bg = "#3a1a1a", fg = "#ff5555" })
            vim.api.nvim_set_hl(0, "DiffChange", { bg = "#1a1a3a", fg = "#8be9fd" })
            vim.api.nvim_set_hl(0, "DiffText", { bg = "#2a2a5a", fg = "#f8f8f2", bold = true })
          end,
        })
      end,
    },

    {
      "nvim-treesitter/nvim-treesitter-context",
      opts = { max_lines = 0 },
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

    {
      "christoomey/vim-tmux-navigator",
      init = function()
        vim.g.tmux_navigator_no_mappings = 1
      end,
      cmd = {
        "TmuxNavigateLeft",
        "TmuxNavigateDown",
        "TmuxNavigateUp",
        "TmuxNavigateRight",
        "TmuxNavigatePrevious",
        "TmuxNavigatorProcessList",
      },
      keys = {
        { "<c-j>", "<cmd>TmuxNavigateLeft<cr>", mode = { "n", "t" } },
        { "<c-k>", "<cmd>TmuxNavigateDown<cr>", mode = { "n", "t" } },
        { "<c-l>", "<cmd>TmuxNavigateUp<cr>", mode = { "n", "t" } },
        { "<c-;>", "<cmd>TmuxNavigateRight<cr>", mode = { "n", "t" } },
        { "<c-tab>", "<cmd>TmuxNavigatePrevious<cr>", mode = { "n", "t" } },
      },
    },

    {
      "lewis6991/gitsigns.nvim",
      opts = {
        current_line_blame = true,
      },
    },

    {
      "mrcjkb/rustaceanvim",
      opts = {
        server = {
          cmd = { "rustup", "run", "nightly", "rust-analyzer" },
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
