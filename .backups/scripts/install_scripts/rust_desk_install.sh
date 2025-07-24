#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

#!/bin/bash
set -e

echo "📦 Installing RustDesk via Flatpak..."

# Step 1: Ensure Flatpak is installed
if ! command -v flatpak &> /dev/null; then
  echo "⚠️ Flatpak not found. Installing it..."
  sudo pacman -S --noconfirm flatpak
fi

# Step 2: Add Flathub repository (if not already added)
if ! flatpak remote-list | grep -q flathub; then
  echo "🔗 Adding Flathub remote..."
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
fi

# Step 3: Install RustDesk
echo "🚀 Installing RustDesk from Flathub..."
flatpak install -y flathub com.github.rustdesk.RustDesk

echo "✅ RustDesk Flatpak installed successfully!"
echo "👉 Launch it with: flatpak run com.github.rustdesk.RustDesk"

