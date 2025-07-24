#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/usr/bin/env bash
set -e

echo "[+] Installing lf and core dependencies..."
yay -S --noconfirm --needed \
  lf bat fzf fd ripgrep highlight poppler \
  ffmpegthumbnailer zathura zathura-pdf-mupdf \
  mediainfo odt2txt pandoc exiftool \
  kitty-terminfo jq wl-clipboard \
  ueberzugpp || echo "Some optional packages skipped."

mkdir -p ~/.config/lf
mkdir -p ~/.local/bin

echo "[+] Writing lf config (lfrc)..."
cat << 'EOF' > ~/.config/lf/lfrc
set shell zsh
set shellopts '-c'
set previewer ~/.config/lf/previewer.sh
set cleaner ~/.config/lf/cleaner.sh
set drawbox true
set icons true
set number true
set scrolloff 10
set period 0
set dirfirst true

map l open
map h up
map j down
map k updir
map q quit
map gh cd ~
map gd cd ~/Downloads
map gp cd ~/Pictures
map / search
map n search-next
map N search-prev
map i shell ~/.config/lf/info.sh
map y copy
map p paste
map d delete
map r rename
map S shell ~/.config/lf/scripts/open_in_term.sh
EOF

echo "[+] Writing previewer.sh..."
cat << 'EOF' > ~/.config/lf/previewer.sh
#!/usr/bin/env bash

file="$1"
mime=$(file -Lb --mime-type "$file")

# Image previews
if [[ "$mime" =~ image/* ]]; then
  if [[ -n "$KITTY_WINDOW_ID" ]]; then
    kitty +kitten icat --transfer-mode=file "$file"
    exit
  elif command -v ueberzugpp &>/dev/null; then
    ueberzugpp layer --parser bash --silent < <(
      printf 'add [identifier]="preview" [path]="%s" [x]="0" [y]="0" [width]=40 [height]=20\n' "$file"
      sleep 1
    )
    exit
  elif command -v swayimg &>/dev/null; then
    swayimg "$file"
    exit
  fi
fi

# PDF preview
if [[ "$mime" == application/pdf ]]; then
  if command -v pdftotext &>/dev/null; then
    pdftotext "$file" - | head -n 100
  elif command -v zathura &>/dev/null; then
    zathura "$file" &
    exit
  fi
  exit
fi

# Office files
if [[ "$file" == *.docx || "$file" == *.pptx || "$file" == *.xlsx ]]; then
  pandoc "$file"
  exit
fi

# Audio / Video preview
if [[ "$mime" =~ audio/* ]]; then
  mediainfo "$file" || exiftool "$file"
  exit
elif [[ "$mime" =~ video/* ]]; then
  ffmpegthumbnailer -i "$file" -o /tmp/thumb.png -s 0
  [[ -f /tmp/thumb.png ]] && kitty +kitten icat /tmp/thumb.png
  exit
fi

# JSON, XML, code files
case "$file" in
  *.json) jq . "$file" ;;
  *.xml)  bat --language=xml "$file" ;;
  *)      bat --paging=never --color=always "$file" ;;
esac
EOF

chmod +x ~/.config/lf/previewer.sh

echo "[+] Writing cleaner.sh..."
cat << 'EOF' > ~/.config/lf/cleaner.sh
#!/bin/sh
killall ueberzugpp &>/dev/null || true
rm -f /tmp/thumb.png
EOF
chmod +x ~/.config/lf/cleaner.sh

echo "[+] Writing info.sh..."
cat << 'EOF' > ~/.config/lf/info.sh
#!/bin/sh
file --brief --mime "$1"
EOF
chmod +x ~/.config/lf/info.sh

echo "[+] Writing open_in_term.sh..."
mkdir -p ~/.config/lf/scripts
cat << 'EOF' > ~/.config/lf/scripts/open_in_term.sh
#!/bin/sh
kitty sh -c "cd \"$PWD\"; exec \$SHELL"
EOF
chmod +x ~/.config/lf/scripts/open_in_term.sh

echo "[✔] Done! lf is now a powerful file manager with full previews on Hyprland."
echo "Run it with: lf"

