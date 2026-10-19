-- stylua: ignore start
-- My Essential Neovim Options --

-- Globals
-- Machine-specific settings (gitignored): vim.g.note_path, vim.g.dadbod_db...
-- A missing file is fine; an error inside it is reported instead of hidden.
local ok, err = pcall(require, "minh.local_config")
if not ok and not err:find("module 'minh.local_config' not found", 1, true) then
  vim.notify("local_config: " .. err, vim.log.levels.WARN)
end
vim.g.note_path = vim.g.note_path or ""
vim.g.dadbod_db = vim.g.dadbod_db or {}

vim.g.loaded_netrw = 1              -- Disable netrw at the very start
vim.g.loaded_netrwPlugin = 1
vim.g.snippet_path = vim.api.nvim_get_runtime_file("lua/snippets", false)[1] or {}

local opt = vim.opt
-- General UI & Feedback
opt.number         = true           -- Show line numbers
opt.relativenumber = true           -- Use relative numbers (essential for jumping)
opt.cursorline     = true           -- Highlight the current line
opt.cursorlineopt  = "number"       -- Only highlight the number, not the whole line (cleaner)
opt.termguicolors  = true           -- True color support (required for modern themes)
opt.signcolumn     = "yes"          -- Always show signcolumn (stops text "jumping" on errors)
opt.fillchars      = { eob = " " }  -- Hide the '~' on empty lines at end of buffer
opt.mouse          = "a"            -- Enable mouse support
opt.updatetime     = 300            -- Faster completion and plugin responsiveness (default is 4000ms)
opt.scrolloff      = 8
opt.list = false
opt.listchars = {
  tab = "  ",
  eol = '↲',
  trail = '•',
  extends = '»',                    -- Use in conjunction with 'nowrap'
  precedes = '«',
}

-- Folds: treesitter folding is enabled per buffer in plugins/nvim-treesitter.lua
-- (only where a parser exists); other buffers keep foldmethod=manual.
opt.foldlevel      = 99             -- Start with every fold open
opt.foldlevelstart = 99


-- Search Settings
opt.ignorecase     = true           -- Case insensitive search...
opt.smartcase      = true           -- ...unless capital letters are used
opt.grepprg        = "rg --vimgrep --no-heading --smart-case" -- Use Ripgrep for searching
opt.incsearch      = true

-- Tabs & Indentation (The 2-space standard)
opt.tabstop        = 2
opt.shiftwidth     = 2
opt.expandtab      = true           -- Use spaces instead of tabs
opt.autoindent     = true
opt.wrap           = false          -- Don't wrap long lines visually
opt.linebreak      = true           -- Where wrap is on: break at word boundaries
opt.breakindent    = true           -- ...and keep the indent of wrapped lines

-- System Integration
opt.clipboard:append("unnamedplus") -- Sync with system clipboard
opt.swapfile       = false          -- Don't create annoying .swp files
opt.undofile       = true           -- Persistent undo (undotree survives restarts)
opt.splitright     = true           -- Vertical splits go to the right
opt.splitbelow     = true           -- Horizontal splits go to the bottom
opt.backspace      = "indent,eol,start" -- Logical backspace behavior

-- Language & Dict (spell is enabled for text filetypes in minh/autocmd.lua)
opt.dictionary     = { vim.fn.stdpath("config") .. "/dict/english.txt" }
-- stylua: ignore end
