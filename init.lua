-- ==========================================================================
-- NOTE: Verified compatible with Neovim v0.12.2
-- ==========================================================================

-- Set leader key (must be done before lazy.nvim/keymaps loaded)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Load core configurations
require("minh.options")
require("minh.keymaps")
require("minh.autocmd")

-- Plugin manager (Lazy.nvim)
require("lazy_cf")

-- UI Components
local ok, _ = pcall(require, "plugins.theme")
if not ok then
  vim.cmd.colorscheme('neovim')
end

require("minh.statusline").setup()
require("minh.tabline").setup()
require("minh.lsp_utils").setup_ui()
