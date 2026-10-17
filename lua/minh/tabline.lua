local M = {}

-- Right-aligned, clickable tab list: " 1 project ".
-- Each tab shows its tab-local cwd (set with :tcd / <leader>tcd), so tabs
-- read as projects; tabs without :tcd show the global cwd.
M.build = function()
  local parts = { "%=" }
  local current = vim.fn.tabpagenr()

  for i = 1, vim.fn.tabpagenr("$") do
    local hl = (i == current) and "%#TabLineSel#" or "%#TabLine#"
    local name = vim.fn.fnamemodify(vim.fn.getcwd(-1, i), ":t"):gsub("%%", "%%%%")
    -- %{n}T ... %T makes the label a mouse click target for tab n
    parts[#parts + 1] = string.format("%%%dT%s %d %s %%T", i, hl, i, name)
  end

  parts[#parts + 1] = "%#TabLineFill#"
  return table.concat(parts)
end

M.setup = function()
  -- 0: never, 1: only when there are 2+ tabs, 2: always
  vim.o.showtabline = 1
  vim.o.tabline = "%!v:lua.require'minh.tabline'.build()"
end

return M
