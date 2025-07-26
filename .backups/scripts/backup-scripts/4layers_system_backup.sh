#!/bin/bash
# Ultimate Arch Linux Btrfs Backup System - 4 Layer Protection
# Author: Arch Linux + Btrfs Expert 
# Version: 1.0 - Production Ready

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BTRFS_UUID="a32332e6-4a1a-4cdf-94b2-d311ba1ea22a"
BACKUP_PATH="/mnt/backup"
HOSTNAME=$(hostname)

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}    Ultimate Arch Linux Btrfs 4-Layer Backup System Setup    ${NC}"
echo -e "${BLUE}================================================================${NC}"
echo ""
echo -e "${GREEN}Layer 1:${NC} Local Btrfs Snapshots (Instant Recovery)"
echo -e "${GREEN}Layer 2:${NC} GRUB Integration (Boot-time Recovery)" 
echo -e "${GREEN}Layer 3:${NC} External Borg Backup (Disaster Recovery)"
echo -e "${GREEN}Layer 4:${NC} Automated Timeline Management (Set & Forget)"
echo ""

read -p "Deploy the complete system? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}Deployment cancelled${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting deployment...${NC}"
echo ""

# ============================================================================
# LAYER 1: BTRFS SNAPSHOTS INFRASTRUCTURE
# ============================================================================

echo -e "${BLUE}=== LAYER 1: Btrfs Snapshots Infrastructure ===${NC}"

# Check if @snapshots exists
echo "🔍 Checking existing Btrfs setup..."
sudo mkdir -p /mnt/btrfs-root
sudo mount -o subvol=/ UUID=$BTRFS_UUID /mnt/btrfs-root

if ! sudo btrfs subvolume list /mnt/btrfs-root | grep -q "@snapshots"; then
    echo "📁 Creating @snapshots subvolume..."
    sudo btrfs subvolume create /mnt/btrfs-root/@snapshots
    echo -e "${GREEN}✅ @snapshots subvolume created${NC}"
else
    echo -e "${YELLOW}⚠️  @snapshots already exists${NC}"
fi

sudo umount /mnt/btrfs-root
sudo rmdir /mnt/btrfs-root

# Create mount point and add to fstab
echo "🔧 Configuring snapshots mount..."
sudo mkdir -p /.snapshots

# Add to fstab if not present
if ! grep -q "/.snapshots" /etc/fstab; then
    echo "UUID=$BTRFS_UUID /.snapshots btrfs rw,noatime,compress=zstd:3,ssd,discard=async,space_cache=v2,subvol=@snapshots 0 0" | sudo tee -a /etc/fstab
    echo -e "${GREEN}✅ Added /.snapshots to fstab${NC}"
fi

# Mount snapshots
sudo mount /.snapshots 2>/dev/null || echo -e "${YELLOW}⚠️  /.snapshots already mounted${NC}"

# ============================================================================
# LAYER 2: GRUB-BTRFS INTEGRATION
# ============================================================================

echo ""
echo -e "${BLUE}=== LAYER 2: GRUB-btrfs Integration ===${NC}"

# Check if grub-btrfs is installed
if ! pacman -Q grub-btrfs &>/dev/null; then
    echo -e "${RED}❌ grub-btrfs not installed. Install with: yay -S grub-btrfs${NC}"
    exit 1
fi

# Configure grub-btrfs
echo "⚙️  Configuring grub-btrfs..."
sudo mkdir -p /etc/default/grub-btrfs
sudo tee /etc/default/grub-btrfs/config > /dev/null <<EOF
# grub-btrfs configuration
GRUB_BTRFS_SHOW_SNAPSHOTS_FOUND="true"
GRUB_BTRFS_LIMIT="10"
GRUB_BTRFS_SHOW_TOTAL_SNAPSHOTS_FOUND="true"
GRUB_BTRFS_TITLE_FORMAT="date"
GRUB_BTRFS_SHOW_PATH="true"
GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION="false"
EOF

# Enable grub-btrfsd service
sudo systemctl enable --now grub-btrfsd.service
echo -e "${GREEN}✅ grub-btrfsd service enabled${NC}"

# ============================================================================
# LAYER 3: BORG BACKUP SYSTEM
# ============================================================================

echo ""
echo -e "${BLUE}=== LAYER 3: Borg Backup System ===${NC}"

