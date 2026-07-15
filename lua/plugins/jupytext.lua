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
				local current_file = vim.fn.expand("%:p")
				local extension = vim.fn.expand("%:e")
				local target_file

				if extension == "md" then
					target_file = vim.fn.fnamemodify(current_file, ":r") .. ".ipynb"
				elseif extension == "ipynb" then
					target_file = vim.fn.fnamemodify(current_file, ":r") .. ".md"
				end

				if target_file and vim.fn.filereadable(target_file) == 1 then
					vim.fn.jobstart({
						"jupytext",
						"--set-formats",
						"ipynb,md",
						"--sync",
						current_file,
					}, {
						on_exit = function(_, code)
							if code ~= 0 then
								vim.notify("Jupytext: Sync Error!", vim.log.levels.ERROR)
							end
						end,
					})
				end
			end,
		})
	end,
}
