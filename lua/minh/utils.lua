local M = {}

-- =============================================================================
-- SNACKS.PICKER HELPER
-- =============================================================================
local function show_toc_with_snacks(results, title)
  local ok, snacks = pcall(require, "snacks")
  if not ok then return end

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
        line = lnum
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
  local catch_next_line = false

  local results = build_toc_data(function(line)
    if line:match("^%s*```") or line:match("^%s*~~~") then
      inside_code_block = not inside_code_block
      return nil
    end

    if inside_code_block or line:match("^`") then return nil end

    -- for gp.nvim chat buffer
    if catch_next_line then
      if line:match("^%s*$") then return nil end

      catch_next_line = false
      return { level = 1, display_text = "💬 MBP: " .. line }
    end
    if line:match("^%s*💬") then
      local inline_text = line:match("^%s*💬 MBP%s*[:%s]*(.*)")

      if inline_text and inline_text ~= "" then
        return { level = 1, display_text = "💬 MBP: " .. inline_text }
      else
        catch_next_line = true
        return nil
      end
    end

    -- for normal markdown
    local heading = line:match("^(#+)%s+.*")
    if heading then
      return { level = #heading, display_text = line }
    end
  end)

  show_toc_with_snacks(results, toc_name)
end

M.latex_toc = function()
  local levels = {
    part = 1, chapter = 2, section = 3,
    subsection = 4, subsubsection = 5, paragraph = 6,
  }

  local results = build_toc_data(function(line)
    -- Ignore comments
    if line:match("^%s*%%") then return nil end

    -- Match \section{Title} or \section*{Title}
    local cmd, title = line:match("\\(%a+)%*?%s*%{(.-)%}")

    if cmd and levels[cmd] then
      return {
        level = levels[cmd],
        display_text = string.format("\\%s: %s", cmd, title)
      }
    end
  end)

  show_toc_with_snacks(results, "LaTeX TOC")
end

return M
