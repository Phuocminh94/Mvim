-- My Essential Neovim Options --

-- Globals
vim.g.note_path = ""
vim.g.loaded_netrw = 1              -- Disable netrw at the very start
vim.g.loaded_netrwPlugin = 1

local opt = vim.opt
-- General UI & Feedback
opt.number         = true           -- Show line numbers
opt.relativenumber = true           -- Use relative numbers (essential for jumping)
opt.cursorline     = true           -- Highlight the current line
opt.cursorlineopt  = "number"       -- Only highlight the number, not the whole line (cleaner)
opt.termguicolors  = true           -- True color support (required for modern themes)
opt.signcolumn     = "yes"          -- Always show signcolumn (stops text "jumping" on errors)
opt.colorcolumn    = "80"           -- Vertical line at 80 chars
opt.fillchars      = { eob = " " }  -- Hide the '~' on empty lines at end of buffer
opt.mouse          = "a"            -- Enable mouse support

-- Search Settings
opt.ignorecase     = true           -- Case insensitive search...
opt.smartcase      = true           -- ...unless capital letters are used
opt.grepprg        = "rg --vimgrep --no-heading --smart-case" -- Use Ripgrep for searching

-- Tabs & Indentation (The 2-space standard)
opt.tabstop        = 2 
opt.shiftwidth     = 2 
opt.expandtab      = true           -- Use spaces instead of tabs
opt.autoindent     = true 
opt.textwidth      = 80             -- Wrap text at 80 characters
opt.wrap           = false          -- Don't wrap long lines visually

-- System Integration
opt.clipboard:append("unnamedplus") -- Sync with system clipboard
opt.swapfile       = false          -- Don't create annoying .swp files
opt.splitright     = true           -- Vertical splits go to the right
opt.splitbelow     = true           -- Horizontal splits go to the bottom
opt.backspace      = "indent,eol,start" -- Logical backspace behavior

-- Language & Dict
opt.spell          = true
opt.dictionary     = { "~/.config/nvim/dict/english.txt" }
