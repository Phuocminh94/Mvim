local M = {}

local terminals = {}

M.create_floating_window = function(opts)
    opts = opts or {}

    -- Default: Right-bottom
    local width = opts.width or math.floor(vim.o.columns * 0.8)
    local height = opts.height or math.floor(vim.o.lines * 0.8)

    local ui = vim.api.nvim_list_uis()[1]
    local col = math.floor((opts.x or 0.5) * (ui.width - width))
    local row = math.floor((opts.y or 0.5) * (ui.height - height))

    local buf
    if opts.buf and vim.api.nvim_buf_is_valid(opts.buf) then
        buf = opts.buf
    else
        buf = vim.api.nvim_create_buf(false, true)
    end

    local win_config = {
        relative = "editor",
        width = width,
        height = height,
        col = col,
        row = row,
        style = "minimal",
        border = "rounded",
    }

    local win = vim.api.nvim_open_win(buf, true, win_config)
    return { buf = buf, win = win }
end

M.toggle = function(id, opts)
    id = id or "default"
    
    -- Ensure defaults are applied even if an ID is passed
    local default_opts = {
        height = 15,
        width = 70,
        x = 1,
        y = .875,
    }
    opts = vim.tbl_deep_extend("force", default_opts, opts or {})

    terminals[id] = terminals[id] or { buf = -1, win = -1 }
    local term = terminals[id]
    opts.buf = term.buf

    if not vim.api.nvim_win_is_valid(term.win) then
        term = M.create_floating_window(opts)
        terminals[id] = term
        
        -- Start terminal only if buffer is new or process died
        if vim.bo[term.buf].buftype ~= "terminal" then
            vim.fn.termopen(opts.cmd or vim.o.shell, {
                on_exit = function()
                    if vim.api.nvim_win_is_valid(term.win) then
                        vim.api.nvim_win_close(term.win, true)
                    end
                end,
            })
        end
        vim.cmd("startinsert")
    else
        vim.api.nvim_win_hide(term.win)
    end
end

vim.api.nvim_create_user_command("FloatTerm", function(params)
    local opts = {}
    local id = "default"

    for _, arg in ipairs(params.fargs) do
        local key, val = string.match(arg, "([^=]+)=([^=]+)")
        if key == "id" then
            id = val
        elseif key and val then
            opts[key] = tonumber(val) or val
        end
    end

    M.toggle(id, opts)
end, { nargs = "*" })

return M
