-- Also sourced by plsql.lua. Everything is buffer-local: <leader>db is the
-- DAP breakpoint key elsewhere.
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
end
map("n", "<leader>db", "<cmd>DBUIToggle<cr>", "Toggle Dadbod UI")
map("n", "<leader>df", "<cmd>DBUIFindBuffer<cr>", "Find current buffer in DBUI")
map("n", "<leader><Enter>", "<cmd>%DB<cr>", "Execute entire SQL file")
map("v", "<leader><leader>", ":DB<cr>", "Execute selected SQL")
map("n", "<leader><leader>", "<cmd>.DB<cr>", "Execute current line")

-- nvim-cmp loads the snippets itself (plugins/nvim-cmp.lua).
local has_cmp, cmp = pcall(require, "cmp")
if has_cmp then
  cmp.setup.buffer({
    sources = {
      { name = "vim-dadbod-completion", priority = 1000 },
      { name = "luasnip" },
      { name = "buffer", priority = 250 },
    },
  })
end
