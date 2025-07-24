#!/bin/bash
# =============================================================================
# Comprehensive Arch Linux Backup System Installer
# 3-Layer Strategy: Btrfs Snapshots + Borg Backups + GRUB Integration
# 
# Author: Based on implementation with ibrahim
# Compatible: Arch Linux + Btrfs + Hyprland
# =============================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
SNAPSHOT_DIR="/.snapshots"
BACKUP_MOUNT="/mnt/backup"
BORG_REPO="/mnt/backup/borg-repo"
SCRIPTS_DIR="/usr/local/bin/backup-scripts"
LOG_DIR="/var/log"

# Logging function
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check system compatibility
check_system() {
    log "Checking system compatibility..."
    
    # Check if Arch Linux
    if [[ ! -f /etc/arch-release ]]; then
        error "This script is designed for Arch Linux only."
        exit 1
    fi
    
    # Check if Btrfs root
    if ! findmnt -n -o FSTYPE / | grep -q btrfs; then
        error "Root filesystem is not Btrfs. This script requires Btrfs root."
        exit 1
    fi
    
    # Check if @ and @home subvolumes exist
    if ! sudo btrfs subvolume list / | grep -q "@$"; then
        error "@ subvolume not found. Please ensure proper Btrfs subvolume layout."
        exit 1
    fi
    
    if ! sudo btrfs subvolume list / | grep -q "@home"; then
        error "@home subvolume not found. Please ensure proper Btrfs subvolume layout."
        exit 1
    fi
    
    success "System compatibility check passed!"
}

# Phase 1: Snapshot Infrastructure
setup_snapshot_infrastructure() {
    log "=== PHASE 1: Setting up Snapshot Infrastructure ==="
    
    # Check if @snapshots subvolume exists
    if ! sudo btrfs subvolume list / | grep -q "@snapshots"; then
        info "Creating @snapshots subvolume..."
        sudo btrfs subvolume create /@snapshots
        success "@snapshots subvolume created!"
    else
        info "@snapshots subvolume already exists"
    fi
    
    # Create snapshots directory if it doesn't exist
    if [[ ! -d "$SNAPSHOT_DIR" ]]; then
        sudo mkdir -p "$SNAPSHOT_DIR"
    fi
    
    # Check if @snapshots is in fstab
    if ! grep -q "@snapshots" /etc/fstab; then
        info "Adding @snapshots to /etc/fstab..."
        local uuid=$(findmnt -n -o UUID /)
        local mount_opts=$(findmnt -n -o OPTIONS / | sed 's/subvol=@[^,]*/subvol=@snapshots/')
        echo "UUID=$uuid $SNAPSHOT_DIR btrfs $mount_opts 0 0" | sudo tee -a /etc/fstab
        success "@snapshots added to fstab!"
    else
        info "@snapshots already in fstab"
    fi
    
    # Mount @snapshots if not mounted
    if ! mountpoint -q "$SNAPSHOT_DIR"; then
        info "Mounting @snapshots..."
        sudo mount "$SNAPSHOT_DIR"
        success "@snapshots mounted!"
    else
        info "@snapshots already mounted"
    fi
    
    # Install grub-btrfs and dependencies
    info "Installing grub-btrfs and dependencies..."
    yay -S --needed --noconfirm grub-btrfs inotify-tools
    success "grub-btrfs and dependencies installed!"
    
    # Configure grub-btrfs
    info "Configuring grub-btrfs..."
    sudo mkdir -p /etc/default/grub-btrfs
    
    cat << 'EOF' | sudo tee /etc/default/grub-btrfs/config > /dev/null
# grub-btrfs configuration
GRUB_BTRFS_SHOW_SNAPSHOTS_FOUND="true"
GRUB_BTRFS_LIMIT="10"
GRUB_BTRFS_SHOW_TOTAL_SNAPSHOTS_FOUND="true"
GRUB_BTRFS_TITLE_FORMAT="date"
GRUB_BTRFS_SHOW_PATH="true"
GRUB_BTRFS_OVERRIDE_BOOT_PARTITION_DETECTION="false"
EOF
    
    # Update GRUB configuration
    info "Updating GRUB configuration..."
    sudo grub-mkconfig -o /boot/grub/grub.cfg
    
    # Enable and start grub-btrfsd
    info "Enabling grub-btrfsd service..."
    sudo systemctl enable grub-btrfsd
    sudo systemctl start grub-btrfsd
    
    success "Phase 1 completed: Snapshot infrastructure ready!"
}

