local utils = require("minh.utils")
local chat_dir = utils.gp_chat_dir
local USER_PREFIX, ASSISTANT_PREFIX = utils.gp_user_prefix, utils.gp_assistant_prefix

--- Move to the next/previous line starting with `prefix`, with it at the top of the window.
local function jump_to(prefix, backward)
  local flags = backward and "bW" or "W"
  local found = 0
  for _ = 1, vim.v.count1 do
    found = math.max(found, vim.fn.search("\\V\\^" .. vim.fn.escape(prefix, "\\"), flags))
  end
  -- No question/answer in that direction: leave the view alone.
  if found > 0 then
    vim.cmd("normal! zt")
  end
end

return {
  "Phuocminh94/gp.nvim",
  cmd = { "GpChatNew", "GpChatToggle", "GpChatPaste", "GpChatFinder" },
  -- Also load when an existing chat file is opened directly (picker, recent
  -- files, :e), so gp can set up its chat buffer features for it.
  event = { "BufReadPre " .. chat_dir .. "/*" },
  keys = {
    { "<leader>Ai", "<cmd>GpChatNew vsplit<cr>", desc = "Gemini: new chat" },
    { "<leader>ai", "<cmd>GpChatToggle vsplit<cr>", desc = "Gemini: toggle chat panel" },
    { "<leader>ai", ":<C-u>'<,'>GpChatPaste vsplit<cr>", mode = "x", desc = "Gemini: paste selection into chat" },
  },
  config = function()
    require("gp").setup({
      default_command_agent = "Gemini",
      default_chat_agent = "Gemini",
      chat_user_prefix = USER_PREFIX,
      chat_assistant_prefix = { ASSISTANT_PREFIX, "" }, -- no "[agent]" suffix
      -- Leave the cursor alone while the answer streams in and when it ends;
      -- by default gp drags it to the end of the buffer and the window scrolls
      -- past what you were reading. <leader>ag jumps to the prompt instead.
      chat_free_cursor = true,

      providers = {
        -- gp ships with openai enabled; an empty table turns it off, so it
        -- does not look for an OpenAI key (the "vault secret not found" warning).
        openai = {},
        -- Listing a provider enables it; the endpoint defaults to the
        -- streamGenerateContent URL, so only the key needs overriding
        -- (gp's default reads GOOGLEAI_API_KEY).
        -- `disable = false` keeps the table non-empty: gp treats an empty table as
        -- "disable this provider", which is what `{ secret = nil }` becomes when
        -- GEMINI_API_KEY is not set in nvim's environment.
        googleai = {
          disable = false,
          secret = os.getenv("GEMINI_API_KEY"),
        },
      },
      agents = {
        {
          name = "Gemini",
          provider = "googleai",
          chat = true, -- gp only lists agents for chat when this is set
          model = { model = "gemini-3.5-flash-lite" },
          system_prompt = "Always provide accurate, logical, and optimized responses.",
        },
      },
    })

    -- Gemini: system prompt as systemInstruction, pasted images (<leader>p) with the question.
    require("minh.gp_gemini").setup()

    -- Disable spellcheck only for gp.nvim chat buffers. Matching the chat
    -- directory is more reliable than the filetype (markdown is shared with
    -- every normal .md file).
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufRead" }, {
      group = vim.api.nvim_create_augroup("minh.gp.no_spell", { clear = true }),
      pattern = chat_dir .. "/*",
      callback = function(args)
        vim.opt_local.spell = false
        vim.keymap.set("n", "<leader>ag", function()
          vim.cmd("normal! G")
          vim.cmd.startinsert({ bang = true })
        end, { buffer = args.buf, desc = "Gemini: go to prompt" })
        local function map(lhs, prefix, backward, desc)
          vim.keymap.set("n", lhs, function()
            jump_to(prefix, backward)
          end, { buffer = args.buf, desc = desc })
        end
        map("[a", USER_PREFIX, true, "Gemini: previous question")
        map("]a", USER_PREFIX, false, "Gemini: next question")
        map("[A", ASSISTANT_PREFIX, true, "Gemini: previous answer")
        map("]A", ASSISTANT_PREFIX, false, "Gemini: next answer")
      end,
    })

    -- The cursor no longer follows the answer, so say when it is complete.
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("minh.gp.done", { clear = true }),
      pattern = "GpDone",
      callback = function()
        vim.notify("Gemini finished. <leader>ag jumps to the prompt", vim.log.levels.INFO)
      end,
    })
  end,
}
