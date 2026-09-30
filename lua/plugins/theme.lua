local theme_path = vim.fn.stdpath("config") .. "/lua/minh/theme.lua"
local loop = vim.uv or vim.loop
local stat = loop.fs_stat(theme_path)

local extra_plugins = {}

if stat then
  local success, result = pcall(dofile, theme_path)
  if success and type(result) == "table" then
    extra_plugins = result
  end
end

local has_custom_theme = #extra_plugins > 0

local plugins = {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    enabled = has_custom_theme,
    name = "aether",
    priority = 1000,
    lazy = false,
    opts = {
      colors = {
        bg = "#222222",
        dark_bg = "#191919",
        darker_bg = "#121212",
        lighter_bg = "#2c2c2c",

        fg = "#c2c2b0",
        dark_fg = "#555555",
        light_fg = "#8a8a7e",
        bright_fg = "#c2c2b0",
        muted = "#666666",

        red = "#685742",
        yellow = "#b36d43",
        orange = "#8d6242",
        green = "#5f875f",
        cyan = "#c9a554",
        blue = "#78824b",
        magenta = "#bb7744",
        brown = "#463121",

        bright_red = "#685742",
        bright_yellow = "#b36d43",
        bright_green = "#5f875f",
        bright_cyan = "#c9a554",
        bright_blue = "#78824b",
        bright_magenta = "#bb7744",

        accent = "#78824b",
        cursor = "#c2c2b0",
        foreground = "#c2c2b0",
        background = "#222222",
        selection = "#383838",
        selection_foreground = "#c2c2b0",
        selection_background = "#383838",
      },
    },
    config = function(_, opts)
      require("aether").setup(opts)
      vim.cmd.colorscheme("aether")
      vim.api.nvim_set_hl(0, "ColorColumn", { bg = "#2c2c2c" })
    end,
  },
}

for _, plugin in ipairs(extra_plugins) do
  table.insert(plugins, plugin)
end

return plugins
