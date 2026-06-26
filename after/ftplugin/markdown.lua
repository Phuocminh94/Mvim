local utils = require("minh.utils")

vim.opt.textwidth = 80
vim.opt.colorcolumn    = "80"           -- Vertical line at 80 chars

vim.keymap.set("n", "<leader>wr", utils.hardwrap_md, { desc = "Hard Wrap 80" })
vim.keymap.set("n", "<leader>tc", utils.markdown_toc, { desc = "Table of Content" })

require('img-clip').setup({
    default = {
        dir_path = vim.g.note_path .. 'assets/images',
        use_absolute_path = true
    }
})
