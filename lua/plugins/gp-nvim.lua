return {
	"Robitx/gp.nvim",
	enabled = true,
	config = function()
		require("gp").setup({
			default_command_agent = "Gemini",
			default_chat_agent = "Gemini",
			chat_user_prefix = "💬 MBP ",
			chat_assistant_prefix = "🤖 ",

			providers = {
				googleai = {
					endpoint = "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
					secret = os.getenv("GEMINI_API_KEY"),
				},
			},
			agents = {
				{
					name = "Gemini",
					provider = "googleai",
					model = { model = "gemini-3.1-flash-lite" },
					system_prompt = "Always provide accurate, logical, and optimized responses.",
				},
			},
		})

		vim.keymap.set("n", "<Leader>Ai", "<cmd>GpChatNew vsplit<cr>", { desc = "AI Chat New" })
		vim.keymap.set("n", "<Leader>ai", "<cmd>GpChatToggle vsplit<cr>", { desc = "AI Chat Toggle Panel" })
		vim.keymap.set("v", "<Leader>ai", ":<C-u>'<,'>GpChatPaste vsplit<cr>", { desc = "AI Chat Paste Selection" })
	end,
}
