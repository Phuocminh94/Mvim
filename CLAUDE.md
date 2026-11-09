# Mvim

Personal Neovim config (Neovim 0.12), plugins via lazy.nvim. Public repo: no
secrets, private paths or personal data here.

## Layout

- `init.lua`: entry point, loads `lua/minh/*` core modules, then `lua/lazy_cf.lua`.
- `lua/minh/`: own modules (options, keymaps, autocmds, statusline, tabline,
  theme, `claude.lua` = Claude Code pane in nvim, `latex_inline.lua` =
  render-markdown handler for inline math).
- `lua/minh/local_config.lua`: per-machine settings, git-ignored.
- `lua/plugins/`: one lazy.nvim spec per file.
- `lua/snippets/`, `after/ftplugin/`, `after/lsp/`: snippets, filetype and LSP overrides.
- `queries/latex/images.scm`: overrides snacks.nvim's query (no inline-formula images).
- `bin/`: helper executables called by the config, found through
  `stdpath("config")`, not `$PATH` (`latex-inline`: inline LaTeX to one line of unicode).
- `tests/`: `wrap_spec.lua` (unit, no plugins), `smoke.lua` (whole config headless).

## Commands

- `make test`: stylua check + unit + smoke. `make fmt`: format with stylua.
- `make startup`: startup time.

## Math rendering (markdown and the Claude pane)

- Inline `$...$`: `bin/latex-inline` (python3 + utftex from libtexprintf),
  falls back to utftex, then latex2text (pylatexenc).
- `$$...$$`: snacks.image, compiled with pdflatex + magick. Its template in
  `lua/plugins/snacks.lua` needs vntex (T5 fontenc; Arch: `texlive-langother`)
  and turns `\ ` into a row break in matrices, as Claude Code's terminal
  renderer prints `\\` as `\`.
- macOS: `brew install utftex`; BasicTeX needs `sudo tlmgr install standalone
  preview etoolbox mathtools xcolor vntex` (the dotfiles installer does both).
- Formula images are cached in `~/.cache/nvim/snacks/image/`; delete the
  `*.math.*` files after changing the template.
- Claude pane: math rendering is on from the start (`m` toggles; set
  `vim.g.claude_math = false` in `local_config.lua` to start off) and redraws 500 ms
  after Claude stops printing.

## Conventions

- Comments explain why, in English. Packages the config needs are listed in
  the separate dotfiles repo (`packages/linux/*.txt`, `packages/macos/Brewfile`).
- Autocmd groups: `minh.<area>.<purpose>`, lowercase, dot-separated, mirroring
  the module (`minh.lsp.attach`, `minh.claude.reload`); per-buffer groups end
  in `.<bufnr>`.
- Keymap labels (`desc`): `Area: action` in lowercase after the colon (names
  and acronyms keep their case: `Iron: toggle REPL`, `Git: next hunk`) for any
  plugin or feature key; core editing keys (splits, tabs, lines, quickfix) are
  bare sentence case (`Focus left split`).
