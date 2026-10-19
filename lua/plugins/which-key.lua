return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts_extend = { "spec" },
  opts = {
    preset = "helix",
    icons = {
      mappings = false, -- removes icons for individual mappings
      rules = false, -- removes automatic icon rules
      breadcrumb = "", -- removes the breadcrumb icon
      group = "", -- removes the group folder icon (annoying +)
    },
    spec = {
      { "<leader>", group = "󱁐 Leader" }, -- Change annoying "+Ignore Space" to "󱁐 Leader"
      { "<leader>a", group = "AI" },
      { "<leader>c", group = "Code / cwd" },
      { "<leader>d", group = "Debug / diagnostics" },
      { "<leader>f", group = "Find" },
      { "<leader>g", group = "Git" },
      { "<leader>h", group = "Hunks" },
      { "<leader>l", group = "Lazygit" },
      { "<leader>m", group = "Markdown" },
      { "<leader>n", group = "Noice" },
      { "<leader>r", group = "REPL / rename" },
      { "<leader>s", group = "Splits / symbols" },
      { "<leader>t", group = "Tabs / TOC" },
      { "<leader>w", group = "Wrap" },
    },
  },
  keys = {
    {
      "<leader>?",
      function()
        require("which-key").show({ global = false })
      end,
      desc = "Buffer Keymaps (which-key)",
    },
    {
      "<c-w><space>",
      function()
        require("which-key").show({ keys = "<c-w>", loop = true })
      end,
      desc = "Window Hydra Mode (which-key)",
    },
  },
}
