#!/bin/bash
# Install dependencies and Pylote from AUR
sudo pacman -S --needed base-devel git python-pyqt5
yay -S pylote-git

# Ensure Wayland dependencies for Hyprland
sudo pacman -S xdg-desktop-portal-hyprland

# Add Hyprland window rules to prevent rendering issues
echo -e "windowrulev2 = noblur, class:^(pylote)$\nwindowrulev2 = opacity 1 override, 1 override, class:^(pylote)$" >> ~/.config/hypr/windowrules.conf

# Source window rules in Hyprland config if not already present
if ! grep -q "source = ~/.config/hypr/windowrules.conf" ~/.config/hypr/hyprland.conf; then
    echo "source = ~/.config/hypr/windowrules.conf" >> ~/.config/hypr/hyprland.conf
fi

# Optional: Add keybinding to launch Pylote (SUPER + D)
echo "bind = \$mainMod, D, exec, pylote" >> ~/.config/hypr/hyprland.conf

# Reload Hyprland configuration
hyprctl reload

# Notify user
echo "Pylote installed and configured! Press SUPER + D to launch, or run 'pylote' manually."
