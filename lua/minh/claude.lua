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
--   transcript() toggle the whole conversation of the session in a float
--                (markdown): [[ ]] prompts, yank just the part you need; it
--                reopens where you left the cursor, or at the first new prompt
--   start(args)  start Claude with CLI args (--resume, --model X), no focus
--   toggle()     show/hide the pane (starts it if needed) without focusing it
--   quit()       end the session with /exit (no "exited with code" error)
--   watch_files() reload buffers Claude edits on disk while the pane runs
--   key(bytes)   type raw keys into the pane: "1"/"2"/"3" for permission
--                prompts, "\27" (<Esc>) to interrupt, "\r" for Enter
--   page(dir)    scroll the conversation half a screen (PgUp/PgDn sent to Claude)
--   select_model() choose a model by exact version (/model in a running pane)
--   scroll_mode() browse the transcript: [ ] prompts, j k d u g G; other key exits
--
-- The pane must already be running (<leader>at); this never focuses it.
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
    vim.notify("Claude is not running (<leader>at)", vim.log.levels.WARN)
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

--- A hidden pane stays hidden (it still gets the text and keeps working): say so,
--- since a permission prompt there would wait unseen. <leader>at shows it,
--- <leader>ac shows the conversation.
local function note_if_hidden(bufnr)
  if #vim.fn.win_findbuf(bufnr) == 0 then
    vim.notify("Sent to Claude (pane hidden: <leader>at to show)", vim.log.levels.INFO)
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

  local group = vim.api.nvim_create_augroup("claude_prompt_" .. buf, { clear = true })
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

--- Newest transcript of a Claude session started in nvim's cwd. Claude Code keeps
--- them as ~/.claude/projects/<cwd, non-alphanumerics as "-">/<session>.jsonl.
local function transcript_file()
  local dir = vim.fs.joinpath(vim.env.HOME, ".claude", "projects", (vim.fn.getcwd():gsub("[^%w]", "-")))
  local newest, newest_mtime = nil, -1
  for _, file in ipairs(vim.fn.glob(dir .. "/*.jsonl", false, true)) do
    local stat = vim.uv.fs_stat(file)
    if stat and stat.mtime.sec > newest_mtime then
      newest, newest_mtime = file, stat.mtime.sec
    end
  end
  return newest
end

--- Markdown lines of the conversation in `file`: one "## ▶ <prompt>" heading per
--- prompt, then Claude's text replies. Tool calls collapse to one "tools:" line.
--- This reads Claude Code's internal format, which is not a stable API.
local function transcript_lines(file)
  local lines, tools = {}, {}
  local function flush_tools()
    if #tools > 0 then
      vim.list_extend(lines, { "", "_tools: " .. table.concat(tools, ", ") .. "_" })
      tools = {}
    end
  end
  local function add_text(text)
    flush_tools()
    table.insert(lines, "")
    vim.list_extend(lines, vim.split(vim.trim(text), "\n", { plain = true }))
  end
  for raw in io.lines(file) do
    -- Tool results (file contents, command output) are most of the file: skip
    -- them unparsed.
    if raw:find('"type":"user"', 1, true) and not raw:find('"tool_result"', 1, true) then
      local ok, entry = pcall(vim.json.decode, raw)
      local content = ok and type(entry) == "table" and not entry.isMeta and entry.message and entry.message.content
      if type(content) == "table" then
        local texts = {}
        for _, part in ipairs(content) do
          if part.type == "text" then
            table.insert(texts, part.text)
          end
        end
        content = table.concat(texts, "\n")
      end
      -- Slash commands and their output come wrapped in <tags>; leave them out.
      if
        type(content) == "string"
        and content ~= ""
        and not content:match("^%s*<")
        and not content:match("^%[Request interrupted")
      then
        flush_tools()
        local prompt = vim.split(vim.trim(content), "\n", { plain = true })
        vim.list_extend(lines, { "", "## ▶ " .. prompt[1] })
        for i = 2, #prompt do
          table.insert(lines, "> " .. prompt[i])
        end
      end
    elseif raw:find('"type":"assistant"', 1, true) then
      local ok, entry = pcall(vim.json.decode, raw)
      local content = ok and type(entry) == "table" and entry.message and entry.message.content
      for _, part in ipairs(type(content) == "table" and content or {}) do
        if part.type == "text" and vim.trim(part.text) ~= "" then
          add_text(part.text)
        elseif part.type == "tool_use" then
          table.insert(tools, part.name)
        end
      end
    end
  end
  flush_tools()
  while lines[1] == "" do
    table.remove(lines, 1)
  end
  return lines
end

--- Jump to the next (1) or previous (-1) prompt heading.
local function jump_prompt(direction)
  vim.fn.search("^## ▶", direction > 0 and "W" or "bW")
end

-- The conversation float keeps its buffer between toggles, so the cursor stays
-- where you left it; the text is rebuilt only when the transcript file changes.
local view = { buf = nil, win = nil, file = nil, mtime = nil, cursor = nil, prompts = 0 }

local function hide_transcript()
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    view.cursor = vim.api.nvim_win_get_cursor(view.win)
    vim.api.nvim_win_close(view.win, true)
  end
  view.win = nil
end

