#!/bin/bash
# Full Rsync Backup Setup Script
# Creates directories, installs rsync backup script, sets permissions, adds aliases, and reloads shell

set -euo pipefail

echo "=== Rsync Backup Setup Started ==="

# 1. Create backup directories
echo "Creating backup directories..."
sudo mkdir -p /mnt/backup/system-mirror
sudo mkdir -p /mnt/backup/home-mirror

# 2. Write rsync backup script to /usr/local/bin/backup-scripts/rsync-backup
echo "Installing rsync backup script..."
sudo mkdir -p /usr/local/bin/backup-scripts

sudo tee /usr/local/bin/backup-scripts/rsync-backup > /dev/null << 'EOF'
#!/bin/bash
# Rsync Backup Script - Browsable System & Home Mirrors
# Usage: rsync-backup [system|home|dotfiles|all]

set -euo pipefail

BACKUP_ROOT="/mnt/backup"
SYSTEM_MIRROR="$BACKUP_ROOT/system-mirror"
HOME_MIRROR="$BACKUP_ROOT/home-mirror"
LOG_FILE="/var/log/rsync-backup.log"
USERNAME=$(logname 2>/dev/null || echo $SUDO_USER)

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_backup_mount() {
    if ! mountpoint -q /mnt/backup; then
        log "❌ Backup drive not mounted at /mnt/backup"
        exit 1
    fi
}

rsync_system() {
    log "Starting system mirror rsync..."
    
    rsync -avH --delete --delete-excluded \
        --exclude='/dev/*' \
        --exclude='/proc/*' \
        --exclude='/sys/*' \
        --exclude='/tmp/*' \
        --exclude='/run/*' \
        --exclude='/mnt/*' \
        --exclude='/media/*' \
        --exclude='/lost+found' \
        --exclude='/var/tmp/*' \
        --exclude='/var/cache/pacman/pkg/*' \
        --exclude='/.snapshots/*' \
        --exclude='/home/*' \
        --exclude='/boot/grub/grubenv' \
        --exclude='/var/lib/systemd/random-seed' \
        --exclude='/var/log/journal/*' \
        --exclude='/var/lib/dhcpcd/*' \
        --stats \
        / "$SYSTEM_MIRROR/"
    
    if [[ $? -eq 0 ]]; then
        log "✅ System mirror completed successfully"
    else
        log "❌ System mirror failed"
        return 1
    fi
}

rsync_home() {
    log "Starting home mirror rsync..."
    
    rsync -avH --delete --delete-excluded \
        --exclude='/.cache/*' \
        --exclude='/.local/share/Trash/*' \
        --exclude='/.mozilla/firefox/*/Cache/*' \
        --exclude='/.config/google-chrome/*/Cache/*' \
        --exclude='/.config/Brave-Browser/*/Cache/*' \
        --exclude='/.steam/steam/steamapps/*' \
        --exclude='/.local/share/Steam/steamapps/*' \
        --exclude='/Downloads/Torrents/*' \
        --exclude='/.thumbnails/*' \
        --exclude='/.gvfs' \
        --exclude='/.recently-used' \
        --stats \
        "/home/$USERNAME/" "$HOME_MIRROR/"
    
    if [[ $? -eq 0 ]]; then
        log "✅ Home mirror completed successfully"
    else
        log "❌ Home mirror failed"
        return 1
    fi
}

rsync_dotfiles() {
    log "Starting critical dotfiles rsync..."
    
    local dotfiles_dir="$HOME_MIRROR/.config-critical"
    mkdir -p "$dotfiles_dir"
    
    local critical_files=(
        ".zshrc"
        ".bashrc"
        ".vimrc"
        ".backups"
        ".gitconfig"
        ".ssh/config"
        ".config/hypr/"
        ".config/waybar/"
        ".config/kitty/"
        ".config/rofi/"
        ".config/dunst/"
        ".config/gtk-3.0/"
        ".config/fontconfig/"
    )
    
    for file in "${critical_files[@]}"; do
        local src="/home/$USERNAME/$file"
        local dest="$dotfiles_dir/$file"
        
        if [[ -e "$src" ]]; then
            log "Backing up: $file"
            mkdir -p "$(dirname "$dest")"
            rsync -avH "$src" "$dest" 2>/dev/null || log "Warning: Could not backup $file"
        fi
    done
    
    log "✅ Critical dotfiles backup completed"
}

create_summary() {
    local summary_file="$BACKUP_ROOT/rsync-backup-info.txt"
    
    cat > "$summary_file" << EOF
Rsync Backup Summary
===================
Backup Date: $(date)
Hostname: $(hostname)
User: $USERNAME

Directory Structure:
├── borg-repo/           # Encrypted Borg archives  
├── system-mirror/       # Complete system files (no /home)
├── home-mirror/         # User home directory
└── rsync-backup-info.txt # This summary file

System Mirror Size: $(du -sh "$SYSTEM_MIRROR" 2>/dev/null | cut -f1 || echo "Unknown")
Home Mirror Size: $(du -sh "$HOME_MIRROR" 2>/dev/null | cut -f1 || echo "Unknown")

Last System Backup: $(stat -c %y "$SYSTEM_MIRROR" 2>/dev/null || echo "Never")
Last Home Backup: $(stat -c %y "$HOME_MIRROR" 2>/dev/null || echo "Never")

To browse backups:
- System files: $SYSTEM_MIRROR
- Home files: $HOME_MIRROR
- Dotfiles: $HOME_MIRROR/.config-critical

To restore a file:
rsync /mnt/backup/system-mirror/path/to/file /path/to/file
EOF
    
    log "Backup summary created: $summary_file"
}

main() {
    check_backup_mount
    
    case "${1:-all}" in
        system)
            rsync_system
            ;;
        home)
            rsync_home
            ;;
        dotfiles)
            rsync_dotfiles
            ;;
        all)
            rsync_system
            rsync_home
            rsync_dotfiles
            ;;
        *)
            echo "Usage: $0 [system|home|dotfiles|all]"
            echo "  system   - Mirror system files (excluding /home)"
            echo "  home     - Mirror user home directory"
            echo "  dotfiles - Quick backup of critical config files"
            echo "  all      - Complete system + home + dotfiles mirror"
            exit 1
            ;;
    esac
    
    create_summary
    log "Rsync backup operation completed"
}

main "$@"
EOF

# 3. Make the script executable
echo "Making rsync-backup script executable..."
sudo chmod +x /usr/local/bin/backup-scripts/rsync-backup

# 4. Add aliases to .zshrc
echo "Adding aliases to ~/.zshrc..."
cat >> ~/.zshrc << 'ALIASES'

# Rsync backup management aliases
alias rsync-dotfiles="sudo /usr/local/bin/backup-scripts/rsync-backup dotfiles"
alias rsync-home="sudo /usr/local/bin/backup-scripts/rsync-backup home"
alias rsync-system="sudo /usr/local/bin/backup-scripts/rsync-backup system"
alias rsync-all="sudo /usr/local/bin/backup-scripts/rsync-backup all"
alias combined-backup="sudo /usr/local/bin/backup-scripts/combined-backup"
alias backup-browse="ls -la /mnt/backup/ && echo && cat /mnt/backup/rsync-backup-info.txt"
ALIASES

# 5. Reload shell aliases
echo "Reloading ~/.zshrc..."
source ~/.zshrc

echo "=== Rsync Backup Setup Complete ==="

