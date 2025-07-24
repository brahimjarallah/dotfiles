#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting FreeCAD Pro installation on Arch (Hyprland)..."

# 1. Ensure yay is installed
if ! command -v yay &>/dev/null; then
  echo "🔧 Installing yay..."
  sudo pacman -S --needed --noconfirm base-devel git
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
fi

# 2. Remove freecad if installed
if pacman -Qi freecad &>/dev/null; then
  echo "🧹 Removing official freecad to avoid conflicts..."
  sudo pacman -Rns --noconfirm freecad
else
  echo "ℹ️ freecad not installed, skipping removal."
fi

# 3. Remove med if installed (to allow med-openmpi)
if pacman -Qi med &>/dev/null; then
  echo "🧹 Removing med to avoid conflicts with med-openmpi..."
  sudo pacman -Rns --noconfirm med
else
  echo "ℹ️ med not installed, skipping removal."
fi

# 4. Install med-openmpi (needed for advanced FEM)
echo "📦 Installing med-openmpi..."
yay -S --noconfirm med-openmpi

# 5. IMPORTANT: DO NOT install hdf5-openmpi to avoid breaking other packages

echo "⚠️ Skipping hdf5-openmpi installation to maintain system stability."

# 6. Install freecad-git (builds from latest sources and compatible with med-openmpi)
echo "🛠️ Installing freecad-git (this will take some time)..."
yay -S --noconfirm freecad-git

# 7. Install core CAD/FEM tools compatible with med-openmpi (no hdf5-openmpi)
echo "📦 Installing core CAD/FEM tools..."
yay -S --noconfirm calculix-ccx elmerfem gmsh paraview openscad povray blender

# 8. Install Python scientific packages for scripting/macros
echo "🐍 Installing/upgrading Python scientific packages..."
pip install --user --upgrade numpy scipy matplotlib pandas sympy jupyter ipython vtk

# 9. Clone essential FreeCAD workbenches into ~/.FreeCAD/Mod
echo "🔧 Installing FreeCAD workbenches..."
mkdir -p ~/.FreeCAD/Mod
cd ~/.FreeCAD/Mod

git clone https://github.com/Zolko-123/FreeCAD_Assembly4.git Assembly4
git clone https://github.com/kbwbe/A2plus.git A2plus
git clone https://github.com/shaise/FreeCAD_SheetMetal.git SheetMetal
git clone https://github.com/FreeCAD/FreeCAD-Fasteners.git Fasteners
git clone https://github.com/FreeCAD/FreeCAD-ExplodedAssembly.git ExplodedAssembly
git clone https://github.com/FreeCAD/FreeCAD-macros.git Macros

# 10. Performance tuning: enable OpenMP threading
echo 'export OMP_NUM_THREADS=$(nproc)' >> ~/.bashrc
export OMP_NUM_THREADS=$(nproc)

# 11. Cleanup orphaned packages
echo "🧹 Cleaning up orphaned packages..."
yay -Yc --noconfirm || echo "⚠️ No orphaned packages found."

echo "✅ FreeCAD Pro setup complete!"
echo "💡 Launch FreeCAD via 'freecad' command."

