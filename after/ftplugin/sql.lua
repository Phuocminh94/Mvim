vim.keymap.set("n", "<leader>db", "<cmd>DBUIToggle<cr>", { desc = "Toggle Dadbod UI" })
vim.keymap.set("n", "<leader>df", "<cmd>DBUIFindBuffer<cr>", { desc = "Find current buffer in DBUI" })
vim.keymap.set("n", "<leader><Enter>", "<cmd>%DB<cr>", { buffer = true, desc = "Execute entire SQL file" })
vim.keymap.set("v", "<leader><Enter>", ":DB<cr>", { buffer = true, desc = "Execute selected SQL" })
vim.keymap.set("n", "<leader><leader>", "<cmd>.DB<cr>", { buffer = true, desc = "Execute current line" })

local has_cmp, cmp = pcall(require, "cmp")
if has_cmp then
    cmp.setup.buffer({
        sources = {
            { name = "vim-dadbod-completion" },
            { name = "buffer" },
        },
    })
end
