return {
  {
    -- The repos moved from williamboman/* to mason-org/* (GitHub redirects the old URLs).
    "mason-org/mason-lspconfig.nvim",
    opts = {
      -- Servers for Mason to install. mason-lspconfig v2 also calls
      -- vim.lsp.enable() for every installed server (automatic_enable = true),
      -- so do not enable them again elsewhere.
      ensure_installed = {
        "lua_ls",
        "basedpyright",
      },
    },
    dependencies = {
      {
        "mason-org/mason.nvim",
        opts = {
          PATH = "append", -- prefer system/user binaries over Mason-installed ones
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
      {
        "neovim/nvim-lspconfig",
        -- Runs before mason-lspconfig enables servers: borders, diagnostics,
        -- capabilities, LspAttach features and the R server.
        config = function()
          require("minh.lsp_utils").setup()
        end,
      },
    },
  },
}