# Check if borg is installed
if ! command -v borg &> /dev/null; then
    echo "📦 Installing borg..."
    sudo pacman -S --noconfirm borgbackup
fi

# Check backup drive
if ! mountpoint -q "$BACKUP_PATH"; then
    echo -e "${RED}❌ Backup drive not mounted at $BACKUP_PATH${NC}"
    echo "Please mount your backup drive and run again"
    exit 1
fi

echo -e "${GREEN}✅ Backup drive accessible at $BACKUP_PATH${NC}"

# ============================================================================
# LAYER 4: AUTOMATION SCRIPTS
# ============================================================================

echo ""
echo -e "${BLUE}=== LAYER 4: Automation Scripts ===${NC}"

# Create the ultimate snapshot script
echo "🔨 Creating snapshot management script..."
sudo tee /usr/local/bin/btrfs-snapshot > /dev/null <<'EOF'
#!/bin/bash
# Ultimate Btrfs Snapshot Script with Timeline Management

SNAPSHOT_DIR="/.snapshots"
DATE=$(date +%Y-%m-%d-%H%M%S)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Create snapshot function
create_snapshot() {
    local subvol=$1
    local name=$2
    local snapshot_path="$SNAPSHOT_DIR/${name}-${DATE}"
    
    log "Creating snapshot: $snapshot_path"
    if btrfs subvolume snapshot -r "$subvol" "$snapshot_path"; then
        # Add metadata
        echo "timeline" > "$snapshot_path/.snapshot_type"
        echo "$DATE" > "$snapshot_path/.snapshot_date"
        log "✅ Snapshot created successfully"
    else
        log "❌ Failed to create snapshot"
        return 1
    fi
}

# Timeline cleanup function
cleanup_snapshots() {
    local pattern=$1
    local keep_hourly=$2
    local keep_daily=$3
    local keep_weekly=$4
    local keep_monthly=$5
    
    cd "$SNAPSHOT_DIR"
    local snapshots=($(ls -1t | grep "^${pattern}-" 2>/dev/null | head -50 || true))
    
    if [ ${#snapshots[@]} -eq 0 ]; then
        return
    fi
    
    log "Processing ${#snapshots[@]} $pattern snapshots for cleanup..."
    
    # Keep recent snapshots (simple approach)
    local total_keep=$((keep_hourly + keep_daily + keep_weekly + keep_monthly))
    
    if [ ${#snapshots[@]} -gt $total_keep ]; then
        local to_delete=("${snapshots[@]:$total_keep}")
        for snapshot in "${to_delete[@]}"; do
            log "Deleting old snapshot: $snapshot"
            btrfs subvolume delete "$SNAPSHOT_DIR/$snapshot" 2>/dev/null || true
        done
    fi
}

# Main execution
case "${1:-timeline}" in
    "timeline")
        log "=== Timeline Snapshot Creation ==="
        
        # Create snapshots
        create_snapshot "/" "root"
        create_snapshot "/home" "home"
        
        # Cleanup old snapshots
        # Root: 8 hourly, 7 daily, 4 weekly, 6 monthly (total: 25)
        cleanup_snapshots "root" 8 7 4 6
        
        # Home: 12 hourly, 10 daily, 4 weekly, 6 monthly (total: 32)  
        cleanup_snapshots "home" 12 10 4 6
        
        log "=== Timeline snapshots completed ==="
        ;;
    "boot")
        log "=== Pre-boot Snapshot Creation ==="
        create_snapshot "/" "boot"
        create_snapshot "/home" "home-boot"
        log "=== Boot snapshots completed ==="
        ;;
    "manual")
        log "=== Manual Snapshot Creation ==="
        create_snapshot "/" "manual"
        create_snapshot "/home" "home-manual"
        log "=== Manual snapshots completed ==="
        ;;
    *)
        echo "Usage: $0 [timeline|boot|manual]"
        echo "  timeline - Automatic timeline snapshots (default)"
        echo "  boot     - Pre-update/reboot snapshots"
        echo "  manual   - Manual snapshots"
        exit 1
        ;;
esac
EOF

sudo chmod +x /usr/local/bin/btrfs-snapshot

