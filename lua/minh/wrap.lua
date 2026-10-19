-- =============================================================================
-- minh.wrap — hard-wrap (reflow) for markdown / rmd / tex
--
-- Usage (after calling require("minh.wrap").attach() in ftplugin):
--   gqip / gqap        reflow paragraph under cursor
--   gq (visual)        reflow selected region
--   gggqG              reflow entire file
--   :Wrap [N]          entire file (or :'<,'>Wrap 100 for region with width 100)
--   <leader>wr         current paragraph (normal) / selected region (visual)
--   <leader>wR         entire file
--
-- Width is taken from buffer's 'textwidth', so each file can have different width:
--   :setlocal tw=100   or modeline at end of file, for example
--   <!-- vim: set tw=100: -->      (markdown / rmd)
--   % vim: set tw=100:             (tex)
-- =============================================================================

local M = {}

-- Display width (not byte count): "ế" = 1 column even though it takes 3 bytes.
local strwidth = vim.api.nvim_strwidth

-- -----------------------------------------------------------------------------
-- Common utilities
-- -----------------------------------------------------------------------------

--- Split paragraph into words, preserving atomic spans that should not be split
--- (`code`, $math$, \(math\), \verb|...|): whitespace inside is temporarily
--- replaced with \1 and restored after splitting.
local function split_words(text, atomic)
  for _, pat in ipairs(atomic) do
    text = text:gsub(pat, function(m)
      return (m:gsub("%s", "\1"))
    end)
  end
  local words = {}
  for w in text:gmatch("%S+") do
    words[#words + 1] = (w:gsub("\1", " "))
  end
  return words
end

--- Pack words into lines ≤ width. Words longer than width (URLs, paths) are left
--- on one line instead of being split in the middle.
local function fill(words, width, first_prefix, rest_prefix)
  if #words == 0 then
    return { (first_prefix:gsub("%s+$", "")) }
  end
  local out = {}
  local cur, cur_w, fresh = first_prefix, strwidth(first_prefix), true
  local rest_w = strwidth(rest_prefix)
  for _, w in ipairs(words) do
    local ww = strwidth(w)
    if fresh then
      cur, cur_w, fresh = cur .. w, cur_w + ww, false
    elseif cur_w + 1 + ww <= width then
      cur, cur_w = cur .. " " .. w, cur_w + 1 + ww
    else
      out[#out + 1] = cur
      cur, cur_w = rest_prefix .. w, rest_w + ww
    end
  end
  out[#out + 1] = cur
  return out
end

-- Math blocks shared between markdown and tex.
local function math_block_open(t)
  if t:match("^%$%$") and not (#t > 2 and t:match("%$%$$")) then
    return function(l)
      return vim.trim(l):match("%$%$$") ~= nil
    end
  end
  if t:match("^\\%[") and not t:find("\\]", 3, true) then
    return function(l)
      return l:find("\\]", 1, true) ~= nil
    end
  end
end

local function env_block_open(t, only)
  local env = t:match("^\\begin{([^}]+)}")
  if not env or (only and not only[(env:gsub("%*$", ""))]) then
    return nil
  end
  local close = "\\end{" .. env .. "}"
  if t:find(close, 1, true) then
    return nil
  end
  return function(l)
    return l:find(close, 1, true) ~= nil
  end
end

-- -----------------------------------------------------------------------------
-- Rules for each filetype
--   block_open(t, lnum) -> function to close block if this line opens a verbatim block
--   is_verbatim(t, line) -> line is preserved as-is (also a paragraph boundary)
--   parse(line)          -> { new, key, first, rest, text }
--   hard_break(line)     -> string to append at end of paragraph, or nil
--   atomic               -> patterns for spans that should not be split
-- -----------------------------------------------------------------------------

local rules = {}

rules.markdown = {
  atomic = {
    "``.-``",
    "`[^`]+`",
    "%$%$.-%$%$",
    "%$[^%s$][^$]-[^%s$]%$",
    "\\%(.-\\%)",
  },

  block_open = function(t, lnum)
    if lnum == 1 and t == "---" then -- YAML front matter (Rmd)
      return function(l)
        local s = vim.trim(l)
        return s == "---" or s == "..."
      end
    end
    local fence = t:match("^(```+)") or t:match("^(~~~+)")
    if fence then
      local ch, n = fence:sub(1, 1), #fence
      return function(l)
        local f = vim.trim(l):match("^([`~]+)$")
        return f ~= nil and f:sub(1, 1) == ch and #f >= n
      end
    end
    if t:match("^<!%-%-") and not t:find("-->", 1, true) then
      return function(l)
        return l:find("-->", 1, true) ~= nil
      end
    end
    return math_block_open(t) or env_block_open(t)
  end,

  is_verbatim = function(t)
    return t:match("^#") -- heading
      or t:match("^|") -- table
      or t:match("^<") -- html
      or t:match("^!%[") -- image on own line (figure in Rmd/pandoc)
      or t:match("^%[[^%]]+%]:") -- reference link
      or t:match("^:::") -- pandoc div
      or t:match("^{{") -- shortcode
      or t:match("^%$%$") -- display math single line
      or t:match("^\\%[") -- \[ ... \] single line
      or t:match("^\\%a") -- latex command: \newpage, \begin...
      or t:match("^>[>%s]*$") -- empty line in blockquote
      or t:match("^=+$") -- setext heading
      or t:match("^[-*_]%s*[-*_]%s*[-*_][-*_%s]*$") -- horizontal rule
  end,

  parse = function(line)
    local quote, rest = line:match("^(%s*>[>%s]*)(.*)$")
    if not quote then
      quote, rest = "", line
    end
    local key = quote:gsub("%s", "")

    local ind, marker, sp, body = rest:match("^(%s*)([-*+])(%s+)(.*)$")
    if not ind then
      ind, marker, sp, body = rest:match("^(%s*)(%d+[.)])(%s+)(.*)$")
    end
    if ind then
      local task = body:match("^%[[ xX-]%]%s+")
      if task then
        marker, sp, body = marker .. sp .. task, "", body:sub(#task + 1)
      end
      local head = ind .. marker .. sp
      return {
        new = true,
        key = key,
        first = quote .. head,
        rest = quote .. string.rep(" ", strwidth(head)),
        text = body,
      }
    end

    local indent, text = rest:match("^(%s*)(.*)$")
    return { new = false, key = key, first = quote .. indent, rest = quote .. indent, text = text }
  end,

  hard_break = function(line)
    if line:match("%S  +$") then
      return "  "
    end
    if line:match("\\$") then
      return ""
    end
  end,
}

-- LaTeX commands at start of line that are still prose (permitted to reflow).
-- stylua: ignore
local TEX_PROSE_CMDS = {
  textbf = true, textit = true, emph = true, texttt = true, underline = true,
  cite = true, ref = true, eqref = true, autoref = true, href = true, url = true,
  footnote = true, LaTeX = true, TeX = true, ldots = true,
}

-- Environments that should be preserved completely.
-- stylua: ignore
local TEX_VERBATIM_ENVS = {
  equation = true, align = true, gather = true, multline = true, flalign = true,
  alignat = true, eqnarray = true, verbatim = true, Verbatim = true,
  lstlisting = true, minted = true, tikzpicture = true, tabular = true,
  tabularx = true, longtable = true, array = true, matrix = true,
  pmatrix = true, bmatrix = true, comment = true,
}

rules.tex = {
  atomic = {
    "%$%$.-%$%$",
    "%$[^%s$][^$]-[^%s$]%$",
    "\\%(.-\\%)",
    "\\verb(.).-%1",
  },

  block_open = function(t)
    return math_block_open(t) or env_block_open(t, TEX_VERBATIM_ENVS)
  end,

  is_verbatim = function(t, line)
    -- Line with comment: joining next line loses the comment, splitting loses
    -- the text after the comment → preserve.
    if t:match("^%%") or line:find("[^\\]%%") then
      return true
    end
    -- Unescaped & = column in tabular/align.
    if t:match("^&") or line:find("[^\\]&") then
      return true
    end
    if t:match("^%$%$") then
      return true
    end
    if t:match("^\\") then
      if t:match("^\\item%f[%A]") or t:match("^\\%(") then
        return false
      end
      local cmd = t:match("^\\(%a+)")
      return not (cmd and TEX_PROSE_CMDS[cmd])
    end
    return false
  end,

  parse = function(line)
    local ind, item = line:match("^(%s*)(\\item%b[]%s*)")
    if not ind then
      ind, item = line:match("^(%s*)(\\item%f[%A]%s*)")
    end
    if ind then
      if not item:match("%s$") then
        item = item .. " "
      end
      local head = ind .. item
      return {
        new = true,
        key = "",
        first = head,
        rest = string.rep(" ", strwidth(head)),
        text = line:sub(#head + 1),
      }
    end
    local indent, text = line:match("^(%s*)(.*)$")
    return { new = false, key = "", first = indent, rest = indent, text = text }
  end,

  hard_break = function(line)
    if line:match("\\\\%s*$") then
      return ""
    end
  end,
}

local FT_RULES = {
  tex = rules.tex,
  plaintex = rules.tex,
  latex = rules.tex,
}

local function rules_for(ft)
  return FT_RULES[ft] or rules.markdown
end

-- -----------------------------------------------------------------------------
-- Engine
-- -----------------------------------------------------------------------------

--- Reflow lines [first, last] (1-based, inclusive).
--- Block state (in code block / math...) is computed from start of file,
--- so selecting a region in the middle of the file still works correctly.
--- @return integer line count after reflow
function M.reflow(buf, first, last, width)
  buf = (buf == nil or buf == 0) and vim.api.nvim_get_current_buf() or buf
  last = math.min(last, vim.api.nvim_buf_line_count(buf))
  if not width or width <= 0 then
    local tw = vim.bo[buf].textwidth
    width = tw > 0 and tw or 80
  end
  local R = rules_for(vim.bo[buf].filetype)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, last, false)

  local out, para, closer = {}, nil, nil

  local function flush()
    if not para then
      return
    end
    local text = table.concat(para.texts, " ")
    local res = fill(split_words(text, R.atomic), width, para.first, para.rest)
    if para.hard then
      res[#res] = res[#res] .. para.hard
    end
    vim.list_extend(out, res)
    para = nil
  end

  for lnum = 1, last do
    local line = lines[lnum]
    local keep
    if closer then
      keep = true
      if closer(line) then
        closer = nil
      end
    else
      local t = vim.trim(line)
      closer = R.block_open(t, lnum)
      keep = closer ~= nil or t == "" or R.is_verbatim(t, line)
    end

    if lnum >= first then
      if keep then
        flush()
        out[#out + 1] = line
      else
        local p = R.parse(line)
        if para and not p.new and p.key == para.key then
          para.texts[#para.texts + 1] = p.text
        else
          flush()
          para = { key = p.key, first = p.first, rest = p.rest, texts = { p.text } }
        end
        local hb = R.hard_break(line)
        if hb then
          para.hard = hb
          flush()
        end
      end
    end
  end
  flush()

  vim.api.nvim_buf_set_lines(buf, first - 1, last, false, out)
  return #out
end

--- Use as 'formatexpr' so gq / gqip / visual gq go through this engine.
function M.formatexpr()
  -- Auto-wrap while typing (insert mode): let Neovim handle it.
  if vim.v.char ~= "" or vim.fn.mode():match("^[iR]") then
    return 1
  end
  local first = vim.v.lnum
  local n = M.reflow(0, first, first + vim.v.count - 1)
  vim.api.nvim_win_set_cursor(0, { first + math.max(n, 1) - 1, 0 })
  vim.cmd("normal! ^")
  return 0
end

--- Attach to current buffer: formatexpr, :Wrap command, and buffer-local keymaps.
function M.attach()
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].formatexpr = "v:lua.require'minh.wrap'.formatexpr()"

  vim.api.nvim_buf_create_user_command(buf, "Wrap", function(o)
    local view = vim.fn.winsaveview()
    M.reflow(buf, o.line1, o.line2, tonumber(o.args))
    vim.fn.winrestview(view)
  end, { range = "%", nargs = "?", bar = true, desc = "Hard wrap (default: entire file) [width]" })

  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
  end
  map("n", "<leader>wr", "gqip", "Wrap paragraph")
  map("x", "<leader>wr", "gq", "Wrap selection")
  map("n", "<leader>wR", "<cmd>Wrap<cr>", "Wrap whole file")
end

return M
