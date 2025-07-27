#!/bin/bash
set -euo pipefail

# Variables: update as needed
ROOT_UUID="a32332e6-4a1a-4cdf-94b2-d311ba1ea22a"
BOOT_DEVICE="/dev/sda1"                  # EFI system partition
BACKUP_UUID="582ACA555F8EFE82"           # Backup disk partition
BORG_REPO="/mnt/backup/borg-repo"
ARCHIVE_NAME="archlinux-2025-07-27-090059"

# 1. Mount the root subvolume (@)
echo "Mounting root subvolume..."
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@ UUID=$ROOT_UUID /mnt/new-root

# 2. Mount other Btrfs subvolumes
echo "Mounting other subvolumes..."
mkdir -p /mnt/new-root/home
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@home UUID=$ROOT_UUID /mnt/new-root/home

mkdir -p /mnt/new-root/var/cache/pacman/pkg
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@pkg UUID=$ROOT_UUID /mnt/new-root/var/cache/pacman/pkg

mkdir -p /mnt/new-root/var/log
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@log UUID=$ROOT_UUID /mnt/new-root/var/log

mkdir -p /mnt/new-root/.snapshots
mount -o rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@snapshots UUID=$ROOT_UUID /mnt/new-root/.snapshots

# 3. Mount /boot (EFI partition)
echo "Mounting /boot..."
mkdir -p /mnt/new-root/boot
mount $BOOT_DEVICE /mnt/new-root/boot

# 4. Mount backup disk containing Borg repo
echo "Mounting backup disk..."
mkdir -p /mnt/backup
mount -o defaults,noatime,nofail,x-systemd.automount,x-systemd.device-timeout=10 UUID=$BACKUP_UUID /mnt/backup

# 5. Install borg if not present (optional)
if ! command -v borg &> /dev/null; then
  echo "Installing borg..."
  pacman -Sy --noconfirm borg
fi

# 6. Set Borg passphrase (if encrypted)
# export BORG_PASSPHRASE='your-passphrase'

# 7. Extract your full system backup to mounted root
echo "Extracting Borg backup..."
borg extract --verbose $BORG_REPO::$ARCHIVE_NAME -C /mnt/new-root

# 8. Prepare for chroot
echo "Preparing chroot environment..."
mount --bind /dev /mnt/new-root/dev
mount --bind /proc /mnt/new-root/proc
mount --bind /sys /mnt/new-root/sys
mount --bind /run /mnt/new-root/run

# 9. Enter chroot to finalize recovery
echo "Entering chroot. Run bootloader reinstall and update initramfs manually:"
arch-chroot /mnt/new-root /bin/bash

# --- Inside chroot you should run commands like: ---
# grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
# grub-mkconfig -o /boot/grub/grub.cfg
# mkinitcpio -P
# passwd  # reset root password if needed
# exit

# 10. Cleanup (after exiting chroot)
echo "Cleaning up mounts..."
umount /mnt/new-root/dev
umount /mnt/new-root/proc
umount /mnt/new-root/sys
umount /mnt/new-root/run

echo "Recovery complete. Reboot your system."

