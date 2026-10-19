return {
  "NvChad/nvim-colorizer.lua",
  -- Loaded at startup: it attaches to buffers from its own autocmds.
  lazy = false,
  config = function()
    require("colorizer").setup()
    vim.keymap.set("n", "<A-c>", "<cmd>ColorizerToggle<CR>", { desc = "Toggle Colorizer" })
  end,
}
