-- https://www.reddit.com/r/neovim/comments/x2nc8o/cant_disable_sql_omni_complete_in_neovim_072/

return {
    'kristijanhusak/vim-dadbod-ui',
    dependencies = {
        { 'tpope/vim-dadbod',                     lazy = true },
        { 'kristijanhusak/vim-dadbod-completion', ft = { 'sql', 'mysql' }, lazy = true }, -- Optional
    },
    cmd = {
        'DBUI',
        'DBUIToggle',
        'DBUIAddConnection',
        'DBUIFindBuffer',
    },
    init = function()
        vim.g.db_ui_use_nerd_fonts = 1 -- enable Nerd Fonts for UI
        vim.g.omni_sql_no_default_maps = 1 -- disable sqlcomplete mappings 
        vim.g.db_ui_disable_info_notifications = 1
        vim.g.db_ui_execute_on_save = 0
        vim.g.dbs = { -- Set up database connection configurations
            {
                name = 'university',
                url = 'postgres://minhbui:******@localhost:5432/university'
            },

            {
                name = '_university',
                url = 'postgres://minhbui:******@localhost:5432/_university'
            },
        }
    end
}

-- postgres://postgres:******@localhost:5432/university
-- |       |        |        |         |       |
-- |       |        |        |         |       └── Database name = university
-- |       |        |        |         └──────── Port = 5432
-- |       |        |        └────────────────── Host = localhost
-- |       |        └─────────────────────────── Password = ******
-- |       └──────────────────────────────────── Username = postgres
-- └──────────────────────────────────────────── Protocol = postgres
