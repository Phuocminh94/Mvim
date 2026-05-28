local utils = require("minh.utils")

vim.keymap.set("n", "<leader>wr", utils.hardwrap_md, { desc = "Hard Wrap 80" })
