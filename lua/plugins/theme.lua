local theme_path = vim.fn.stdpath("config") .. "/lua/minh/theme.lua"
local loop = vim.uv or vim.loop
local stat = loop.fs_stat(theme_path)

local plugins = {
  {
    "ReallySnazzy/osaka-jade-nvim",
    priority = 1000,
    config = function()
      vim.cmd([[colorscheme osaka-jade]])
      vim.api.nvim_set_hl(0, "NeoTreeDirectoryName", { fg = "#F7E8B2", bold = true })
      vim.api.nvim_set_hl(0, "NeoTreeDirectoryIcon", { fg = "#F7E8B2" })
      vim.api.nvim_set_hl(0, "NeoTreeGitUntracked", { fg = "#E67D64" })
      vim.api.nvim_set_hl(0, "NeoTreeGitUnstaged", { fg = "#E67D64" })
    end,
  },
}

if stat then
  local success, extra_plugins = pcall(dofile, theme_path)

  if success and type(extra_plugins) == "table" then
    for _, plugin in ipairs(extra_plugins) do
      table.insert(plugins, plugin)
    end
  end
end

return plugins
