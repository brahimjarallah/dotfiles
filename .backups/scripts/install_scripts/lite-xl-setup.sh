#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

#!/bin/bash

# Lite XL setup script for Arch Linux + Hyprland
# Theme: Catppuccin Mocha Blue
#
#

yay -S ttf-fira-code ttf-jetbrains-mono

set -e

echo "🔧 Installing Lite XL and plugins..."
yay -S --noconfirm lite-xl lite-xl-plugins

echo "🎨 Setting up Catppuccin Mocha Blue theme for Lite XL..."

# Config directory
CONFIG_DIR="$HOME/.config/lite-xl"
mkdir -p "$CONFIG_DIR"

# Clone Catppuccin theme
THEME_DIR="$CONFIG_DIR/themes"
mkdir -p "$THEME_DIR"
curl -L https://raw.githubusercontent.com/catppuccin/lite-xl/main/themes/catppuccin-mocha.lua -o "$THEME_DIR/catppuccin-mocha.lua"

# Set theme in config
INIT_FILE="$CONFIG_DIR/init.lua"
cat > "$INIT_FILE" << 'EOF'
-- Lite XL Init.lua Config
local core = require "core"
local config = require "core.config"

-- Set Theme
core.reload_module("colors.catppuccin-mocha")

-- UI Settings
config.scale_mode = "dpi"
config.fps = 144
config.max_log_items = 200
config.scroll_past_end = true
config.ignore_files = {"%.git/", "node_modules/", "%.o$", "%.a$", "%.class$", "%.pyc$"}

-- Default font
config.font = renderer.font.load(DATADIR .. "/fonts/FiraCode-Regular.ttf", 14 * SCALE)
config.code_font = renderer.font.load(DATADIR .. "/fonts/FiraCode-Regular.ttf", 14 * SCALE)

-- Plugins
require "plugins.autosave"
require "plugins.detectindent"
require "plugins.lineguide"
require "plugins.trimwhitespace"

EOF

echo "📦 Installing recommended plugins..."
PLUGIN_DIR="$CONFIG_DIR/plugins"
mkdir -p "$PLUGIN_DIR"

cd "$PLUGIN_DIR"

declare -a PLUGINS=(
  "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autosave.lua"
  "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/lineguide.lua"
  "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/detectindent.lua"
  "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/trimwhitespace.lua"
)

for PLUGIN in "${PLUGINS[@]}"; do
  wget "$PLUGIN"
done

echo "🎉 Lite XL installed and themed with Catppuccin Mocha!"
echo "✅ Launch with: lite-xl"

