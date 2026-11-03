return {
  "coder/claudecode.nvim",
  -- Pinned to a commit that was read through; review the diff before moving it.
  commit = "c0deb41a0c6ac74c620be0a683aa9834e535c84a",
  dependencies = { "folke/snacks.nvim" },
  cmd = { "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeAdd", "ClaudeCodeSend" },
  keys = {
    {
      "<leader>ac",
      function()
        require("minh.claude").toggle()
      end,
      desc = "Claude: go to pane, Normal mode (hide from inside)",
    },
    {
      "<leader>af",
      function()
        vim.cmd("ClaudeCodeFocus")
        -- auto_insert is off (Normal mode on entering the pane): this one is to type.
        if vim.bo.buftype == "terminal" then
          vim.cmd.startinsert()
        end
      end,
      desc = "Claude: focus to type",
    },
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
    {
      "<leader>ar",
      function()
        vim.cmd("ClaudeCode --resume")
        -- The session picker takes keys: Insert mode, not the pane's usual Normal.
        if vim.bo.buftype == "terminal" then
          vim.cmd.startinsert()
        end
      end,
      desc = "Claude: resume (pick session)",
    },
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
      "<leader>al",
      function()
        require("minh.claude").commands()
      end,
      desc = "Claude: list the session's commands (to learn from)",
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
  },
  config = function()
    require("claudecode").setup({
      models = require("minh.claude").MODELS,
      -- The default renderer prints the conversation like any program, so it
      -- lands in the terminal buffer's scrollback: <C-\><C-n> then moves, searches
      -- and yanks through all of it. Fullscreen keeps it inside Claude and nvim
      -- only sees the visible screen. Only this pane; ~/.claude/settings.json
      -- keeps its own "tui". Single quotes: claudecode splits this like a shell.
      terminal_cmd = [[claude --settings '{"tui":"default"}']],
      -- Entering the pane (<leader>ac, a click, <C-w>) lands in Normal mode, the
      -- cursor free to move and yank; `i` (or <leader>af) to type.
      -- A float over the editor; <leader>ac hides it again.
      terminal = {
        auto_insert = false,
        snacks_win_opts = { position = "float", width = 0.85, height = 0.85, border = "rounded" },
      },
    })

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
          -- The whole conversation lives in the scrollback: keep a long session.
          vim.bo[args.buf].scrollback = 100000
          -- <A-u>/<A-d> scroll half a page, only inside the pane (a hidden float is
          -- no use scrolling from outside). Terminal mode keeps the view at the
          -- bottom, so while typing they leave it first (`i` to type again).
          vim.keymap.set("t", "<A-u>", [[<C-\><C-n><C-u>]], { buffer = args.buf, desc = "Claude: scroll up (Normal mode)" })
          vim.keymap.set("t", "<A-d>", [[<C-\><C-n><C-d>]], { buffer = args.buf, desc = "Claude: scroll down (Normal mode)" })
          vim.keymap.set("n", "<A-u>", "<C-u>", { buffer = args.buf, desc = "Claude: scroll up" })
          vim.keymap.set("n", "<A-d>", "<C-d>", { buffer = args.buf, desc = "Claude: scroll down" })
          -- q in Normal mode hides the float (no macros in a terminal; same as <leader>ac).
          vim.keymap.set("n", "q", function()
            require("minh.claude").toggle()
          end, { buffer = args.buf, desc = "Claude: hide the pane" })
          -- In Normal mode <C-o> would jump back to the previous buffer; send it to
          -- Claude instead (expands the "ctrl+o to expand" tool output).
          vim.keymap.set("n", "<C-o>", function()
            require("minh.claude").key("\15")
          end, { buffer = args.buf, desc = "Send <C-o> to Claude (expand tool output)" })
        end
      end,
    })
  end,
}
