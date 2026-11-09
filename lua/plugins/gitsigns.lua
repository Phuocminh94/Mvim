-- Deletions get their own shapes so the gutter tells them apart without colour:
-- ▁ = lines removed below this one, ▔ = removed above (top of file).
local signs = {
  add = { text = "▎" },
  change = { text = "▎" },
  delete = { text = "▁" },
  topdelete = { text = "▔" },
  changedelete = { text = "~" },
  untracked = { text = "┆" },
}

return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" }, -- Lazy-load on file open
  opts = {
    signs = signs,
    -- Staged hunks: same shapes, only the fainter colour differs.
    signs_staged = signs,
    -- Inline blame (<leader>hB) is off by default; show it soon after the cursor stops.
    current_line_blame_opts = { delay = 300 },
  },
}
