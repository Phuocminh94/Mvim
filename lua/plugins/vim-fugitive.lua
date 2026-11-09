return {
  "tpope/vim-fugitive",
  cmd = { "G", "Git", "Gdiffsplit", "Gvdiffsplit", "Gstatus" },
  keys = {
    { "<leader>gs", "<cmd>Git<cr>", desc = "Git: status" },
    { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git: diff split" },
  },
}
