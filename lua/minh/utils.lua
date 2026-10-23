local M = {}

-- gp.nvim saves chats here (its default chat_dir).
M.gp_chat_dir = vim.fn.stdpath("data") .. "/gp/chats"

-- Line prefixes that start a turn in a gp chat (plugins/gp-nvim.lua sets them
-- in gp, the chat outline and the [a / ]a jumps read them).
M.gp_user_prefix = "❯ MBP "
M.gp_assistant_prefix = "◆ Gemini "

--- True when `buf` is a gp.nvim chat file.
function M.is_gp_chat(buf)
  local name = vim.api.nvim_buf_get_name(buf or 0)
  return vim.startswith(name, M.gp_chat_dir .. "/")
end

-- =============================================================================
-- SNACKS.PICKER HELPER
-- =============================================================================
local function show_toc_with_snacks(results, title)
  local ok, snacks = pcall(require, "snacks")
  if not ok then
    return
  end

  snacks.picker.pick({
    title = title,
    items = results,
    format = function(item)
      return { { item.text, "Normal" } }
    end,
    layout = {
      preview = false,
      layout = {
        width = 0.5,
        height = 0.4,
        border = "single",
      },
    },
    win = {
      input = { border = "single" },
      list = { border = "single" },
    },
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.api.nvim_win_set_cursor(0, { item.line, 0 })
      end
    end,
  })
end

-- =============================================================================
-- SECTION: CORE UTILITIES  (hard-wrap has moved to minh/wrap.lua)
-- =============================================================================

--- Engine: scans lines and builds a table of contents using a parser rule.
local function build_toc_data(parser_fn)
  local results = {}
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for lnum, line in ipairs(lines) do
    local entry = parser_fn(line, lnum)
    if entry then
      table.insert(results, {
        text = string.rep("  ", entry.level - 1) .. entry.display_text,
        line = entry.line or lnum,
      })
    end
  end
  return results
end

-- =============================================================================
-- SECTION: TABLE OF CONTENTS (THE RULES)
-- =============================================================================

M.markdown_toc = function(toc_name)
  toc_name = toc_name or "Markdown TOC"
  local inside_code_block = false

  local results = build_toc_data(function(line)
    if line:match("^%s*```") or line:match("^%s*~~~") then
      inside_code_block = not inside_code_block
      return nil
    end

    if inside_code_block or line:match("^`") then
      return nil
    end

    -- for normal markdown
    local heading = line:match("^(#+)%s+.*")
    if heading then
      return { level = #heading, display_text = line }
    end
  end)

  show_toc_with_snacks(results, toc_name)
end

--- Outline of a gp.nvim chat: the topic, every question (numbered, first line
--- of its text) and the headings inside the answers, nested under their question.
M.gp_chat_toc = function(toc_name)
  local inside_code_block = false
  local awaiting_question -- line number of a user prefix whose text is still to come
  local n = 0

  local results = build_toc_data(function(line, lnum)
    if line:match("^%s*```") or line:match("^%s*~~~") then
      inside_code_block = not inside_code_block
      return nil
    end
    if inside_code_block then
      return nil
    end

    -- Text of a question, on the line(s) after its prefix.
    if awaiting_question then
      if line:match("^%s*$") then
        return nil
      end
      local at = awaiting_question
      awaiting_question = nil
      n = n + 1
      return { level = 2, line = at, display_text = string.format("%s%d. %s", "❯ ", n, line) }
    end

    local topic = line:match("^# topic:%s*(.*)")
    if topic then
      return { level = 1, display_text = "# " .. topic }
    end

    if vim.startswith(line, M.gp_user_prefix) then
      local inline_text = line:sub(#M.gp_user_prefix + 1)
      if inline_text:match("%S") then
        n = n + 1
        return { level = 2, display_text = string.format("%s%d. %s", "❯ ", n, inline_text) }
      end
      awaiting_question = lnum
      return nil
    end

    local heading = line:match("^(#+)%s+.*")
    if heading then
      return { level = #heading + 2, display_text = line }
    end
  end)

  show_toc_with_snacks(results, toc_name)
end

M.latex_toc = function()
  local levels = {
    part = 1,
    chapter = 2,
    section = 3,
    subsection = 4,
    subsubsection = 5,
    paragraph = 6,
  }

  local results = build_toc_data(function(line)
    -- Ignore comments
    if line:match("^%s*%%") then
      return nil
    end

    -- Match \section{Title} or \section*{Title}
    local cmd, title = line:match("\\(%a+)%*?%s*%{(.-)%}")

    if cmd and levels[cmd] then
      return {
        level = levels[cmd],
        display_text = string.format("\\%s: %s", cmd, title),
      }
    end
  end)

  show_toc_with_snacks(results, "LaTeX TOC")
end

return M
