return {
	"GCBallesteros/jupytext.nvim",
	config = function()
		require("jupytext").setup({
			style = "markdown",
			output_extension = "md",
		})

		local jupytext_sync = vim.api.nvim_create_augroup("JupytextSync", { clear = true })

		vim.api.nvim_create_autocmd("BufWritePost", {
			group = jupytext_sync,
			pattern = { "*.ipynb", "*.md" },
			callback = function()
				local current_file = vim.fn.expand("%")
				vim.fn.jobstart({
					"jupytext",
					"--set-formats",
					"ipynb,md",
					"--sync",
					current_file,
				}, {
					on_exit = function(_, code)
						if code == 0 then
						else
							vim.notify("Jupytext: Sync Error!", vim.log.levels.ERROR)
						end
					end,
				})
			end,
		})
	end,
}
