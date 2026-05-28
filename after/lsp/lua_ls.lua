local status_ok, lsp_utils = pcall(require, "minh.lsp_utils")

return {
  capabilities =  lsp_utils.capabilities,
  on_attach = lsp_utils.on_attach,
  settings = {
    Lua = {
      diagnostics = {
        globals = { "vim" }
      },
      workspace = {
        library = {
          [vim.fn.expand("$VIMRUNTIME/lua")] = true,
          [vim.fn.expand("$VIMRUNTIME/lua/vim/lsp")] = true,
        },
        maxPreload = 2000,
        preloadFileSize = 1000,
      },
    },
  },
}
