#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

# Real rsync backup (remove --dry-run)
sudo rsync -av \
    --exclude="/dev/*" \
    --exclude="/proc/*" \
    --exclude="/sys/*" \
    --exclude="/tmp/*" \
    --exclude="/run/*" \
    --exclude="/mnt/*" \
    --exclude="/media/*" \
    --exclude="/lost+found" \
    --exclude="/var/tmp/*" \
    --exclude="/var/cache/pacman/pkg/*" \
    --exclude="/.snapshots/*" \
    --exclude="/home/*/.cache/*" \
    --exclude="/home/*/.local/share/Trash/*" \
    / /mnt/backup/rsync-repo/
