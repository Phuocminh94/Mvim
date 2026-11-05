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

---@param ctx render.md.handler.Context
---@return render.md.Mark[]
function M.parse(ctx)
  local buf = ctx.buf
  pending[buf] = pending[buf] or {}
  local text = vim.treesitter.get_node_text(ctx.root, buf)
  if not text:match("^%$%$") then
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
  local new, seen = {}, {}
  for _, f in ipairs(formulas) do
    if cache[f.input] == nil and not seen[f.input] then
      seen[f.input] = true
      new[#new + 1] = f.input
    end
  end
  convert(new)
  local marks = {}
  for _, f in ipairs(formulas) do
    vim.list_extend(marks, marks_for(buf, f))
  end
  return marks
end

return M
