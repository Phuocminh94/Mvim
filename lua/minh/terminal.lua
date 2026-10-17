-- =============================================================================
-- minh.terminal — floating terminals with adaptive layout
--
--   <A-/>          toggle terminal #1 of the current cwd (tab-local cwd aware)
--   2<A-/>         toggle terminal #2 of the current cwd (any count works)
--   <A-/> inside   hide the terminal you are in
--   <A-z> inside   zoom: fill the editor / restore
--   q (normal)     hide the terminal
--   :FloatTerm id=build layout=bottom height=0.3 cmd=htop cwd=~/proj
--   :FloatTermPick pick among running terminals
--
-- The window title follows the program in the foreground of the terminal
-- ("zsh" at the prompt, "R" inside an R console, "ipython", "htop"...).
-- Pass title= to pin a fixed title. Linux only: it reads /proc.
--
-- Layout "auto" picks a shape from the editor size each time it opens and
-- again on VimResized:
--   wide editor  (>= 160 cols)  -> right panel, full height
--   normal       (otherwise)    -> bottom panel, full width
--   small        (< 100x24)     -> fills the editor
-- Explicit layouts: "right", "bottom", "center", "full".
-- width/height accept a ratio (0..1] of the editor or an absolute cell count.
-- =============================================================================

local M = {}

M.config = {
  border = "rounded",
  layout = "auto",
  wide_cols = 160, -- editor needs this many columns for a right panel
  small_cols = 100, -- below this (or small_rows) the terminal fills the editor
  small_rows = 24,
  right = { ratio = 0.4, min = 60, max = 100 }, -- panel width
  bottom = { ratio = 0.35, min = 10, max = 25 }, -- panel height
  center = { width = 0.8, height = 0.8 },
}

---@type table<string, table> id -> { id, cwd, cmd, layout, width, height, title, buf, win, zoomed }
local terms = {}

local api = vim.api

local function clamp(v, lo, hi)
  return math.max(lo, math.min(hi, v))
end

-- A size spec is a ratio of `total` when <= 1, otherwise an absolute cell count.
local function resolve(spec, total)
  if not spec then
    return nil
  end
  return spec <= 1 and math.floor(total * spec) or math.floor(spec)
end

-- Usable editor area: rows exclude the tabline, statusline and cmdline.
local function area()
  local tabline = vim.o.showtabline == 2 or (vim.o.showtabline == 1 and vim.fn.tabpagenr("$") > 1)
  local top = tabline and 1 or 0
  local bottom = vim.o.cmdheight + (vim.o.laststatus > 0 and 1 or 0)
  return { top = top, rows = vim.o.lines - top - bottom, cols = vim.o.columns }
end

local function pick_layout(layout, a)
  if layout ~= "auto" then
    return layout
  end
  local c = M.config
  if a.cols < c.small_cols or a.rows < c.small_rows then
    return "full"
  end
  return a.cols >= c.wide_cols and "right" or "bottom"
end

-- Window config for nvim_open_win / nvim_win_set_config.
-- width/height are inner sizes; the border adds 2 cells in each direction.
local function win_config(t)
  local a, c = area(), M.config
  local layout = t.zoomed and "full" or pick_layout(t.layout, a)
  local w, h, row, col

  if layout == "right" then
    w = resolve(t.width, a.cols) or clamp(math.floor(a.cols * c.right.ratio), c.right.min, c.right.max)
    h = a.rows - 2
    row, col = a.top, a.cols - w - 2
  elseif layout == "bottom" then
    w = a.cols - 2
    h = resolve(t.height, a.rows) or clamp(math.floor(a.rows * c.bottom.ratio), c.bottom.min, c.bottom.max)
    row, col = a.top + a.rows - h - 2, 0
  elseif layout == "full" then
    w, h = a.cols - 2, a.rows - 2
    row, col = a.top, 0
  else -- "center"
    w = resolve(t.width, a.cols) or math.floor(a.cols * c.center.width)
    h = resolve(t.height, a.rows) or math.floor(a.rows * c.center.height)
    row = a.top + math.floor((a.rows - h - 2) / 2)
    col = math.floor((a.cols - w - 2) / 2)
  end

  return {
    relative = "editor",
    style = "minimal",
    border = c.border,
    width = math.max(w, 1),
    height = math.max(h, 1),
    row = math.max(row, 0),
    col = math.max(col, 0),
    title = " " .. t.title .. " ",
    title_pos = "center",
  }