# Phase 2: Create automation scripts
create_automation_scripts() {
    log "=== PHASE 2: Creating Automation Scripts ==="
    
    # Create scripts directory
    sudo mkdir -p "$SCRIPTS_DIR"
    
    # Create btrfs-snapshot script
    info "Creating btrfs-snapshot script..."
    cat << 'EOF' | sudo tee "$SCRIPTS_DIR/btrfs-snapshot" > /dev/null
#!/bin/bash
# Btrfs Timeline Snapshot Script
# Usage: btrfs-snapshot [root|home|both]

set -euo pipefail

SNAPSHOT_DIR="/.snapshots"
DATE=$(date +%Y-%m-%d-%H%M%S)

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a /var/log/btrfs-snapshots.log
}

# Create root snapshot
create_root_snapshot() {
    local snapshot_name="root-${DATE}"
    log "Creating root snapshot: ${snapshot_name}"
    
    if btrfs subvolume snapshot / "${SNAPSHOT_DIR}/${snapshot_name}"; then
        log "✅ Root snapshot created successfully: ${snapshot_name}"
    else
        log "❌ Failed to create root snapshot: ${snapshot_name}"
        return 1
    fi
}

# Create home snapshot  
create_home_snapshot() {
    local snapshot_name="home-${DATE}"
    log "Creating home snapshot: ${snapshot_name}"
    
    if btrfs subvolume snapshot /home "${SNAPSHOT_DIR}/${snapshot_name}"; then
        log "✅ Home snapshot created successfully: ${snapshot_name}"
    else
        log "❌ Failed to create home snapshot: ${snapshot_name}"
        return 1
    fi
}

# Main logic
case "${1:-both}" in
    root)
        create_root_snapshot
        ;;
    home)
        create_home_snapshot
        ;;
    both)
        create_root_snapshot
        create_home_snapshot
        ;;
    *)
        echo "Usage: $0 [root|home|both]"
        exit 1
        ;;
esac

log "Snapshot operation completed"
EOF
    
    # Create btrfs-cleanup script
    info "Creating btrfs-cleanup script..."
    cat << 'EOF' | sudo tee "$SCRIPTS_DIR/btrfs-cleanup" > /dev/null
#!/bin/bash
# Btrfs Snapshot Cleanup Script with Retention Policy
# Implements retention: hourly, daily, weekly, monthly snapshots

set -euo pipefail

SNAPSHOT_DIR="/.snapshots"
LOG_FILE="/var/log/btrfs-snapshots.log"

# Retention policies
# Root: 10 hourly, 10 daily, 10 weekly, 10 monthly
# Home: 20 hourly, 15 daily, 8 weekly, 6 monthly

ROOT_HOURLY=10
ROOT_DAILY=10
ROOT_WEEKLY=10
ROOT_MONTHLY=10

HOME_HOURLY=20
HOME_DAILY=15
HOME_WEEKLY=8
HOME_MONTHLY=6

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to clean snapshots by time period
cleanup_snapshots() {
    local pattern="$1"
    local keep_count="$2"
    local time_desc="$3"
    
    log "Cleaning up $time_desc snapshots (keeping $keep_count latest)"
    
    # Find snapshots matching pattern, sort by date (newest first), skip the ones to keep, delete the rest
    find "$SNAPSHOT_DIR" -maxdepth 1 -name "$pattern" -type d | \
    sort -r | \
    tail -n +$((keep_count + 1)) | \
    while read -r snapshot; do
        log "Deleting old snapshot: $(basename "$snapshot")"
        if btrfs subvolume delete "$snapshot"; then
            log "✅ Deleted: $(basename "$snapshot")"
        else
            log "❌ Failed to delete: $(basename "$snapshot")"
        fi
    done
}

