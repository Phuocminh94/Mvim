return {
	"nvim-mini/mini.indentscope",
	version = false,
	opts = {
		symbol = "│",
		options = { try_as_border = true },
		draw = { delay = 100 },
	},
	init = function()
		local disabled_filetypes = {
			"dashboard",
			"fzf",
			"help",
			"lazy",
			"mason",
			"neo-tree",
			"notify",
			"terminal",
		}

		vim.api.nvim_create_autocmd("FileType", {
			pattern = disabled_filetypes,
			callback = function()
				vim.b.miniindentscope_disable = true
			end,
		})

		vim.api.nvim_create_autocmd("TermOpen", {
			pattern = "*",
			callback = function()
				vim.b.miniindentscope_disable = true
			end,
		})
	end,
}
