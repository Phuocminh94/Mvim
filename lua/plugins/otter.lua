local fts = { "markdown", "rmd", "quarto" }

--- Code chunks to give LSP features to: a fence with a language, ```python or ```{r}.
local function has_code_chunk(buf)
  for _, line in ipairs(vim.api.nvim_buf_get_lines(buf, 0, -1, false)) do
    if line:match("^%s*```+%s*{?%a") then
      return true
    end
  end
  return false
end

return {
  "jmbuhr/otter.nvim",
  ft = fts,
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "neovim/nvim-lspconfig",
  },
  opts = {
    buffers = {
      write_to_disk = false,
    },
  },
  config = function(_, opts)
    local otter = require("otter")
    otter.setup(opts)

    -- Once per buffer, and only when it has code: activating starts hidden
    -- buffers and LSP clients (basedpyright, lua_ls, R) for that file.
    local function activate(buf)
      if vim.b[buf].otter_activated or require("minh.utils").is_gp_chat(buf) or not has_code_chunk(buf) then
        return
      end
      vim.b[buf].otter_activated = true
      vim.api.nvim_buf_call(buf, function()
        otter.activate({ "python", "lua" }, true, true, nil)
      end)
    end

    vim.api.nvim_create_autocmd({ "FileType", "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("OtterAutostart", { clear = true }),
      pattern = fts,
      callback = function(args)
        activate(args.buf)
      end,
    })
    -- The buffer whose FileType loaded this plugin.
    if vim.tbl_contains(fts, vim.bo.filetype) then
      activate(vim.api.nvim_get_current_buf())
    end
  end,
}
