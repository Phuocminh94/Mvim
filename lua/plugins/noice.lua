-- https://www.reddit.com/r/neovim/comments/1b8ccyu/how_to_stop_automatic_display_of_signature_help/
-- https://github.com/folke/noice.nvim/issues/1172
return {
	"folke/noice.nvim",
	event = "VeryLazy",
	enabled = true,
	opts = {
		lsp = {
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
			signature = {
        enabled=false,
				auto_open = { enabled = false },
				opts = {
          -- Prevents the signature panel from stealing focus while typing
					focus = false,
				},
			},
		},
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
					},
				},
				view = "mini",
			},
		},
		presets = {
			bottom_search = true,
			command_palette = true,
			long_message_to_split = true,
			lsp_doc_border = true,
		},
	},
	dependencies = {
		"MunifTanjim/nui.nvim",
		{
			"folke/snacks.nvim",
			opts = {
				bigfile = { enabled = false },
				dashboard = { enabled = false },
				explorer = { enabled = false },
        image = {enabled = true},
				indent = { enabled = false },
				input = { enabled = false },
        lazygit = {enabled = false},
				notifier = { enabled = true },
				picker = { enabled = false },
				quickfile = { enabled = false },
				scope = { enabled = false },
				scroll = { enabled = false },
				statuscolumn = { enabled = false },
				words = { enabled = false },
			},
		},
	},
	config = function(_, opts)
		-- HACK: noice shows messages from before it was enabled,
		-- but this is not ideal when Lazy is installing plugins,
		-- so clear the messages in this case.
		if vim.o.filetype == "lazy" then
			vim.cmd([[messages clear]])
		end
		require("noice").setup(opts)
	end,
}
