-- Overrides on top of nvim-lspconfig's defaults (must live in after/lsp/).

-- Use the R of the active conda env: languageserver is installed per R library,
-- so the server has to run with the same R as the project. Fall back to the R
-- found in PATH when no env is active or the env has no R.
local cmd = { "R", "--no-echo", "-e", "languageserver::run()" }
local prefix = vim.env.CONDA_PREFIX
if prefix and vim.fn.executable(prefix .. "/bin/R") == 1 then
  cmd[1] = prefix .. "/bin/R"
end

-- Project root: R project markers, falling back to the file's own folder.
-- (The default is the .git folder or the home directory.)
local markers = { DESCRIPTION = true, [".Rprofile"] = true, ["renv.lock"] = true, [".git"] = true }

return {
  cmd = cmd,
  filetypes = { "r", "rmd" },
  root_dir = function(bufnr, on_dir)
    local root = vim.fs.root(bufnr, function(name)
      return markers[name] or name:match("%.Rproj$") ~= nil
    end)
    on_dir(root or vim.fs.dirname(vim.api.nvim_buf_get_name(bufnr)))
  end,
  settings = { r = { lsp = { diagnostics = true } } },
}
