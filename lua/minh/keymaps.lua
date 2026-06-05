-- 1. Global Map Helper (Used for general mappings)
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
map("n", "<leader>nh", "<cmd>nohl<CR>", "Clear search highlights")

-- Better vertical navigation (moves visually through wrapped lines)
map("n", "j", "gj")
map("n", "k", "gk")

-- Join lines while keeping the cursor in place (by @ThePrimeagen)
map("n", "J", "mzJ`z")

-- Keep cursor centered when searching/scrolling (by @ThePrimeagen)
map("n", "n", "nzz")
map("n", "N", "Nzz")
map("n", "<C-d>", "<C-d>zzzv")
map("n", "<C-u>", "<C-u>zzzv")

-- Spell check autocorrect
map("i", "<C-z>", "<C-g>u<Esc>[s1z=`]a<C-g>u", "Auto-correct last typo")

-- Terminal Mode
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

-- Resize splits
map("n", "<C-w>k", "<cmd>resize -2<CR>", "Decrease height")
map("n", "<C-w>j", "<cmd>resize +2<CR>", "Increase height")
map("n", "<C-w>h", "<cmd>vertical resize -2<CR>", "Decrease width")
map("n", "<C-w>l", "<cmd>vertical resize +2<CR>", "Increase width")

-- Tab management
map("n", "<leader>tn", "<cmd>tabnew<CR>", "Open new tab")
map("n", "<leader>tx", "<cmd>tabclose<CR>", "Close tab")
map("n", "<leader>tf", "<cmd>tabnew %<CR>", "Move buffer to tab")

-------------------------------------------------------------------------------
-- PLUGINS & PICKERS
-------------------------------------------------------------------------------
-- NERDTree
map("n", "<leader>e", "<cmd>Neotree toggle<CR>", "Toggle File Explorer")

-- Quickfix list
map("n", "]q", "<cmd>cnext<CR>", "Next quickfix item")
map("n", "[q", "<cmd>cprev<CR>", "Prev quickfix item")
map("n", "<leader>gg", ":copen | :silent :grep ", "Vimgrep")

-- EasyAlign / Sort
map({ "n", "x" }, "ga", "<Plug>(EasyAlign)", "EasyAlign")
map("v", "<leader>s", ":sort /^\\s*/<CR>", "Sort lines")

-- Utilities
map("n", "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", "Toggle Markdown Preview")
map({ "n", "t" }, "<A-/>", function() -- <C-/> conflicts with Tmux
	local opts = vim.fn.has("win32") == 1 and { cmd = "powershell" } or {}
	require("minh.terminal").toggle(nil, opts)
end, "Toggle Floatterm")
map("n", "<A-c>", "<cmd>ColorizerToggle<CR>", "Toggle Colorizer")
map("n", "<leader>p", "<cmd>PasteImage<CR>", "Paste Image (img-clip)")

-- Telescope
local ivy_config = {
	layout_config = { preview_width = 0.6 },
}

map("n", "<leader>ff", function()
	require("telescope.builtin").find_files(require("telescope.themes").get_ivy(ivy_config), "Find Files")
end)

map("n", "<leader>fo", function()
	require("telescope.builtin").oldfiles(require("telescope.themes").get_cursor({ previewer = false }))
end, "Recent Files")

map("n", "<leader>fg", function()
	require("telescope.builtin").live_grep(require("telescope.themes").get_ivy(ivy_config))
end, "Grep")

map("n", "<leader>fh", function()
	require("telescope.builtin").help_tags(require("telescope.themes").get_ivy(ivy_config))
end)

map("n", "<leader>fk", function()
	require("telescope.builtin").keymaps(require("telescope.themes").get_ivy(ivy_config))
end)

map("n", "<leader>fb", function()
	require("telescope.builtin").buffers(require("telescope.themes").get_cursor({ previewer = false }))
end)

map("n", "<leader>fc", function()
	local theme = require("telescope.themes").get_ivy(vim.tbl_deep_extend("force", ivy_config, {
		cwd = vim.fn.stdpath("config"),
	}))
	require("telescope.builtin").find_files(theme)
end, "Find Configs")

map("n", "<leader>fp", function()
	local theme = require("telescope.themes").get_dropdown()
	require("telescope").load_extension("projects")
	require("telescope").extensions.projects.projects(theme)
end, "Find projects")

map("n", "<leader>fn", function()
  require("telescope.builtin").find_files({cwd=vim.g.note_path})
end, "Find mNote")



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
		lsp_map("n", "gd", vim.lsp.buf.definition, "Goto Definition")
		lsp_map("n", "gD", vim.lsp.buf.declaration, "Goto Declaration")
		lsp_map("n", "gi", vim.lsp.buf.implementation, "Goto Implementation")
		lsp_map("n", "gr", vim.lsp.buf.references, "Find references")
		lsp_map("n", "gy", vim.lsp.buf.type_definition, "Type Definition")

		-- Formatting
		lsp_map({ "n", "v" }, "<leader>fm", function()
			require("conform").format({ lsp_fallback = true, async = false })
		end, "Format file/buffer")
	end,
})

-- Toggle diagnostic signs
local signs_enabled = true
map("n", "<leader>ds", function()
	local is_enabled = vim.diagnostic.is_enabled()
	vim.diagnostic.enable(not is_enabled)
	print("Diagnostic signs: " .. (is_enabled and "ON" or "OFF"))
end, "Toggle diagnostic signs")

-------------------------------------------------------------------------------
-- SNIPPETS & GIT
-------------------------------------------------------------------------------
map("i", "<C-s>", function()
	require("luasnip").expand()
end, "Expand snippet")

-- Gitsigns
map("n", "]h", function()
	require("gitsigns").next_hunk()
end, "Next git hunk")
map("n", "[h", function()
	require("gitsigns").prev_hunk()
end, "Prev git hunk")
map("n", "<leader>hr", function()
	require("gitsigns").reset_hunk()
end, "Reset git hunk")
map("n", "<leader>hp", function()
	require("gitsigns").preview_hunk()
end, "Preview git hunk")
map("n", "<leader>lg", function()
	if vim.fn.executable("lazygit") == 1 then
		local opts = {
			x = 0.5,
			y = 0.5,
			width = math.floor(0.8 * vim.o.columns),
			height = math.floor(0.8 * vim.o.lines),
			cmd = "lazygit",
		}
		local id = "lazygit"

		require("minh.terminal").toggle(id, opts)
		local current_buf = vim.api.nvim_get_current_buf()

		-- Create a one-shot autocmd to clean up this specific buffer on exit
		vim.api.nvim_create_autocmd("TermClose", {
			buffer = current_buf,   -- Only trigger for this specific terminal buffer
			once = true,            -- Run once and self-destruct to prevent memory leaks
			callback = function()
				-- Force wipe out the buffer once the process (lazygit) exits
				vim.cmd("bdelete!")
			end,
		})
	else
		vim.notify("'lazygit' not yet installed!", vim.log.levels.WARN)
	end
end, "Lazygit")
