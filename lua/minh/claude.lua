-- =============================================================================
-- minh.claude — drive the Claude Code pane without leaving the current buffer
--
--   ask(general) prompt for a question (cursor stays put), send it to Claude with
--                an @file#Lx-y reference to the selection, or else to the
--                function/class around the cursor (treesitter), or the line;
--                with `general`, no reference at all
--   ask_clipboard() same, but sends the system clipboard (terminal output, a
--                browser snippet...) as a code block; the question may be empty;
--                in visual mode, copies the selection first
--   start(args)  start Claude with CLI args (--resume, --model X), no focus
--   toggle()     go into the pane in Normal mode (shows/starts it if needed),
--                or hide it from inside; `i` types to Claude
--   quit()       end the session with /exit (no "exited with code" error)
--   watch_files() reload buffers Claude edits on disk while the pane runs
--   key(bytes)   type raw keys into the pane: "1"/"2"/"3" for permission
--                prompts, "\27" (<Esc>) to interrupt, "\r" for Enter
--   select_model() choose a model by exact version (/model in a running pane)
--   toggle_markdown() render math in the pane (pretend markdown) or back to text
--   commands()   every tool call of the session in a tab (sh): Bash commands
--                verbatim with description and first output lines, to learn from
--   show_tool_output() <C-o> on a collapsed tool call in the pane: its full output
--
-- The pane must already be running (<leader>ac); apart from toggle(), this
-- never focuses it.
-- Built on claudecode.terminal, whose send_to_terminal() does the chansend.
-- =============================================================================

local M = {}

local SUBMIT_DELAY_MS = 150
local COMMAND_DELAY_MS = 250 -- time for Claude's slash-command menu to open
local IMAGE_DELAY_MS = 400 -- time for Claude to read the pasted image
local MAX_PROMPT_LINES = 10

local function terminal()
  return require("claudecode.terminal")
end

--- Buffer of the running Claude terminal, or nil (with a notice).
local function pane()
  local bufnr = terminal().get_active_terminal_bufnr()
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    vim.notify("Claude is not running (<leader>ac)", vim.log.levels.WARN)
    return nil
  end
  return bufnr
end

--- Line range (1-based, inclusive) of the function or class around the cursor.
local function enclosing_range()
  local ok, node = pcall(vim.treesitter.get_node)
  while ok and node do
    local t = node:type()
    if t:find("function", 1, true) or t:find("method", 1, true) or t:find("class", 1, true) then
      local first, _, last = node:range()
      return first + 1, last + 1
    end
    node = node:parent()
  end
  local row = vim.fn.line(".")
  return row, row
end

--- "@path#Lx-y" for the visual selection, else the enclosing function, else the line.
local function reference(visual)
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return nil, "buffer has no file"
  end
  local first, last
  if visual then
    first, last = vim.fn.line("v"), vim.fn.line(".")
    if first > last then
      first, last = last, first
    end
  else
    first, last = enclosing_range()
  end
  local path = vim.fn.fnamemodify(name, ":.")
  return first == last and ("@%s#L%d"):format(path, first) or ("@%s#L%d-%d"):format(path, first, last)
end

--- The window showing the pane, or nil. A hidden float keeps its window (with
--- `hide` set in its config), so a window alone does not mean visible.
local function visible_win(bufnr)
  for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
    if not vim.api.nvim_win_get_config(win).hide then
      return win
    end
  end
end

--- A hidden pane stays hidden (it still gets the text and keeps working): say so,
--- since a permission prompt there would wait unseen. <leader>ac shows it.
local function note_if_hidden(bufnr)
  if not visible_win(bufnr) then
    vim.notify("Sent to Claude (pane hidden: <leader>ac to show)", vim.log.levels.INFO)
  end
end

--- Send `text` to the pane and submit it.
local function submit(text)
  local bufnr = pane()
  if not bufnr then
    return
  end
  note_if_hidden(bufnr)
  -- A "\r" in the same write as the text is taken as part of a paste by Claude's
  -- TUI and does not submit, so send Enter on its own a moment later.
  local function send(chunk, then_enter)
    if terminal().send_to_terminal(chunk, { submit = false }) and then_enter then
      vim.defer_fn(function()
        M.key("\r")
      end, SUBMIT_DELAY_MS)
    end
  end
  -- A slash command opens Claude's command menu, which swallows the first
  -- characters typed right after "/" ("/model x" arrived as "del x"): send the
  -- command word first, and its arguments once the menu is up.
  local command, args = text:match("^(/%S+)(%s.*)$")
  if command then
    send(command, false)
    vim.defer_fn(function()
      send(args, true)
    end, COMMAND_DELAY_MS)
  else
    send(text, true)
  end
