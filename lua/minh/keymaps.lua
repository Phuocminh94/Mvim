-- Global Map Helper (Used for general mappings)
local function map(mode, lhs, rhs, desc, opts)
  local options = { desc = desc, silent = true }
  if opts then
    options = vim.tbl_extend("force", options, opts)
  end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Disable Space bar default behavior
map("n", "<Space>", "<Nop>", "Ignore Space")

-------------------------------------------------------------------------------
-- GENERAL QoL
-------------------------------------------------------------------------------
map("i", "jk", "<Esc>", "Exit insert mode")
-- map("n", "<leader>nh", "<cmd>nohl<CR>", "Clear search highlights")
map("n", "<leader>nh", "<cmd>Noice dismiss<CR>", "Noice dismiss")

-- Move by screen line through wrapped text, but keep counts (5j, 10k) linewise
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", nil, { expr = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", nil, { expr = true })

-- Join lines while keeping the cursor in place (by @ThePrimeagen)
map("n", "J", "mzJ`z")

-- Keep cursor centered when searching/scrolling (by @ThePrimeagen)
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "<C-d>", "<C-d>zzzv")
map("n", "<C-u>", "<C-u>zzzv")

-- Spell check autocorrect
map("i", "<C-z>", "<C-g>u<Esc>[s1z=`]a<C-g>u", "Auto-correct last typo")

-- Terminal Mode (minh.terminal restores <Esc> for program terminals like lazygit)
map("t", "<Esc>", [[<C-\><C-n>]], "Exit terminal mode")

-- Change working directory to current file
map("n", "<leader>cd", function()
  local bufname = vim.api.nvim_buf_get_name(0)
  if bufname == "" then
    return
  end
  local dirname = vim.fs.dirname(bufname)
  if dirname and vim.fn.getcwd() ~= dirname then
    vim.fn.chdir(dirname)
    vim.notify("Changed directory to " .. dirname, vim.log.levels.INFO)
  end
end, "Change cwd to file's directory")

-------------------------------------------------------------------------------
-- WINDOW & TAB MANAGEMENT
-------------------------------------------------------------------------------
-- Navigate splits
map("n", "<C-h>", "<C-w>h", "Focus left split")
map("n", "<C-j>", "<C-w>j", "Focus below split")
map("n", "<C-k>", "<C-w>k", "Focus above split")
map("n", "<C-l>", "<C-w>l", "Focus right split")

-- Create splits
map("n", "<leader>sv", "<C-w>v", "Split vertically")
map("n", "<leader>sh", "<C-w>s", "Split horizontally")
map("n", "<leader>se", "<C-w>=", "Make splits equal")
map("n", "<leader>sx", "<cmd>close<CR>", "Close split")

-- Resize splits (<C-w>hjkl keep their default: move between windows)
map("n", "<C-Up>", "<cmd>resize -2<CR>", "Decrease height")
map("n", "<C-Down>", "<cmd>resize +2<CR>", "Increase height")
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Decrease width")
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase width")

