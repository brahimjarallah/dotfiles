#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"


#!/usr/bin/env bash
set -e

echo "🛠️  Pre-creating required config files..."
sudo mkdir -p /etc/conf.d
echo "# empty conf to satisfy snap-pac" | sudo tee /etc/conf.d/snapper > /dev/null

echo "📦 Installing snapper, snap-pac, grub-btrfs-git..."
yay -S snapper snap-pac grub-btrfs-git --noconfirm

echo "🔧 Creating Snapper config for root..."
sudo snapper -c root create-config /

echo "📁 Creating .snapshots mount point and setting permissions..."
sudo mkdir -p /.snapshots
sudo mount -a
sudo chmod 750 /.snapshots
sudo chown :wheel /.snapshots

echo "🕒 Enabling Snapper systemd timers..."
sudo systemctl enable --now snapper-timeline.timer
sudo systemctl enable --now snapper-cleanup.timer

echo "📂 Enabling grub-btrfs systemd daemon..."
sudo systemctl enable --now grub-btrfsd.service

echo "🔄 Generating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

echo "✅ Snapper + grub-btrfs setup is complete!"

