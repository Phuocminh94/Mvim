return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
      {
        "theHamsta/nvim-dap-virtual-text",
        -- Pinned to a commit that was read through; review the diff before moving it.
        commit = "fbdb48c2ed45f4a8293d0d483f7730d24467ccb6",
      },
    },
    -- Load DAP (and dap-ui, nio) on the first debug key instead of at startup.
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "DAP: toggle breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP: continue / start",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "DAP: step into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "DAP: step over",
      },
      {
        "<leader>du",
        function()
          require("dap").step_out()
        end,
        desc = "DAP: step out",
      },
      {
        "<leader>ds",
        function()
          require("minh.dap").step_mode()
        end,
        desc = "DAP: step mode (n i o c; other key exits)",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input({ prompt = "Breakpoint condition: " }, function(condition)
            if condition and condition ~= "" then
              require("dap").set_breakpoint(condition)
            end
          end)
        end,
        desc = "DAP: conditional breakpoint",
      },
      {
        "<leader>dC",
        function()
          require("dap").run_to_cursor()
        end,
        desc = "DAP: run to cursor",
      },
      {
        "<leader>dR",
        function()
          require("dap").restart()
        end,
        desc = "DAP: restart session",
      },
      {
        "<leader>dl",
        function()
          require("dap").run_last()
        end,
        desc = "DAP: run last",
      },
      {
        "<leader>de",
        function()
          require("dapui").eval(nil, { enter = true })
        end,
        mode = { "n", "x" },
        desc = "DAP: eval expression under cursor / selection",
      },
      {
        "<leader>dw",
        function()
          require("minh.dap").watch()
        end,
        desc = "DAP: watch variable under cursor (any frame if in the debugged file)",
      },
      {
        "<leader>dr",
        function()
          require("minh.dap").focus_repl()
        end,
        desc = "DAP: go to REPL",
      },
      {
        "<leader>dt",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP: toggle UI",
      },
      {
        "<leader>dx",
        function()
          require("dap").terminate()
        end,
        desc = "DAP: terminate session",
      },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "python" },
        automatic_installation = true,
        handlers = {}, -- default adapter/configuration setup for each installed adapter
      })

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        -- In Stacks, `o` (open) selects a frame: the code view, Scopes and the REPL
        -- then use that frame's variables. <CR> only expands/collapses.
        mappings = { expand = { "<CR>", "<2-LeftMouse>" }, open = "o" },
        -- Breakpoints are already signs in the code, so no breakpoints pane: more
        -- room for variables. The console must stay: the Python launch configs use
        -- console = "integratedTerminal", and without this pane nvim-dap opens its
        -- own terminal split on every launch (a second pane under the REPL).
        layouts = {
          {
            position = "left",
            size = 0.35, -- of the editor width
            elements = {
              { id = "scopes", size = 0.6 },
              { id = "watches", size = 0.2 },
              { id = "stacks", size = 0.2 },
            },
          },
          {
            position = "bottom",
            size = 0.25,
            elements = { { id = "repl", size = 0.6 }, { id = "console", size = 0.4 } },
          },
        },
      })
      require("nvim-dap-virtual-text").setup({})

      -- Long values (Value(data=..., grad=...), lists) wrap instead of scrolling sideways.
      -- (dap-ui sets the filetype after the window opens, hence FileType too.)
      local function wrap_dap_windows(args)
        local ft = vim.bo[args.buf].filetype
        if ft == "dap-repl" or ft:match("^dapui_") then
          vim.schedule(function()
            for _, win in ipairs(vim.fn.win_findbuf(args.buf)) do
              vim.wo[win].wrap = true
              vim.wo[win].linebreak = true
            end
          end)
        end
      end
      -- dap-ui panes have fixed sizes, so when space runs short nvim squeezes one
      -- of them to a column or two and it stays that way: on a resize of the
      -- editor (herdr pane resize or zoom), and when a split opens or closes
      -- beside them (the Claude pane, <leader>ac). Re-apply the layout sizes after
      -- either (this runs after the global `wincmd =` in minh.autocmd).
      local resetting = false
      vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, {
        group = vim.api.nvim_create_augroup("minh.dap.ui_resize", { clear = true }),
        callback = function()
          if resetting then
            return
          end
          for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
            if vim.bo[vim.api.nvim_win_get_buf(win)].filetype:match("^dapui_") then
              resetting = true
              vim.schedule(function()
                pcall(dapui.open, { reset = true })
                resetting = false
              end)
              return
            end
          end
        end,
      })

      local group = vim.api.nvim_create_augroup("minh.dap.wrap", { clear = true })
      vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter" }, { group = group, callback = wrap_dap_windows })

      -- Open the UI when a session starts. It is not closed automatically on
      -- exit, so the output and the last variables stay readable; close with <leader>dt.
      dap.listeners.before.attach.dapui_config = dapui.open
      dap.listeners.before.launch.dapui_config = dapui.open

      -- Single-width signs: emoji such as 🔴 / ▶️ take two cells and shift the sign column.
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapStopped", { text = "→", texthl = "DiagnosticWarn", linehl = "Visual" })
    end,
  },
}
