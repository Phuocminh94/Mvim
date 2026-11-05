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
    overrides = {
      buftype = { terminal = { render_modes = { "nt" }, sign = { enabled = false } } },
    },
  },
}
