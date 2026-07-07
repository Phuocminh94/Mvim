local utils = require("minh.utils")

local filename = vim.fn.expand("%:t")
local is_ai_buff = filename:match("^%d%d%d%d") ~= nil

vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = (not is_ai_buff) and "80" or ""

--- ==================== KEYMAPS ====================

vim.keymap.set("n", "<leader>wr", function()
  local current_ft = vim.bo.filetype
  
  if current_ft == "tex" then
    utils.hardwrap_tex(80)
  else
    utils.hardwrap_md(80)
  end
end, { desc = "Hard Wrap 80" })

vim.keymap.set("n", "<leader>tc", function()
  local current_file = vim.fn.expand("%:t")
  local is_ai = current_file:match("^%d%d%d%d") ~= nil
  
  local toc_name = is_ai and "Chat History Outline" or "Table of Content"
  utils.markdown_toc(toc_name)
end, { desc = "Table of Content" })

--- ==================== PLUGINS ====================
require('img-clip').setup({
  default = {
    dir_path = vim.g.note_path .. 'assets/images',
    use_absolute_path = true
  }
})
