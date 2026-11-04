return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  opts = {
    -- Inline $...$ becomes unicode (needs utftex, falls back to latex2text);
    -- $$...$$ blocks are left to snacks.image, which draws them as pictures.
    latex = { inline = true, block = false },
    -- The Claude pane can pretend to be markdown (`m` in it, minh.claude):
    -- draw only in its Normal mode ("nt"), not while Claude streams output.
    overrides = {
      buftype = { terminal = { render_modes = { "nt" }, sign = { enabled = false } } },
    },
  },
}
