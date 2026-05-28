return {
  "norcalli/nvim-colorizer.lua",
  config = function()
    require("colorizer").setup({
      "*", -- Enable colorizer for all filetypes
      css = { rgb_fn = true, hsl_fn = true }, -- Enable RGB and HSL functions for CSS
      html = { names = true }, -- Enable color names for HTML
    })
  end,
}
