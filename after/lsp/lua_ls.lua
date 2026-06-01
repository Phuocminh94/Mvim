local status_ok, lsp_utils = pcall(require, "minh.lsp_utils")

return {
  capabilities =  lsp_utils.capabilities,
  on_attach = lsp_utils.on_attach
}
