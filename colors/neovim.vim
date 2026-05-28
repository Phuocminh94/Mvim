" Neovim colorscheme
" By:  Minh Bui <buiphuocminh94@gmail.com>
" Last Change: 2025 May 5

set bg=dark
hi clear
if exists("syntax_on")
  syntax reset
endif

let colors_name = "neovim"

" Basics
hi Normal           guifg=#00d000  guibg=#0b151b  ctermfg=82      ctermbg=black
hi ErrorMsg         guifg=#ffffff  guibg=#ff0000  ctermfg=white      ctermbg=red
hi Visual           guifg=#a9d5c4  guibg=#537ba3  ctermfg=darkgreen  ctermbg=darkgrey
hi Todo             guifg=#001000  guibg=#00ff00  ctermfg=black      ctermbg=lightgreen
hi NonText          guifg=#354948                 ctermfg=lightgreen
hi Search           guifg=#001000  guibg=#60ff60
hi Question         guifg=#80ff80                 ctermfg=lightgreen
hi MatchParen       guifg=#90ff90  guibg=bg       gui=bold
hi LineNr           guifg=#83919f                 ctermfg=darkgrey
hi CursorLineNr     guifg=#ffff00                 ctermfg=yellow
hi Directory        guifg=#40d040                 ctermfg=lightgreen
hi Folded           guifg=#001000  guibg=#006000  ctermfg=black      ctermbg=darkgreen  gui=bold
hi ColorColumn      guibg=#003000                                    ctermbg=darkgreen
hi Error            guibg=#ff8000                                    ctermbg=red
hi CursorLine       guifg=#001000  guibg=#008000  ctermfg=black      ctermbg=green
hi NormalFloat      guifg=#00d000  guibg=#0b151b  ctermfg=82         ctermbg=black

" Splitter
hi StatusLine       guifg=#000000  guibg=#20a020  ctermfg=black      ctermbg=green      gui=none  term=none      cterm=none
hi StatusLineNC     guifg=#000000  guibg=#006000  ctermfg=black      ctermbg=darkgreen  gui=none  term=none      cterm=none
hi VertSplit        guifg=#000000  guibg=#006000  ctermfg=black      ctermbg=darkgreen  gui=none  term=none      cterm=none

" Popup menu
hi Pmenu            guifg=#80ff80  guibg=#002000  ctermfg=green      ctermbg=black
hi PmenuSel         guifg=#001000  guibg=#80ff80  ctermfg=darkgreen  ctermbg=darkgrey
hi PmenuSbar        guibg=#104010
hi PmenuThumb       guibg=#40a040

" Code colors
hi Comment          guifg=#888888                 ctermfg=darkgrey  ctermbg=bg        gui=italic
hi Constant         guifg=#ffff00                 ctermfg=226       guibg=NONE
hi StringConstant   guifg=#008800                 ctermfg=49
hi Special          guifg=#30ff30                 ctermfg=149
hi Identifier       guifg=#57bb56                 ctermfg=148
hi Function         guifg=#00bab6
hi Statement        guifg=#40ff40                 ctermfg=72        gui=none
hi PreProc          guifg=#00c000                 ctermfg=72
hi Type             guifg=#30ff30                 ctermfg=154        gui=none
hi Underlined                                                                                 term=underline cterm=underline
hi Ignore           guifg=bg                      ctermfg=bg
hi Operator         guifg=#30ff30                 ctermfg=yellow

" Completion (nvim-cmp or CoC)
hi CmpItemAbbr      guifg=#ffff00  guibg=NONE
hi CmpItemAbbrMatch guifg=#ffff00  guibg=NONE
hi CmpItemKind      guifg=#00bab6  guibg=NONE

" Floating window borders
hi FloatBorder      guifg=#354948
hi TelescopeBorder  guifg=#354948

" Statusline
hi St_Mode guibg=#373b43 guifg=#83919f gui=bold
hi St_Text guibg=#242830 guifg=#83919f gui=bold
hi St_CWD  guibg=#373b43 guifg=#40ff40 gui=bold

" Tabline
hi Tabline  guibg=#373b43 guifg=#83919f gui=bold
hi TablineFill guibg=#0b151b gui=bold
hi TablineSel guifg=#ffffff guibg=#00bab6

" Syntax links
hi link String         StringConstant
hi link Character      Constant
hi link Number         Constant
hi link Boolean        Constant
hi link Float          Number
hi link Function       Identifier
hi link Conditional    Statement
hi link Repeat         Statement
hi link Label          Statement
hi link Operator       Statement
hi link Keyword        Statement
hi link Exception      Statement
hi link Include        PreProc
hi link Define         PreProc
hi link Macro          PreProc
hi link PreCondit      PreProc
hi link StorageClass   Type
hi link Structure      Type
hi link Typedef        Type
hi link SpecialChar    Special
hi link Delimiter      Special
hi link SpecialComment Special
hi link Debug          Special