end

--- Send `text` as one bracketed paste (so its newlines do not submit) and submit it.
local function submit_paste(text)
  local bufnr = pane()
  if not bufnr then
    return
  end
  note_if_hidden(bufnr)
  M.key("\27[200~" .. text .. "\27[201~")
  vim.defer_fn(function()
    M.key("\r")
  end, SUBMIT_DELAY_MS)
end

--- Multi-line prompt in a floating window that grows with the text (vim.ui.input
--- is a single line that scrolls sideways). <CR> sends, <C-j> or <S-CR> adds a
--- newline, q or <Esc> in normal mode cancels. Focus returns to the code window.
local function prompt(title, on_submit, allow_empty)
  local origin = vim.api.nvim_get_current_win()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "claude_prompt"
  -- Same box as noice's command_palette cmdline: 60 wide, row 3, centered.
  local width = math.min(60, vim.o.columns - 4)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    row = 3,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = 1,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
    footer = " <CR> send · <C-j> newline · q cancel ",
    footer_pos = "center",
  })
  vim.wo[win].wrap = true
  vim.wo[win].linebreak = true
  vim.wo[win].statuscolumn = " " -- the 1-column left padding of noice's cmdline
  if vim.fn.hlexists("NoiceCmdlinePopup") == 1 then
    vim.wo[win].winhighlight =
      "Normal:NoiceCmdlinePopup,FloatTitle:NoiceCmdlinePopupTitle,FloatBorder:NoiceCmdlinePopupBorder"
  end

  local function resize()
    if vim.api.nvim_win_is_valid(win) then
      local height = vim.api.nvim_win_text_height(win, {}).all
      vim.api.nvim_win_set_height(win, math.max(1, math.min(height, MAX_PROMPT_LINES)))
    end
  end

  local done = false
  local function close(send)
    if done then
      return
    end
    done = true
    local text = vim.trim(table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), "\n"))
    vim.cmd.stopinsert()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_win_is_valid(origin) then
      vim.api.nvim_set_current_win(origin)
    end
    if send and (allow_empty or text ~= "") then
      vim.schedule(function()
        on_submit(text)
      end)
    end
  end

  local function map(modes, lhs, fn)
    vim.keymap.set(modes, lhs, fn, { buffer = buf, nowait = true })
  end
  local function newline()
    -- "n": do not remap, so <CR> inserts a line break instead of sending.
    vim.api.nvim_feedkeys(vim.keycode("<C-g>u<CR>"), "in", false)
  end
  map({ "i", "n" }, "<CR>", function()
    close(true)
  end)
  map("i", "<C-j>", newline)
  map("i", "<S-CR>", newline)
  map({ "i", "n" }, "<C-c>", function()
    close(false)
  end)
  map("n", "q", function()
    close(false)
  end)
  map("n", "<Esc>", function()
    close(false)
  end)

  local group = vim.api.nvim_create_augroup("minh.claude.prompt." .. buf, { clear = true })
  vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, { group = group, buffer = buf, callback = resize })
  -- Clicking or jumping to another window abandons the prompt.
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    buffer = buf,
    callback = function()
      vim.schedule(function()
        close(false)
      end)
    end,
  })
  vim.cmd.startinsert()
end

--- Ask Claude. With `general` the question goes out as is, with no @file reference.
function M.ask(general)
  if general then
    prompt("Claude", submit)
    return
  end

  local visual = vim.fn.mode():match("^[vV\22]") ~= nil
  local ref, err = reference(visual)
  if not ref then
    vim.notify("Claude: " .. err, vim.log.levels.WARN)
    return
  end
  if visual then
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "nx", false)
  end
  if vim.bo.modified then
    vim.notify("Claude reads the saved file; this buffer has unsaved changes", vim.log.levels.WARN)
  end

  prompt(ref, function(question)
    submit(ref .. " " .. question)
  end)
end

--- True when the clipboard holds an image and no plain text (needs wl-paste).
local function clipboard_has_image()
  if vim.fn.executable("wl-paste") == 0 then
    return false
  end
  local out = vim.system({ "wl-paste", "--list-types" }, { text = true }):wait(1000)
  local types = out.code == 0 and out.stdout or ""
  return types:find("image/", 1, true) ~= nil and types:find("text/plain", 1, true) == nil
