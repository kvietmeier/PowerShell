" Basic .vimrc
" Created by Karl Vietmeier

" vi compatibility
"set compatible
set nocompatible

" Show line numbers, file stats, and status bar
"set number
set ruler
set laststatus=2

" Last line
set showmode
set showcmd

" Whitespace/formatting/code
syntax on
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set autoindent
"set si "Smart indent
set showmatch
"set wrap
"set textwidth=72
"set formatoptions=tcqrn1


" Turn backup off, since most stuff is in SVN, git et.c anyway...
set nobackup
set nowb
set noswapfile


" Color scheme (terminal)
"colorscheme desert
set t_Co=256
set background=dark


""" For solarized color scheme
""" put https://raw.github.com/altercation/vim-colors-solarized/master/colors/solarized.vim
""" in ~/.vim/colors/ and uncomment:
"let g:solarized_termcolors=256
"let g:solarized_termtrans=1
"colorscheme solarized