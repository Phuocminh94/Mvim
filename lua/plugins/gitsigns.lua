return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },  -- Lazy-load on file open
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "▎" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
      untracked = { text = "▎" },
    },
  },
}
