#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


# Install
sudo pacman -S grim slurp tesseract tesseract-data-eng

echo '# Direct OCR to clipboard'
echo 'grim -g "$(slurp)" - | tesseract stdin stdout | wl-copy'

echo '# Create a keybind in hyprland.conf'
echo '#bind = $mainMod SHIFT, T, exec, grim -g "$(slurp)" - | tesseract stdin stdout | wl-copy'
