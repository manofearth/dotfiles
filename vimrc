if v:version < 800
    execute pathogen#infect()
endif

" Basic {{{
set relativenumber
set shiftround
set incsearch
set showcmd
set shiftwidth=4
set tabstop=4
set expandtab
syntax on
filetype on
filetype plugin on
filetype indent on

let mapleader="\<space>"
let maplocalleader="\\"

" open buffer with all folds collapsed:
set foldlevelstart=0

" put swapfiles in separated dir (not in the same with file)
silent !mkdir -p ~/.vimswp
set directory=~/.vimswp

" russian keymap
set keymap=russian-jcukenwin
set iminsert=0
set imsearch=0

set background=dark

set completeopt-=preview " disable split with documentation on autocomplete
" }}}

" Mappings {{{
" fast way to edit and reload vimrc:
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
" }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

" Statusline {{{
set laststatus=2 "always visible
set statusline=%f
set statusline+=%=
set statusline+=%y
" }}}
