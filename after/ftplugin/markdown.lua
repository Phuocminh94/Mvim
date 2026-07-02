local utils = require("minh.utils")

vim.opt_local.textwidth = 80
vim.opt_local.colorcolumn = "80"

vim.keymap.set("n", "<leader>wr", utils.hardwrap_md, { desc = "Hard Wrap 80" })
vim.keymap.set("n", "<leader>tc", function ()
  local filename = vim.fn.expand("%:t")
  local toc_name = filename:match("^%d%d%d%d") and "Chat History Outline" or "Markdown TOC"
  utils.markdown_toc(toc_name)
end, { desc = "Table of Content" })

require('img-clip').setup({
    default = {
        dir_path = vim.g.note_path .. 'assets/images',
        use_absolute_path = true
    }
})

-- -- Suppress gp.vim annoying debug message
-- vim.api.nvim_create_autocmd({ "BufLeave", "BufHidden" }, {
--     pattern = "*.md",
--     callback = function(ev)
--         local filename = vim.fn.fnamemodify(ev.file, ":t")
--
--         if filename:match("^%d%d%d%d") then
--             if vim.bo[ev.buf].modified then
--                 vim.cmd("silent! noautocmd write")
--             end
--         end
--     end,
--     desc = "Auto-save only for Markdown files starting with 4 digits (e.g. 2026...)",
-- })
