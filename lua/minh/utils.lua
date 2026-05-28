local M = {}

-- =============================================================================
-- SECTION: CORE UTILITIES (THE ENGINES)
-- =============================================================================

--- Helper: Logic for splitting a long string into a table of wrapped fragments
local function wrap_string(text, n)
  local result = {}
  local line = text
  while #line > n do
    local segment = line:sub(1, n)
    -- Capture position of the last space within the segment
    local break_at = segment:match(".*()%s") 
    
    if break_at then
      table.insert(result, line:sub(1, break_at - 1))
      -- Move 'line' to after the space, trimming leading whitespace
      line = line:sub(break_at + 1):gsub("^%s*", "")
    else
      -- Force break if no space found
      table.insert(result, line:sub(1, n))
      line = line:sub(n + 1)
    end
  end
  table.insert(result, line)
  return result
end

--- Engine: Handles buffer I/O and loops through lines using a skip-rule
local function apply_hardwrap(n, should_skip_fn)
  n = n or 80
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local wrapped = {}

  for _, line in ipairs(lines) do
    if should_skip_fn(line) then
      table.insert(wrapped, line)
    else
      local fragments = wrap_string(line, n)
      for _, f in ipairs(fragments) do
        table.insert(wrapped, f)
      end
    end
  end
  vim.api.nvim_buf_set_lines(0, 0, -1, false, wrapped)
end

--- Engine: Scans lines and builds a table of contents based on a parser-rule
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
-- SECTION: HARDWRAP LOGIC (THE RULES)
-- =============================================================================

M.hardwrap_md = function(n)
  local in_math_block = false
  
  apply_hardwrap(n, function(line)
    local trimmed = line:match("^%s*(.-)%s*$")
    
    -- Handle Block Toggles
    local is_toggle = trimmed == "$$" or trimmed == "\\[" or trimmed == "\\]" or trimmed:find("^```")
    if is_toggle then
      in_math_block = not in_math_block
      return true 
    end

    -- Skip rules
    return in_math_block 
      or trimmed:find("^#")           -- Headers
      or trimmed:find("^`")           -- Inline code
      or trimmed:find("^%$")          -- Inline math
      or trimmed:find("^\\%(")        -- LaTeX inline math
  end)
end

M.hardwrap_tex = function(n)
  apply_hardwrap(n, function(line)
    -- Skip lines starting with \ (commands) except \item
    return line:match("^%s*\\") and not line:match("^%s*\\item")
  end)
end

-- =============================================================================
-- SECTION: TABLE OF CONTENTS (THE RULES)
-- =============================================================================

M.markdown_toc = function()
  local inside_code_block = false
  
  local results = build_toc_data(function(line)
    if line:match("^```") then
      inside_code_block = not inside_code_block
      return nil
    end

    if inside_code_block or line:match("`") then return nil end

    local heading = line:match("^(#+)%s+.*")
    if heading then
      return { level = #heading, display_text = line }
    end
  end)

  require("telescope").show_toc_picker(results, "Markdown TOC")
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

  require("telescope").show_toc_picker(results, "LaTeX TOC")
end

return M
