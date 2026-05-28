local M = {}

M.build = function()
  local s = "%=" -- Align to the right
  local total = vim.fn.tabpagenr("$")
  local current = vim.fn.tabpagenr()

  for i = 1, total do
    -- Use a ternary-like table for cleaner highlight selection
    local hl = (i == current) and "%#TabLineSel#" or "%#TabLine#"

    -- Add click support! %iT makes the tab clickable in some terminals
    s = s .. "%" .. i .. "T" .. hl .. "  " .. i .. "  " .. "%T"
  end

    return s .. "%#TabLineFill#"
end

M.setup = function()
    -- 0: never, 1: only if >= 2 tabs, 2: always
    -- We likely want 1 or 2. Let's use 2 so you can always see it.
    vim.o.showtabline = vim.fn.tabpagenr("$") > 1 and 0 or 1
    
    -- Optimized string: using %!v:lua is correct for Neovim
    vim.o.tabline = "%!v:lua.require('minh.tabline').build()"
end

return M
