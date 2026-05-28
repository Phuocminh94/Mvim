-- @see disable statusline of NERDTree https://github.com/preservim/nerdtree/issues/280
return {
  'preservim/nerdtree',
  cmd = { 'NERDTreeToggle', 'NERDTreeFind', 'NERDTree' },
  init = function()
    vim.g.NERDTreeShowHidden = 1
    vim.g.NERDTreeQuitOnOpen = 1
    vim.g.NERDTreeMinimalUI = 1
    vim.g.NERDTreeStatusline = '%#NonText#'
  end,
}
