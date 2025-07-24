#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting full FreeCAD professional installation script..."

# 1. Update system and install yay if not present
if ! command -v yay &> /dev/null; then
  echo "🔧 yay not found, installing base-devel and git first..."
  sudo pacman -S --needed --noconfirm base-devel git
  echo "🔧 Cloning yay..."
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  cd /tmp/yay
  makepkg -si --noconfirm
  cd -
fi

echo "⬆️ Updating system..."
sudo pacman -Syu --noconfirm

# 2. Install FreeCAD base package from official repo (stable)
echo "📦 Installing FreeCAD base package..."
sudo pacman -S --noconfirm freecad

# 3. Install extra FreeCAD workbenches/plugins from AUR
echo "📦 Installing FreeCAD additional workbenches/plugins..."

yay -S --noconfirm \
  freecad-addons           \
  freecad-assembly4       \
  freecad-a2plus          \
  freecad-sheetmetal      \
  freecad-fem-tools       \
  freecad-raytracing      \
  freecad-fasteners       \
  freecad-robot           \
  freecad-surface         \
  freecad-toolpath        \
  freecad-drawing         \
  freecad-macro-library

# 4. Install dependencies and related CAD/CAE tools
echo "📦 Installing dependencies and CAD/CAE tools..."

sudo pacman -S --noconfirm \
  python python-pip python-numpy python-scipy python-matplotlib \
  opencascade           \
  vtk                   \
  qt5-base qt5-svg qt5-declarative \
  openscenegraph        \
  openblas              \
  gcc-fortran           \
  gnuplot               \
  cmake                 \
  blender               \
  openscad              \
  povray                \
  git                   \
  meshlab               \
  vtk-python            \
  eigen                 \
  boost                 \
  libusb                \
  boost-libs            \
  openmpi               \
  mpich                 \
  libx11                \
  freeglut              \
  glew                  \
  qt5-tools             \
  qt5-webengine

# 5. Install FEM solvers/tools (for simulation)
echo "📦 Installing FEM solvers and simulation tools..."

yay -S --noconfirm \
  salome-meca           \
  calculix-ccx          \
  elmer                 \
  openfoam              \
  paraview              \
  gmsh

# 6. Setup Python environment for FreeCAD scripting and macros
echo "🐍 Setting up Python environment..."

pip install --user --upgrade \
  numpy scipy matplotlib pandas sympy vtk jupyter ipython pyqt5

# 7. Install FreeCAD user addons manager (for easier plugin management inside FreeCAD)
echo "🔧 Installing FreeCAD Addon Manager..."

mkdir -p ~/.FreeCAD/Mod
cd ~/.FreeCAD/Mod
git clone https://github.com/FreeCAD/FreeCAD-addons.git AddonManager

# 8. Optional: Enable some performance tweaks (OpenMP threads etc)
echo "⚙️ Setting environment variables for better performance..."

echo 'export OMP_NUM_THREADS=$(nproc)' >> ~/.bashrc
export OMP_NUM_THREADS=$(nproc)

# 9. Cleanup
echo "🧹 Cleaning up..."

yay -Yc --noconfirm

echo "✅ FreeCAD full professional environment setup complete!"
echo "Run FreeCAD and use Addon Manager to install more workbenches or macros as needed."

exit 0

