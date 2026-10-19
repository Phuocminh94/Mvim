return {
  "nvim-treesitter/nvim-treesitter-context",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    enable = true,
    max_lines = 3,
    min_window_height = 0,
    line_numbers = true,
    multiline_threshold = 1,
  },
}
