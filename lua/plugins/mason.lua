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
      -- A pyright left installed by Mason would attach next to basedpyright and
      -- every LSP picker would list each location twice.
      automatic_enable = { exclude = { "pyright" } },
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
        config = function(_, opts)
          require("mason").setup(opts)
          -- Mason installs basedpyright in a venv bound to the python that built it;
          -- once Homebrew or pacman upgrades that python, the server stops starting
          -- and nvim says nothing. Only a file check, so startup stays fast.
          vim.schedule(function()
            local venv = vim.fn.stdpath("data") .. "/mason/packages/basedpyright/venv"
            local python = venv .. (vim.fn.has("win32") == 1 and "/Scripts/python.exe" or "/bin/python")
            if vim.uv.fs_stat(venv) and not vim.uv.fs_stat(python) then
              vim.notify(
                "basedpyright is broken (its venv's python is gone): run :MasonInstall --force basedpyright",
                vim.log.levels.WARN
              )
            end
          end)
        end,
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
