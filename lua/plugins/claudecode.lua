return {
  "coder/claudecode.nvim",
  -- Pinned to a commit that was read through; review the diff before moving it.
  commit = "c0deb41a0c6ac74c620be0a683aa9834e535c84a",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeAdd", "ClaudeCodeSend" },
  keys = {
    {
      "<leader>at",
      function()
        require("minh.claude").toggle()
      end,
      desc = "Claude: toggle (no focus)",
    },
    { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Claude: focus" },
    { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Claude: add buffer" },
    { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "x", desc = "Claude: send selection" },
    { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Claude: accept diff" },
    { "<leader>an", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Claude: deny diff" },
    {
      "<leader>am",
      function()
        require("minh.claude").select_model()
      end,
      desc = "Claude: select model",
    },
    -- Session: the pane is one session; these only apply when no pane is running.
    { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Claude: resume (pick session)" },
    {
      "<leader>aq",
      function()
        require("minh.claude").quit()
      end,
      desc = "Claude: quit (/exit, ends session)",
    },
    -- Without focusing the pane (minh.claude):
    {
      "<leader>aa",
      function()
        require("minh.claude").ask()
      end,
      mode = { "n", "x" },
      desc = "Claude: ask about selection/function",
    },
    {
      "<leader>aA",
      function()
        require("minh.claude").ask(true)
      end,
      desc = "Claude: ask a general question (no code reference)",
    },
    {
      "<leader>ap",
      function()
        require("minh.claude").ask_clipboard()
      end,
      mode = { "n", "x" },
      desc = "Claude: send clipboard / selection (+ optional question)",
    },
    {
      "<leader>ac",
      function()
        require("minh.claude").transcript()
      end,
      desc = "Claude: conversation (browse, copy from it)",
    },
    {
      "<leader>a1",
      function()
        require("minh.claude").key("1")
      end,
      desc = "Claude: answer 1 (yes)",
    },
    {
      "<leader>a2",
      function()
        require("minh.claude").key("2")
      end,
      desc = "Claude: answer 2",
    },
    {
      "<leader>a3",
      function()
        require("minh.claude").key("3")
      end,
      desc = "Claude: answer 3 (no)",
    },
    {
      "<leader>a<CR>",
      function()
        require("minh.claude").key("\r")
      end,
      desc = "Claude: Enter",
    },
    {
      "<leader>ax",
      function()
        require("minh.claude").key("\27")
      end,
      desc = "Claude: interrupt (Esc)",
    },
    {
      "<leader>aj",
      function()
        require("minh.claude").scroll_mode()
      end,
      desc = "Claude: browse transcript ([ ] j k d u g G)",
    },
    {
      "<A-d>",
      function()
        require("minh.claude").page(1)
      end,
      desc = "Claude: scroll half page down",
    },
    {
      "<A-u>",
      function()
        require("minh.claude").page(-1)
      end,
      desc = "Claude: scroll half page up",
    },
  },
  config = function()
    require("claudecode").setup({ models = require("minh.claude").MODELS })

    -- Show what Claude wrote: reload buffers changed on disk (see minh.claude).
    vim.o.autoread = true
    local group = vim.api.nvim_create_augroup("claudecode_reload", { clear = true })
    vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
      group = group,
      callback = require("minh.claude").reload_changed,
    })
    vim.api.nvim_create_autocmd("FileChangedShellPost", {
      group = group,
      callback = function(args)
        vim.notify("Reloaded " .. vim.fn.fnamemodify(args.file, ":t") .. " (changed on disk)", vim.log.levels.INFO)
      end,
    })
    require("minh.claude").watch_files()

    -- Claude Code uses <Esc> to interrupt, so pass it through instead of the
    -- global `t <Esc>` (leave terminal mode). <C-\><C-n> still leaves it.
    vim.api.nvim_create_autocmd("TermOpen", {
      group = vim.api.nvim_create_augroup("claudecode_term_esc", { clear = true }),
      callback = function(args)
        if vim.api.nvim_buf_get_name(args.buf):find("claude", 1, true) then
          vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = args.buf, desc = "Send <Esc> to Claude" })
        end
      end,
    })
  end,
}
