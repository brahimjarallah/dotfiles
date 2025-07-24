#!/usr/bin/env bash
set -euo pipefail

echo "=== 🧠 Updating system and installing qutebrowser + tools ==="
sudo pacman -Syu --noconfirm qutebrowser alacritty pass python-pyqt5 python-pip curl

echo "=== 🗂️  Creating qutebrowser config directory ==="
mkdir -p ~/.config/qutebrowser

echo "=== 📥 Downloading dwt1's qutebrowser config.py ==="
curl -fsSL https://gitlab.com/dwt1/dotfiles/-/raw/master/.config/qutebrowser/config.py -o ~/.config/qutebrowser/config.py

echo "=== 🔐 Installing qute-pass userscript from robertfoster/qute-pass ==="
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/robertfoster/qute-pass/master/qute-pass -o ~/.local/bin/qute-pass
chmod +x ~/.local/bin/qute-pass

echo "=== 🧼 Ensuring ~/.local/bin is in PATH ==="
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    export PATH="$HOME/.local/bin:$PATH"
fi

echo "=== ✅ DONE ==="
echo "Launch with: qutebrowser"
echo "Or bind in Hyprland with:"
echo ""
echo "   bind = \$mainMod, G, exec, qutebrowser --basedir ~/.config/qutebrowser"
echo ""
echo "Try ',p' inside qutebrowser to test password integration (requires pass + gpg setup)"

