#!/bin/bash

# Define variables
LAYOUT_DIR="$HOME/.config/klavaro/layouts"
LAYOUT_FILE="$LAYOUT_DIR/colemak_mod-dh.xml"
SYSTEM_LAYOUT_DIR="/usr/share/klavaro/layouts"

# Create the directory if it doesn't exist
mkdir -p "$LAYOUT_DIR"

# Write the Colemak Mod-DH XML layout to the file
cat > "$LAYOUT_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<keyboard_layout name="Colemak Mod-DH" author="Custom Script" description="Colemak Mod-DH Layout for Klavaro">
  <rows>
    <row>
      <key>q</key> <key>w</key> <key>f</key> <key>p</key> <key>g</key> <key>j</key> <key>l</key> <key>u</key> <key>y</key> <key>;</key>
    </row>
    <row>
      <key>a</key> <key>r</key> <key>s</key> <key>t</key> <key>d</key> <key>h</key> <key>n</key> <key>e</key> <key>i</key> <key>o</key>
    </row>
    <row>
      <key>z</key> <key>x</key> <key>c</key> <key>d</key> <key>v</key> <key>b</key> <key>k</key> <key>m</key> <key>,</key> <key>.</key>
    </row>
  </rows>
</keyboard_layout>
EOF

echo "Custom Colemak Mod-DH layout saved to $LAYOUT_FILE"

# Optional: Copy to system-wide folder (comment out if you don't want this)
read -p "Copy layout to system folder for global availability? (requires sudo) [y/N]: " choice
if [[ "$choice" =~ ^[Yy]$ ]]; then
  sudo cp "$LAYOUT_FILE" "$SYSTEM_LAYOUT_DIR/"
  echo "Copied to $SYSTEM_LAYOUT_DIR/"
fi

echo "You can now launch Klavaro and select the 'Colemak Mod-DH' layout."

