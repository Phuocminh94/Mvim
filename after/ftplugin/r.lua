vim.keymap.set("n", "<leader>ls", function()
  vim.lsp.enable("r_language_server")
  print("R LSP Enabled!")
end, { buffer = true, desc = "Enable R LSP" })
