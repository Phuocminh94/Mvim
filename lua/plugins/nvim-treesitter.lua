return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  lazy = false, -- main branch does not support lazy-loading, must load at startup
  config = function()
    -- Only sets the parser/query install directory; main branch setup()
    -- no longer accepts ensure_installed/highlight/indent (that's the old master-branch API)
    require("nvim-treesitter").setup({
      install_dir = vim.fn.stdpath("data") .. "/site",
    })

    -- List of parsers to install. install() is async and a no-op
    -- for parsers already installed, so this is cheap to call on every startup
    local parsers = {
      "bash",
      "lua",
      "markdown",
      "markdown_inline",
      "python",
      "query",
      "vim",
      "vimdoc",
      "r",
      "sql",
      "yaml",
      "latex",
    }
    require("nvim-treesitter").install(parsers)

    -- .Rmd has no dedicated treesitter parser, so map the "rmd" filetype
    -- to reuse the "markdown" parser (register(lang, filetype))
    vim.treesitter.language.register("markdown", "rmd")

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
      callback = function(args)
        local buf = args.buf

        -- Skip special buffers (floating UI from snacks, notify, telescope, nui, etc.)
        -- these have no real parser and can crash vim.treesitter.start()
        if vim.bo[buf].buftype ~= "" then
          return
        end

        local ft = args.match
        local lang = vim.treesitter.language.get_lang(ft) or ft

        -- Try to resolve/load the parser for this language; bail out silently if unavailable
        local has_lang = pcall(vim.treesitter.language.add, lang)
        if not has_lang then
          return
        end

        -- language.add() can sometimes report true even when the parser
        -- isn't actually usable yet (e.g. the snacks_notif crash case),
        -- so wrap start() in pcall as well for safety
        local ok_start = pcall(vim.treesitter.start, buf, lang)
        if not ok_start then
          return
        end

        -- Enable treesitter-based folding for this window
        vim.wo.foldmethod = "expr"
        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
        vim.wo.foldlevel = 99 -- start with all folds open

        -- Enable treesitter-based indentation for this buffer
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end,
    })
  end,
}
