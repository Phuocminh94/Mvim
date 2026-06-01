return {
	"mbbill/undotree",
	config = function()
		-- Toggle Undotree visual history panel
		vim.keymap.set("n", "<leader>u", "<cmd>UndotreeToggle<cr>", { desc = "Toggle Undo Tree" })
	end,
}
