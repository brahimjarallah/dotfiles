#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/usr/bin/env bash
set -euo pipefail

echo "🚀 Starting full STM32CubeIDE installation with yay and essential tools..."

# Check if yay is installed
if ! command -v yay &>/dev/null; then
  echo "❌ yay not found! Please install yay first."
  exit 1
fi

# Update system and AUR packages
echo "🔄 Updating system and AUR packages..."
yay -Syu --noconfirm

# Install STM32CubeIDE from AUR (usually named stm32cubeide)
echo "📦 Installing STM32CubeIDE from AUR..."
yay -S --noconfirm stm32cubeide

# Install essential STM32 development tools from official repos
echo "🛠 Installing essential development tools: arm-none-eabi-gcc, openocd, stlink, dfu-util, and cmake..."
sudo pacman -S --noconfirm arm-none-eabi-gcc arm-none-eabi-newlib openocd stlink dfu-util cmake

# Optional: install git if not present (very recommended)
if ! command -v git &>/dev/null; then
  echo "🔧 Installing git..."
  sudo pacman -S --noconfirm git
fi

# Optional: install minicom or picocom for serial debugging
echo "🔧 Installing minicom and picocom for serial terminal access..."
sudo pacman -S --noconfirm minicom picocom

# Optional: udev rules for ST-Link (should come with stlink package but verify)
echo "🔧 Setting up udev rules for ST-Link..."
sudo cp /usr/lib/udev/rules.d/49-stlinkv2.rules /etc/udev/rules.d/ || echo "Udev rules file not found, skipping"
sudo udevadm control --reload-rules
sudo udevadm trigger

echo "✅ STM32CubeIDE and development tools installed successfully!"
echo "You can now launch STM32CubeIDE by running: stm32cubeide"

