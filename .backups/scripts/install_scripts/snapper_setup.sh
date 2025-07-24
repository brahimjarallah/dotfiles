# Remove partial installs if any
sudo pacman -Rdd snapper snap-pac grub-btrfs --noconfirm || true
sudo rm -rf /etc/snapper

# Install snapper only
yay -S snapper --noconfirm

# Create root config (mandatory)
sudo snapper -c root create-config /

# Create .snapshots mountpoint and mount
sudo mkdir -p /.snapshots
sudo mount -a

# Now install snap-pac and grub-btrfs
yay -S snap-pac grub-btrfs-git --noconfirm

# Enable timers and service
sudo systemctl enable --now snapper-timeline.timer snapper-cleanup.timer grub-btrfsd.service

# Regenerate grub config
sudo grub-mkconfig -o /boot/grub/grub.cfg

