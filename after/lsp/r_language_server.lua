local status_ok, lsp_utils = pcall(require, "minh.lsp_utils")

local cmd = { "sh", "-c", "R --slave -e 'languageserver::run()'" }

if vim.env.CONDA_PREFIX then
  cmd = { os.getenv("CONDA_PREFIX") .. "/bin/R", "--slave", "-e", "languageserver::run()" }
end

return {
  -- cmd = { os.getenv("CONDA_PREFIX") .. "/bin/R", "--slave", "-e", "languageserver::run()" },
  -- cmd = { "sh", "-c", "R --slave -e 'languageserver::run()'" }, -- Multi-environment R LSP hook (inherits active Conda/renv context)
  cmd = cmd,
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