end

-- Floating windows belong to one tabpage, so "visible" means: valid and in this tab.
local function visible(t)
  return t.win ~= nil
    and api.nvim_win_is_valid(t.win)
    and api.nvim_win_get_tabpage(t.win) == api.nvim_get_current_tabpage()
end

local function hide(t)
  if t.win and api.nvim_win_is_valid(t.win) then
    api.nvim_win_hide(t.win)
  end
  t.win = nil
end

local function find_by_win(win)
  for _, t in pairs(terms) do
    if t.win == win then
      return t
    end
  end
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

--- Name of the program in the foreground of terminal `t`.
--- The shell's /proc/<pid>/stat holds the terminal's foreground process group
--- (field 8, "tpgid"); that group's leader names the running program.
--- Reading the foreground group (not the shell's children) ignores short-lived
--- helpers such as a prompt calling git. Returns nil when it cannot be read.
local function foreground_name(t)
  if not t.job then
    return nil
  end
  local ok, pid = pcall(vim.fn.jobpid, t.job)
  if not ok then
    return nil
  end
  local stat = read_file("/proc/" .. pid .. "/stat")
  if not stat then
    return nil
  end
  -- "pid (comm) state ppid pgrp session tty_nr tpgid ..."; comm may contain spaces.
  local tpgid = stat:match("^%d+ %b() %S+ %S+ %S+ %S+ %S+ (%-?%d+)")
  local comm = tpgid and read_file("/proc/" .. tpgid .. "/comm")
  return comm and vim.trim(comm) or nil
end

--- Update the title from the foreground program; redraw only when it changed.
local function refresh_title(t)
  if t.fixed_title then
    return
  end
  local name = foreground_name(t)
  if not name or name == "" then
    return
  end
  local title = name .. t.suffix
  if title == t.title then
    return
  end
  t.title = title
  if t.win and api.nvim_win_is_valid(t.win) then
    api.nvim_win_set_config(t.win, win_config(t))
  end
  vim.cmd.redrawstatus() -- statuslines that show M.title(buf) follow too
end

--- Poll while the terminal window is open; the timer stops itself when it closes.
local function watch_title(t)
  if t.fixed_title or t.timer then
    return
  end
  local timer = (vim.uv or vim.loop).new_timer()
  t.timer = timer
  timer:start(
    500,
    700,
    vim.schedule_wrap(function()
      if not (t.win and api.nvim_win_is_valid(t.win)) then
        timer:stop()
        timer:close()
        t.timer = nil
        return
      end
      refresh_title(t)
    end)
  )
end

local function start_job(t)
  t.job = vim.fn.jobstart(t.cmd or vim.o.shell, {
    term = true,
    cwd = t.cwd,
    on_exit = function(_, code)
      vim.schedule(function()
        if terms[t.id] == t then
          terms[t.id] = nil -- next toggle starts a fresh process
        end
        if not api.nvim_buf_is_valid(t.buf) then
          return
        end
        if code == 0 then
          api.nvim_buf_delete(t.buf, { force = true }) -- also closes the window
        else
          -- Keep the output visible so errors can be read; wipe it once hidden.
          vim.bo[t.buf].bufhidden = "wipe"
        end
      end)
    end,
  })

  local function bmap(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = t.buf, silent = true, desc = desc })
  end
  bmap({ "n", "t" }, "<A-z>", M.zoom, "Terminal: zoom / restore")
  bmap("n", "q", function()
    hide(t)
  end, "Terminal: hide")
  if t.cmd then
    -- Full-screen programs (lazygit, htop, fzf...) need <Esc> themselves,
    -- so override the global `t <Esc>` mapping for this buffer.
    bmap("t", "<Esc>", "<Esc>", "Send <Esc> to program")
  end
end

