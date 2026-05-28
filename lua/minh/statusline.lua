local M = {}
local fn = vim.fn

-- Cache the devicons requirement so we don't pcall every frame
local devicons_present, devicons = pcall(require, "nvim-web-devicons")

local is_activewin = function()
    return vim.api.nvim_get_current_win() == vim.g.statusline_winid
end

local stbufnr = function()
    return vim.api.nvim_win_get_buf(vim.g.statusline_winid)
end

M.modes = {
    ["n"] = "NORMAL",
    ["no"] = "NORMAL (no)",
    ["nov"] = "NORMAL (nov)",
    ["noV"] = "NORMAL (noV)",
    ["noCTRL-V"] = "NORMAL",
    ["niI"] = "NORMAL i",
    ["niR"] = "NORMAL r",
    ["niV"] = "NORMAL v",
    ["nt"] = "NTERMINAL",
    ["ntT"] = "NTERMINAL (ntT)",

    ["v"] = "VISUAL",
    ["vs"] = "V-CHAR (Ctrl O)",
    ["V"] = "V-LINE",
    ["Vs"] = "V-LINE",
    [""] = "V-BLOCK",

    ["i"] = "INSERT",
    ["ic"] = "INSERT (completion)",
    ["ix"] = "INSERT completion",

    ["t"] = "TERMINAL",

    ["R"] = "REPLACE",
    ["Rc"] = "REPLACE (Rc)",
    ["Rx"] = "REPLACEa (Rx)",
    ["Rv"] = "V-REPLACE",
    ["Rvc"] = "V-REPLACE (Rvc)",
    ["Rvx"] = "V-REPLACE (Rvx)",

    ["s"] = "SELECT",
    ["S"] = "S-LINE",
    [""] = "S-BLOCK",
    ["c"] = "COMMAND",
    ["cv"] = "COMMAND",
    ["ce"] = "COMMAND",
    ["r"] = "PROMPT",
    ["rm"] = "MORE",
    ["r?"] = "CONFIRM",
    ["x"] = "CONFIRM",
    ["!"] = "SHELL",
}

M.mode = function()
    if not is_activewin() then return "" end
    local m = vim.api.nvim_get_mode().mode
    -- REFACTOR: Added a fallback "UNKNOWN" to prevent crashes
    local mode_str = M.modes[m] or "UNKNOWN" 
    return "%#St_Mode#  " .. mode_str .. " "
end

M.file = function()
    local icon = "󰈚"
    local path = vim.api.nvim_buf_get_name(stbufnr())
    local name = (path == "" and "Empty") or path:match "([^/\\]+)[/\\]*$"

    if name ~= "Empty" and devicons_present then
        local ft_icon = devicons.get_icon(name)
        icon = ft_icon or icon
    end

    return "%#St_Text# " .. icon .. " " .. name .. " "
end

M.git = function()
    -- REFACTOR: Simplified check
    local buf_git = vim.b[stbufnr()].gitsigns_status_dict
    if not buf_git or not buf_git.head then
        return ""
    end

    local added = (buf_git.added and buf_git.added ~= 0) and ("  " .. buf_git.added) or ""
    local changed = (buf_git.changed and buf_git.changed ~= 0) and ("  " .. buf_git.changed) or ""
    local removed = (buf_git.removed and buf_git.removed ~= 0) and ("  " .. buf_git.removed) or ""
    
    return "  " .. buf_git.head .. added .. changed .. removed
end

M.cwd = function()
    -- REFACTOR: Use gitsigns check instead of expensive finddir
    local is_git = vim.b[stbufnr()].gitsigns_status_dict ~= nil
    local icon = is_git and "%#St_CWD#  " or "%#St_CWD#  "
    return icon .. fn.fnamemodify(fn.getcwd(), ":t") .. " "
end

M.clock = function()
    return "%#St_Text#   " .. os.date("%H:%M") .. " "
end

M.cursor = "%#St_Text# Ln %l, Col %v  "

M.build_statusline = function()
    return table.concat({
        M.mode(),
        M.file(),
        M.git(),
        "%=",
        M.clock(),
        "%=",
        M.cursor,
        M.cwd(),
    })
end

M.setup = function()
    vim.opt.laststatus = 3
    -- REFACTOR: Ensure the module name matches filename (statusline.lua)
    vim.opt.statusline = "%!v:lua.require('minh.statusline').build_statusline()"

    local timer = vim.loop.new_timer()
    timer:start(0, 1000, vim.schedule_wrap(function()
        vim.cmd("redrawstatus")
    end))
end

return M
