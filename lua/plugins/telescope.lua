return {
  'nvim-telescope/telescope.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },

  -- 1. Use a function for 'opts' to safely require actions
  opts = function()
    local actions = require("telescope.actions")

    return {
      defaults = {
        prompt_prefix = " 🔍 ",
        selection_caret = "  ",
        entry_prefix = "  ",
        selection_strategy = "reset",
        sorting_strategy = "ascending",
        layout_config = {
          horizontal = {
            preview_width = 0.55,
            results_width = 0.8,
          },
        },
        borderchars = {
          prompt =  { " ", " ", "─", "│", "│", " ", "─", "└" },
          results = { "─", " ", " ", "│", "┌", "─", " ", "│" },
          preview = { "─", "│", "─", "│", "┬", "┐", "┘", "┴" },
        },
        mappings = {
          n = { ["q"] = actions.close },
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<C-n>"] = actions.cycle_history_next,
            ["<C-p>"] = actions.cycle_history_prev,
          },
        },
      },
    }
  end,

  -- 2. Config handles initialization and custom functions
  config = function(_, opts)
    local telescope = require("telescope")
    local pickers = require("telescope.pickers")
    local finders = require("telescope.finders")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")
    local conf = require("telescope.config").values

    -- Initialize Telescope with our opts
    telescope.setup(opts)

    -- Define and attach the custom TOC picker
    telescope.show_toc_picker = function(results, title)
      pickers.new({}, {
        prompt_title = title,
        layout_config = { width = 0.5, height = 0.4 },
        sorter = conf.generic_sorter({}),
        borderchars = {
          prompt =  { " ", "│", "─", "│", "│", "│", "┘", "└" },
          results = { "─", "│", " ", "│", "┌", "┐", "│", "│" },
        },

        finder = finders.new_table {
          results = results,
          entry_maker = function(entry)
            return {
              value = entry,
              display = entry.text,
              ordinal = entry.text,
              lnum = entry.line,
            }
          end
        },

        attach_mappings = function(prompt_bufnr)
          actions.select_default:replace(function()
            local selection = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if selection then
              vim.api.nvim_win_set_cursor(0, { selection.lnum, 0 })
            end
          end)
          return true
        end,
      }):find()
    end
  end,
}