# Cleanup function for root snapshots
cleanup_root() {
    log "Starting root snapshot cleanup"
    cleanup_snapshots "root-*" "$ROOT_HOURLY" "root hourly"
}

# Cleanup function for home snapshots  
cleanup_home() {
    log "Starting home snapshot cleanup"
    cleanup_snapshots "home-*" "$HOME_HOURLY" "home hourly"
}

# Main execution
log "===== Starting snapshot cleanup process ====="

cleanup_root
cleanup_home

# Clean up test snapshots (remove any test-* snapshots older than 1 hour)
find "$SNAPSHOT_DIR" -maxdepth 1 -name "test-*" -type d -mmin +60 | \
while read -r test_snapshot; do
    log "Cleaning up test snapshot: $(basename "$test_snapshot")"
    btrfs subvolume delete "$test_snapshot" && \
    log "✅ Cleaned test snapshot: $(basename "$test_snapshot")"
done

log "===== Snapshot cleanup finished ====="

# Show current snapshot count
log "Current snapshots:"
ls -la "$SNAPSHOT_DIR" | grep "^d" | wc -l | xargs -I {} log "Total snapshots: {}"
EOF
    
    # Create borg-backup script
    info "Creating borg-backup script..."
    cat << 'EOF' | sudo tee "$SCRIPTS_DIR/borg-backup" > /dev/null
#!/bin/bash
# Borg Backup Script for Full System Backup
# Runs full system backup with exclusions

set -euo pipefail

# Configuration
REPO="/mnt/backup/borg-repo"
LOG_FILE="/var/log/borg-backup.log"
HOSTNAME=$(hostname)
BACKUP_NAME="${HOSTNAME}-$(date +%Y-%m-%d-%H%M%S)"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Check if backup drive is mounted
if ! mountpoint -q /mnt/backup; then
    log "❌ Backup drive not mounted at /mnt/backup"
    exit 1
fi

# Check if repository exists
if [ ! -d "$REPO" ]; then
    log "❌ Borg repository not found at $REPO"
    exit 1
fi

log "Starting Borg backup: $BACKUP_NAME"

# Create package lists before backup
log "Creating package lists"
pacman -Qqen > /tmp/pkglist.txt
pacman -Qqem > /tmp/aur.txt

# Run Borg backup with exclusions
borg create \
    --verbose \
    --filter AME \
    --list \
    --stats \
    --show-rc \
    --compression lz4 \
    --exclude-caches \
    --exclude '/dev/*' \
    --exclude '/proc/*' \
    --exclude '/sys/*' \
    --exclude '/tmp/*' \
    --exclude '/run/*' \
    --exclude '/mnt/*' \
    --exclude '/media/*' \
    --exclude '/lost+found' \
    --exclude '/var/tmp/*' \
    --exclude '/var/cache/pacman/pkg/*' \
    --exclude '/.snapshots/*' \
    --exclude '/home/*/.cache/*' \
    --exclude '/home/*/.local/share/Trash/*' \
    --exclude '/home/*/.mozilla/firefox/*/Cache/*' \
    --exclude '/home/*/.config/google-chrome/*/Cache/*' \
    --exclude '/home/*/.steam/steam/steamapps/*' \
    \
    "$REPO::$BACKUP_NAME" \
    / \
    /tmp/pkglist.txt \
    /tmp/aur.txt

backup_exit=$?

# Clean up temporary files
rm -f /tmp/pkglist.txt /tmp/aur.txt

