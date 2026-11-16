; Overrides snacks.nvim's queries/latex/images.scm (config dir comes first in the
; runtimepath, and there is no "; extends"). Same as the original minus the
; `inline_formula` rule: inline $...$ math is drawn as unicode by render-markdown
; (snacks stretched those images), only $$...$$ and math environments stay images.

; In the Claude pane code blocks have no ``` fences, so a SQL body quoted with
; $$ (CREATE FUNCTION ... AS $$ SELECT ...; $$) parses as display math. Skip
; a $$ block holding a line that ends in a bare `;` or an uppercase SQL keyword.
((displayed_equation
  (#set! image.ext "math.tex"))
  @image.content @image
  (#not-lua-match? @image "[^\\];%s*\n")
  (#not-lua-match? @image "%f[%w]SELECT%f[%W]")
  (#not-lua-match? @image "%f[%w]FROM%f[%W]")
  (#not-lua-match? @image "%f[%w]WHERE%f[%W]")
  (#not-lua-match? @image "%f[%w]BEGIN%f[%W]")
  (#not-lua-match? @image "%f[%w]RETURN%f[%W]")
  (#not-lua-match? @image "%f[%w]DECLARE%f[%W]"))

((math_environment
  (#set! image.ext "math.tex"))
  @image.content @image
  (#not-has-ancestor? @image "displayed_equation" "math_environment"))

(graphics_include
  (_ (path) @image.src)
) @image
