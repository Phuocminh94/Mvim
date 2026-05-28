local M = {}

--- Setup global UI elements like borders and diagnostics
M.setup_ui = function()
    local border = "rounded"

    -- Add border to LSP hover and signature help
    vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
        vim.lsp.handlers.hover,
        { border = border }
    )


    vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
        vim.lsp.handlers.signature_help,
        { border = border }
    )

    -- Global diagnostic config (updated for Nvim 0.10+)
    vim.diagnostic.config({
        virtual_text = false,
        -- Pass the icons directly into the signs table here
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR] = "󰅚 ",
                [vim.diagnostic.severity.WARN]  = " ",
                [vim.diagnostic.severity.HINT]  = "󰛩 ",
                [vim.diagnostic.severity.INFO]  = " ",
            },
        },
        update_in_insert = false,
        float = {
            border = border,
            source = "always", -- show diagnostic source [cite: 2]
        },
    })
end

--- Highlight symbol under cursor
local function lsp_highlight_document(client, bufnr)
    -- Modern check using server_capabilities
    if client.server_capabilities.documentHighlightProvider then
        local hl_augroup = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
        
        -- Clear existing autocmds for this buffer to prevent duplicates on reload
        vim.api.nvim_clear_autocmds({ buffer = bufnr, group = hl_augroup })

        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
            group = hl_augroup,
            buffer = bufnr,
            callback = vim.lsp.buf.document_highlight,
        })

        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
            group = hl_augroup,
            buffer = bufnr,
            callback = vim.lsp.buf.clear_references,
        })
    end
end

--- Buffer-Local Auto-Signature Setup
local function check_triggeredChars(triggerChars)
    local cur_line = vim.api.nvim_get_current_line()
    local pos = vim.api.nvim_win_get_cursor(0)[2]
    local prev_char = cur_line:sub(pos - 1, pos - 1)
    local cur_char = cur_line:sub(pos, pos)

    for _, char in ipairs(triggerChars) do
        if cur_char == char or prev_char == char then
            return true
        end
    end
    return false
end

local function setup_auto_signature(client, bufnr)
    -- SAFETY CHECK: Ensure the language server actually supports signature help
    local signature_provider = client.server_capabilities.signatureHelpProvider
    if not signature_provider or not signature_provider.triggerCharacters then
        return -- Exit silently if the server doesn't support it
    end

    local triggerChars = signature_provider.triggerCharacters
    local group = vim.api.nvim_create_augroup("LspSignature", { clear = false })
    
    vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })

    vim.api.nvim_create_autocmd("TextChangedI", {
        group = group,
        buffer = bufnr,
        callback = function()
            if check_triggeredChars(triggerChars) then
                vim.lsp.buf.signature_help({ focus = false, silent = true, max_height = 7, border = "rounded" })
            end
        end,
    })
end

--- Shared on_attach function to pass to each server
M.on_attach = function(client, bufnr)
    lsp_highlight_document(client, bufnr)
    setup_auto_signature(client, bufnr)
end

--- Base capabilities
M.capabilities = vim.lsp.protocol.make_client_capabilities()

return M
