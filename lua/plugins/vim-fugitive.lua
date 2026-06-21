return {
	"tpope/vim-fugitive",
	cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gstatus" },
	keys = {
		{ "<leader>gs", "<cmd>Git<cr>", desc = "Git Status" },
		{ "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git Diff" },
	},
}
