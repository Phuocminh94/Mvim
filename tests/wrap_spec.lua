-- Unit tests for lua/minh/wrap.lua. No plugins needed:
--   nvim --clean --headless -l tests/wrap_spec.lua
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
package.path = root .. "/lua/?.lua;" .. root .. "/lua/?/init.lua;" .. package.path

local wrap = require("minh.wrap")
local failed, passed = 0, 0

--- Reflow `input` (whole buffer) with filetype `ft` at `width`, compare with `expected`.
local function case(name, ft, width, input, expected)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].filetype = ft
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, input)
  wrap.reflow(buf, 1, #input, width)
  local got = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Reflowing the result again must not change it.
  wrap.reflow(buf, 1, #got, width)
  local again = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  vim.api.nvim_buf_delete(buf, { force = true })

  if vim.deep_equal(got, expected) and vim.deep_equal(again, got) then
    passed = passed + 1
    return
  end
  failed = failed + 1
  print("FAIL: " .. name)
  print("  expected: " .. vim.inspect(expected))
  print("  got:      " .. vim.inspect(got))
  if not vim.deep_equal(again, got) then
    print("  not idempotent, second pass: " .. vim.inspect(again))
  end
end

case("joins and fills a paragraph", "markdown", 20, {
  "one two three",
  "four five six seven eight nine",
}, {
  "one two three four",
  "five six seven eight",
  "nine",
})

case("keeps code fences and headings", "markdown", 10, {
  "# A very long heading line",
  "```lua",
  "local x = 1 local y = 2",
  "```",
}, {
  "# A very long heading line",
  "```lua",
  "local x = 1 local y = 2",
  "```",
})

case("list items get a hanging indent", "markdown", 16, {
  "- alpha beta gamma delta",
  "- [ ] task one two three",
}, {
  "- alpha beta",
  "  gamma delta",
  "- [ ] task one",
  "      two three",
})

case("inline code and math are not split", "markdown", 12, {
  "see `a b c d` and $x + y$ ok",
}, {
  "see",
  "`a b c d`",
  "and $x + y$",
  "ok",
})

case("hard break with two trailing spaces ends the line", "markdown", 40, {
  "first line  ",
  "second line",
}, {
  "first line  ",
  "second line",
})

case("blockquote keeps its prefix", "markdown", 14, {
  "> one two three four five",
}, {
  "> one two",
  "> three four",
  "> five",
})

case("YAML front matter is left alone", "rmd", 10, {
  "---",
  "title: a long title here",
  "---",
  "a b",
  "c",
}, {
  "---",
  "title: a long title here",
  "---",
  "a b c",
})

case("width counts display cells, not bytes", "markdown", 11, {
  "tiếng việt có dấu",
}, {
  "tiếng việt",
  "có dấu",
})

case("long words (URLs) stay on one line", "markdown", 10, {
  "see https://example.com/a/long/path now",
}, {
  "see",
  "https://example.com/a/long/path",
  "now",
})

case("tex: comments and environments are kept", "tex", 12, {
  "some text % a comment here",
  "\\begin{equation}",
  "a + b = c + d + e",
  "\\end{equation}",
  "alpha beta gamma delta",
}, {
  "some text % a comment here",
  "\\begin{equation}",
  "a + b = c + d + e",
  "\\end{equation}",
  "alpha beta",
  "gamma delta",
})

case("tex: \\item gets a hanging indent", "tex", 18, {
  "\\item one two three four",
}, {
  "\\item one two",
  "      three four",
})

io.stdout:write(string.format("wrap_spec: %d passed, %d failed\n", passed, failed))
os.exit(failed == 0 and 0 or 1)
