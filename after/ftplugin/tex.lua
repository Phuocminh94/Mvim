-- No longer sources markdown.lua: tex needs its own TOC and wrap rules.
-- Override width per file with a modeline:  % vim: set tw=100:
vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = "+1"

require("minh.wrap").attach()

vim.keymap.set("n", "<leader>tc", require("minh.utils").latex_toc, { buffer = true, desc = "LaTeX TOC" })
