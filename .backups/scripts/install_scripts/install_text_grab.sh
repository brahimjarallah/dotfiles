#!/usr/bin/env bash
# Arch Linux text-grab installer script

set -e

# Install dependencies
echo "==> Installing dependencies..."
sudo pacman -S --needed git meson ninja tesseract tesseract-data-eng base-devel --noconfirm

# Clone the repo
echo "==> Cloning text-grab repository..."
git clone https://github.com/AlynxZhou/text-grab.git ~/text-grab

#git clone git://github.com/AlynxZhou/text-grab.git ~/text-grab


# Build
cd ~/text-grab
echo "==> Setting up build..."
meson setup build
echo "==> Compiling..."
meson compile -C build

# Install
echo "==> Installing..."
sudo meson install -C build

# Clean up
echo "==> Cleaning up..."
cd ~
rm -rf ~/text-grab

echo ""
echo "✅ text-grab installed successfully!"
echo ""

# Suggest Hyprland keybind
cat <<EOF

🌟 To bind text-grab to a hotkey in Hyprland, add this to your hyprland.conf:

bind = SUPER, T, exec, text-grab

Then reload Hyprland config or restart Hyprland.

✅ Usage:
Press SUPER+T, draw a rectangle, and text will be copied to your clipboard automatically.

EOF

