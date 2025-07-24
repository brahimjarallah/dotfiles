#!/bin/bash

# Vim Keys System-wide Installer for Arch Linux + Hyprland
# This script sets up system-wide vim-style navigation using keyd
# Alt+hjkl = arrow keys, Alt+Ctrl+hjkl = word/line navigation, etc.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_not_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should NOT be run as root!"
        log_info "Run as regular user: ./install_vim_keys.sh"
        exit 1
    fi
}

# Check if we're on Arch Linux
check_arch() {
    if ! command -v pacman &> /dev/null; then
        log_error "This script is designed for Arch Linux (pacman not found)"
        exit 1
    fi
    log_success "Arch Linux detected"
}

# Install keyd
install_keyd() {
    log_info "Installing keyd..."
    
    if command -v keyd &> /dev/null; then
        log_success "keyd is already installed"
        keyd --version
    else
        sudo pacman -S --noconfirm keyd
        log_success "keyd installed successfully"
    fi
}

# Add user to keyd group
setup_user_groups() {
    log_info "Setting up user groups..."
    
    # Add to keyd group
    if groups $USER | grep -q "keyd"; then
        log_success "User already in keyd group"
    else
        sudo usermod -aG keyd $USER
        log_success "Added user to keyd group"
    fi
    
    # Add to input group (sometimes needed)
    if groups $USER | grep -q "input"; then
        log_success "User already in input group"
    else
        sudo usermod -aG input $USER
        log_success "Added user to input group"
    fi
}

# Create udev rules
setup_udev_rules() {
    log_info "Setting up udev rules..."
    
    sudo tee /etc/udev/rules.d/90-keyd.rules > /dev/null << 'EOF'
KERNEL=="event*", GROUP="input", MODE="0664"
KERNEL=="uinput", GROUP="input", MODE="0664"
SUBSYSTEM=="input", GROUP="keyd", MODE="0664"
EOF
    
    # Reload udev rules
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    log_success "udev rules created and reloaded"
}

# Create keyd configuration
create_keyd_config() {
    log_info "Creating keyd configuration..."
    
    # Create keyd directory
    sudo mkdir -p /etc/keyd
    
    # Backup existing config if it exists
    if [[ -f /etc/keyd/default.conf ]]; then
        sudo cp /etc/keyd/default.conf /etc/keyd/default.conf.backup.$(date +%Y%m%d_%H%M%S)
        log_info "Backed up existing keyd configuration"
    fi
    
    # Create the main configuration
    sudo tee /etc/keyd/default.conf > /dev/null << 'EOF'
[ids]
*

[main]
# Alt key becomes an overlay for vim-style navigation
leftalt = overload(nav, leftalt)

[nav]
# Basic vim navigation (Alt+hjkl)
h = left
j = down
k = up
l = right

# Word navigation (Alt+Ctrl+h/l)
control+h = C-left     # Move word left
control+l = C-right    # Move word right

# Line navigation (Alt+Ctrl+j/k)
control+j = end        # End of line
control+k = home       # Beginning of line

# Document navigation (Alt+Shift+j/k)
shift+j = C-end        # End of document
shift+k = C-home       # Beginning of document

# Page navigation (Alt+Ctrl+Shift+j/k)
shift+control+j = pagedown    # Page down
shift+control+k = pageup      # Page up

# Selection with vim keys (Alt+Shift+hjkl)
shift+h = S-left       # Select left
shift+l = S-right      # Select right

# Word selection (Alt+Ctrl+Shift+h/l)
shift+control+h = C-S-left    # Select word left
shift+control+l = C-S-right   # Select word right

# Line selection (Alt+Ctrl+Shift+j/k for line selection)
# Note: These might work differently in different applications
# shift+control+j = S-end       # Select to end of line
# shift+control+k = S-home      # Select to beginning of line

# Bonus: Common vim-like shortcuts
# Delete operations (Alt+x for delete char, Alt+Ctrl+x for delete word)
x = delete             # Delete character (like vim x)
control+x = C-delete   # Delete word

# Quick save/undo
s = C-s               # Save
z = C-z               # Undo  
shift+z = C-y         # Redo (Ctrl+Shift+Z in many apps)
EOF
    
    log_success "keyd configuration created"
}

# Test keyd configuration
test_keyd_config() {
    log_info "Testing keyd configuration syntax..."
    
    if sudo keyd -c /etc/keyd/default.conf &>/dev/null; then
        log_success "Configuration syntax is valid"
    else
        log_error "Configuration syntax error:"
        sudo keyd -c /etc/keyd/default.conf
        exit 1
    fi
}

