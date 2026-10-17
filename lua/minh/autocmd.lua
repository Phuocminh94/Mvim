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
	pattern = { "checkhealth", "help", "fugitive", "lspinfo", "man", "qf", "git", "lazygit", "spectre_panel" },
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
		-- opt_local: only this buffer (vim.opt would also change the global value)
		vim.opt_local.formatoptions:remove({ "c", "r", "o" })
	end,
})

-- 7. Executable Path Detection (Generic)
-- Resolve once per session; try each candidate name in order.
local set_exe_path = function(global_var, candidates)
	if vim.g[global_var] then
		return
	end
	for _, exe in ipairs(candidates) do
		local path = vim.fn.exepath(exe)
		if path ~= "" then
			vim.g[global_var] = path
			return
		end
	end
	vim.notify(table.concat(candidates, "/") .. " not found in PATH", vim.log.levels.WARN)
end

autocmd("FileType", {
	pattern = "python",
	group = custom,
	callback = function()
		set_exe_path("py_path", { "python3", "python" })
	end,
})

autocmd("FileType", {
	pattern = "r",
	group = custom,
	callback = function()
		set_exe_path("r_path", { "R" })
	end,
})

-- 8. Hide the statusline on the dashboard, restore it when leaving
autocmd({ "FileType", "BufEnter" }, {
	pattern = "dashboard",
	group = custom,
	callback = function()
		vim.opt.laststatus = 0
	end,
})

autocmd("BufLeave", {
	group = custom,
	callback = function()
		if vim.bo.filetype == "dashboard" then
			vim.opt.laststatus = 3
		end
	end,
})

-- 10. Snacks.indent
autocmd("FileType", {
	group = custom,
	pattern = { "dashboard", "markdown", "txt", "dbout", "sql", "plsql", "mysql", "qmd", "rmd" },
	callback = function()
		vim.b.snacks_indent = false
	end,
})

-- 11. Keep Google Drive files out of oldfiles / recent files.
-- The shada "r" flag marks a path as removable media: no marks or oldfiles
-- are stored for it. (Setting 'shadafile' per buffer did not work: it is a
-- global option, so opening one gdrive file disabled shada for the session.)
vim.opt.shada:append("r" .. vim.fn.expand("~/Cloud/gdrive/"))

-- 12. Force UI redraw on command-line changes to fix stuck LSP/search artifacts (noice.nvim)
local redraw_group = vim.api.nvim_create_augroup("update_search_redraw", { clear = true })
vim.api.nvim_create_autocmd("CmdlineChanged", {
	group = redraw_group,
	desc = "Fix command-line rendering artifacts by scheduling a redraw",
	callback = function()
		vim.schedule(vim.cmd.redraw)
	end,
})

-- 13. Remove items from quickfix / location list with dd (keeps the title)
autocmd("FileType", {
  group = custom,
  pattern = "qf",
  callback = function(ev)
    vim.keymap.set("n", "dd", function()
      local is_loc = vim.fn.win_gettype() == "loclist"
      local what = { items = 0, title = 0 }
      local list = is_loc and vim.fn.getloclist(0, what) or vim.fn.getqflist(what)
      local lnum = vim.fn.line(".")
      if lnum > #list.items then
        return
      end
      table.remove(list.items, lnum)
      local new = { items = list.items, title = list.title }
      if is_loc then
        vim.fn.setloclist(0, {}, "r", new)
      else
        vim.fn.setqflist({}, "r", new)
      end
      vim.api.nvim_win_set_cursor(0, { math.max(1, math.min(lnum, #list.items)), 0 })
    end, { buffer = ev.buf, silent = true, desc = "Remove item" })
  end,
})

-- 14. Auto sync quickfix item based on cursor position
autocmd("CursorMoved", {
  group = custom,
  callback = function()
    -- Cheap check first: winid of the quickfix window in this tab (0 = none)
    local qf_win = vim.fn.getqflist({ winid = 0 }).winid
    if qf_win == 0 or qf_win == vim.api.nvim_get_current_win() then
      return
    end

    local bufnr = vim.api.nvim_get_current_buf()
    local lnum = vim.api.nvim_win_get_cursor(0)[1]

    -- Closest item at or above the cursor in this buffer. The list is not
    -- assumed to be sorted, so scan all of it.
    local best_idx, best_diff = nil, math.huge
    for i, item in ipairs(vim.fn.getqflist()) do
      if item.bufnr == bufnr and item.lnum <= lnum and lnum - item.lnum < best_diff then
        best_idx, best_diff = i, lnum - item.lnum
      end
    end

    -- Only touch the list when the index actually changes
    if best_idx and vim.fn.getqflist({ idx = 0 }).idx ~= best_idx then
      pcall(vim.api.nvim_win_set_cursor, qf_win, { best_idx, 0 })
      -- Sync the list's current index so :cnext / :cprev continue from here
      pcall(vim.fn.setqflist, {}, "r", { idx = best_idx })
    end
  end,
})

-- 15. Use treesitter for highlighting, keep VimTeX syntax (needed by its motions)
autocmd("FileType", {
  group = custom,
  pattern = "tex",
  callback = function(args)
    vim.treesitter.start(args.buf, "latex")
    vim.bo[args.buf].syntax = "ON" -- Re-enable VimTeX syntax
  end,
})
