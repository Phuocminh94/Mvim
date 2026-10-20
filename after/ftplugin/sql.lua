-- Also sourced by plsql.lua. Everything is buffer-local: <leader>db is the
-- DAP breakpoint key elsewhere.
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
end
map("n", "<leader>db", "<cmd>DBUIToggle<cr>", "Toggle Dadbod UI")
map("n", "<leader>df", "<cmd>DBUIFindBuffer<cr>", "Find current buffer in DBUI")
-- DBUIFindBuffer only asks for a database while the buffer has none
-- (b:dbui_db_key_name); once assigned it keeps it. Forget the assignment so it
-- asks again. Its question is an inputlist(), whose numbered list noice does
-- not show, so pick by name here and hand the number to that inputlist().
map("n", "<leader>dr", function()
  require("lazy").load({ plugins = { "vim-dadbod-ui" } })
  local dbs = vim.fn["db_ui#connections_list"]()
  if #dbs == 0 then
    vim.notify("No databases in DBUI (vim.g.dadbod_db)", vim.log.levels.WARN)
    return
  end

  -- Answer db_ui's inputlist() with g:minh_dbui_choice when it is set.
  vim.cmd("runtime autoload/db_ui/utils.vim")
  vim.cmd([[
    function! db_ui#utils#inputlist(list) abort
      return exists('g:minh_dbui_choice') ? g:minh_dbui_choice : inputlist(a:list)
    endfunction
  ]])

  local buf = vim.api.nvim_get_current_buf()
  vim.ui.select(dbs, {
    prompt = "Assign buffer to database",
    -- Same order as the list db_ui numbers, so the index is its answer.
    format_item = function(db)
      return db.name .. (db.is_connected and " ✓" or "")
    end,
  }, function(_, idx)
    if not idx then
      return
    end
    vim.schedule(function()
      vim.api.nvim_set_current_buf(buf)
      for _, var in ipairs({ "dbui_db_key_name", "dbui_table_name", "dbui_schema_name", "db" }) do
        vim.b[var] = nil
      end
      vim.g.minh_dbui_choice = idx
      local ok, err = pcall(vim.cmd, "DBUIFindBuffer")
      vim.g.minh_dbui_choice = nil
      if not ok then
        vim.notify(err, vim.log.levels.ERROR)
      end
    end)
  end)
end, "Reassign buffer to another database")
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
