return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts_extend = { "spec" },
	opts = {
		preset = "helix",
		defaults = {},
		icons = {
			mappings = false, -- removes icons for individual mappings
			rules = false, -- removes automatic icon rules
			breadcrumb = "", -- removes the breadcrumb icon
			group = "", -- removes the group folder icon (annoying +)
		},
		spec = {
			{ "<leader>", group = "󱁐 Leader" }, -- Change annoying "+Ignore Space" to "󱁐 Leader"
		},
	},
	keys = {
		{
			"<leader>?",
			function()
				require("which-key").show({ global = false })
			end,
			desc = "Buffer Keymaps (which-key)",
		},
		{
			"<c-w><space>",
			function()
				require("which-key").show({ keys = "<c-w>", loop = true })
			end,
			desc = "Window Hydra Mode (which-key)",
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
	end,
}