log "Backup finished with exit code: $backup_exit"

if [ $backup_exit -eq 0 ]; then
    log "✅ Backup completed successfully: $BACKUP_NAME"
else
    log "❌ Backup failed with exit code: $backup_exit"
    exit $backup_exit
fi

# Prune old backups (retention: 7 daily, 4 weekly, 6 monthly)
log "Pruning old backups"
borg prune \
    --list \
    --prefix "${HOSTNAME}-" \
    --show-rc \
    --keep-daily 7 \
    --keep-weekly 4 \
    --keep-monthly 6 \
    "$REPO"

prune_exit=$?

if [ $prune_exit -eq 0 ]; then
    log "✅ Pruning completed successfully"
else
    log "❌ Pruning failed with exit code: $prune_exit"
fi

log "Borg backup operation completed"
EOF
    
    # Create backup-status script
    info "Creating backup-status script..."
    cat << 'EOF' | sudo tee "$SCRIPTS_DIR/backup-status" > /dev/null
#!/bin/bash
# Backup System Status Script

echo "=== BACKUP SYSTEM STATUS ==="
echo

echo "📅 SYSTEMD TIMERS STATUS:"
systemctl list-timers | grep -E "(btrfs|borg)" || echo "No backup timers found"
echo

echo "📂 CURRENT SNAPSHOTS:"
ls -la /.snapshots/ | tail -n +2
echo "Total snapshots: $(ls -1 /.snapshots/ | wc -l)"
echo

echo "💾 BORG REPOSITORY STATUS:"
if [ -d "/mnt/backup/borg-repo" ]; then
    echo "Repository location: /mnt/backup/borg-repo"
    sudo borg list /mnt/backup/borg-repo 2>/dev/null | tail -5 || echo "No archives found or repository locked"
else
    echo "❌ Borg repository not found"
fi
echo

echo "📊 DISK USAGE:"
df -h /.snapshots /mnt/backup 2>/dev/null || echo "Could not get disk usage"
echo