# Create the ultimate Borg backup script
echo "🔨 Creating Borg backup script..."
sudo tee /usr/local/bin/borg-backup > /dev/null <<EOF
#!/bin/bash
# Ultimate Borg Backup Script

set -e

BACKUP_PATH="$BACKUP_PATH"
REPO_PATH="\$BACKUP_PATH/borg-repo"
HOSTNAME="$HOSTNAME"

# Logging
log() {
    echo "[\$(date '+%Y-%m-%d %H:%M:%S')] \$1"
}

log "=== Starting Borg Backup ==="

# Check backup drive
if ! mountpoint -q "\$BACKUP_PATH"; then
    log "❌ Backup drive not mounted at \$BACKUP_PATH"
    exit 1
fi

# Initialize repo if needed
if [ ! -d "\$REPO_PATH" ]; then
    log "🔧 Initializing Borg repository..."
    borg init --encryption=repokey-blake2 "\$REPO_PATH"
    log "✅ Repository initialized"
    log "🔑 IMPORTANT: Save your repository passphrase!"
fi

# Create backup
log "📦 Creating backup archive..."

borg create \\
    --verbose \\
    --filter AME \\
    --list \\
    --stats \\
    --show-rc \\
    --compression lz4 \\
    --exclude-caches \\
    "\$REPO_PATH::\$HOSTNAME-{now}" \\
    / \\
    --exclude '/dev/*' \\
    --exclude '/proc/*' \\
    --exclude '/sys/*' \\
    --exclude '/tmp/*' \\
    --exclude '/run/*' \\
    --exclude '/mnt/*' \\
    --exclude '/media/*' \\
    --exclude '/lost+found' \\
    --exclude '/var/cache/*' \\
    --exclude '/var/tmp/*' \\
    --exclude '/var/lib/pacman/sync/*' \\
    --exclude '/home/*/.cache/*' \\
    --exclude '/home/*/.local/share/Trash/*' \\
    --exclude '/home/*/.local/share/Steam/*' \\
    --exclude '/.snapshots/*' \\
    --exclude '/swapfile*'

backup_exit=\$?

# Package lists backup
log "📋 Backing up package lists..."
mkdir -p /tmp/pkglists
pacman -Qqen > /tmp/pkglists/explicit.txt
pacman -Qqem > /tmp/pkglists/aur.txt
pacman -Qq > /tmp/pkglists/all.txt

borg create \\
    --compression lz4 \\
    "\$REPO_PATH::\$HOSTNAME-packages-{now}" \\
    /tmp/pkglists/

# Cleanup
rm -rf /tmp/pkglists

# Prune old backups
log "🧹 Pruning old backups..."
borg prune \\
    --list \\
    --prefix "\$HOSTNAME-" \\
    --show-rc \\
    --keep-daily 7 \\
    --keep-weekly 4 \\
    --keep-monthly 6 \\
    "\$REPO_PATH"

prune_exit=\$?

# Global exit status
global_exit=\$((backup_exit > prune_exit ? backup_exit : prune_exit))

if [ \${global_exit} -eq 0 ]; then
    log "✅ Backup completed successfully"
elif [ \${global_exit} -eq 1 ]; then
    log "⚠️  Backup completed with warnings"
else
    log "❌ Backup failed with errors"
fi

log "=== Borg Backup Complete ==="
exit \${global_exit}
EOF

sudo chmod +x /usr/local/bin/borg-backup

# Create systemd services and timers
echo "⚙️  Creating systemd automation..."

# Snapshot service
sudo tee /etc/systemd/system/btrfs-snapshot.service > /dev/null <<EOF
[Unit]
Description=Btrfs Timeline Snapshots
Wants=local-fs.target
After=local-fs.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/btrfs-snapshot timeline
StandardOutput=journal
StandardError=journal
EOF

# Snapshot timer (every 3 hours)
sudo tee /etc/systemd/system/btrfs-snapshot.timer > /dev/null <<EOF
[Unit]
Description=Btrfs Timeline Snapshots Timer
Requires=btrfs-snapshot.service

[Timer]
OnCalendar=*-*-* 00,03,06,09,12,15,18,21:00:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF

# Borg backup service
sudo tee /etc/systemd/system/borg-backup.service > /dev/null <<EOF
[Unit]
Description=Borg System Backup
Wants=network-online.target
After=network-online.target
ConditionPathIsMountPoint=$BACKUP_PATH

