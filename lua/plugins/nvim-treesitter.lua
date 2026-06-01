return {
	"nvim-treesitter/nvim-treesitter",
	branch = "main",
	build = ":TSUpdate",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		require("nvim-treesitter").setup({
			ensure_installed = {
				"bash", 
				"lua",
				"markdown",
				"markdown_inline",
				"python",
				"query",
				"vim",
				"vimdoc",
			},
			highlight = {
				enable = true,
			},
			indent = {
				enable = true,
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("user_treesitter_fold", { clear = true }),
			callback = function()
				vim.wo.foldmethod = "expr"
				vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
				vim.wo.foldlevel = 99
			end,
		})
	end,
}
