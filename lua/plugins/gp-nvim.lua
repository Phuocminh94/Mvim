-- gp.nvim saves chats here (its default chat_dir)
local chat_dir = vim.fn.stdpath("data") .. "/gp/chats"

return {
  "Phuocminh94/gp.nvim",
  cmd = { "GpChatNew", "GpChatToggle", "GpChatPaste", "GpChatFinder" },
  -- Also load when an existing chat file is opened directly (picker, recent
  -- files, :e), so gp can set up its chat buffer features for it.
  event = { "BufReadPre " .. chat_dir .. "/*" },
  keys = {
    { "<leader>Ai", "<cmd>GpChatNew vsplit<cr>", desc = "AI Chat New" },
    { "<leader>ai", "<cmd>GpChatToggle vsplit<cr>", desc = "AI Chat Toggle Panel" },
    { "<leader>ai", ":<C-u>'<,'>GpChatPaste vsplit<cr>", mode = "x", desc = "AI Chat Paste Selection" },
  },
  config = function()
    require("gp").setup({
      default_command_agent = "Gemini",
      default_chat_agent = "Gemini",
      chat_user_prefix = "💬 MBP ",
      chat_assistant_prefix = "🤖 ",

      providers = {
        -- Listing a provider enables it; the endpoint defaults to the
        -- streamGenerateContent URL, so only the key needs overriding
        -- (gp's default reads GOOGLEAI_API_KEY).
        googleai = {
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

    -- Disable spellcheck only for gp.nvim chat buffers. Matching the chat
    -- directory is more reliable than the filetype (markdown is shared with
    -- every normal .md file).
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufRead" }, {
      group = vim.api.nvim_create_augroup("gp_nvim_no_spell", { clear = true }),
      pattern = chat_dir .. "/*",
      callback = function()
        vim.opt_local.spell = false
      end,
    })
  end,
}
