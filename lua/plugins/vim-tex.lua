return {
  "lervag/vimtex",
  ft = { "tex", "plaintex" },
  -- VimTeX reads its g: options when it loads, so set them in init.
  init = function()
    vim.g.vimtex_view_method = "zathura"
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
  end,
}
