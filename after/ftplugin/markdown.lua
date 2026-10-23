local utils = require("minh.utils")

local is_ai_buf = utils.is_gp_chat(0)

-- Default width; override per file with a modeline
--   <!-- vim: set tw=100: -->
-- or temporarily with :setlocal tw=100
vim.opt_local.textwidth = 80
-- "+1" = column right after textwidth, so it follows when tw changes.
vim.opt_local.colorcolumn = is_ai_buf and "" or "+1"

-- gq / gqip / <leader>wr / <leader>wR / :Wrap
require("minh.wrap").attach()

vim.keymap.set("n", "<leader>tc", function()
  if is_ai_buf then
    utils.gp_chat_toc("Chat History Outline")
  else
    utils.markdown_toc("Table of Content")
  end
end, { buffer = true, desc = "Table of Content" })