--- Fill (or refill) the conversation buffer from `file`. False if unreadable.
local function load_transcript(file, mtime)
  local ok, lines = pcall(transcript_lines, file)
  if not ok or #lines == 0 then
    vim.notify("Claude: could not read " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.WARN)
    return false
  end
  if not (view.buf and vim.api.nvim_buf_is_valid(view.buf)) then
    view.buf = vim.api.nvim_create_buf(false, true)
    vim.bo[view.buf].bufhidden = "hide"
    vim.bo[view.buf].filetype = "markdown"
    local function map(lhs, fn)
      vim.keymap.set("n", lhs, fn, { buffer = view.buf, nowait = true })
    end
    map("q", hide_transcript)
    map("<Esc>", hide_transcript)
    for lhs, direction in pairs({ ["]]"] = 1, ["]a"] = 1, ["[["] = -1, ["[a"] = -1 }) do
      map(lhs, function()
        jump_prompt(direction)
      end)
    end
  end
  vim.bo[view.buf].modifiable = true
  vim.api.nvim_buf_set_lines(view.buf, 0, -1, false, lines)
  vim.bo[view.buf].modifiable = false
  -- Prompt heading lines; a new prompt since the last look moves the cursor to
  -- the first new one, otherwise the cursor stays where it was left.
  local headings = {}
  for i, line in ipairs(lines) do
    if line:match("^## ▶") then
      table.insert(headings, i)
    end
  end
  if view.file ~= file then
    view.cursor = nil -- another session: start at its last answer
  elseif view.cursor and #headings > view.prompts then
    view.cursor = { headings[view.prompts + 1], 0 }
    view.scroll_top = true
  end
  view.file, view.mtime, view.prompts = file, mtime, #headings
  return true
end

--- Toggle the whole conversation of the current session in a float (markdown):
--- [[ ]] (or [a ]a) jump between prompts, select + y copies, q hides. Reopening
--- returns to where the cursor was, or to the first new prompt if you asked
--- something since; the first time it starts at the last answer.
--- Works whether or not the pane is running.
function M.transcript()
  if view.win and vim.api.nvim_win_is_valid(view.win) then
    hide_transcript()
    return
  end
  local file = transcript_file()
  if not file then
    vim.notify("Claude: no session transcript for " .. vim.fn.getcwd(), vim.log.levels.WARN)
    return
  end
  local stat = vim.uv.fs_stat(file)
  local mtime = stat and stat.mtime.sec
  local fresh = view.buf and vim.api.nvim_buf_is_valid(view.buf) and view.file == file and view.mtime == mtime
  if not fresh and not load_transcript(file, mtime) then
    return
  end

  local width = math.min(100, vim.o.columns - 4)
  local height = math.max(3, math.floor((vim.o.lines - 4) * 0.8))
  view.win = vim.api.nvim_open_win(view.buf, true, {
    relative = "editor",
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    width = width,
    height = height,
    border = "rounded",
    title = " Claude conversation ",
    title_pos = "center",
    footer = " [[ ]] prompts · select + y copy · q hide ",
    footer_pos = "center",
  })
  vim.wo[view.win].wrap = true
  vim.wo[view.win].linebreak = true
  -- Leaving the float any other way (clicking out, <C-w>w) also hides it.
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = view.buf,
    once = true,
    callback = function()
      vim.schedule(hide_transcript)
    end,
  })

  local last = vim.api.nvim_buf_line_count(view.buf)
  if view.cursor then
    vim.api.nvim_win_set_cursor(view.win, { math.min(view.cursor[1], last), view.cursor[2] })
    if view.scroll_top then
      vim.cmd("normal! zt")
      view.scroll_top = false
    end
  else
    -- Start at the last prompt, scrolled so its answer fills the window.
    vim.api.nvim_win_set_cursor(view.win, { last, 0 })
    jump_prompt(-1)
    vim.cmd("normal! zt")
  end
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

--- Show or hide the pane without moving focus into it.
function M.toggle()
  local bufnr = terminal().get_active_terminal_bufnr()
  if bufnr and vim.fn.bufwinid(bufnr) ~= -1 then
    terminal().simple_toggle() -- visible: hide
  else
    terminal().ensure_visible() -- hidden or not started: show/start, no focus
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

-- Claude Code (fullscreen renderer) scrolls its own conversation in the alternate
-- screen, so the nvim window cannot scroll it: send the keys it documents instead.
local PGUP, PGDN = "\27[5~", "\27[6~"
local TOP, BOTTOM = "\27[1;5H", "\27[1;5F" -- Ctrl+Home, Ctrl+End

--- Scroll the conversation half a screen: 1 = down, -1 = up.
function M.page(direction)
  M.key(direction > 0 and PGDN or PGUP)
end

-- Transcript view (Ctrl+O) of Claude Code: j/k, Ctrl+d/Ctrl+u, g/G scroll and
-- { / } jump to the previous / next prompt of yours (its answer is just below).
local CTRL_O, CTRL_D, CTRL_U = "\15", "\4", "\21"
local TRANSCRIPT_KEYS = {
  ["["] = "{",
  ["]"] = "}",
  j = "j",
  k = "k",
  d = CTRL_D,
  u = CTRL_U,
  g = "g",
  G = "G",
}

--- Browse the conversation in Claude's transcript view without focusing the pane:
--- [ ] previous/next prompt (and the answer under it), j k lines, d u half page,
--- g G top/bottom. Any other key (Esc, q...) closes the transcript and leaves.
--- Ctrl+O toggles, so this assumes the pane is not already in transcript view.
function M.scroll_mode()
  if not pane() then
    return
  end
  M.key(CTRL_O)
  while true do
    vim.api.nvim_echo({ { "-- Claude transcript: [ ] prompt  j k  d u  g G  (other key exits) --", "ModeMsg" } }, false, {})
    vim.cmd.redraw()
    local key = vim.fn.getcharstr()
    local bytes = TRANSCRIPT_KEYS[key]
    -- Focus changes and mouse events are special keys: ignore, don't exit.
    if not bytes and key:byte(1) ~= 0x80 then
      break
    end
    if bytes then
      M.key(bytes)
    end
  end
  M.key("q")
  vim.api.nvim_echo({ { "" } }, false, {})
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
