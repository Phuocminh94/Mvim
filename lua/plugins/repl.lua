return {
    "Vigemus/iron.nvim",
    config = function()
        local iron = require("iron.core")
        local view = require("iron.view")

        iron.setup({
            -- Where the REPL opens and which command to use
            config = {
                repl_definition = {
                    python = { command = { "ipython", "--no-autoindent" } }, -- or { "python" }
                    sh     = { command = { "bash" } },
                    rmd    = { command = { "ipython", "--no-autoindent" } }, -- or { "python" }
                    R      = { command = { "Rscript" } }
                },
                repl_open_cmd = function(ft, cmd)
                  vim.cmd("botright vsplit")
                  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 3))  -- width in columns
                  local winnr = vim.api.nvim_get_current_win()

                  -- Customize window options
                  vim.wo[winnr].number = false
                  vim.wo[winnr].relativenumber = false
                  vim.wo[winnr].signcolumn = "no"

                  return winnr
                end
            },

            -- Keymaps
            keymaps = {
                toggle_repl       = "<space>rt", -- toggle REPL
                visual_send       = "<space>rv", -- visual selection send
                send_line         = "<space>rl",
                send_paragraph    = "<space>rp",
                send_until_cursor = "<space>ru",
                cr                = "<space>rn",
                interrupt         = "<space>ri<space>",
                exit              = "<space>rq",
                clear             = "<space>rc",
            },

            highlight = { italic = true },
            ignore_blank_lines = true,
        })

        -- Restart isn’t a key in iron’s keymaps;:
        vim.keymap.set("n", "<space>rr", "<cmd>IronRestart<cr>", { desc = "Iron: Restart REPL" })
        vim.keymap.set("n", "<space>rf", "<cmd>IronFocus<cr>", { desc = "Iron: Focus REPL" })
    end,
}
