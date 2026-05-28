return {
  'stevearc/conform.nvim',
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    formatters_by_ft = {
      tex = { 'latexindent' },
      python = { 'black', 'isort' },
      r = { 'air' },
    },
  },
}
