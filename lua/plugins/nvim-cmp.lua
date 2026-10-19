return {
  "hrsh7th/nvim-cmp",
  event = "InsertEnter",
  dependencies = {
    "hrsh7th/cmp-buffer", -- source for text in buffer
    "hrsh7th/cmp-path", -- source for file system paths
    "hrsh7th/cmp-nvim-lsp", -- Required for the 'nvim_lsp' source to work
    {
      "L3MON4D3/LuaSnip",
      -- follow latest release.
      version = "v2.*", -- Replace <CurrentMajor> by the latest released major (first number of latest release)
      -- install jsregexp (optional!).
      build = "make install_jsregexp",
    },
    "saadparwaiz1/cmp_luasnip", -- for autocompletion
    "rafamadriz/friendly-snippets", -- useful snippets
    "onsails/lspkind.nvim", -- vs-code like pictograms
  },

  config = function()
    local cmp = require("cmp")

    local luasnip = require("luasnip")
    luasnip.config.setup({
      region_check_events = "InsertEnter",
      delete_check_events = "TextChanged,InsertLeave",
    })

    local lspkind = require("lspkind")

    -- Scroll the completion docs, or else the first floating window
    -- (signature help): `key` is the raw <C-b>/<C-f> to run in it.
    local function scroll(delta, key)
      return cmp.mapping(function(fallback)
        if cmp.visible_docs() then
          cmp.scroll_docs(delta)
          return
        end
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          if vim.api.nvim_win_get_config(win).relative ~= "" then
            vim.fn.win_execute(win, "normal! " .. key)
            return
          end
        end
        fallback()
      end, { "i", "s" })
    end

    -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
    require("luasnip.loaders.from_vscode").lazy_load()

    -- loads my own snippets
    require("luasnip.loaders.from_lua").lazy_load({ paths = vim.g.snippet_path })
    luasnip.filetype_extend("rmd", { "markdown" })
    luasnip.filetype_extend("tex", { "markdown" })

    cmp.setup({
      -- Automatically highlight the first option
      completion = {
        completeopt = "menu,menuone,noinsert",
      },

      -- See also minh.lsp_utils for the signature panel UI
      window = {
        completion = cmp.config.window.bordered({ border = "rounded" }),
        documentation = cmp.config.window.bordered({ border = "rounded" }),
      },
      snippet = { -- configure how nvim-cmp interacts with snippet engine
        expand = function(args)
          luasnip.lsp_expand(args.body)
        end,
      },
      mapping = cmp.mapping.preset.insert({
        ["<C-k>"] = cmp.mapping.select_prev_item(), -- previous suggestion
        ["<C-j>"] = cmp.mapping.select_next_item(), -- next suggestion
        ["<C-b>"] = scroll(-4, "\x02"), -- \x02 = <C-b>
        ["<C-f>"] = scroll(4, "\x06"), -- \x06 = <C-f>
        ["<C-Space>"] = cmp.mapping.complete(), -- show completion suggestions
        ["<C-s>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.confirm({ select = true })
          elseif luasnip.expandable() then
            luasnip.expand()
          else
            fallback()
          end
        end),
        ["<C-e>"] = cmp.mapping.abort(), -- close completion window
        ["<Tab>"] = cmp.mapping(function(fallback)
          if luasnip.expand_or_locally_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if luasnip.locally_jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }),
      -- sources for autocompletion
      sources = cmp.config.sources({
        { name = "lazydev", group_index = 0 },
        { name = "nvim_lsp" },
        { name = "luasnip" }, -- snippets
        { name = "buffer" }, -- text within current buffer
        { name = "path" }, -- file system paths
      }),

      -- configure lspkind for vs-code like pictograms in completion menu
      formatting = {
        format = lspkind.cmp_format({
          maxwidth = 50,
          ellipsis_char = "...",
        }),
      },
    })
  end,
}
