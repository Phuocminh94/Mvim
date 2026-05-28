local utils = require("minh.utils")

vim.keymap.set("n", "<leader>tc", utils.latex_toc, { desc = "Table of Content" })
vim.keymap.set("n", "<leader>wr", utils.hardwrap_tex, { desc = "Hard Wrap 80" })
