; Overrides snacks.nvim's queries/latex/images.scm (config dir comes first in the
; runtimepath, and there is no "; extends"). Same as the original minus the
; `inline_formula` rule: inline $...$ math is drawn as unicode by render-markdown
; (snacks stretched those images), only $$...$$ and math environments stay images.

(displayed_equation
  (#set! image.ext "math.tex"))
  @image.content @image

((math_environment
  (#set! image.ext "math.tex"))
  @image.content @image
  (#not-has-ancestor? @image "displayed_equation" "math_environment"))

(graphics_include
  (_ (path) @image.src)
) @image
