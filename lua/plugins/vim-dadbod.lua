-- https://www.reddit.com/r/neovim/comments/x2nc8o/cant_disable_sql_omni_complete_in_neovim_072/

if not pcall(require, "minh/local_config") then
	vim.g.dadbod_db = {}
end

return {
	"kristijanhusak/vim-dadbod-ui",
	dependencies = {
		{ "tpope/vim-dadbod", lazy = true },
		{ "kristijanhusak/vim-dadbod-completion", lazy = true, ft = { "sql", "mysql", "plsql" } },
    -- NOTE: config for sql(s) buffers are in ftplugins
	},
	cmd = {
		"DBUI",
		"DBUIToggle",
		"DBUIAddConnection",
		"DBUIFindBuffer",
	},
	init = function()
		vim.g.db_ui_use_nerd_fonts = 1     -- enable Nerd Fonts for UI
		vim.g.omni_sql_no_default_maps = 1 -- disable sqlcomplete mappings
		vim.g.db_ui_disable_info_notifications = 1
		vim.g.db_ui_execute_on_save = 0
		vim.g.dbs = vim.g.dadbod_db        -- set up database connection configurations (See below)
	end,
}

-- {
--   name = 'university',
--   url = 'postgres://minhbui:******@localhost:5432/university'
-- },
--   |       |        |        |         |       |
--   |       |        |        |         |       └── Database name = university
--   |       |        |        |         └──────── Port = 5432
--   |       |        |        └────────────────── Host = localhost
--   |       |        └─────────────────────────── Password = ******
--   |       └──────────────────────────────────── Username = postgres
--   └──────────────────────────────────────────── Protocol = postgres
