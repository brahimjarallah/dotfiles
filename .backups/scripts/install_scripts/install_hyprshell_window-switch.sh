#!/bin/bash

# Hyprshell Installation Script for Arch Linux + Hyprland
# This script installs and configures hyprshell for Windows Alt+Tab-like experience
# Author: Generated for hyprshell setup
# Usage: chmod +x install_hyprshell.sh && ./install_hyprshell.sh

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if we're on Arch Linux
check_arch() {
    if [[ ! -f /etc/arch-release ]]; then
        print_error "This script is designed for Arch Linux!"
        exit 1
    fi
}

# Function to check if AUR helper is available
check_aur_helper() {
    if command_exists yay; then
        AUR_HELPER="yay"
    elif command_exists paru; then
        AUR_HELPER="paru"
    else
        print_error "No AUR helper found! Please install yay or paru first."
        echo "To install yay:"
        echo "sudo pacman -S --needed git base-devel"
        echo "git clone https://aur.archlinux.org/yay.git"
        echo "cd yay && makepkg -si"
        exit 1
    fi
    print_status "Found AUR helper: $AUR_HELPER"
}

# Function to check if Hyprland is running
check_hyprland() {
    if [[ -z "$HYPRLAND_INSTANCE_SIGNATURE" ]]; then
        print_warning "Hyprland doesn't seem to be running. Make sure to run this in a Hyprland session for full functionality."
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_success "Hyprland session detected"
    fi
}

# Function to install dependencies
install_dependencies() {
    print_status "Installing dependencies..."
    
    # Install GTK4 dependencies
    sudo pacman -S --needed --noconfirm gtk4 gtk4-layer-shell
    
    print_success "Dependencies installed"
}

# Function to install hyprshell
install_hyprshell() {
    print_status "Installing hyprshell from AUR..."
    
    $AUR_HELPER -S --needed --noconfirm hyprshell
    
    print_success "hyprshell installed successfully"
}

# Function to generate configuration
generate_config() {
    print_status "Generating hyprshell configuration..."
    
    # Create config directory if it doesn't exist
    mkdir -p ~/.config/hyprshell
    
    print_status "Running interactive configuration..."
    print_warning "You'll be prompted for configuration options:"
    echo "  - Key combination for overview: Super + Tab (recommended)"
    echo "  - Default Terminal: kitty (or your preferred terminal)"
    echo "  - Launcher plugins: Keep default (5 plugins)"
    echo "  - Search engines: Keep default (2 engines)"
    echo "  - Switch mode modifier: Super (recommended)"
    echo "  - Switch between workspaces: Choose based on preference"
    echo "  - Default focused color: Choose your preference"
    echo
    
    # Run interactive config generation
    hyprshell config generate
    
    print_success "Configuration generated successfully"
}

# Function to validate configuration
validate_config() {
    print_status "Validating configuration..."
    
    if hyprshell config check; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed!"
        exit 1
    fi
}

# Function to setup systemd service
setup_service() {
    print_status "Setting up systemd service..."
    
    # Enable and start the service
    systemctl --user enable hyprshell.service
    systemctl --user start hyprshell.service
    
    # Check if service is running
    if systemctl --user is-active --quiet hyprshell.service; then
        print_success "hyprshell service is running"
    else
        print_error "Failed to start hyprshell service"
        print_status "Check logs with: journalctl --user -u hyprshell.service"
        exit 1
    fi
}

# Function to update hyprland config (remove exec-once if present)
update_hyprland_config() {
    print_status "Checking Hyprland configuration..."
    
    HYPR_CONFIG="$HOME/.config/hypr/hyprland.conf"
    
    if [[ -f "$HYPR_CONFIG" ]]; then
        # Check if exec-once for hyprshell exists and remove it
        if grep -q "exec-once.*hyprshell" "$HYPR_CONFIG"; then
            print_status "Removing conflicting exec-once line from hyprland.conf..."
            sed -i '/exec-once.*hyprshell/d' "$HYPR_CONFIG"
            print_success "Cleaned up hyprland.conf"
        fi
    else
        print_warning "Hyprland config not found at $HYPR_CONFIG"
    fi
}

# Function to test installation
test_installation() {
    print_status "Testing installation..."
    
    # Check if hyprshell command exists
    if command_exists hyprshell; then
        print_success "hyprshell command available"
    else
        print_error "hyprshell command not found!"
        exit 1
    fi
    
    # Check if service is running
    if systemctl --user is-active --quiet hyprshell.service; then
        print_success "hyprshell service is active"
    else
        print_warning "hyprshell service is not active"
    fi
    
    # Check if config files exist
    if [[ -f ~/.config/hyprshell/config.toml ]]; then
        print_success "Configuration file exists"
    else
        print_error "Configuration file not found!"
        exit 1
    fi
}

# Function to show usage instructions
show_usage() {
    print_success "Installation completed successfully!"
    echo
    print_status "How to use hyprshell:"
    echo "  • Super + Tab: Open overview/launcher"
    echo "  • Hold Super + Tab: Window/workspace switcher (like Windows Alt+Tab)"
    echo "  • In overview: Type to search apps, use Ctrl+1/2/3 to launch"
    echo "  • In switcher: Tab/Shift+Tab to navigate, release Super to switch"
    echo
    print_status "Useful commands:"
    echo "  • Check service status: systemctl --user status hyprshell.service"
    echo "  • View logs: journalctl --user -u hyprshell.service -f"
    echo "  • Restart service: systemctl --user restart hyprshell.service"
    echo "  • Edit config: vim ~/.config/hyprshell/config.toml"
    echo "  • Edit styling: vim ~/.config/hyprshell/styles.css"
    echo
    print_status "If you need to reconfigure:"
    echo "  • Run: hyprshell config generate"
    echo
    print_warning "Note: You may need to reload Hyprland or restart your session for full functionality"
}

# Main installation function
main() {
    echo "=========================================="
    echo "     Hyprshell Installation Script       "
    echo "=========================================="
    echo
    
    # Check prerequisites
    check_arch
    check_aur_helper
    check_hyprland
    
    # Install everything
    install_dependencies
    install_hyprshell
    generate_config
    validate_config
    setup_service
    update_hyprland_config
    test_installation
    
    # Show usage instructions
    show_usage
    
    print_success "Hyprshell installation completed!"
    print_status "Press Super + Tab to test the overview"
    print_status "Hold Super and press Tab to test window switching"
}

# Run main function
main "$@"
