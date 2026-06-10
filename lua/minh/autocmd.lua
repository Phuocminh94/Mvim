-- AUTOCMDS (Automation & Event Hooks)
-- Reference: https://github.com/hieulw/nvimrc/blob/lua-config/lua/hieulw/autocmds.lua

local custom = vim.api.nvim_create_augroup("MyAutocmd", { clear = true })
local autocmd = vim.api.nvim_create_autocmd

-- 1. Highlight on yank
autocmd("TextYankPost", {
	desc = "highlight yanked text",
	group = custom,
	callback = function()
		vim.highlight.on_yank({ higroup = "Visual", timeout = 200 })
	end,
})

-- 2. Quick escape for non-critical windows
autocmd("FileType", {
	desc = "quick escape with q",
	group = custom,
	pattern = { "checkhealth", "help", "lspinfo", "man", "qf", "git", "lazygit", "spectre_panel" },
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
		vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

-- 3. Auto-resize splits
autocmd("VimResized", {
	desc = "resize splits if window got resized",
	group = custom,
	callback = function()
		local current_tab = vim.fn.tabpagenr()
		vim.cmd("tabdo wincmd =")
		vim.cmd("tabnext " .. current_tab)
	end,
})

-- 4. Search highlighting management
autocmd("CmdlineEnter", {
	desc = "enable hlsearch when entering cmdline",
	group = custom,
	pattern = { "/", "?" },
	callback = function()
		vim.opt.hlsearch = true
	end,
})

autocmd("CmdlineLeave", {
	desc = "disable hlsearch when leaving cmdline",
	group = custom,
	pattern = { "/", "?" },
	callback = function()
		vim.opt.hlsearch = false
	end,
})

-- 5. Text file improvements
autocmd("FileType", {
	desc = "wrap and check for spell in text filetypes",
	group = custom,
	pattern = { "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.wrap = true
		vim.opt_local.spell = true
	end,
})

-- 6. Avoid auto-commenting new lines
autocmd("BufWinEnter", {
	desc = "avoid auto insert comment on newline",
	group = custom,
	callback = function()
		vim.opt.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- 7. Executable Path Detection (Generic)
local set_exe_path = function(ft, exe_name, global_var)
	local path = vim.fn.exepath(exe_name)
	if path ~= "" then
		vim.g[global_var] = path
	else
		vim.notify(exe_name .. " not found in PATH", vim.log.levels.WARN)
	end
end

autocmd("FileType", {
	pattern = "python",
	group = custom,
	callback = function()
		set_exe_path("python", "python", "py_path")
	end,
})

autocmd("FileType", {
	pattern = "r",
	group = custom,
	callback = function()
		set_exe_path("r", "R", "r_path")
	end,
})

-- 8. Hide the statusline when entering the dashboard buffer
local dashboard_status_group = vim.api.nvim_create_augroup("HideStatuslineOnDashboard", { clear = true })

vim.api.nvim_create_autocmd({ "FileType", "BufEnter" }, {
	pattern = "dashboard",
	group = dashboard_status_group,
	callback = function()
		vim.opt.laststatus = 0
	end,
})

vim.api.nvim_create_autocmd("BufLeave", {
	pattern = "*",
	group = dashboard_status_group,
	callback = function()
		if vim.bo.filetype == "dashboard" and vim.bo.filetype ~= "TelescopePrompt" then
			vim.opt.laststatus = 3
		end
	end,
})

-- 9. Telescope: Hide statusline if called from Dashboard
vim.api.nvim_create_autocmd("FileType", {
	pattern = "TelescopePrompt",
	group = dashboard_status_group,
	callback = function()
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_get_option_value("filetype", { buf = bufnr }) == "dashboard" then
				vim.opt.laststatus = 0
				break
			end
		end
	end,
})

-- 10. Snacks.indent
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "dashboard", "markdown", "txt", "dbout", "sql", "plsql", "mysql", "qmd", "rmd"}, 
  callback = function()
    vim.b.snacks_indent = false
  end,
})

-- 11. Exclude google drive's item from old files
vim.api.nvim_create_autocmd("BufReadPre", {
  callback = function()
    local path = vim.api.nvim_buf_get_name(0)
    if path:find("^/home/mbp/GoogleDrive/") then
      vim.opt_local.shadafile = "NONE"
    end
  end,
})
