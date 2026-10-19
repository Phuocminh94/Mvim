return {
  "echasnovski/mini.bufremove",
  version = "*",
  keys = {
    {
      "<leader>x",
      function()
        require("mini.bufremove").delete(0, false)
      end,
      desc = "Delete buffer (keep window)",
    },
  },
  opts = {},
}
