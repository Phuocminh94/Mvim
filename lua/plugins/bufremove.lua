return {
  'echasnovski/mini.bufremove',
  version = '*',
  config = function()
    require('mini.bufremove').setup()
    vim.keymap.set('n', '<Leader>x', function()
      require('mini.bufremove').delete(0, false)
    end)
  end
}
