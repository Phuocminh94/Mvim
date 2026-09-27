return {
  "Phuocminh94/gp.nvim",
  enabled = true,
  config = function()
    require("gp").setup({
      default_command_agent = "Gemini",
      default_chat_agent = "Gemini",
      chat_user_prefix = "💬 MBP ",
      chat_assistant_prefix = "🤖 ",

      providers = {
        googleai = {
          endpoint =
          "https://generativelanguage.googleapis.com/v1beta/models/{{model}}:streamGenerateContent?key={{secret}}",
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

    -- Disable spellcheck only for gp.nvim chat buffers.
    -- gp.nvim chat files are always saved under the chat_dir directory
    -- (default: stdpath("data") .. "/gp/chats"), so matching by path
    -- is more reliable than matching by filetype ("markdown", shared
    -- with all normal .md files).
    local gp_chat_dir = vim.fn.stdpath("data") .. "/gp/chats"
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufRead" }, {
      group = vim.api.nvim_create_augroup("gp_nvim_no_spell", { clear = true }),
      pattern = gp_chat_dir .. "/*",
      callback = function()
        vim.opt_local.spell = false
      end,
    })

    vim.keymap.set("n", "<Leader>Ai", "<cmd>GpChatNew vsplit<cr>", { desc = "AI Chat New" })
    vim.keymap.set("n", "<Leader>ai", "<cmd>GpChatToggle vsplit<cr>", { desc = "AI Chat Toggle Panel" })
    vim.keymap.set("v", "<Leader>ai", ":<C-u>'<,'>GpChatPaste vsplit<cr>", { desc = "AI Chat Paste Selection" })
  end,
}
