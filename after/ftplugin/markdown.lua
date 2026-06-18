local utils = require("minh.utils")

vim.keymap.set("n", "<leader>wr", utils.hardwrap_md, { desc = "Hard Wrap 80" })
vim.keymap.set("n", "<leader>tc", utils.markdown_toc, { desc = "Table of Content" })

require('img-clip').setup({
    default = {
        dir_path = vim.g.note_path .. 'assets/images',
        use_absolute_path = true
    }
})
