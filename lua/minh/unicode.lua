-- Type a shortcut, press Space, get the symbol: "/gamma " -> "γ ", "/^2 " -> "²".
-- <C-]> does the same without the space, for "α," or "α)". Prose filetypes only:
-- in code, a comment like //phi would turn into Φ.
-- Same names as the macOS Text Replacement list (which terminals never trigger).
-- Space is the trigger because abbreviations cannot start with "/".
-- The whole whitespace-delimited word must match, so paths like src/in are safe;
-- opening brackets and $ before it are kept: "(/alpha " -> "(α ".
-- A plain mapping, not an <expr> one: when keys arrive in a burst (a plugin loading
-- on InsertEnter), <expr> runs before the letters typed just before it are in the
-- buffer and would see a half-typed word. It feeds <BS>s and the symbol instead of
-- editing the buffer, so "." repeats the symbol, not the shortcut.

local M = {}

local data = require("minh.unicode_data")

M.filetypes = { "markdown", "rmd", "quarto", "tex", "plaintex", "text", "gitcommit", "mail" }

--- The shortcut before the cursor and its symbol.
--- @param before string  text of the line before the cursor
--- @return string|nil key, string|nil symbol  nil when the last word is not a shortcut
function M.lookup(before)
  local word = before:match("%S+$")
  if not word then
    return nil, nil
  end
  local key = word:match("^[%(%[{$]*(.*)$")
  return key, data[key]
end

--- Feed the keys that replace the shortcut before the cursor (if any), then `after`.
local function expand(after)
  local keys = after
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local key, symbol = M.lookup(vim.api.nvim_get_current_line():sub(1, col))
  if symbol then
    keys = string.rep("<BS>", vim.fn.strchars(key)) .. symbol .. after
  end
  -- vim.keycode also escapes the 0x80 bytes of symbols like † (E2 80 A0), which
  -- feedkeys would read as the start of a special key.
  -- "n": no remapping, so this Space does not call the mapping again;
  -- "i": run before anything typed after it.
  if keys ~= "" then
    vim.api.nvim_feedkeys(vim.keycode(keys), "ni", false)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("minh.unicode.filetype", { clear = true }),
    pattern = M.filetypes,
    callback = function(args)
      -- Prompt and terminal buffers are not text.
      if vim.bo[args.buf].buftype ~= "" then
        return
      end
      local opts = { buffer = args.buf }
      vim.keymap.set("i", "<Space>", function()
        expand(" ")
      end, vim.tbl_extend("force", opts, { desc = "Unicode: expand /shortcut" }))
      vim.keymap.set("i", "<C-]>", function()
        expand("")
      end, vim.tbl_extend("force", opts, { desc = "Unicode: expand /shortcut, no space" }))
    end,
  })
end

return M
