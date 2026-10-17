return {
  "folke/lazydev.nvim",
  ft = "lua",
  cmd = "LazyDev",
  opts = {
    -- Type definitions are loaded only when the word appears in the file.
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "lazy.nvim", words = { "lazy" } },
      -- The global `Snacks` used in keymaps.lua (Snacks.picker...);
      -- without this lua_ls reports "Undefined global Snacks".
      { path = "snacks.nvim", words = { "Snacks" } },
    },
  },
}
