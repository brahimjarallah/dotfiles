#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/usr/bin/env bash

set -euo pipefail

echo "📦 Installing GIMP and BIMP via Flatpak..."

# Step 1: Ensure Flatpak is installed
if ! command -v flatpak &>/dev/null; then
  echo "🔧 Flatpak not found, installing..."
  sudo pacman -Syu --noconfirm flatpak
fi

# Step 2: Add Flathub repo if not already added
if ! flatpak remotes | grep -q flathub; then
  echo "🔗 Adding Flathub remote..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Step 3: Install GIMP
echo "🎨 Installing GIMP..."
flatpak install -y flathub org.gimp.GIMP

# Step 4: Install BIMP plugin
echo "🧩 Installing BIMP plugin..."
flatpak install -y flathub org.gimp.GIMP.Plugin.BIMP

# Step 5: Done
echo "✅ GIMP and BIMP plugin installed via Flatpak successfully!"

