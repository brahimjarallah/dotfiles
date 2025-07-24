#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/bin/bash
#!/bin/bash

echo "🔧 Installing Thunar and necessary plugins for Hyprland..."

# Update system
sudo pacman -Syu --noconfirm

# Core Thunar + Plugins
sudo pacman -S --noconfirm thunar \
    thunar-volman \
    thunar-archive-plugin \
    thunar-media-tags-plugin \
    tumbler \
    ffmpegthumbnailer \
    libgsf \
    poppler-glib

# GVFS & UDisks2 for USB mounts, Trash, Networking
sudo pacman -S --noconfirm gvfs \
    gvfs-mtp \
    gvfs-gphoto2 \
    gvfs-afc \
    gvfs-smb \
    gvfs-nfs \
    udisks2

# Archive backends (optional but useful)
sudo pacman -S --noconfirm file-roller \
    p7zip \
    unzip \
    unrar \
    xarchiver

# Enable udisks2
echo "📦 Enabling udisks2..."
sudo systemctl enable --now udisks2.service

# Add user to needed groups
sudo usermod -aG storage,power "$USER"

# Polkit agent (for mounting under Wayland / Hyprland)
sudo pacman -S --noconfirm polkit-gnome

# Hyprland integration reminder
echo -e "\n👉 Add this to your Hyprland config (~/.config/hypr/hyprland.conf):\n"
echo "exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"

echo -e "\n✅ Thunar and all plugins installed successfully!"
echo "🧪 Launch it using: thunar"

