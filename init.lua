-- ==========================================================================
-- NOTE: Verified compatible with Neovim v0.12.6
-- ==========================================================================

-- Set leader key (must be done before lazy.nvim/keymaps loaded)
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- Load core configurations
require("minh.options")
require("minh.keymaps")
require("minh.autocmd")
-- Before lazy.nvim: its ColorScheme autocmd must see the colorscheme being set.
require("minh.highlights").setup()

-- Plugin manager (Lazy.nvim)
require("lazy_cf")

-- Personal
require("minh.statusline").setup()
require("minh.tabline").setup()
require("minh.lsp_utils").setup_ui()
