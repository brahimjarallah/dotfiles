#!/bin/bash
echo "Testing Swappy functionality..."

echo "1. Testing grim..."
if command -v grim &> /dev/null; then
    echo "✓ grim is installed"
else
    echo "✗ grim is NOT installed"
fi

echo "2. Testing slurp..."
if command -v slurp &> /dev/null; then
    echo "✓ slurp is installed"
else
    echo "✗ slurp is NOT installed"
fi

echo "3. Testing swappy..."
if command -v swappy &> /dev/null; then
    echo "✓ swappy is installed"
else
    echo "✗ swappy is NOT installed"
fi

echo "4. Testing wl-clipboard..."
if command -v wl-copy &> /dev/null; then
    echo "✓ wl-clipboard is installed"
else
    echo "✗ wl-clipboard is NOT installed"
fi

echo ""
echo "Configuration files:"
echo "Swappy config: ~/.config/swappy/config"
echo "Screenshots dir: ~/Downloads"
echo "Keybindings: ~/.config/hypr/keybindings.conf"
echo ""
echo "Keybindings:"
echo "Super + Shift + S: Screenshot selected area and annotate"
echo "Super + Shift + F: Screenshot full screen and annotate"
echo "Super + Shift + A: Screenshot area to file then annotate"
echo ""
echo "To reload Hyprland config: hyprctl reload"
