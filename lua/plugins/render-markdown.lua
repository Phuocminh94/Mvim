return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  opts = {
    -- Inline $...$ becomes one line of unicode, drawn by minh.latex_inline (via
    -- bin/latex-inline, needs python3 + utftex, falls back to latex2text);
    -- $$...$$ blocks are left to snacks.image, which draws them as pictures.
    latex = { inline = true, block = false },
    custom_handlers = {
      latex = {
        parse = function(ctx)
          return require("minh.latex_inline").parse(ctx)
        end,
      },
    },
    -- The Claude pane can pretend to be markdown (`m` in it, minh.claude):
    -- draw only in its Normal mode ("nt"), not while Claude streams output.
    -- Math only there: Claude Code has already drawn the rest (tables, lists,
    -- code), and anything else hidden in its text shifts its table borders.
    overrides = {
      buftype = {
        terminal = (function()
          -- No anti_conceal: the pane is read-only, and the cursor line showing
          -- raw $...$ looked like math failing to render.
          -- Conceal stays on while Claude streams (Terminal mode): snacks.image
          -- hides a $$ block's source under its picture by conceal, and with the
          -- default 0 the end of each source line longer than the picture showed.
          local only_math = {
            render_modes = { "nt" },
            anti_conceal = { enabled = false },
            win_options = { conceallevel = { default = 2, rendered = 3 } },
          }
          for _, feature in ipairs({
            "bullet", "checkbox", "code", "dash", "heading", "html", "indent", "inline_highlight",
            "link", "paragraph", "pipe_table", "quote", "sign", "yaml",
          }) do
            only_math[feature] = { enabled = false }
          end
          return only_math
        end)(),
      },
    },
  },
}
