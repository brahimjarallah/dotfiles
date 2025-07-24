#!/bin/bash

# Install neovim and xclip
sudo pacman -S --noconfirm neovim xclip

# Create config directory if needed
mkdir -p ~/.config/nvim

# Write init.vim
cat > ~/.config/nvim/init.vim <<'EOF'
" Save with Ctrl+`
nnoremap <C-`> :w<CR>
inoremap <C-`> <Esc>:w<CR>a

" Copy visual selection with Alt+Shift+`
vnoremap <A-S-`> "+y

" Copy all buffer with Ctrl+Shift+`
nnoremap <C-S-`> :%y+<CR>
EOF

echo "Neovim installed and configured!"

