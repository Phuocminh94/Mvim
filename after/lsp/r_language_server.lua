local status_ok, lsp_utils = pcall(require, "minh.lsp_utils")
return {
	cmd = { os.getenv("CONDA_PREFIX") .. "/bin/R", "--slave", "-e", "languageserver::run()" },
  capabilities =  lsp_utils.capabilities,
  on_attach = lsp_utils.on_attach,
	root_markers = { ".git", ".Rprofile", "DESCRIPTION" },
	filetypes = { "r", "rmd" },
	settings = {
		r = {
			lsp = {
				diagnostics = true,
			},
		},
	},
}
