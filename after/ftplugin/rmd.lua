local utils = require("minh.utils")

vim.keymap.set("n", "<leader>wr", utils.hardwrap_md, { desc = "Hard Wrap 80" })
vim.keymap.set("n", "<leader>tc", utils.markdown_toc, { desc = "TOC" })
