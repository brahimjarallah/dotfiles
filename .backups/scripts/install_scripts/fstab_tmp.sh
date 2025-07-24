#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

#!/bin/bash
set -e

# Variables
UUID="a32332e6-4a1a-4cdf-94b2-d311ba1ea22a"
MOUNTPOINT="/.snapshots"
SUBVOL=".snapshots"

echo "🔧 Creating mount point ${MOUNTPOINT} if it doesn't exist..."
sudo mkdir -p "$MOUNTPOINT"

echo "📝 Backing up current /etc/fstab to /etc/fstab.bak..."
sudo cp /etc/fstab /etc/fstab.bak

echo "📝 Updating /etc/fstab entry for snapshots..."

# Remove existing snapshots mount lines (if any)
sudo sed -i '/[[:space:]]\/\.snapshots[[:space:]]/d' /etc/fstab

# Add correct mount entry
echo "UUID=${UUID} ${MOUNTPOINT} btrfs rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=${SUBVOL} 0 0" | sudo tee -a /etc/fstab

echo "🔄 Mounting ${MOUNTPOINT}..."
sudo mount "$MOUNTPOINT"

echo "✅ Snapshots mount setup complete. Current mounts:"
mount | grep "$MOUNTPOINT"

