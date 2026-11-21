-- nvim --clean --headless -l tests/unicode_spec.lua
package.path = vim.fn.getcwd() .. "/lua/?.lua;" .. package.path
local u = require("minh.unicode")

local function check(before, want_key, want_symbol)
  local key, symbol = u.lookup(before)
  if key ~= want_key or symbol ~= want_symbol then
    local msg = ("FAIL %q: got %s %s, want %s %s\n"):format(
      before,
      tostring(key),
      tostring(symbol),
      tostring(want_key),
      tostring(want_symbol)
    )
    io.stderr:write(msg)
    os.exit(1)
  end
end

check("see /gamma", "/gamma", "γ")
check("//gamma", "//gamma", "Γ")
check("x /^2", "/^2", "²")
check("/_i", "/_i", "ᵢ")
check("(/alpha", "/alpha", "α") -- opening brackets and $ stay
check("$/bbR", "/bbR", "ℝ")
check("src/in", "src/in", nil) -- the word is not exactly "/in"
check("/nonsense", "/nonsense", nil)
check("", nil, nil)
print("unicode_spec: ok")
