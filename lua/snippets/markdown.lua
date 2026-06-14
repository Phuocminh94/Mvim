local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local rep = require("luasnip.extras").rep

return {
	-- 1. LaTeX Environment
	s({
		trig = "en",
		dscr = "Insert LaTeX environment",
	}, {
		t("\\begin{"), i(1, "env"), t({ "}", "\t" }),
		i(2),
		t({ "", "\\end{" }), rep(1), t("}"),
		i(0),
	}),

	-- 2. Inline Math ($...$)
	s({
		trig = "ma",
		dscr = "Inline math block",
	}, {
		t("$"), i(1), t("$"), i(0),
	}),

	-- 3. Display Math ($$ ... $$)
	s({
		trig = "dm",
		dscr = "Display math block $$ $$",
	}, {
		t({ "$$", "\t" }), i(1), t({ "", "$$" }),
		i(0),
	}),

	-- 4. Display Math (\[ ... \])
	s({
		trig = "mm",
		dscr = "Display math block \\[ \\]",
	}, {
		t({ "\\[", "\t" }), i(1), t({ "", "\\]" }),
		i(0),
	}),

	-- 5. Fraction
	s({
		trig = "fr",
		dscr = "LaTeX fraction \\frac{num}{den}",
	}, {
		t("\\frac{"), i(1, "num"), t("}{"), i(2, "den"), t("}"), i(0)
	}),

	-- 6. Display style
	s({
		trig = "ds",
		dscr = "LaTeX \\displaystyle",
	}, {
		t("\\displaystyle "), i(0)
	}),

	-- 7. Display Fraction (\displaystyle\frac{}{})
	s({
		trig = "dfr",
		dscr = "LaTeX \\displaystyle\\frac{num}{den}",
	}, {
		t("\\displaystyle\\frac{"), i(1, "num"), t("}{"), i(2, "den"), t("}"), i(0)
	}),

	-- 8. Bold Vector (Standard)
	s({
		trig = "vb",
		dscr = "LaTeX bold vector \\mathbf{x}",
	}, {
		t("\\mathbf{"), i(1, "x"), t("}"), i(0)
	}),

	-- 9. Bold Symbol Vector (Greek)
	s({
		trig = "vbs",
		dscr = "LaTeX bold symbol vector \\boldsymbol{\\alpha}",
	}, {
		t("\\boldsymbol{"), i(1, "\\alpha"), t("}"), i(0)
	}),

	-- 10. Blackboard Bold (Math Sets)
	s({
		trig = "bb",
		dscr = "LaTeX blackboard bold \\mathbb{R}",
	}, {
		t("\\mathbb{"), i(1, "R"), t("}"), i(0)
	}),
}
