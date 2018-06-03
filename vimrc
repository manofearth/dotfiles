if v:version < 800
    execute pathogen#infect()
endif

" Basic {{{
if exists('+relativenumber')
    set relativenumber
else
    set number
endif

set shiftround
set incsearch
set showcmd
set shiftwidth=2
set tabstop=2
set expandtab
syntax on
filetype plugin indent on
set autoindent

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

set fileencodings=utf-8,utf-16le,cp1251

set background=dark

set completeopt-=preview " disable split with documentation on autocomplete
" }}}

" Mappings {{{
" fast way to edit and reload vimrc:
nnoremap <leader>ev :vsplit $MYVIMRC<cr>
nnoremap <leader>sv :source $MYVIMRC<cr>
nnoremap <leader>rw :%s/\<<C-r><C-w>\>//g<Left><Left>
vnoremap <C-r> "hy:%s/<C-r>h//gc<Left><Left><Left>
" }}}

" Vimscript file settings {{{
augroup filetype_vim
    autocmd!
    autocmd FileType vim setlocal foldmethod=marker
augroup END
" }}}

" Statusline {{{
set laststatus=2 "always visible
set statusline=%f " file path
set statusline+=%= " right align
set statusline+=%k " keymap name
set statusline+=\  " space as separator
set statusline+=%{&fileformat} " unix/dos/mac
set statusline+=\  " space as separator
set statusline+=%{&fileencoding} " file encoding
set statusline+=\  " space as separator
set statusline+=%y " filetype
" }}}
