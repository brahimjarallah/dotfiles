#!/usr/bin/env bash
set -euo pipefail

echo "🛠️ Starting full KiCad professional installation on Arch Linux..."

# Step 1: System update
sudo pacman -Syu --noconfirm

# Step 2: Install base development tools
sudo pacman -S --noconfirm base-devel git cmake meson boost pkgconf

# Step 3: Install KiCad (includes symbols, footprints, 3D packages)
sudo pacman -S --noconfirm kicad

# Step 4: Install KiCad-related tools and plugins from AUR
echo "📦 Installing KiCad AUR plugins and utilities with yay..."
yay -S --noconfirm \
  kicad-plugin-manager \
  kicad-diff \
  kicad-autorouter-icy \
  kicad-cli \
  kicad-jlcpcb-panelizer \
  kicad-3d-models-git

# Step 5: AI-assisted and advanced routing tools (experimental)
yay -S --noconfirm \
  icarus-ai-router-git \
  toporouter

# Step 6: Skipped kicad-automation-scripts — repo no longer available
echo "⚠️ Skipping kicad-automation-scripts installation — upstream repo not found."
echo "You can explore alternatives like 'kikit' or native KiCad Python scripting."

# Step 7: Professional design helper tools
sudo pacman -S --noconfirm \
  git-lfs \
  imagemagick \
  inkscape \
  blender \
  freecad

yay -S --noconfirm wxgtk3 gerbv

# Step 8: Set KiCad environment variables for Zsh
echo "💾 Configuring KiCad environment variables for Zsh..."
{
  echo "export KICAD_SYMBOL_DIR=/usr/share/kicad/symbols"
  echo "export KICAD_FOOTPRINT_DIR=/usr/share/kicad/footprints"
  echo "export KICAD_3DMODEL_DIR=/usr/share/kicad/3dmodels"
} >> ~/.zshrc

# Step 9: Apply .zshrc changes
echo "🔁 Reloading shell configuration..."
source ~/.zshrc

echo -e "\n✅ KiCad professional environment installation complete!"
echo "🚀 Recommendations:"
echo " - Use Plugin & Content Manager inside KiCad."
echo " - Use icarus-ai-router and toporouter for assisted layout."
echo " - Explore alternatives like 'kikit' or native Python scripting for automation."
echo " - Customize themes and performance settings for Hyprland/Wayland."

