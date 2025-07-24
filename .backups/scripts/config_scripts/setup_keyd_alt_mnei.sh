#!/bin/bash
set -e

echo "Installing keyd if not installed..."
if ! command -v keyd &>/dev/null; then
  sudo pacman -Sy --noconfirm keyd
else
  echo "keyd already installed."
fi

echo "Creating /etc/keyd/default.conf with Alt+mnei remaps..."
sudo tee /etc/keyd/default.conf > /dev/null <<EOF
[ids]

*

[main]
# Alt + mnei => arrow keys
alt+m = left
alt+n = down
alt+e = up
alt+i = right

# Optional: disable original arrows (uncomment if needed)
# left = void
# right = void
# up = void
# down = void
EOF

echo "Enabling and starting keyd service..."
sudo systemctl enable --now keyd

echo "Checking keyd status..."
systemctl status keyd --no-pager

echo "Setup complete! Test Alt+m, Alt+n, Alt+e, Alt+i as arrow keys."

