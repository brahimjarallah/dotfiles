#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

#!/bin/bash
set -e

echo "==> Installing ONLYOFFICE Desktop Editors (binary version)..."
yay -S --noconfirm onlyoffice-bin

echo "==> Installing MS-compatible fonts (for better doc rendering)..."
yay -S --noconfirm ttf-ms-fonts ttf-dejavu ttf-liberation noto-fonts

echo "==> Installing spellcheck dictionaries..."
yay -S --noconfirm hunspell-en_us hunspell-fr hunspell-de hunspell-es

echo "==> Installing plugin requirements..."
yay -S --noconfirm ttf-font-awesome unzip curl nodejs npm

echo "==> Creating ONLYOFFICE plugins directory if not exists..."
mkdir -p ~/.onlyoffice/desktopeditors/plugins

echo "==> Downloading & enabling useful ONLYOFFICE plugins..."
cd ~/.onlyoffice/desktopeditors/plugins

# List of useful plugins to install manually
declare -A plugins
plugins=(
  ["YouTube"]="https://github.com/ONLYOFFICE/onlyoffice-plugins/archive/refs/heads/master.zip"
)

for name in "${!plugins[@]}"; do
  echo "==> Downloading plugin: $name"
  curl -LO "${plugins[$name]}"
  unzip master.zip
  cp -r onlyoffice-plugins-master/* .
  rm -rf onlyoffice-plugins-master master.zip
done

echo "==> Setting GTK theme support for Hyprland compatibility..."
# Optional: if using GTK theme like Adwaita
yay -S --noconfirm gtk3 gtk-engine-murrine gnome-themes-extra

echo "==> ONLYOFFICE Installation Complete!"
echo "Launch it via the app menu or by running: desktopeditors"