end

--- Attach the clipboard image with Claude's own Ctrl+V, then send the question.
local function submit_image(question)
  local bufnr = pane()
  if not bufnr then
    return
  end
  note_if_hidden(bufnr)
  M.key("\22") -- Ctrl+V: Claude reads the image from the clipboard itself
  vim.defer_fn(function()
    if question ~= "" then
      terminal().send_to_terminal(question, { submit = false })
    end
    vim.defer_fn(function()
      M.key("\r")
    end, SUBMIT_DELAY_MS)
  end, IMAGE_DELAY_MS)
end

--- Ask Claude about the system clipboard: the question (may be empty) goes first,
--- then the clipboard in a fenced block. In visual mode the selection is copied
--- to the clipboard first.
function M.ask_clipboard()
  if vim.fn.mode():match("^[vV\22]") then
    vim.cmd([[normal! "+y]]) -- copy the selection first, then ask about it
  end
  if not vim.fn.mode():match("^[vV\22]") and clipboard_has_image() then
    prompt("clipboard · image", submit_image, true)
    return
  end
  local clip = vim.fn.getreg("+")
  if vim.trim(clip) == "" then
    vim.notify("Claude: the clipboard is empty", vim.log.levels.WARN)
    return
  end
  local lines = select(2, clip:gsub("\n", "\n")) + 1
  prompt(("clipboard · %d lines"):format(lines), function(question)
    local parts = question ~= "" and { question, "" } or {}
    vim.list_extend(parts, { "```", (clip:gsub("\n+$", "")), "```" })
    submit_paste(table.concat(parts, "\n"))
  end, true)
end

--- End the session with /exit: Claude quits with code 0, unlike ClaudeCodeClose,
--- which kills it and makes the plugin report "exited with code -1".
function M.quit()
  submit("/exit")
end

--- Start Claude with extra CLI arguments, without focusing the pane. Arguments only
--- apply to a new process, so a running pane is left alone (quit it first).
function M.start(args)
  if terminal().get_active_terminal_bufnr() then
    vim.notify("Claude is already running; quit it first (<leader>aq) to start with " .. args, vim.log.levels.WARN)
    return
  end
  terminal().ensure_visible(nil, args)
end

--- Move into the pane in Normal mode, to read, search and yank through the
--- conversation (`i` types to Claude); from inside the pane, hide it. Shows the
--- pane first if hidden, starting Claude if needed.
function M.toggle()
  local bufnr = terminal().get_active_terminal_bufnr()
  local win = bufnr and visible_win(bufnr)
  if win and win == vim.api.nvim_get_current_win() then
    terminal().simple_toggle() -- in the pane: hide
    -- The plugin leaves the hidden float with `wincmd p`, which can leave the
    -- cursor in it (no valid previous window): then go to the previous window
    -- if it is a plain visible one, else the first such window of the tab.
    if vim.api.nvim_win_get_config(0).hide then
      local function plain(w)
        local cfg = w ~= 0 and vim.api.nvim_win_is_valid(w) and vim.api.nvim_win_get_config(w)
        return cfg and cfg.relative == "" and not cfg.hide
      end
      local target = vim.fn.win_getid(vim.fn.winnr("#"))
      if not plain(target) then
        target = vim.iter(vim.api.nvim_tabpage_list_wins(0)):find(plain)
      end
      if target then
        vim.api.nvim_set_current_win(target)
      end
    end
    return
  end
  if not win then
    terminal().ensure_visible()
    bufnr = terminal().get_active_terminal_bufnr()
    win = bufnr and visible_win(bufnr)
  end
  if win then
    vim.api.nvim_set_current_win(win)
    vim.cmd.stopinsert()
  end
end

--- Type `bytes` into the pane exactly (no submit, no newline handling).
function M.key(bytes)
  local bufnr = pane()
  if not bufnr then
    return
  end
  local chan = vim.b[bufnr].terminal_job_id
  if not chan or chan == 0 then
    chan = vim.bo[bufnr].channel
  end
  if not chan or chan == 0 or vim.fn.chansend(chan, bytes) == 0 then
    vim.notify("Claude: the pane's process is not accepting input", vim.log.levels.WARN)
  end
end

--- snacks.image keeps its own list of the buffer's images (closing them alone
--- does not stick: it shows them again on the next cursor move). Its refresh
--- finds the formulas from treesitter, so on plain text it removes them all, and
--- on markdown it draws them back.
local function refresh_images(buf)
  pcall(vim.api.nvim_exec_autocmds, "WinScrolled", { group = "snacks.image.inline." .. buf, buffer = buf })
end

--- Render what Claude printed since math rendering was turned on. Terminal
--- output does not reach treesitter's change tracking, so the markdown tree
--- stays at the text it first saw: reparse it all, then redraw (render-markdown
--- forced, snacks.image). Runs on entering Normal mode in the pane.
local function rerender_markdown(buf)
  local win = vim.fn.bufwinid(buf)
  if not vim.b[buf].claude_markdown or win == -1 then
    return
  end
  -- Nothing printed since the last time (same length, same tail): skip.
  local count = vim.api.nvim_buf_line_count(buf)
  local sig = count .. table.concat(vim.api.nvim_buf_get_lines(buf, math.max(count - 20, 0), -1, false), "\n")
  if vim.b[buf].claude_markdown_sig == sig then
    return
  end
  vim.b[buf].claude_markdown_sig = sig
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if ok and parser then
    parser:invalidate(true)
    -- Only the visible lines (a full parse of a long session is ~90 ms);
    -- render-markdown parses the rest itself as you scroll to it.
    parser:parse({ vim.fn.line("w0", win) - 1, vim.fn.line("w$", win) })
  end
  -- Internal module: the public API has no forced redraw of one buffer.
  pcall(function()
    require("render-markdown.core.ui").update(buf, win, "ClaudeOutput", true)
  end)
  refresh_images(buf)
end

local RERENDER_IDLE_MS = 500

--- Re-render once Claude has printed nothing for RERENDER_IDLE_MS, so math shows
--- without leaving Terminal mode. While Claude streams, on_lines only restarts
--- the timer; the render itself (visible lines only) takes about 10 ms.
local function watch_output(buf)
  if vim.b[buf].claude_output_watched then
    return
  end
  vim.b[buf].claude_output_watched = true
  local timer = assert(vim.uv.new_timer())
  vim.api.nvim_buf_attach(buf, false, {
    on_lines = function()
      timer:stop()
      timer:start(
        RERENDER_IDLE_MS,
        0,
        vim.schedule_wrap(function()
          if vim.api.nvim_buf_is_valid(buf) then
            rerender_markdown(buf)
          end
        end)
      )
    end,
    on_detach = function()
      timer:stop()
      timer:close()
    end,
  })
end

--- Keymaps and options of the pane's terminal buffer. Called on TermOpen and
--- again after toggle_markdown(): filetype changes run ftplugins, and markdown's
--- maps [[ ]] (its undo unmaps them), which would clobber the pane's own.
function M.setup_pane(buf)
  vim.keymap.set("t", "<Esc>", "<Esc>", { buffer = buf, desc = "Claude: send Esc" })
  -- The whole conversation lives in the scrollback: keep a long session.
  vim.bo[buf].scrollback = 100000
  -- <A-u>/<A-d> scroll half a page, only inside the pane (a hidden float is
  -- no use scrolling from outside). Terminal mode keeps the view at the
  -- bottom, so while typing they leave it first (`i` to type again).
  vim.keymap.set("t", "<A-u>", [[<C-\><C-n><C-u>]], { buffer = buf, desc = "Claude: scroll up (Normal mode)" })
  vim.keymap.set("t", "<A-d>", [[<C-\><C-n><C-d>]], { buffer = buf, desc = "Claude: scroll down (Normal mode)" })
  vim.keymap.set("n", "<A-u>", "<C-u>", { buffer = buf, desc = "Claude: scroll up" })
  vim.keymap.set("n", "<A-d>", "<C-d>", { buffer = buf, desc = "Claude: scroll down" })
  -- q in Normal mode hides the float (no macros in a terminal; same as <leader>ac).
  vim.keymap.set("n", "q", function()
    M.toggle()
  end, { buffer = buf, desc = "Claude: hide the pane" })
  -- [[ / ]]: previous / next prompt of yours (Claude prints them as
  -- "❯ text"), put at the top of the window with its answer below. The
  -- input box is a "❯" line under a "───" rule: skipped.
  local function prompt_line(lnum)
    return not vim.fn.getline(lnum - 1):match("^%s*─")
  end
  for lhs, flags in pairs({ ["[["] = "bW", ["]]"] = "W" }) do
    vim.keymap.set("n", lhs, function()
      local start, found = vim.api.nvim_win_get_cursor(0), nil
      for _ = 1, vim.v.count1 do
        local lnum = vim.fn.search([[\v^\s*[❯›] ]], flags)
        while lnum > 0 and not prompt_line(lnum) do
          lnum = vim.fn.search([[\v^\s*[❯›] ]], flags)
        end
        if lnum == 0 then
          break
        end
        found = lnum
      end
      -- search() moved the cursor even onto skipped lines: settle it.
      vim.api.nvim_win_set_cursor(0, found and { found, 0 } or start)
      if found then
        vim.cmd("normal! zt")
      end
    end, { buffer = buf, desc = "Claude: " .. (lhs == "[[" and "previous" or "next") .. " prompt" })
  end
  -- m: render math in the pane (markdown) or back to plain text.
  vim.keymap.set("n", "m", function()
    M.toggle_markdown()
  end, { buffer = buf, desc = "Claude: toggle math rendering" })
  -- In Normal mode <C-o> would jump back to the previous buffer. On a collapsed
  -- tool call it shows the call's full output (show_tool_output); anywhere else
  -- it goes to Claude (toggles its transcript view).
  vim.keymap.set("n", "<C-o>", function()
    if not M.show_tool_output() then
      M.key("\15")
    end
  end, { buffer = buf, desc = "Claude: full tool output here, else <C-o> to Claude" })
  -- With math rendering on, draw what Claude printed meanwhile when you stop
  -- typing (Terminal -> Normal mode) or come back to the pane.
  local group = vim.api.nvim_create_augroup("minh.claude.pane_markdown." .. buf, { clear = true })
  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    buffer = buf,
    callback = function()
      if vim.fn.mode(true) == "nt" then
        rerender_markdown(buf)
      end
    end,
  })
  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    buffer = buf,
    callback = function()
      rerender_markdown(buf)
    end,
  })
  -- Safety net for <C-o> above: if that map is ever missing, <C-o> jumps back
  -- to the working buffer. An empty jumplist leaves it nothing to jump to.
  -- Cause not confirmed (a bare nvim_open_win float starts with an empty
  -- jumplist); if it still happens, check `:verbose nmap <buffer> <C-o>`.
  vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
    group = group,
    buffer = buf,
    callback = function()
      vim.cmd("clearjumps")
    end,
  })
