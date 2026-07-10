return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim",
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "python" },
        automatic_installation = true,
        handlers = {},
      })

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = { expand = { "<CR>", "<2-LeftMouse>" }, open = "o" },
      })

      dap.listeners.before.attach.dapui_config = function() dapui.open() end
      dap.listeners.before.launch.dapui_config = function() dapui.open() end
      dap.listeners.before.event_terminated.dapui_config = function() dapui.close() end
      dap.listeners.before.event_exited.dapui_config = function() dapui.close() end

      local keymap = vim.keymap.set
      keymap("n", "<leader>db", dap.toggle_breakpoint, { desc = "DAP: Toggle Breakpoint" })
      keymap("n", "<leader>dc", dap.continue, { desc = "DAP: Continue / Start" })
      keymap("n", "<leader>di", dap.step_into, { desc = "DAP: Step Into" })
      keymap("n", "<leader>do", dap.step_over, { desc = "DAP: Step Over" })
      keymap("n", "<leader>du", dap.step_out, { desc = "DAP: Step Out" })
      keymap("n", "<leader>dr", dap.repl.open, { desc = "DAP: Open REPL" })
      keymap("n", "<leader>dt", dapui.toggle, { desc = "DAP: Toggle UI" })
      keymap("n", "<leader>dx", dap.terminate, { desc = "DAP: Terminate Session" })

      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "▶️", texthl = "", linehl = "Visual", numhl = "" })
    end,
  },
}