echo "📝 RECENT LOGS:"
echo "--- Snapshot logs (last 5 lines) ---"
tail -5 /var/log/btrfs-snapshots.log 2>/dev/null || echo "No snapshot logs found"
echo
echo "--- Borg logs (last 5 lines) ---"
tail -5 /var/log/borg-backup.log 2>/dev/null || echo "No borg logs found"
EOF
    
    # Make all scripts executable
    sudo chmod +x "$SCRIPTS_DIR"/*
    
    success "Phase 2 completed: Automation scripts created!"
}

# Create systemd services and timers
create_systemd_services() {
    log "=== Creating Systemd Services and Timers ==="
    
    # Root snapshot service
    info "Creating btrfs-snapshot-root.service..."
    cat << 'EOF' | sudo tee /etc/systemd/system/btrfs-snapshot-root.service > /dev/null
[Unit]
Description=Create Btrfs Root Snapshot
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-scripts/btrfs-snapshot root
ExecStartPost=/usr/local/bin/backup-scripts/btrfs-cleanup
User=root
EOF
    
    # Home snapshot service
    info "Creating btrfs-snapshot-home.service..."
    cat << 'EOF' | sudo tee /etc/systemd/system/btrfs-snapshot-home.service > /dev/null
[Unit]
Description=Create Btrfs Home Snapshot  
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-scripts/btrfs-snapshot home
ExecStartPost=/usr/local/bin/backup-scripts/btrfs-cleanup
User=root
EOF
    
    # Root snapshot timer (every 4 hours)
    info "Creating btrfs-snapshot-root.timer..."
    cat << 'EOF' | sudo tee /etc/systemd/system/btrfs-snapshot-root.timer > /dev/null
[Unit]
Description=Create Btrfs Root Snapshot Every 4 Hours
Requires=btrfs-snapshot-root.service

[Timer]
OnCalendar=*:00/4:00
Persistent=true
RandomizedDelaySec=300

[Install]
WantedBy=timers.target
EOF
    
    # Home snapshot timer (every 2 hours)
    info "Creating btrfs-snapshot-home.timer..."
    cat << 'EOF' | sudo tee /etc/systemd/system/btrfs-snapshot-home.timer > /dev/null
[Unit]
Description=Create Btrfs Home Snapshot Every 2 Hours
Requires=btrfs-snapshot-home.service

[Timer]
OnCalendar=*:00/2:00
Persistent=true
RandomizedDelaySec=180

[Install]
WantedBy=timers.target
EOF
    
    # Borg backup service
    info "Creating borg-backup.service..."
    cat << 'EOF' | sudo tee /etc/systemd/system/borg-backup.service > /dev/null
[Unit]
Description=Borg Backup
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-scripts/borg-backup
User=root
TimeoutStartSec=14400
EOF
    
    # Borg backup timer (daily at 2 AM)
    info "Creating borg-backup.timer..."
    cat << 'EOF' | sudo tee /etc/systemd/system/borg-backup.timer > /dev/null
[Unit]
Description=Daily Borg Backup at 2 AM
Requires=borg-backup.service

[Timer]
OnCalendar=daily
Persistent=true
RandomizedDelaySec=600

[Install]
WantedBy=timers.target
EOF
    
    # Reload systemd and enable timers
    info "Enabling systemd timers..."
    sudo systemctl daemon-reload
    sudo systemctl enable btrfs-snapshot-root.timer
    sudo systemctl enable btrfs-snapshot-home.timer
    sudo systemctl enable borg-backup.timer
    sudo systemctl start btrfs-snapshot-root.timer
    sudo systemctl start btrfs-snapshot-home.timer
    sudo systemctl start borg-backup.timer
    
    success "Systemd services and timers created and enabled!"
}

# Phase 3: Borg backup setup
setup_borg_backup() {
    log "=== PHASE 3: Setting up Borg Backup ==="
    
    # Install borgbackup
    info "Installing borgbackup..."
    yay -S --needed --noconfirm borgbackup
    
    # Check if backup mount point exists
    if [[ ! -d "$BACKUP_MOUNT" ]]; then
        error "Backup mount point $BACKUP_MOUNT does not exist."
        error "Please ensure your external backup drive is mounted at $BACKUP_MOUNT"
        error "Add it to /etc/fstab for automatic mounting."
        return 1
    fi
    
    # Check if backup drive is mounted
    if ! mountpoint -q "$BACKUP_MOUNT"; then
        warning "Backup drive is not mounted at $BACKUP_MOUNT"
        warning "Please mount your backup drive and run this section manually:"
        warning "sudo borg init --encryption=repokey-blake2 $BORG_REPO"
        return 0
    fi
    
    # Initialize Borg repository if it doesn't exist
    if [[ ! -d "$BORG_REPO" ]]; then
        warning "Borg repository will be initialized at $BORG_REPO"
        warning "You will be prompted for a passphrase. REMEMBER IT!"
        warning "This passphrase is required to restore your backups."
        echo
        read -p "Press Enter to continue with Borg repository initialization..."
        
        sudo borg init --encryption=repokey-blake2 "$BORG_REPO"
        
        # Export repository key
        info "Exporting repository key..."
        sudo borg key export "$BORG_REPO" "$BORG_REPO.key"
        sudo chmod 600 "$BORG_REPO.key"
        
        success "Borg repository initialized successfully!"
        warning "IMPORTANT: Backup the key file at $BORG_REPO.key"
    else
        info "Borg repository already exists at $BORG_REPO"
    fi
    
    success "Phase 3 completed: Borg backup ready!"
}

# Add convenient aliases
setup_aliases() {
    log "=== Setting up Convenient Aliases ==="
    
    local shell_config=""
    if [[ -f ~/.zshrc ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -f ~/.bashrc ]]; then
        shell_config="$HOME/.bashrc"
    else
        warning "No shell config file found. Skipping alias setup."
        return 0
    fi
    
    info "Adding backup aliases to $shell_config..."
    
    # Check if aliases already exist
    if grep -q "backup-status" "$shell_config"; then
        info "Backup aliases already exist in $shell_config"
        return 0
    fi
    
    cat << 'EOF' >> "$shell_config"

# Backup management aliases
alias backup-status="sudo /usr/local/bin/backup-scripts/backup-status"
alias backup-snapshot="sudo /usr/local/bin/backup-scripts/btrfs-snapshot"
alias backup-cleanup="sudo /usr/local/bin/backup-scripts/btrfs-cleanup"
alias backup-borg="sudo /usr/local/bin/backup-scripts/borg-backup"
alias backup-list="sudo borg list /mnt/backup/borg-repo"
EOF
    
    success "Backup aliases added to $shell_config"
    info "Run 'source $shell_config' to load the new aliases"
}

# Test the installation
test_installation() {
    log "=== Testing Installation ==="
    
    # Test snapshot creation
    info "Testing snapshot creation..."
    sudo "$SCRIPTS_DIR/btrfs-snapshot" both
    
    # Test cleanup
    info "Testing cleanup..."
    sudo "$SCRIPTS_DIR/btrfs-cleanup"
    
    # Check timer status
    info "Checking timer status..."
    systemctl list-timers | grep -E "(btrfs|borg)"
    
    success "Installation test completed!"
}

# Main installation function
main() {
    echo -e "${PURPLE}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║           Arch Linux 3-Layer Backup System Installer        ║
║                                                              ║
║  📸 Layer 1: Btrfs Snapshots (Instant Recovery)            ║
║  💾 Layer 2: Borg Backups (Disaster Recovery)              ║
║  🚀 Layer 3: GRUB Integration (Boot-time Recovery)         ║
║                                                              ║
║  Created by: ibrahim & Claude (Arch Linux experts)          ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    log "Starting comprehensive backup system installation..."
    echo
    
    # Pre-installation checks
    check_root
    check_system
    
    # Confirm installation
    echo -e "${YELLOW}This script will:"
    echo "  • Set up Btrfs snapshot infrastructure"
    echo "  • Create automated snapshot scripts with retention policies"
    echo "  • Configure GRUB integration for boot-time recovery"
    echo "  • Set up Borg encrypted backups"
    echo "  • Create systemd timers for automation"
    echo "  • Install convenient management aliases"
    echo -e "${NC}"
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Installation cancelled by user."
        exit 0
    fi
    
    # Execute installation phases
    setup_snapshot_infrastructure
    echo
    create_automation_scripts
    echo
    create_systemd_services
    echo
    setup_borg_backup
    echo
    setup_aliases
    echo
    test_installation
    echo
    
    # Final success message
    echo -e "${GREEN}"
    cat << 'EOF'
🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉

Your 3-layer backup system is now active:

✅ Btrfs Snapshots: Automated every 2-4 hours
✅ Borg Backups: Daily encrypted backups  
✅ GRUB Integration: Boot from snapshots
✅ Systemd Timers: All automation enabled
✅ Management Aliases: Easy commands available

Next Steps:
1. Reboot to test GRUB snapshot integration
2. Check backup status: backup-status
3. Verify timer schedules: systemctl list-timers
4. Test snapshot boot recovery from GRUB menu

Your data is now enterprise-level protected! 💪
EOF
    echo -e "${NC}"
    
    warning "IMPORTANT REMINDERS:"
    echo "• Remember your Borg repository passphrase!"
    echo "• Backup the key file: $BORG_REPO.key"
    echo "• Test recovery procedures periodically"
    echo "• Monitor logs in /var/log/btrfs-snapshots.log and /var/log/borg-backup.log"
}

# Run main installation
main "$@"
