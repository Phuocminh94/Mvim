return {
  "Vigemus/iron.nvim",
  -- Load on first use instead of at startup. Keys without a right-hand side
  -- only trigger the load; iron's own mappings (created in setup) then run.
  cmd = { "IronRepl", "IronRestart", "IronFocus", "IronHide" },
  keys = {
    { "<leader>rt", desc = "Iron: Toggle REPL" },
    { "<leader><leader>", mode = { "n", "x" }, desc = "Iron: Send line / selection" },
    { "<leader>rp", desc = "Iron: Send paragraph" },
    { "<leader>ru", desc = "Iron: Send until cursor" },
    { "<leader>rb", desc = "Iron: Send # %% cell and move to next" },
    { "<leader>rr", "<cmd>IronRestart<cr>", desc = "Iron: Restart REPL" },
    { "<leader>rf", "<cmd>IronFocus<cr>", desc = "Iron: Focus REPL" },
    {
      "<leader>rl",
      function()
        require("iron.core").send_line()
      end,
      desc = "Iron: Send line (additional)",
    },
    {
      "<leader>rv",
      function()
        require("iron.core").visual_send()
      end,
      mode = "x",
      desc = "Iron: Send selection (additional)",
    },
  },
  config = function()
    local iron = require("iron.core")
    local common = require("iron.fts.common")

    -- iron's built-in ipython definition uses bracketed paste: multi-line
    -- blocks (functions, loops, blank lines inside them) arrive as one paste.
    -- A custom definition must keep `format`, otherwise lines are typed one by one.
    local ipython = {
      command = { "ipython", "--no-autoindent" },
      format = common.bracketed_paste_python,
      block_dividers = { "# %%", "#%%" }, -- cells for <leader>rb
    }

    iron.setup({
      config = {
        -- Keys are filetypes, so R files use "r" (lowercase).
        repl_definition = {
          python = ipython,
          rmd = ipython, -- Rmd with Python chunks; use the `r` entry if your chunks are R
          markdown = ipython, -- Jupytext / notes with Python fences
          sh = { command = { "bash" } },
          -- Interactive R (not Rscript, which runs a script and exits).
          r = { command = { "R", "--no-save" }, format = common.bracketed_paste },
          sql = {
            command = function()
              -- Set vim.g.psql_container in lua/minh/local_config.lua
              local container = vim.g.psql_container or "docker-db-mgmt-postgres-1"
              local db = vim.fn.input("Database name: ", "")
              return { "docker", "exec", "-it", container, "psql", "-U", "postgres", "-d", db }
            end,
          },
        },
        -- Right split, one third of the editor width (computed when it opens)
        repl_open_cmd = function()
          vim.cmd("botright vsplit")
          vim.cmd("vertical resize " .. math.floor(vim.o.columns / 3))
          local win = vim.api.nvim_get_current_win()
          vim.wo[win].number = false
          vim.wo[win].relativenumber = false
          vim.wo[win].signcolumn = "no"
          return win
        end,
      },

      keymaps = {
        toggle_repl = "<leader>rt",
        visual_send = "<leader><leader>",
        send_line = "<leader><leader>",
        send_paragraph = "<leader>rp",
        send_until_cursor = "<leader>ru",
        send_code_block_and_move = "<leader>rb",
        cr = "<leader><CR>",
        interrupt = "<leader>ri<leader>",
        exit = "<leader>rq",
        clear = "<leader>rc",
      },

      highlight = { italic = true },
      ignore_blank_lines = true,
    })
  end,
}
