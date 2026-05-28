return {
  "lervag/vimtex",
  ft = { "tex", "plaintex" },
  config = function()
    vim.cmd('filetype plugin indent on')
    vim.cmd('syntax enable')

    vim.g.vimtex_view_method = "general"
    vim.g.vimtex_view_general_viewer = "sioyek"
    vim.g.vimtex_view_enabled = 1

    vim.g.vimtex_compiler_method = 'latexmk'
    vim.g.vimtex_view_general_options_latexmk = "--unique"
    vim.g.maplocalleader = ','

    vim.g.vimtex_compiler_latexmk = {
      executable = 'latexmk',
      options = {
        -- '-xelatex',
        '-pdfxe', -- <— single, unambiguous switch
        '-file-line-error',
        '-synctex=1',
        '-interaction=nonstopmode',
      },
    }
  end,
}