-- Tab management
map("n", "<leader>tn", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>td", "<cmd>tabclose<CR>", "Close tab")
map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Move buffer to tab")
map("n", "<leader>tN", function()
  vim.ui.input({ prompt = "Enter directory: ", completion = "dir" }, function(path)
    if path and path ~= "" then
      vim.cmd("tabnew")
      vim.cmd("tcd " .. path)
    end
  end)
end, "Open new tab with specific CWD")

-------------------------------------------------------------------------------
-- PLUGINS & PICKERS
-------------------------------------------------------------------------------
-- Neo-tree
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", "Toggle File Explorer")

-- Quickfix list
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprev<CR>", "Prev quickfix item")

-- Sort (EasyAlign `ga` lives in plugins/vim-easy-align.lua)
map("x", "<leader>s", ":sort /^\\s*/<CR>", "Sort lines")

-- Utilities
map("n", "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", "Toggle Markdown Preview")
-- <C-/> conflicts with Tmux. A count picks the terminal number: 2<A-/>
map({ "n", "t" }, "<A-/>", function()
  local opts = vim.fn.has("win32") == 1 and { cmd = "powershell" } or {}
  require("minh.terminal").toggle(nil, opts)
end, "Toggle terminal")
map("n", "<leader>ft", function()
  require("minh.terminal").pick()
end, "Find terminals")
map("n", "<leader>p", "<cmd>PasteImage<CR>", "Paste Image (img-clip)")

-------------------------------------------------------------------------------
-- SNACKS PICKER
-------------------------------------------------------------------------------
map("n", "<leader>ff", function()
  Snacks.picker.files({ layout = "sidebar" })
end, "Find Files")

map("n", "<leader>fo", function()
  Snacks.picker.recent({ layout = "vscode", preview = false })
end, "Recent Files")

map("n", "<leader>fg", function()
  Snacks.picker.grep()
end, "Grep")

map("n", "<leader>fh", function()
  Snacks.picker.help({ layout = "ivy" })
end, "Help Tags")

map("n", "<leader>fk", function()
  Snacks.picker.keymaps({ layout = "ivy" })
end, "Keymaps")

map("n", "<leader>fb", function()
  Snacks.picker.buffers({ layout = "vscode", preview = false })
end, "Buffers")

map("n", "<leader>f/", function()
  Snacks.picker.lines()
end, "Grep Current Buffer")

map("n", "<leader>fc", function()
  Snacks.picker.files({ cwd = vim.fn.stdpath("config"), layout = "ivy" })
end, "Find Configs")

map("n", "<leader>fp", function()
  Snacks.picker.projects({ layout = "vscode", preview = false })
end, "Find Projects")

map("n", "<leader>fn", function()
  if vim.g.note_path == "" then
    vim.notify("Set vim.g.note_path in lua/minh/local_config.lua", vim.log.levels.WARN)
    return
  end
  Snacks.picker.files({ cwd = vim.g.note_path })
end, "Find Note")

map("n", "<leader>fN", function()
  Snacks.picker.notifications()
end, "Notification History")

map("n", "<leader>fs", function()
  vim.wo.spell = true
  local bufnr = vim.api.nvim_get_current_buf()
  local items = {}
  for lnum, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
    for _, r in ipairs(vim.spell.check(line)) do
      table.insert(items, {
        buf = bufnr,
        pos = { lnum, r[3] - 1 }, -- vim.spell.check returns col 1-based, picker uses 0-based
        text = r[1] .. " (" .. r[2] .. ")",
        word = r[1],
        kind = r[2],
      })
    end
  end
  Snacks.picker.pick({
    title = "Spelling errors",
    items = items,
    format = function(item)
      return {
        { string.format("%4d:%-3d ", item.pos[1], item.pos[2] + 1), "SnacksPickerIdx" },
        { item.word, "DiagnosticError" },
        { "  " .. item.kind, "Comment" },
      }
    end,
    -- preview = "none",
  })
end, "Spelling errors (buffer)")

-------------------------------------------------------------------------------
-- LSP & DIAGNOSTICS (Autocmd controlled)
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspConfig", { clear = true }),
  callback = function(ev)
    -- Buffer-local helper for LSP keys
    local function lsp_map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, silent = true, desc = desc })
    end

    -- Diagnostics & Basic LSP
    lsp_map("n", "gl", vim.diagnostic.open_float, "Line diagnostics")
    lsp_map("n", "K", vim.lsp.buf.hover, "Hover docs")
    lsp_map("n", "gs", vim.lsp.buf.signature_help, "Signature help")
    lsp_map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    lsp_map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")

    -- Navigation via Native LSP (Standard Jumps)
    lsp_map("n", "gd", function()
      Snacks.picker.lsp_definitions()
    end, "Goto Definition")

    lsp_map("n", "gD", function()
      Snacks.picker.lsp_declarations()
    end, "Goto Declaration")

    lsp_map("n", "gri", function()
      Snacks.picker.lsp_implementations()
    end, "Goto Implementation")

    -- nowait: Neovim 0.11+ has global gra/grn/grr/gri..., which would make a
    -- plain `gr` wait for 'timeoutlen' before firing.
    vim.keymap.set("n", "gr", function()
      Snacks.picker.lsp_references()
    end, { buffer = ev.buf, silent = true, nowait = true, desc = "Find references" })

    lsp_map("n", "gy", function()
      Snacks.picker.lsp_type_definitions()
    end, "Type Definition")

    -- Not gci/gco: `gc` is the comment operator (gcip) and gco adds a comment below.
    lsp_map("n", "<leader>ci", function()
      Snacks.picker.lsp_incoming_calls()
    end, "Calls Incoming")

    lsp_map("n", "<leader>co", function()
      Snacks.picker.lsp_outgoing_calls()
    end, "Calls Outgoing")

    lsp_map("n", "<leader>ss", function()
      Snacks.picker.lsp_symbols()
    end, "LSP Symbols")
    lsp_map("n", "<leader>sd", function()
      Snacks.picker.diagnostics()
    end, "LSP Diagnostics")
  end,
})

-- Formatting is global: conform also runs formatters for buffers without an LSP
-- (see formatters_by_ft in plugins/conform.lua).
map({ "n", "x" }, "<leader>fm", function()
  require("conform").format({ lsp_format = "fallback", async = false })
end, "Format file/selection")

-- Toggle diagnostics (signs, virtual text and underline together)
map("n", "<leader>ds", function()
  local enabled = not vim.diagnostic.is_enabled()
  vim.diagnostic.enable(enabled)
  vim.notify("Diagnostics: " .. (enabled and "ON" or "OFF"), vim.log.levels.INFO)
end, "Toggle diagnostics")

-------------------------------------------------------------------------------
-- GIT
-------------------------------------------------------------------------------

-- Gitsigns
map("n", "]h", function()
  require("gitsigns").nav_hunk("next")
end, "Next git hunk")
map("n", "[h", function()
  require("gitsigns").nav_hunk("prev")
end, "Prev git hunk")
map("n", "<leader>hr", function()
  require("gitsigns").reset_hunk()
end, "Reset git hunk")
map("n", "<leader>hp", function()
  require("gitsigns").preview_hunk()
end, "Preview git hunk")
map("n", "<leader>hs", function()
  require("gitsigns").stage_hunk()
end, "Stage git hunk")
map("n", "<leader>hq", ":Gitsigns setqflist<CR>", "Quickfix list hunk (buffer)")
map("n", "<leader>hQ", ":Gitsigns setqflist all<CR>", "Quickfix list hunk (projects)")

-- Lazygit: one instance per cwd; minh.terminal closes it when lazygit exits
map("n", "<leader>lg", function()
  if vim.fn.executable("lazygit") ~= 1 then
    vim.notify("'lazygit' not yet installed!", vim.log.levels.WARN)
    return
  end
  require("minh.terminal").toggle("lazygit:" .. vim.fn.getcwd(), {
    cmd = "lazygit",
    layout = "center",
    width = 0.9,
    height = 0.9,
  })
end, "Lazygit")