end

--- Toggle math rendering in the pane (`m` in its Normal mode): the terminal buffer
--- pretends to be markdown, so render-markdown draws inline $...$ as unicode and
--- snacks.image draws $$...$$ blocks. The text is Claude's output, hard-wrapped at
--- the pane width: a formula cut by a wrap renders wrong. Acts on the current
--- buffer (render-markdown's buf_enable does too); `quiet` skips the message.
function M.toggle_markdown(quiet)
  local buf = vim.api.nvim_get_current_buf()
  if vim.b[buf].claude_markdown then
    vim.b[buf].claude_markdown = false
    pcall(function()
      require("render-markdown").buf_disable()
    end)
    vim.treesitter.stop(buf)
    -- Not "": with no filetype, treesitter keeps handing out the cached markdown
    -- parser. A filetype with no parser makes the lookup fail, as snacks needs.
    vim.bo[buf].filetype = "claude"
    M.setup_pane(buf)
    refresh_images(buf)
    vim.notify("Claude pane: plain text", vim.log.levels.INFO)
    return
  end
  vim.b[buf].claude_markdown = true
  -- Loaded first: render-markdown only attaches on a FileType event it sees.
  pcall(require("lazy").load, { plugins = { "render-markdown.nvim" } })
  -- snacks.image creates its FileType autocmd on the first BufReadPre; in a
  -- session that has only opened the pane, no file was read, so nothing would
  -- attach images to the pane. setup() is idempotent.
  pcall(function()
    Snacks.image.setup()
  end)
  vim.bo[buf].filetype = "markdown"
  vim.wo.spell = false -- the markdown FileType autocmd turns it on
  -- The parser stays (render-markdown and snacks read it); highlighting goes,
  -- treesitter's and the regex syntax that stop() turns back on. Claude Code
  -- already styled this text, and both conceal parts of it (backticks are
  -- dropped by Claude): `G.degree[u]` became G.degreeu, `a.*.b` lost its *.
  vim.treesitter.stop(buf)
  vim.bo[buf].syntax = "OFF"
  M.setup_pane(buf)
  pcall(function()
    require("render-markdown").buf_enable()
  end)
  refresh_images(buf) -- a second time on: snacks is attached already, so redraw
  watch_output(buf)
  if not quiet then
    vim.notify("Claude pane: math rendered (m: back to plain text)", vim.log.levels.INFO)
  end
end

--- Newest transcript of a Claude session started in nvim's cwd. Claude Code keeps
--- them as ~/.claude/projects/<cwd, non-alphanumerics as "-">/<session>.jsonl.
local function transcript_files()
  local dir = vim.fs.joinpath(vim.env.HOME, ".claude", "projects", (vim.fn.getcwd():gsub("[^%w]", "-")))
  local files = {}
  for _, file in ipairs(vim.fn.glob(dir .. "/*.jsonl", false, true)) do
    local stat = vim.uv.fs_stat(file)
    if stat then
      table.insert(files, { path = file, mtime = stat.mtime.sec })
    end
  end
  table.sort(files, function(a, b)
    return a.mtime > b.mtime
  end)
  return vim.tbl_map(function(f)
    return f.path
  end, files)
end

local function transcript_file()
  return transcript_files()[1]
end

local OUTPUT_LINES = 5 -- output lines kept under each command

--- Tool calls of the session in `file`, in order: { name, input, output, error }.
--- Only lines holding a tool call or result are decoded. This reads Claude Code's
--- internal format, which is not a stable API.
local function tool_calls(file)
  local calls, by_id = {}, {}
  for raw in io.lines(file) do
    if raw:find('"tool_use"', 1, true) or raw:find('"tool_result"', 1, true) then
      local ok, entry = pcall(vim.json.decode, raw)
      local content = ok and type(entry) == "table" and entry.message and entry.message.content
      for _, part in ipairs(type(content) == "table" and content or {}) do
        if part.type == "tool_use" then
          local call = { name = part.name, input = part.input or {} }
          table.insert(calls, call)
          by_id[part.id] = call
        elseif part.type == "tool_result" and by_id[part.tool_use_id] then
          local out = part.content
          if type(out) == "table" then
            local texts = {}
            for _, p in ipairs(out) do
              if p.type == "text" then
                table.insert(texts, p.text)
              end
            end
            out = table.concat(texts, "\n")
          end
          local call = by_id[part.tool_use_id]
          call.output, call.error = type(out) == "string" and out or "", part.is_error == true
        end
      end
    end
  end
  return calls
end

--- One-line summary of a non-Bash tool call (its main argument).
local function call_summary(call)
  local i = call.input
  local arg = i.file_path or i.pattern or i.query or i.url or i.skill or i.path or i.description
  if call.name == "Grep" and i.path then
    arg = ('"%s" in %s'):format(i.pattern, i.path)
  end
  if not arg then
    arg = vim.json.encode(i):sub(1, 120)
  end
  return call.name .. " " .. tostring(arg)
end

--- Lines of one tool call: Bash as "# description", the command and its first
--- output lines as comments; any other tool as one "# Tool argument" line.
local function call_lines(call)
  if call.name ~= "Bash" then
    return { "# · " .. call_summary(call) }
  end
  -- Some sessions record no description: the header still marks where a command starts.
  local lines = { "# ▸ " .. (call.input.description or "Bash") .. (call.error and "  [error]" or "") }
  vim.list_extend(lines, vim.split(call.input.command or "", "\n", { plain = true }))
  local out = vim.split(vim.trim(call.output or ""), "\n", { plain = true })
  if out[1] ~= "" then
    for n = 1, math.min(#out, OUTPUT_LINES) do
      table.insert(lines, "#   │ " .. out[n])
    end
    if #out > OUTPUT_LINES then
      table.insert(lines, ("#   │ … +%d lines"):format(#out - OUTPUT_LINES))
    end
  end
  return lines
end

-- A tool call in the pane: "● Bash(command…" (the args wrapped over a few
-- lines), "⎿ output", "… +N lines (ctrl+o to expand)". With the default renderer
-- those lines sit in the scrollback and Claude never redraws them, so Ctrl+O
-- there only reprints the transcript at the bottom. show_tool_output() reads
-- the full output from the session transcript instead.
local TOOL_BULLETS = { "●", "⏺" }
local RESULT_MARKS = { "⎿", "└" }
local EXPAND_HINT = "ctrl+o to expand"

local function starts_with_any(s, prefixes)
  for _, p in ipairs(prefixes) do
    if vim.startswith(s, p) then
      return p
    end
  end
end

--- "● Name(args" -> name, rest of the line; nil for any other line.
local function tool_header(line)
  local s = vim.trim(line)
  local bullet = starts_with_any(s, TOOL_BULLETS)
  if bullet then
    return s:sub(#bullet + 1):match("^%s*([%w_]+)%((.*)$")
  end
end

--- A line that starts another message: your prompt, or any "●" line.
local function message_start(line)
  local s = vim.trim(line)
  return vim.startswith(s, "❯") or starts_with_any(s, TOOL_BULLETS) ~= nil
end

--- The collapsed tool call around the cursor: { name, args, output } with the
--- args and first output lines as the pane shows them (wrapped, cut with "…"),
--- or nil when the cursor is not on a call that still has its "ctrl+o to
--- expand" line.
local function collapsed_call()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local header
  for n = row, math.max(1, row - 60), -1 do
    local line = vim.fn.getline(n)
    if tool_header(line) then
      header = n
      break
    elseif message_start(line) then
      return nil
    end
  end
  if not header then
    return nil
  end
  local name, args = tool_header(vim.fn.getline(header))
  local hint, in_args, output = nil, true, {}
  for n = header + 1, header + 60 do
    local line = vim.fn.getline(n)
    if n > vim.fn.line("$") or message_start(line) then
      break
    end
    if line:find(EXPAND_HINT, 1, true) then
      hint = n
      break
    end
    local s = vim.trim(line)
    local mark = starts_with_any(s, RESULT_MARKS)
    if mark then
      in_args, s = false, s:sub(#mark + 1)
    end
    if in_args then
      args = args .. line
    elseif s ~= "" then
      table.insert(output, s)
    end
  end
  -- The hint plus the line or two under it ("Allowed by auto mode").
  if not hint or row > hint + 2 then
    return nil
  end
  return { name = name, args = args, output = output }
end

--- Text without whitespace or "…": the pane wraps long args (sometimes inside a
--- word) and cuts them, so only the characters themselves can be compared.
local function squeeze(s)
  return (s:gsub("…", ""):gsub("%s+", ""))
end

--- The tool call's input as one string to search in (Bash: its command).
local function input_text(call)
  if call.name == "Bash" then
    return call.input.command or ""
  end
  local parts = {}
  for _, v in pairs(call.input) do
    if type(v) == "string" then
      table.insert(parts, v)
    end
  end
  return table.concat(parts, " ")
end

--- One call's full output in a float over the pane; q or <Esc> closes it.
local function show_output(call)
  local lines = { "# " .. (call.input.description or call.name) .. (call.error and "  [error]" or "") }
  if call.name == "Bash" then
    vim.list_extend(lines, vim.split(call.input.command or "", "\n", { plain = true }))
  else
    table.insert(lines, "# " .. call_summary(call))
  end
  table.insert(lines, "")
  vim.list_extend(lines, vim.split((call.output:gsub("\r", "")), "\n", { plain = true }))
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  local width = math.floor(vim.o.columns * 0.8)
  local height = math.max(1, math.min(#lines, math.floor(vim.o.lines * 0.8)))
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " " .. call.name .. " output (q closes) ",
    title_pos = "center",
    zindex = 60, -- above the pane's own float
  })
  for _, lhs in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", lhs, "<cmd>close<cr>", { buffer = buf, nowait = true })
  end
end

--- <C-o> in the pane's Normal mode: on a collapsed tool call, show its full
--- output and return true; anywhere else return false (the caller sends <C-o>
--- to Claude). Similar commands share long prefixes (every psql call starts
--- alike), so a call must contain all of the shown args, and among those the
--- newest whose output also holds the shown first output lines wins.
function M.show_tool_output()
  local shown = collapsed_call()
  if not shown then
    return false
  end
  local needle = squeeze(shown.args):gsub("%)$", "")
  if needle == "" then
    return false
  end
  -- Newest transcripts first: another Claude session in the same directory
  -- (a second nvim, herdr) may have written more recently than this pane's.
  local fallback
  for _, file in ipairs(vim.list_slice(transcript_files(), 1, 3)) do
    local ok, calls = pcall(tool_calls, file)
    for n = ok and #calls or 0, 1, -1 do
      local call = calls[n]
      -- The pane shows some tools under other names (Grep as "Search"), so
      -- only Bash is matched by name.
      local same_tool = call.name == shown.name or shown.name ~= "Bash"
      if same_tool and call.output and squeeze(input_text(call)):find(needle, 1, true) then
        local out = squeeze(call.output)
        local all_shown = true
        for _, line in ipairs(shown.output) do
          if not out:find(squeeze(line), 1, true) then
            all_shown = false
            break
          end
        end
        if all_shown then
          show_output(call)
          return true
        end
        fallback = fallback or call
      end
    end
  end
  if fallback then
    show_output(fallback)
    vim.notify("Claude: no call with this exact output; showing the newest with these args", vim.log.levels.WARN)
  else
    vim.notify("Claude: this call is not in the session transcript", vim.log.levels.WARN)
  end
  return true
end

--- Every tool call of the current session in a buffer (filetype sh), to read and
--- learn from: Bash commands verbatim with their description and first output
--- lines, other tools (Read, Edit, Grep...) as one comment line each. Newest
--- first; `r` reverses the order, `q` closes. Works whether or not the pane runs.
function M.commands()
  local file = transcript_file()
  if not file then
    vim.notify("Claude: no session transcript for " .. vim.fn.getcwd(), vim.log.levels.WARN)
    return
  end
  local ok, calls = pcall(tool_calls, file)
  if not ok then
    vim.notify("Claude: could not read " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.WARN)
    return
  end
  if #calls == 0 then
    vim.notify("Claude: no commands in this session yet", vim.log.levels.INFO)
    return
  end
  local newest_first = true
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  local function render()
    local lines = {}
    for n = 1, #calls do
      local call = calls[newest_first and #calls - n + 1 or n]
      if n > 1 then
        table.insert(lines, "")
      end
      vim.list_extend(lines, call_lines(call))
    end
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
  end
  render()
  vim.bo[buf].filetype = "sh"
  vim.cmd("tab sbuffer " .. buf)
  vim.keymap.set("n", "q", "<cmd>bwipeout<cr>", { buffer = buf, desc = "Claude: close the commands list" })
  vim.keymap.set("n", "r", function()
    newest_first = not newest_first
    render()
    vim.api.nvim_win_set_cursor(0, { 1, 0 })
  end, { buffer = buf, desc = "Claude: reverse the list order" })
  vim.notify(("Claude: %d tool calls (%s first) · r reverse · q close"):format(#calls, "newest"))
end

--- Exact versions in the labels; the plugin's own list only has "(Latest)" aliases.
M.MODELS = {
  { name = "Opus 5.5", value = "claude-opus-5-5" },
  { name = "Sonnet 5.5", value = "claude-sonnet-5-5" },
  { name = "Haiku 5.5", value = "claude-haiku-5-5" },
  { name = "Fable 5.1", value = "claude-fable-5-1" },
  { name = "Default (account recommended)", value = "default" },
}

--- Pick a model. In a running pane this sends `/model <name>` (switches the
--- session without focusing it); with no pane it starts Claude with --model.
function M.select_model()
  vim.ui.select(M.MODELS, {
    prompt = "Claude model:",
    format_item = function(item)
      return item.name
    end,
  }, function(choice)
    if not choice then
      return
    end
    if terminal().get_active_terminal_bufnr() then
      submit("/model " .. choice.value)
    else
      M.start("--model " .. choice.value)
    end
  end)
end

--- Reload buffers whose file Claude changed on disk. Only unmodified buffers: a
--- plain :checktime on a modified one pops a prompt in the middle of typing.
function M.reload_changed()
  if vim.fn.mode() == "c" then
    return
  end
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].buftype == "" and not vim.bo[buf].modified then
      vim.cmd("silent! checktime " .. buf)
    end
  end
end

--- While the pane runs, check once a second (autocmds alone only fire on focus
--- or key presses, and the cursor stays in your buffer while Claude works).
function M.watch_files()
  local timer = vim.uv.new_timer()
  timer:start(
    1000,
    1000,
    vim.schedule_wrap(function()
      if terminal().get_active_terminal_bufnr() then
        M.reload_changed()
      end
    end)
  )
end

M._reference = reference

return M
