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
    { "<leader>Ai", "<cmd>GpChatNew vsplit<cr>", desc = "AI Chat New" },
    { "<leader>ai", "<cmd>GpChatToggle vsplit<cr>", desc = "AI Chat Toggle Panel" },
    { "<leader>ai", ":<C-u>'<,'>GpChatPaste vsplit<cr>", mode = "x", desc = "AI Chat Paste Selection" },
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
          model = { model = "gemini-3.5-flash-lite" },
          system_prompt = "Always provide accurate, logical, and optimized responses.",
        },
      },
    })

    -- Images pasted with <leader>p (img-clip) go to Gemini with the question.
    require("minh.gp_images").setup()

    -- Disable spellcheck only for gp.nvim chat buffers. Matching the chat
    -- directory is more reliable than the filetype (markdown is shared with
    -- every normal .md file).
    vim.api.nvim_create_autocmd({ "BufWinEnter", "BufRead" }, {
      group = vim.api.nvim_create_augroup("gp_nvim_no_spell", { clear = true }),
      pattern = chat_dir .. "/*",
      callback = function(args)
        vim.opt_local.spell = false
        vim.keymap.set("n", "<leader>ag", function()
          vim.cmd("normal! G")
          vim.cmd.startinsert({ bang = true })
        end, { buffer = args.buf, desc = "AI Chat: go to prompt" })
        local function map(lhs, prefix, backward, desc)
          vim.keymap.set("n", lhs, function()
            jump_to(prefix, backward)
          end, { buffer = args.buf, desc = desc })
        end
        map("[a", USER_PREFIX, true, "AI Chat: previous question")
        map("]a", USER_PREFIX, false, "AI Chat: next question")
        map("[A", ASSISTANT_PREFIX, true, "AI Chat: previous answer")
        map("]A", ASSISTANT_PREFIX, false, "AI Chat: next answer")
      end,
    })

    -- The cursor no longer follows the answer, so say when it is complete.
    vim.api.nvim_create_autocmd("User", {
      group = vim.api.nvim_create_augroup("gp_nvim_done", { clear = true }),
      pattern = "GpDone",
      callback = function()
        vim.notify("Gemini finished. <leader>ag jumps to the prompt", vim.log.levels.INFO)
      end,
    })
  end,
}
