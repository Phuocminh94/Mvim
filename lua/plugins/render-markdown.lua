return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },
  opts = {
    -- Inline $...$ becomes unicode (needs utftex, falls back to latex2text);
    -- $$...$$ blocks are left to snacks.image, which draws them as pictures.
    latex = { inline = true, block = false },
  },
}
