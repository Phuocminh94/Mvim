return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "mason-org/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
    },
    -- Load DAP (and dap-ui, nio) on the first debug key instead of at startup.
    keys = {
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        desc = "DAP: Toggle Breakpoint",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        desc = "DAP: Continue / Start",
      },
      {
        "<leader>di",
        function()
          require("dap").step_into()
        end,
        desc = "DAP: Step Into",
      },
      {
        "<leader>do",
        function()
          require("dap").step_over()
        end,
        desc = "DAP: Step Over",
      },
      {
        "<leader>du",
        function()
          require("dap").step_out()
        end,
        desc = "DAP: Step Out",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.open()
        end,
        desc = "DAP: Open REPL",
      },
      {
        "<leader>dt",
        function()
          require("dapui").toggle()
        end,
        desc = "DAP: Toggle UI",
      },
      {
        "<leader>dx",
        function()
          require("dap").terminate()
        end,
        desc = "DAP: Terminate Session",
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
        mappings = { expand = { "<CR>", "<2-LeftMouse>" }, open = "o" },
      })

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
