"""bin/latex-inline: inline LaTeX in, one line of unicode out.

Run by `make unit`; skipped when utftex is missing. Inputs are as they reach
nvim's Claude pane: Claude Code prints \\\\ as \\ and \\{ as {, and wraps lines.
"""

import os
import shutil
import subprocess
import sys

SCRIPT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "bin", "latex-inline")

CASES = [
    # fractions, roots, binomials
    (r"\frac{s}{\det M}", "s/(det M)"),
    (r"\frac{1}{ps-qr}", "1/(ps-qr)"),
    (r"\tfrac12", "1/2"),
    (r"\frac{\pi}{2}", "π/2"),
    (r"\frac{1}{2n}", "1/(2n)"),
    (r"x^{2}+\frac{1}{2}", "x²+1/2"),
    (r"\left(\frac{a}{b}\right)^2", "(a/b)²"),
    (r"\sqrt{a+b}", "√(a+b)"),
    (r"\sqrt[3]{x}", "∛x"),
    (r"\binom{n}{k}", "C(n,k)"),
    # scripts
    (r"M^{-1}", "M⁻¹"),
    (r"(M^{-1})_{aa}", "(M⁻¹)ₐₐ"),
    (r"M_{aa}^{-1}", "Mₐₐ⁻¹"),
    (r"{M_{aa}}^{-1}", "Mₐₐ⁻¹"),
    (r"e^{i\theta}", "eⁱᶿ"),
    (r"x^{ab}_{q}", "xᵃᵇ_q"),
    (r"A^\top", "Aᵀ"),
    (r"f'(x)", "f′(x)"),
    (r"x_{i,j}", "xᵢ,ⱼ"),
    (r"E_r", "Eᵣ"),
    (r"{}^{14}C", "¹⁴C"),
    # operators
    (r"\sum_{i=1}^n x_i", "∑ᵢ₌₁ⁿ xᵢ"),
    (r"\int_0^1 f(x)\,dx", "∫₀¹ f(x)dx"),
    (r"\lim_{t\to 0} f(t)", "lim_(t→0) f(t)"),
    (r"\det M", "det M"),
    (r"\det(M)", "det(M)"),
    (r"\det\big(M\big)", "det(M)"),
    (r"(\operatorname{adj} M)_{aa}=(-1)^{a+a}\det M[a,a]", "(adj M)ₐₐ=(-1)ᵃ⁺ᵃdet M[a,a]"),
    # symbols and one-argument commands
    (r"\mathbb{R}^n", "ℝⁿ"),
    (r"\mathbb{Z}_n", "ℤₙ"),
    (r"\alpha\le\beta", "α≤β"),
    (r"t\to 1/t", "t→1/t"),
    (r"3\times3", "3×3"),
    (r"M=I-tA", "M=I-tA"),
    (r"\text{bỏ hàng } a", "bỏ hàng a"),
    (r"\hat{x}+\vec{v}", None),  # utftex's own drawing; only checked to be one line
    # matrices: rows broken by \\ or, after Claude Code, by "\ "
    (r"\begin{pmatrix}1&-t\ -t&1\end{pmatrix}", "(1  -t; -t  1)"),
    (r"\begin{pmatrix}1&-t\\ -t&1\end{pmatrix}", "(1  -t; -t  1)"),
    (r"M=\begin{bmatrix}a_{11}&\frac{1}{2}\\[2pt]0&\sqrt{x}\end{bmatrix}^{-1}", "M=[a₁₁  1/2; 0  √x]⁻¹"),
    (r"\det\begin{vmatrix}p&q\\r&s\end{vmatrix}=ps-qr", "det |p  q; r  s|=ps-qr"),
    (r"f=\begin{cases}1&x>0\\0&\text{khác}\end{cases}", "f={1  x>0; 0  khác"),
    # set braces: \{ \} as written, and as Claude Code prints them ({ })
    (r"\pi = \{\{u\},\ V(G)\setminus\{u\}\}", "π={{u}, V(G)⧵{u}}"),
    (r"\pi = {{u},\ V(G)\setminus{u}}", "π={{u}, V(G)⧵{u}}"),
    (r"S={1,2,3}", "S={1,2,3}"),
    (r"A\cup{x}", "A∪{x}"),
    (r"\{x\}", "{x}"),
    (r"I-tA(X\setminus a)", "I-tA(X⧵a)"),
    # hard-wrapped by the pane
    ("I-\n  tA(X\\setminus\n  a)", "I-tA(X⧵a)"),
    # ligature fonts draw != as ≠
    (r"9!=362,880", "9! = 362,880"),
    (r"(2n)!=\frac{a}{b}", "(2n)! = a/b"),
    (r"a\neq b", "a≠b"),
    (r"n!", "n!"),
]


def convert(src):
    res = subprocess.run([SCRIPT], input=src, capture_output=True, text=True)
    return res.returncode, res.stdout.rstrip("\n")


def main():
    if not shutil.which("utftex"):
        print("latex_inline_spec: skipped (no utftex)")
        return 0
    failed = 0
    for src, want in CASES:
        code, got = convert(src)
        ok = code == 0 and "\n" not in got and (want is None or got == want)
        if not ok:
            failed += 1
            print(f"FAIL {src!r}\n  want {want!r}\n  got  {got!r} (exit {code})")
    print(f"latex_inline_spec: {len(CASES) - failed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
