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
map("n", "<leader>td", "<cmd>tabclose<CR>", "Close tab")
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

-------------------------------------------------------------------------------
-- SNACKS PICKER
-------------------------------------------------------------------------------
map("n", "<leader>ff", function() Snacks.picker.files({ layout = "sidebar" }) end, "Find Files")

map("n", "<leader>fo", function() Snacks.picker.recent({ layout = "vscode", preview = false }) end, "Recent Files")

map("n", "<leader>fg", function() Snacks.picker.grep(ivy_config) end, "Grep")

map("n", "<leader>fh", function() Snacks.picker.help({ layout = "ivy" }) end, "Help Tags")

map("n", "<leader>fk", function() Snacks.picker.keymaps({ layout = "ivy" }) end, "Keymaps")

map("n", "<leader>fb", function() Snacks.picker.buffers({layout="vscode", preview=false}) end, "Buffers")

map("n", "<leader>fc", function() Snacks.picker.files({ cwd = vim.fn.stdpath("config"), layout = "ivy", }) end, "Find Configs")

map("n", "<leader>fp", function() Snacks.picker.projects({layout="vscode", preview=false}) end, "Find Projects")

map("n", "<leader>fn", function() Snacks.picker.files({ cwd = vim.g.note_path }) end, "Find mNote")

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
		lsp_map("n", "gd", function() Snacks.picker.lsp_definitions() end, "Goto Definition")

		lsp_map("n", "gD", function() Snacks.picker.lsp_declarations() end, "Goto Declaration")

		lsp_map("n", "gi", function() Snacks.picker.lsp_implementations() end, "Goto Implementation")

		lsp_map("n", "gr", function() Snacks.picker.lsp_references() end, "Find references")

		lsp_map("n", "gy", function() Snacks.picker.lsp_type_definitions() end, "Type Definition")

		lsp_map("n", "gai", function() Snacks.picker.lsp_incoming_calls() end, "Calls Incoming")

		lsp_map("n", "gao", function() Snacks.picker.lsp_outgoing_calls() end, "Calls Outgoing")

		lsp_map("n", "<leader>ss", function() Snacks.picker.lsp_symbols() end, "LSP Symbols")
		lsp_map("n", "<leader>sd", function() Snacks.picker.diagnostics() end, "LSP Diagnostics")

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
-- GIT
-------------------------------------------------------------------------------

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
			buffer = current_buf, -- Only trigger for this specific terminal buffer
			once = true, -- Run once and self-destruct to prevent memory leaks
			callback = function()
				-- Force wipe out the buffer once the process (lazygit) exits
				vim.cmd("bdelete!")
			end,
		})
	else
		vim.notify("'lazygit' not yet installed!", vim.log.levels.WARN)
	end
end, "Lazygit")
