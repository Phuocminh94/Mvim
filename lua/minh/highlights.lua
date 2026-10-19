-- =============================================================================
-- minh.highlights — overrides re-applied after every :colorscheme
--
-- `:colorscheme` (and an omarchy theme switch) runs `hi clear`, so anything set
-- once at startup is lost. setup() registers a ColorScheme autocmd and applies
-- the overrides. Call it before lazy.nvim loads the colorscheme (see init.lua).
-- =============================================================================

local M = {}

local api = vim.api

local function get(name)
  return api.nvim_get_hl(0, { name = name, link = false })
end

--- Mix two 0xRRGGBB colors: a = 0 gives `bg`, a = 1 gives `fg`.
function M.blend(bg, fg, a)
  local function ch(c, shift)
    return bit.band(bit.rshift(c, shift), 0xff)
  end
  local function mix(shift)
    return math.floor(ch(bg, shift) * (1 - a) + ch(fg, shift) * a + 0.5)
  end
  return string.format("#%02x%02x%02x", mix(16), mix(8), mix(0))
end

-- A ColorColumn that stands out from Normal.bg. Must run before the
-- transparency overrides below clear Normal.bg.
local function colorcolumn()
  local normal, cl = get("Normal"), get("CursorLine")
  if not (normal.bg and normal.fg) then
    return
  end
  local color
  if cl.bg and cl.bg ~= normal.bg then
    color = M.blend(normal.bg, cl.bg, 0.5)
  else
    -- CursorLine has no background of its own: 12% of the text color.
    color = M.blend(normal.bg, normal.fg, 0.12)
  end
  api.nvim_set_hl(0, "ColorColumn", { bg = color })
end

-- Groups used by minh.statusline: the theme's own StatusLine colors, so the
-- bar looks like a plain statusline; only the mode and cwd get an accent.
-- colors/neovim.vim defines its own St_* groups, so leave those alone.
local function statusline()
  if vim.g.colors_name == "neovim" then
    return
  end
  local sl, str = get("StatusLine"), get("String")
  api.nvim_set_hl(0, "St_Mode", { bg = sl.bg, fg = sl.fg, bold = true })
  api.nvim_set_hl(0, "St_Text", { bg = sl.bg, fg = sl.fg })
  api.nvim_set_hl(0, "St_CWD", { bg = sl.bg, fg = str.fg or sl.fg, bold = true })
end

-- stylua: ignore
local TRANSPARENT = {
  "Normal", "NormalNC", "NormalFloat", "FloatBorder", "Pmenu", "Terminal",
  "EndOfBuffer", "FoldColumn", "Folded", "SignColumn", "WhichKeyFloat",
  "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeVertSplit", "NeoTreeWinSeparator", "NeoTreeEndOfBuffer",
}

local function transparency()
  for _, name in ipairs(TRANSPARENT) do
    -- Keep fg/bold/links: only drop the background.
    local hl = get(name)
    hl.bg = nil
    api.nvim_set_hl(0, name, hl)
  end
end

function M.apply()
  colorcolumn()
  statusline()
  transparency()
end

function M.setup()
  api.nvim_create_autocmd("ColorScheme", {
    group = api.nvim_create_augroup("MinhHighlights", { clear = true }),
    callback = M.apply,
  })
end

return M
