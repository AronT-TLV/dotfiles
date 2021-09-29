tnoremap <Esc> <C-\><C-n>
tnoremap <C-v><Esc> <Esc>
nnoremap <M-h> <c-w>h
nnoremap <M-j> <c-w>j
nnoremap <M-k> <c-w>k
nnoremap <M-l> <c-w>l
nnoremap <M-^> <C-^>
tnoremap <M-h> <c-\><c-n><c-w>h
tnoremap <M-j> <c-\><c-n><c-w>j
tnoremap <M-j> <c-\><c-n><c-w>k
tnoremap <M-j> <c-\><c-n><c-w>l

" automated installation of vimplug
if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
  silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" package manager vim-plug
call plug#begin('~/.config/nvim/plugged')

" language support
Plug 'JuliaEditorSupport/julia-vim'
call plug#end()

filetype plugin indent on

" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
" silent! helptags ALL