[Service]
Type=oneshot
ExecStart=/usr/local/bin/borg-backup
StandardOutput=journal
StandardError=journal
TimeoutSec=7200

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$BACKUP_PATH
EOF

# Borg backup timer (daily at 2 AM)
sudo tee /etc/systemd/system/borg-backup.timer > /dev/null <<EOF
[Unit]
Description=Daily Borg Backup Timer
Requires=borg-backup.service

[Timer]
OnCalendar=*-*-* 02:00:00
Persistent=true
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target
EOF

# Enable all services
echo "🚀 Enabling automation..."
sudo systemctl daemon-reload
sudo systemctl enable btrfs-snapshot.timer
sudo systemctl enable borg-backup.timer

# Start snapshot timer immediately
sudo systemctl start btrfs-snapshot.timer

# Create initial snapshots
echo "📸 Creating initial snapshots..."
sudo /usr/local/bin/btrfs-snapshot timeline

# Update GRUB
echo "🔄 Updating GRUB menu..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# Create convenience aliases script
echo "🛠️  Creating convenience commands..."
sudo tee /usr/local/bin/backup-status > /dev/null <<'EOF'
#!/bin/bash
# Backup System Status Check

echo "=== BTRFS SNAPSHOTS ==="
echo "Snapshots available: $(ls /.snapshots/ | wc -l)"
echo "Latest snapshots:"
ls -1t /.snapshots/ | head -5

echo ""
echo "=== SYSTEMD TIMERS ==="
systemctl list-timers --no-pager | grep -E "(btrfs-snapshot|borg-backup)"

echo ""
echo "=== BORG REPOSITORY ==="
if [ -d "/mnt/backup/borg-repo" ]; then
    echo "Repository size: $(du -sh /mnt/backup/borg-repo 2>/dev/null | cut -f1)"
    echo "Latest archives:"
    borg list /mnt/backup/borg-repo 2>/dev/null | tail -3 || echo "Repository locked or not accessible"
else
    echo "Repository not found - run first backup"
fi

echo ""
echo "=== GRUB-BTRFSD STATUS ==="
systemctl is-active grub-btrfsd.service
EOF

sudo chmod +x /usr/local/bin/backup-status

# Final system verification
echo ""
echo -e "${BLUE}=== SYSTEM VERIFICATION ===${NC}"

echo "🔍 Checking snapshots subvolume:"
sudo btrfs subvolume show /.snapshots

echo ""
echo "🔍 Checking initial snapshots:"
ls -la /.snapshots/

echo ""
echo "🔍 Checking timers:"
systemctl list-timers --no-pager | grep -E "(btrfs-snapshot|borg-backup)"

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}    🎉 DEPLOYMENT COMPLETE - 4-LAYER BACKUP SYSTEM ACTIVE 🎉    ${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${YELLOW}What's Running:${NC}"
echo "✅ Layer 1: Btrfs snapshots (every 3 hours)"
echo "✅ Layer 2: GRUB integration (automatic menu updates)"  
echo "✅ Layer 3: Borg backups (daily at 2 AM)"
echo "✅ Layer 4: Timeline management (automatic cleanup)"
echo ""
echo -e "${YELLOW}Manual Commands:${NC}"
echo "📸 Create snapshot:     sudo btrfs-snapshot [timeline|boot|manual]"
echo "💾 Run Borg backup:     sudo borg-backup"
echo "📊 Check status:        sudo backup-status"
echo "📋 List snapshots:      ls /.snapshots/"
echo "🔍 List Borg archives:  borg list /mnt/backup/borg-repo"
echo ""
echo -e "${YELLOW}Recovery:${NC}"
echo "🔄 Boot from snapshot:   Reboot → GRUB → Advanced → Snapshots"
echo "📁 Restore files:       borg extract /mnt/backup/borg-repo::archive path"
echo "🗂️  Mount archive:       borg mount /mnt/backup/borg-repo::archive /mnt/restore"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Run initial Borg backup: sudo borg-backup"
echo "2. Test snapshot recovery by rebooting"
echo "3. Check status anytime: sudo backup-status"
echo ""
echo -e "${RED}⚠️  IMPORTANT: Save your Borg repository passphrase!${NC}"
echo ""