# Enable and start keyd service
enable_keyd_service() {
    log_info "Enabling and starting keyd service..."
    
    sudo systemctl enable keyd
    sudo systemctl restart keyd
    
    # Wait a moment for service to start
    sleep 2
    
    if sudo systemctl is-active --quiet keyd; then
        log_success "keyd service is running"
    else
        log_error "keyd service failed to start"
        log_info "Checking logs:"
        sudo journalctl -u keyd -n 10 --no-pager
        exit 1
    fi
}

# Check service status and logs
check_service_status() {
    log_info "Checking keyd service status..."
    
    echo "=== Service Status ==="
    sudo systemctl status keyd --no-pager -l
    
    echo ""
    echo "=== Recent Logs ==="
    sudo journalctl -u keyd -n 10 --no-pager
    
    echo ""
    echo "=== Device Matches ==="
    sudo journalctl -u keyd -n 20 --no-pager | grep "DEVICE:" || log_info "No device information found"
}

# Create uninstaller script
create_uninstaller() {
    log_info "Creating uninstaller script..."
    
    cat > "$HOME/uninstall_vim_keys.sh" << 'EOF'
#!/bin/bash

echo "Uninstalling vim keys setup..."

# Stop and disable keyd
sudo systemctl stop keyd
sudo systemctl disable keyd

# Remove keyd package
sudo pacman -R keyd --noconfirm

# Remove configuration
sudo rm -rf /etc/keyd/

# Remove udev rules
sudo rm -f /etc/udev/rules.d/90-keyd.rules
sudo udevadm control --reload-rules

# Remove user from groups (optional)
# sudo gpasswd -d $USER keyd
# sudo gpasswd -d $USER input

echo "Vim keys setup uninstalled. Please reboot for complete removal."
EOF
    
    chmod +x "$HOME/uninstall_vim_keys.sh"
    log_success "Uninstaller created at $HOME/uninstall_vim_keys.sh"
}

# Print usage instructions
print_usage() {
    echo ""
    echo "=============================================="
    echo "🎉 VIM KEYS INSTALLATION COMPLETED! 🎉"
    echo "=============================================="
    echo ""
    echo "📋 KEY BINDINGS:"
    echo "  Basic Navigation:"
    echo "    Alt + h/j/k/l     → Arrow keys (←↓↑→)"
    echo ""
    echo "  Word Navigation:"
    echo "    Alt + Ctrl + h/l  → Word left/right"
    echo ""
    echo "  Line Navigation:"
    echo "    Alt + Ctrl + j/k  → End/beginning of line"
    echo ""
    echo "  Document Navigation:"
    echo "    Alt + Shift + j/k → End/beginning of document"
    echo ""
    echo "  Page Navigation:"
    echo "    Alt + Ctrl + Shift + j/k → Page down/up"
    echo ""
    echo "  Selection:"
    echo "    Alt + Shift + h/j/k/l → Select with arrows"
    echo "    Alt + Ctrl + Shift + h/l → Select words"
    echo ""
    echo "  Bonus (while holding Alt):"
    echo "    Alt + x           → Delete character"
    echo "    Alt + Ctrl + x    → Delete word"
    echo "    Alt + s           → Save (Ctrl+S)"
    echo "    Alt + z           → Undo (Ctrl+Z)"
    echo "    Alt + Shift + z   → Redo (Ctrl+Y)"
    echo ""
    echo "⚠️  IMPORTANT: You need to REBOOT for group changes to take effect!"
    echo ""
    echo "🔧 TROUBLESHOOTING:"
    echo "  • Check service: sudo systemctl status keyd"
    echo "  • Check logs: sudo journalctl -u keyd -n 10"
    echo "  • Test config: sudo keyd -c /etc/keyd/default.conf"
    echo "  • Monitor keys: sudo keyd monitor (then press Alt+h)"
    echo ""
    echo "❌ TO UNINSTALL:"
    echo "  • Run: $HOME/uninstall_vim_keys.sh"
    echo ""
}

# Main installation function
main() {
    echo "=============================================="
    echo "🚀 VIM KEYS INSTALLER FOR ARCH LINUX"
    echo "=============================================="
    echo "This will install system-wide vim-style navigation"
    echo "Alt+hjkl = arrow keys everywhere!"
    echo ""
    
    read -p "Continue with installation? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Installation cancelled"
        exit 0
    fi
    
    log_info "Starting vim keys installation..."
    
    # Run installation steps
    check_not_root
    check_arch
    install_keyd
    setup_user_groups  
    setup_udev_rules
    create_keyd_config
    test_keyd_config
    enable_keyd_service
    check_service_status
    create_uninstaller
    print_usage
    
    log_success "Installation completed!"
    log_warning "REBOOT REQUIRED for group changes to take effect"
}

# Run main function
main "$@"
