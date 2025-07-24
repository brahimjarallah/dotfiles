" Save with Ctrl-s in normal and insert mode
nnoremap <C-s> :w<CR>
inoremap <C-s> <Esc>:w<CR>a
vnoremap <C-s> <Esc>:w<CR>gv



" Force save with Ctrl+Alt+S in normal, insert, and visual modes
nnoremap <C-M-S> :w!<CR>
inoremap <C-M-S> <Esc>:w!<CR>a
vnoremap <C-M-S> <Esc>:w!<CR>gv

