return {
  "stevearc/conform.nvim",
  -- Loaded on first use: <leader>fm in keymaps.lua requires "conform".
  -- (No format-on-save here, so there is no reason to load it on BufReadPre.)
  cmd = "ConformInfo",
  opts = {
    -- Use the LSP formatter when no formatter is listed for the filetype
    -- (e.g. lua_ls for Lua), so the keymap does not need to pass it.
    default_format_opts = { lsp_format = "fallback" },
    formatters_by_ft = {
      tex = { "latexindent" },
      -- Formatters run in order: sort imports first, then let black have the
      -- final say. black then isort can leave a file black would change again.
      python = { "isort", "black" },
      r = { "air" },
    },
    formatters = {
      -- Make isort wrap imports the way black does.
      isort = { prepend_args = { "--profile", "black" } },
    },
  },
}
