-- render-markdown handler for inline $...$ math, in place of its builtin latex
-- handler. Formulas go through bin/latex-inline (one line of unicode: a/b, √x,
-- xᵢ), then utftex, then latex2text. Each is drawn inside the sentence in place
-- of its source, also when it spans lines: the Claude pane hard-wraps Claude's
-- output, and the builtin handler draws such a formula above the text and
-- leaves the source in view. $$...$$ blocks are left to snacks.image.

local M = {}

local SCRIPT = vim.fs.joinpath(vim.fn.stdpath("config"), "bin", "latex-inline")
local CONVERTERS = { SCRIPT, "utftex", "latex2text" }
local HL = "RenderMarkdownMath"

---@type table<string, string|false> formula -> output (false: all failed)
local cache = {}
---@type table<integer, {sr: integer, sc: integer, er: integer, ec: integer, input: string}[]>
local pending = {}

--- Run the converters on the formulas not cached yet, in parallel, each one
--- on the inputs the previous ones failed.
local function convert(inputs)
  for _, cmd in ipairs(CONVERTERS) do
    if #inputs == 0 then
      return
    end
    if vim.fn.executable(cmd) == 1 then
      local tasks, failed = {}, {}
      for _, input in ipairs(inputs) do
        tasks[input] = vim.system({ cmd }, { stdin = input, text = true })
      end
      for input, task in pairs(tasks) do
        local res = task:wait(2000)
        local out = res.code == 0 and res.stdout and vim.trim(res.stdout) or ""
        if out ~= "" then
          cache[input] = out
        else
          failed[#failed + 1] = input
        end
      end
      inputs = failed
    end
  end
  for _, input in ipairs(inputs) do
    cache[input] = false
  end
end

---@param f {sr: integer, sc: integer, er: integer, ec: integer, input: string}
---@return render.md.Mark[]
local function marks_for(buf, f)
  local out = cache[f.input]
  if not out then
    return {}
  end
  local lines = vim.split(out, "\n", { plain = true })
  if #lines > 1 then
    -- Several lines (a matrix in $...$): above the formula, source kept.
    return {
      {
        conceal = true,
        start_row = f.sr,
        start_col = 0,
        opts = {
          virt_lines = vim.tbl_map(function(l)
            return { { string.rep(" ", f.sc) .. l, HL } }
          end, lines),
          virt_lines_above = true,
        },
      },
    }
  end
  if f.sr == f.er then
    return {
      {
        conceal = true,
        start_row = f.sr,
        start_col = f.sc,
        opts = { end_col = f.ec, conceal = "", virt_text = { { out, HL } }, virt_text_pos = "inline" },
      },
    }
  end
  -- Spans lines: the result goes where it starts, each line hides its part.
  local text = vim.api.nvim_buf_get_lines(buf, f.sr, f.er + 1, false)
  local marks = {
    {
      conceal = true,
      start_row = f.sr,
      start_col = f.sc,
      opts = { end_col = #text[1], conceal = "", virt_text = { { out, HL } }, virt_text_pos = "inline" },
    },
  }
  for row = f.sr + 1, f.er do
    local line = text[row - f.sr + 1]
    local from = #(line:match("^%s*")) -- keep the indent the line shares with the paragraph
    local to = row == f.er and f.ec or #line
    if to > from then
      marks[#marks + 1] = {
        conceal = true,
        start_row = row,
        start_col = from,
        opts = { end_col = to, conceal = "" },
      }
    end
  end
  return marks
end

-- Tables Claude Code draws in its pane (│ borders) wrap long cells over several
-- lines, so a formula can start in one line of a cell and end in the next. The
-- markdown parser reads line by line across the whole table and pairs a $ in one
-- cell with a $ in another, so table lines are read here instead, cell by cell.

local BORDER = "│"

local function is_table_line(line)
  return line ~= nil and line:match("^%s*│") ~= nil
end

--- Byte ranges (0-based, end exclusive) of the cells of a table line.
local function cells(line)
  local res, pos = {}, line:find(BORDER, 1, true)
  while pos do
    local nxt = line:find(BORDER, pos + #BORDER, true)
    if not nxt then
      break
    end
    res[#res + 1] = { from = pos - 1 + #BORDER, to = nxt - 1 }
    pos = nxt
  end
  return res
end

--- Formulas of one table row (lines i..j of `lines`, buffer row base + k - 1).
--- Each has `parts`: the piece of it on each line, {row, line, from, to}.
local function row_formulas(lines, base, i, j, found)
  local layout = cells(lines[i])
  local rows = {}
  for k = i, j do
    local c = cells(lines[k])
    if #c == 0 or #c ~= #layout then
      return
    end
    rows[#rows + 1] = { row = base + k - 1, line = lines[k], cells = c }
  end
  for col = 1, #layout do
    -- The cell's text, its lines joined by a space, with where each piece came from.
    local segs, joined = {}, ""
    for _, r in ipairs(rows) do
      local c = r.cells[col]
      local s = r.line:sub(c.from + 1, c.to)
      local body = vim.trim(s)
      if body ~= "" then
        if joined ~= "" then
          joined = joined .. " "
        end
        segs[#segs + 1] = { row = r.row, line = r.line, col = c.from + #s:match("^%s*"), at = #joined + 1, len = #body }
        joined = joined .. body
      end
    end
    local dollars, p = {}, 1
    while true do
      local d = joined:find("$", p, true)
      if not d then
        break
      end
      if joined:sub(d + 1, d + 1) == "$" then
        p = d + 2 -- $$ is no inline formula
      elseif d > 1 and joined:sub(d - 1, d - 1) == "\\" then
        p = d + 1
      else
        dollars[#dollars + 1] = d
        p = d + 1
      end
    end
    -- Pandoc's rule, so prices are no math: an opening $ has no space after it,
    -- a closing $ no space before it and no digit after it.
    local pairs_ = {}
    local open
    for _, d in ipairs(dollars) do
      if open and not joined:sub(d - 1, d - 1):match("%s") and not joined:sub(d + 1, d + 1):match("%d") then
        pairs_[#pairs_ + 1] = { open, d }
        open = nil
      elseif not joined:sub(d + 1, d + 1):match("^%s?$") then
        open = d
      end
    end
    for _, pair in ipairs(pairs_) do
      local ps, pe = pair[1], pair[2]
      local input = vim.trim(joined:sub(ps + 1, pe - 1))
      local parts = {}
      for _, s in ipairs(segs) do
        local from = math.max(ps, s.at)
        local to = math.min(pe, s.at + s.len - 1)
        if from <= to then
          parts[#parts + 1] = { row = s.row, line = s.line, from = s.col + from - s.at, to = s.col + to - s.at + 1 }
        end
      end
      if input ~= "" and #parts > 0 then
        found[#found + 1] = { input = input, parts = parts }
      end
    end
  end
end

--- Formulas in the table lines around what the windows of `buf` show.
local function table_formulas(buf)
  local first, last = math.huge, -1
  for _, win in ipairs(vim.fn.win_findbuf(buf)) do
    first = math.min(first, vim.fn.line("w0", win) - 1)
    last = math.max(last, vim.fn.line("w$", win) - 1)
  end
  local found = {}
  if last < 0 then
    return found
  end
  local base = math.max(0, first - 50)
  local lines = vim.api.nvim_buf_get_lines(buf, base, last + 50, false)
  local i = 1
  while i <= #lines do
    if is_table_line(lines[i]) then
      local j = i
      while is_table_line(lines[j + 1]) do
        j = j + 1
      end
      if base + j - 1 >= first and base + i - 1 <= last then
        row_formulas(lines, base, i, j, found)
      end
      i = j + 1
    else
      i = i + 1
    end
  end
  return found
end

--- Marks for the table formulas: each piece is hidden, the result drawn in place
--- of the first, and the width that changes is given back (spaces) or taken
--- (from the cell's spare spaces) just before the cell's right border, so the
--- borders stay where Claude drew them. A formula whose result does not fit
--- stays as source.
local function table_marks(formulas)
  local placed = {}
  for _, f in ipairs(formulas) do
    local out = cache[f.input]
    if out and not out:find("\n") then
      local shifts = {}
      for n, part in ipairs(f.parts) do
        local text = n == 1 and out or ""
        local border = part.line:find(BORDER, part.to + 1, true)
        if not border then
          shifts = nil
          break
        end
        local width = vim.fn.strdisplaywidth(part.line:sub(part.from + 1, part.to)) - vim.fn.strdisplaywidth(text)
        shifts[#shifts + 1] = { row = part.row, line = part.line, col = border - 1, width = width }
      end
      if shifts then
        placed[#placed + 1] = { f = f, out = out, shifts = shifts }
      end
    end
  end
  -- Total change per border; drop formulas while some border has too little room.
  local function totals()
    local sum = {}
    for _, p in ipairs(placed) do
      for _, s in ipairs(p.shifts) do
        local key = s.row .. ":" .. s.col
        sum[key] = sum[key] or { row = s.row, line = s.line, col = s.col, width = 0 }
        sum[key].width = sum[key].width + s.width
      end
    end
    return sum
  end
  local function spare(line, col)
    local before = line:sub(1, col):match("( *)$")
    return #before - 1 -- one space stays between the text and the border
  end
  local sum = totals()
  local bad = true
  while bad do
    bad = false
    for key, t in pairs(sum) do
      if t.width < 0 and -t.width > spare(t.line, t.col) then
        for n = #placed, 1, -1 do
          local hit = false
          for _, s in ipairs(placed[n].shifts) do
            hit = hit or (s.row .. ":" .. s.col) == key
          end
          if hit then
            table.remove(placed, n)
            break
          end
        end
        sum, bad = totals(), true
        break
      end
    end
  end
  local marks = {}
  for _, p in ipairs(placed) do
    for n, part in ipairs(p.f.parts) do
      local opts = { end_col = part.to, conceal = "" }
      if n == 1 then
        opts.virt_text, opts.virt_text_pos = { { p.out, HL } }, "inline"
      end
      marks[#marks + 1] = { row = part.row, col = part.from, opts = opts }
    end
  end
  for _, t in pairs(sum) do
    if t.width > 0 then
      marks[#marks + 1] = {
        row = t.row,
        col = t.col,
        opts = { virt_text = { { string.rep(" ", t.width) } }, virt_text_pos = "inline" },
      }
    elseif t.width < 0 then
      marks[#marks + 1] = { row = t.row, col = t.col - 1 + t.width, opts = { end_col = t.col - 1, conceal = "" } }
    end
  end
  return marks
end

---@param ctx render.md.handler.Context
---@return render.md.Mark[]
function M.parse(ctx)
  local buf = ctx.buf
  pending[buf] = pending[buf] or {}
  local text = vim.treesitter.get_node_text(ctx.root, buf)
  local terminal = vim.bo[buf].buftype == "terminal"
  local skip = false
  if terminal then
    local sr, _, er = ctx.root:range()
    skip = is_table_line(vim.api.nvim_buf_get_lines(buf, sr, sr + 1, false)[1])
      or is_table_line(vim.api.nvim_buf_get_lines(buf, er, er + 1, false)[1])
  end
  if not skip and not text:match("^%$%$") then
    local sr, sc, er, ec = ctx.root:range()
    local input = vim.trim(text:match("^%$*(.-)%$*$") or text)
    if input ~= "" then
      table.insert(pending[buf], { sr = sr, sc = sc, er = er, ec = ec, input = input })
    end
  end
  if not ctx.last then
    return {}
  end
  -- Last formula of this pass: convert what is new, all at once, and draw all.
  local formulas = pending[buf]
  pending[buf] = nil
  local in_tables = terminal and table_formulas(buf) or {}
  local new, seen = {}, {}
  for _, list in ipairs({ formulas, in_tables }) do
    for _, f in ipairs(list) do
      if cache[f.input] == nil and not seen[f.input] then
        seen[f.input] = true
        new[#new + 1] = f.input
      end
    end
  end
  convert(new)
  -- Added through render-markdown's Marks (internal module), as its builtin
  -- handler does: that records each concealed range and inline text in the
  -- buffer context, so a table measures ℤₙ and not the $\mathbb{Z}_n$ source.
  local context = require("render-markdown.request.context").get(buf)
  local marks = require("render-markdown.lib.marks").new(context, true)
  for _, f in ipairs(formulas) do
    for _, m in ipairs(marks_for(buf, f)) do
      marks:add(context.config.latex, "latex", m.start_row, m.start_col, m.opts)
    end
  end
  for _, m in ipairs(table_marks(in_tables)) do
    marks:add(context.config.latex, "latex", m.row, m.col, m.opts)
  end
  return marks:get()
end

return M
