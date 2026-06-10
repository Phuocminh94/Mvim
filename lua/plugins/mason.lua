return {
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      -- list of servers for mason to install
      ensure_installed = {
        "lua_ls",
        "basedpyright"
      },
    },
    dependencies = {
      {
        "williamboman/mason.nvim",
        opts = {
          PATH = "append", -- Prioritize system/user global binaries over Mason-installed ones`
          ui = {
            icons = {
              package_installed = "✓",
              package_pending = "➜",
              package_uninstalled = "✗",
            },
          },
        },
      },
      {"neovim/nvim-lspconfig"}
  },
}
}