-- Show `t` in the current tab: focus it if visible, otherwise open a window.
local function show(t)
  if visible(t) then
    api.nvim_set_current_win(t.win)
  else
    -- One terminal on screen at a time, so panels never stack on top of each other.
    for _, other in pairs(terms) do
      hide(other)
    end
    local fresh = not (t.buf and api.nvim_buf_is_valid(t.buf))
    if fresh then
      t.buf = api.nvim_create_buf(false, true)
    end
    t.win = api.nvim_open_win(t.buf, true, win_config(t))
    if fresh then
      start_job(t)
    end
  end
  watch_title(t)
  vim.cmd.startinsert()
end

local function default_title(cmd, count)
  local name = cmd and cmd:match("^%S+") or vim.fn.fnamemodify(vim.o.shell, ":t")
  return count > 1 and (name .. " #" .. count) or name
end

--- Toggle a terminal.
--- @param id string|nil  nil/"default" = per-cwd terminal, numbered by v:count1
--- @param opts table|nil { cmd, cwd, layout, width, height, title }
function M.toggle(id, opts)
  opts = opts or {}
  local count = vim.v.count1

  -- Pressing the key inside a managed terminal (no count) hides that terminal.
  local current = find_by_win(api.nvim_get_current_win())
  if current and (id == nil or id == "default") and vim.v.count == 0 then
    hide(current)
    return
  end

  local cwd = opts.cwd and vim.fn.expand(opts.cwd) or vim.fn.getcwd()
  if id == nil or id == "default" then
    id = cwd .. "#" .. count
  end

  local t = terms[id]
  if not t then
    t = {
      id = id,
      cwd = cwd,
      cmd = opts.cmd,
      layout = opts.layout or M.config.layout,
      width = opts.width,
      height = opts.height,
      title = opts.title or default_title(opts.cmd, count),
      fixed_title = opts.title ~= nil, -- pinned: do not follow the foreground program
      suffix = count > 1 and (" #" .. count) or "",
    }
    terms[id] = t
  end

  if visible(t) and api.nvim_get_current_win() == t.win then
    hide(t)
  else
    show(t)
  end
  return t
end

--- Title of the managed terminal that owns `buf` (e.g. "R", "zsh"), or nil.
--- For statuslines: `require("minh.terminal").title(bufnr)`.
function M.title(buf)
  for _, t in pairs(terms) do
    if t.buf == buf then
      return t.title
    end
  end
end

--- Zoom the current terminal to fill the editor, or restore its layout.
function M.zoom()
  local t = find_by_win(api.nvim_get_current_win())
  if not t then
    return
  end
  t.zoomed = not t.zoomed
  api.nvim_win_set_config(t.win, win_config(t))
end

--- Pick among running terminals (uses vim.ui.select, so snacks/dressing style it).
function M.pick()
  local items = vim.tbl_values(terms)
  if #items == 0 then
    vim.notify("No running terminals", vim.log.levels.INFO)
    return
  end
  table.sort(items, function(a, b)
    return a.id < b.id
  end)
  vim.ui.select(items, {
    prompt = "Terminals",
    format_item = function(t)
      return string.format("%-16s %s", t.title, vim.fn.fnamemodify(t.cwd, ":~"))
    end,
  }, function(t)
    if t then
      show(t)
    end
  end)
end

local group = api.nvim_create_augroup("MinhTerminal", { clear = true })

-- Re-layout visible terminals when the editor size changes.
api.nvim_create_autocmd("VimResized", {
  group = group,
  callback = function()
    for _, t in pairs(terms) do
      if visible(t) then
        api.nvim_win_set_config(t.win, win_config(t))
      end
    end
  end,
})

api.nvim_create_user_command("FloatTerm", function(params)
  local id, opts = nil, {}
  for _, arg in ipairs(params.fargs) do
    local key, val = arg:match("^([^=]+)=(.+)$")
    if key == "id" then
      id = val
    elseif key then
      opts[key] = tonumber(val) or val
    end
  end
  M.toggle(id, opts)
end, { nargs = "*", desc = "Toggle floating terminal (id= cmd= cwd= layout= width= height=)" })

api.nvim_create_user_command("FloatTermPick", M.pick, { desc = "Pick a running terminal" })

return M
