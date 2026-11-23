return {
  "lervag/vimtex",
  ft = { "tex", "plaintex" },
  -- VimTeX reads its g: options when it loads, so set them in init.
  init = function()
    -- no zathura on macOS (sioyek's cask is disabled, fails Gatekeeper) or Windows (SumatraPDF, from winget)
    vim.g.vimtex_view_method = vim.fn.has("mac") == 1 and "skim"
      or vim.fn.has("win32") == 1 and "sumatrapdf"
      or "zathura"
    vim.g.vimtex_compiler_method = "latexmk"
    vim.g.vimtex_compiler_latexmk = {
      executable = "latexmk",
      options = {
        "-pdfxe",
        "-file-line-error",
        "-synctex=1",
        "-interaction=nonstopmode",
      },
    }
    -- Keep the quickfix window closed after compiling; errors are one
    -- :VimtexErrors (<localleader>le) away, and a failed build says so below.
    vim.g.vimtex_quickfix_mode = 0
    vim.api.nvim_create_autocmd("User", {
      pattern = "VimtexEventCompileFailed",
      callback = function()
        vim.notify("LaTeX: compile failed (<localleader>le for errors)", vim.log.levels.WARN)
      end,
    })
  end,
}
