-- =============================================================================
-- minh.lsp_utils — shared LSP setup (Neovim 0.11+)
--
-- Call require("minh.lsp_utils").setup() once (see plugins/mason.lua).
-- Per-server files are then only needed to override nvim-lspconfig defaults,
-- and those belong in after/lsp/<name>.lua.
-- =============================================================================

local M = {}

local api = vim.api
local border = "rounded"

--- Borders and diagnostics.
M.setup_ui = function()
  -- One option for every floating window: hover, signature help, diagnostics.
  -- (Overriding vim.lsp.handlers["textDocument/hover"] no longer works:
  -- since 0.11, vim.lsp.buf.hover() does not go through vim.lsp.handlers.)
  vim.o.winborder = border

  vim.diagnostic.config({
    virtual_text = false,
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = "󰅚 ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.HINT] = "󰛩 ",
        [vim.diagnostic.severity.INFO] = " ",
      },
    },
    update_in_insert = false,
    severity_sort = true, -- errors win over warnings in the sign column
    float = {
      border = border,
      source = true, -- "always" is the pre-0.10 spelling; true or "if_many" now
    },
  })

  -- References under the cursor (LspReferenceText/Read/Write) keep the
  -- colorscheme's background highlight; Neovim's default links them to Visual.
end

--- Completion capabilities (a table, or nil for Neovim's defaults).
--- nvim-cmp needs cmp_nvim_lsp's table. (blink.cmp 1.x registers its own on 0.11+.)
local function default_capabilities()
  local ok, cmp_lsp = pcall(require, "cmp_nvim_lsp")
  return ok and cmp_lsp.default_capabilities() or nil
end
M.capabilities = default_capabilities()

-- -----------------------------------------------------------------------------
-- Per-buffer features, attached through LspAttach so they work for every
-- server, including ones enabled by mason-lspconfig with no file of their own.
-- -----------------------------------------------------------------------------

local hl_group = api.nvim_create_augroup("MinhLspDocumentHighlight", { clear = true })
local sig_group = api.nvim_create_augroup("MinhLspSignature", { clear = true })

--- Highlight other uses of the symbol under the cursor after 'updatetime'.
local function highlight_references(client, bufnr)
  if not client:supports_method("textDocument/documentHighlight", bufnr) then
    return
  end
  -- Several clients may attach to one buffer; keep a single set of autocmds.
  api.nvim_clear_autocmds({ group = hl_group, buffer = bufnr })
  api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = hl_group,
    buffer = bufnr,
    callback = vim.lsp.buf.document_highlight,
  })
  api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = hl_group,
    buffer = bufnr,
    callback = vim.lsp.buf.clear_references,
  })
end

--- Open signature help while typing right after a trigger character, e.g. "(" or ",".
local function auto_signature(client, bufnr)
  local provider = client.server_capabilities.signatureHelpProvider
  if not (provider and provider.triggerCharacters) then
    return
  end
  local triggers = {}
  for _, ch in ipairs(provider.triggerCharacters) do
    triggers[ch] = true
  end

  api.nvim_clear_autocmds({ group = sig_group, buffer = bufnr })
  api.nvim_create_autocmd("TextChangedI", {
    group = sig_group,
    buffer = bufnr,
    callback = function()
      local line = api.nvim_get_current_line()
      local col = api.nvim_win_get_cursor(0)[2] -- 0-based byte column
      -- The character just typed, or the one before it (keeps the popup up
      -- while typing the first character of an argument).
      if triggers[line:sub(col, col)] or triggers[line:sub(col - 1, col - 1)] then
        vim.lsp.buf.signature_help({ focus = false, silent = true, max_height = 10 })
      end
    end,
  })
end

--- True when another client attached to `bufnr` still supports `method`.
local function others_support(bufnr, method, leaving_id)
  for _, c in ipairs(vim.lsp.get_clients({ bufnr = bufnr, method = method })) do
    if c.id ~= leaving_id then
      return true
    end
  end
  return false
end

M.setup = function()
  M.setup_ui()

  -- Defaults merged into every server config before its own settings.
  vim.lsp.config("*", { capabilities = M.capabilities })

  -- Mason does not install the R server (it is an R package), so
  -- mason-lspconfig cannot auto-enable it. Requires install.packages("languageserver").
  vim.lsp.enable("r_language_server")

  local group = api.nvim_create_augroup("MinhLspAttach", { clear = true })
  api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(ev)
      local client = vim.lsp.get_client_by_id(ev.data.client_id)
      if client then
        highlight_references(client, ev.buf)
        auto_signature(client, ev.buf)
      end
    end,
  })

  -- Remove the autocmds when the last capable client leaves the buffer, so
  -- CursorHold does not keep sending requests after :LspStop / :LspRestart.
  api.nvim_create_autocmd("LspDetach", {
    group = group,
    callback = function(ev)
      local id = ev.data.client_id
      if not others_support(ev.buf, "textDocument/documentHighlight", id) then
        vim.lsp.buf.clear_references()
        api.nvim_clear_autocmds({ group = hl_group, buffer = ev.buf })
      end
      if not others_support(ev.buf, "textDocument/signatureHelp", id) then
        api.nvim_clear_autocmds({ group = sig_group, buffer = ev.buf })
      end
    end,
  })
end

return M
