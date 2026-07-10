return {
  'jmbuhr/otter.nvim',
  dependencies = {
    'nvim-treesitter/nvim-treesitter',
    'neovim/nvim-lspconfig',
  },
  opts = {
    buffers = {
      languages = { "python", "lua", "r" },
      write_to_disk = false,
    }
  },
  config = function(_, opts)
    local otter = require('otter')
    otter.setup(opts)

    local otter_group = vim.api.nvim_create_augroup("OtterAutostart", { clear = true })
    vim.api.nvim_create_autocmd({ "BufEnter", "BufReadPost" }, {
      group = otter_group,
      pattern = { "*.md", "*.Rmd", "*.qmd" }, 
      callback = function()
        otter.activate({ "python", "lua" }, true, true, nil)
      end,
    })
  end,
}
