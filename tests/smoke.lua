-- Smoke test: start the real config headless, load every plugin, open one file
-- per filetype and check for errors and a few invariants.
--   nvim --headless -c "luafile tests/smoke.lua"
-- Exits 0 when everything passes, 1 otherwise.

local failures = {}
local function check(ok, msg)
  if not ok then
    failures[#failures + 1] = msg
  end
end

-- Errors already in :messages (from startup, a plugin config, an autocmd...).
local function new_errors(seen)
  local out = {}
  local msgs = vim.api.nvim_exec2("messages", { output = true }).output
  for line in msgs:gmatch("[^\n]+") do
    if (line:match("E%d+:") or line:match("[Ee]rror")) and not seen[line] then
      seen[line] = true
      out[#out + 1] = line
    end
  end
  return out
end

local function run()
  local seen = {}
  local tmp = vim.fn.tempname()
  vim.fn.mkdir(tmp, "p")

  -- 0. Options as set by minh.options, before any FileType autocmd changes them.
  check(not vim.go.foldexpr:find("nvim_treesitter#", 1, true), "foldexpr uses removed nvim_treesitter#foldexpr()")

  -- 1. Every plugin loads and runs its config (lazy specs are not loaded
  -- otherwise in a headless session).
  local ok, err = pcall(function()
    require("lazy").load({ plugins = vim.tbl_keys(require("lazy.core.config").plugins) })
  end)
  check(ok, "loading all plugins: " .. tostring(err))
  for _, e in ipairs(new_errors(seen)) do
    check(false, "startup: " .. e)
  end

  -- 2. One file per filetype: ftplugins, FileType autocmds, treesitter, LSP setup.
  local files = {
    ["a.md"] = { "# Title", "", "text with `code`", "", "```python", "x = 1", "```" },
    ["a.py"] = { "def f(x):", "    return x" },
    ["a.lua"] = { "local x = 1", "return x" },
    ["a.tex"] = { "\\section{A}", "text % comment" },
    ["a.sql"] = { "select 1;" },
    ["a.R"] = { "x <- 1" },
    ["a.txt"] = { "plain" },
  }
  for name, lines in pairs(files) do
    local path = tmp .. "/" .. name
    vim.fn.writefile(lines, path)
    local ok_edit, edit_err = pcall(vim.cmd.edit, path)
    check(ok_edit, name .. ": " .. tostring(edit_err))
    -- Exercise CursorMoved / fold / statusline code paths.
    pcall(vim.api.nvim_win_set_cursor, 0, { #lines, 0 })
    vim.api.nvim_exec_autocmds("CursorMoved", {})
    pcall(vim.fn.foldlevel, 1)
    local ok_sl, sl_err = pcall(vim.api.nvim_eval_statusline, vim.o.statusline, {})
    check(ok_sl, name .. ": statusline: " .. tostring(sl_err))
    for _, e in ipairs(new_errors(seen)) do
      check(false, name .. ": " .. e)
    end
  end

  -- 3. Invariants this config relies on.
  vim.cmd.edit(tmp .. "/a.md")
  check(vim.bo.formatexpr:find("minh.wrap", 1, true), "markdown: formatexpr is not minh.wrap")
  check(vim.wo.spell, "markdown: spell is off")

  vim.cmd.edit(tmp .. "/a.py")
  check(not vim.wo.spell, "python: spell should only be on for text filetypes")
  check(vim.fn.maparg("<C-w>j", "n") == "", "<C-w>j is remapped (should move between windows)")
  -- LSP keymaps are created on LspAttach; fire it by hand (no real client).
  vim.api.nvim_exec_autocmds("LspAttach", { buffer = 0, data = { client_id = -1 } })
  check(vim.fn.maparg("gci", "n") == "" and vim.fn.maparg("gco", "n") == "", "gci/gco shadow the comment operator")

  vim.cmd.edit(tmp .. "/a.sql")
  local db = vim.fn.maparg("<leader>db", "n", false, true)
  check(db.buffer == 1, "sql: <leader>db should be buffer-local")

  -- 4. Highlights survive a colorscheme reload.
  vim.cmd.colorscheme(vim.g.colors_name or "default")
  local function hl(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
  end
  check(hl("Normal").bg == nil, "Normal has a background after :colorscheme (transparency lost)")
  check(hl("ColorColumn").bg ~= nil, "ColorColumn has no background")
  check(next(hl("St_Mode")) ~= nil, "St_Mode is not defined")

  -- 5. A file name with % must not break the statusline.
  vim.cmd.edit(vim.fn.fnameescape(tmp .. "/100%.md"))
  local text = vim.api.nvim_eval_statusline(vim.o.statusline, {}).str
  check(text:find("100%.md", 1, true), "statusline does not show '100%.md': " .. text)

  for _, e in ipairs(new_errors(seen)) do
    check(false, "end: " .. e)
  end

  if #failures == 0 then
    io.stdout:write("smoke: OK\n")
    vim.cmd("qa!")
  else
    io.stdout:write("smoke: " .. #failures .. " failure(s)\n  " .. table.concat(failures, "\n  ") .. "\n")
    vim.cmd("cq!")
  end
end

-- -c runs before VimEnter; wait for startup to finish.
vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    vim.schedule(function()
      local ok, err = xpcall(run, debug.traceback)
      if not ok then
        io.stdout:write("smoke: crashed\n" .. err .. "\n")
        vim.cmd("cq!")
      end
    end)
  end,
})
