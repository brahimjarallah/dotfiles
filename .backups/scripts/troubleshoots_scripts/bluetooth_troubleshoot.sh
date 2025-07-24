#!/bin/bash

# Bluetooth Troubleshoot Script for Arch Linux + Hyprland
# Author: AI Assistant
# Version: 1.0

set -e

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

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "This script should not be run as root!"
        exit 1
    fi
}

# Function to install packages
install_packages() {
    print_header "INSTALLING BLUETOOTH PACKAGES"
    
    local packages=("bluez" "bluez-utils" "blueman")
    local missing_packages=()
    
    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            missing_packages+=("$package")
        fi
    done
    
    if [ ${#missing_packages[@]} -gt 0 ]; then
        print_status "Installing missing packages: ${missing_packages[*]}"
        sudo pacman -S --needed "${missing_packages[@]}"
        print_success "Packages installed successfully"
    else
        print_success "All required packages are already installed"
    fi
}

# Function to check hardware
check_hardware() {
    print_header "CHECKING BLUETOOTH HARDWARE"
    
    print_status "Checking USB Bluetooth adapters..."
    if lsusb | grep -i bluetooth; then
        print_success "Bluetooth USB adapter detected"
    else
        print_warning "No USB Bluetooth adapter found"
    fi
    
    print_status "Checking PCI Bluetooth adapters..."
    if lspci | grep -i bluetooth; then
        print_success "Bluetooth PCI adapter detected"
    else
        print_warning "No PCI Bluetooth adapter found"
    fi
    
    print_status "Checking kernel modules..."
    if lsmod | grep -E "(bluetooth|btusb|btintel|btrtl)" | head -5; then
        print_success "Bluetooth kernel modules loaded"
    else
        print_warning "No Bluetooth kernel modules found"
        print_status "Attempting to load kernel modules..."
        sudo modprobe bluetooth
        sudo modprobe btusb
        sudo modprobe btintel
        sudo modprobe btrtl
        print_success "Kernel modules loaded"
    fi
}

# Function to check rfkill
check_rfkill() {
    print_header "CHECKING RFKILL STATUS"
    
    if command_exists rfkill; then
        print_status "Current rfkill status:"
        rfkill list
        
        if rfkill list bluetooth | grep -q "blocked: yes"; then
            print_warning "Bluetooth is blocked by rfkill"
            print_status "Unblocking Bluetooth..."
            sudo rfkill unblock bluetooth
            print_success "Bluetooth unblocked"
        else
            print_success "Bluetooth is not blocked by rfkill"
        fi
    else
        print_warning "rfkill command not found, installing..."
        sudo pacman -S --needed util-linux
    fi
}

# Function to manage systemd service
manage_bluetooth_service() {
    print_header "MANAGING BLUETOOTH SERVICE"
    
    # Check if service is masked
    if systemctl is-enabled bluetooth &>/dev/null; then
        if [ "$(systemctl is-enabled bluetooth)" = "masked" ]; then
            print_warning "Bluetooth service is masked"
            print_status "Unmasking Bluetooth service..."
            sudo systemctl unmask bluetooth
            print_success "Bluetooth service unmasked"
        fi
    fi
    
    # Check service status
    print_status "Current Bluetooth service status:"
    systemctl status bluetooth --no-pager || true
    
    # Start and enable service
    print_status "Starting Bluetooth service..."
    sudo systemctl start bluetooth
    print_success "Bluetooth service started"
    
    print_status "Enabling Bluetooth service..."
    sudo systemctl enable bluetooth
    print_success "Bluetooth service enabled"
    
    # Verify service is running
    if systemctl is-active --quiet bluetooth; then
        print_success "Bluetooth service is running"
    else
        print_error "Failed to start Bluetooth service"
        systemctl status bluetooth --no-pager
    fi
}

# Function to test Bluetooth functionality
test_bluetooth() {
    print_header "TESTING BLUETOOTH FUNCTIONALITY"
    
    print_status "Testing hciconfig..."
    if command_exists hciconfig; then
        if hciconfig -a | grep -q "hci"; then
            print_success "Bluetooth adapter detected by hciconfig"
            hciconfig -a
        else
            print_warning "No Bluetooth adapter found by hciconfig"
        fi
    else
        print_warning "hciconfig not available"
    fi
    
    print_status "Testing bluetoothctl..."
    if command_exists bluetoothctl; then
        print_success "bluetoothctl is available"
        timeout 5 bluetoothctl show || print_warning "bluetoothctl timeout or no adapter"
    else
        print_error "bluetoothctl not found"
    fi
}

# Function to configure Hyprland
configure_hyprland() {
    print_header "CONFIGURING HYPRLAND"
    
    local hypr_config="$HOME/.config/hypr/hyprland.conf"
    
    if [ -f "$hypr_config" ]; then
        print_status "Checking Hyprland configuration..."
        
        if grep -q "blueman-applet" "$hypr_config"; then
            print_success "blueman-applet already configured in Hyprland"
        else
            print_status "Adding blueman-applet to Hyprland autostart..."
            echo "exec-once = blueman-applet" >> "$hypr_config"
            print_success "blueman-applet added to Hyprland configuration"
        fi
    else
        print_warning "Hyprland configuration file not found at $hypr_config"
        print_status "Creating minimal Hyprland config with Bluetooth..."
        mkdir -p "$HOME/.config/hypr"
        echo "exec-once = blueman-applet" > "$hypr_config"
        print_success "Created Hyprland config with Bluetooth support"
    fi
}

# Function to start Bluetooth manager
start_bluetooth_manager() {
    print_header "STARTING BLUETOOTH MANAGER"
    
    # Kill existing instances
    pkill -f blueman-manager || true
    pkill -f blueman-applet || true
    
    sleep 2
    
    # Start blueman-applet in background
    if command_exists blueman-applet; then
        print_status "Starting blueman-applet..."
        blueman-applet &
        print_success "blueman-applet started"
    fi
    
    # Start blueman-manager
    if command_exists blueman-manager; then
        print_status "Starting blueman-manager..."
        blueman-manager &
        print_success "blueman-manager started"
    fi
}

# Function to show final status
show_final_status() {
    print_header "FINAL STATUS"
    
    print_status "Bluetooth service status:"
    systemctl is-active bluetooth && print_success "Service: RUNNING" || print_error "Service: STOPPED"
    
    print_status "Bluetooth adapters:"
    if hciconfig 2>/dev/null | grep -q "hci"; then
        print_success "Adapter: DETECTED"
    else
        print_error "Adapter: NOT DETECTED"
    fi
    
    print_status "Bluetooth processes:"
    if pgrep -f "blueman" > /dev/null; then
        print_success "Blueman: RUNNING"
    else
        print_warning "Blueman: NOT RUNNING"
    fi
}

# Function to display help
show_help() {
    echo "Bluetooth Troubleshoot Script for Arch Linux + Hyprland"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -q, --quick         Quick fix (skip hardware checks)"
    echo "  -v, --verbose       Verbose output"
    echo "  --no-install        Skip package installation"
    echo "  --no-hyprland       Skip Hyprland configuration"
    echo ""
    echo "This script will:"
    echo "  1. Install required Bluetooth packages"
    echo "  2. Check hardware compatibility"
    echo "  3. Manage rfkill settings"
    echo "  4. Configure systemd services"
    echo "  5. Test Bluetooth functionality"
    echo "  6. Configure Hyprland integration"
    echo "  7. Start Bluetooth manager"
}

# Main function
main() {
    local quick_mode=false
    local verbose=false
    local skip_install=false
    local skip_hyprland=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -q|--quick)
                quick_mode=true
                shift
                ;;
            -v|--verbose)
                verbose=true
                set -x
                shift
                ;;
            --no-install)
                skip_install=true
                shift
                ;;
            --no-hyprland)
                skip_hyprland=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    print_header "BLUETOOTH TROUBLESHOOT SCRIPT"
    print_status "Starting Bluetooth troubleshooting for Arch Linux + Hyprland..."
    
    # Check if not running as root
    check_root
    
    # Install packages
    if [ "$skip_install" = false ]; then
        install_packages
    fi
    
    # Hardware checks (skip in quick mode)
    if [ "$quick_mode" = false ]; then
        check_hardware
    fi
    
    # Check rfkill
    check_rfkill
    
    # Manage Bluetooth service
    manage_bluetooth_service
    
    # Test Bluetooth functionality
    if [ "$quick_mode" = false ]; then
        test_bluetooth
    fi
    
    # Configure Hyprland
    if [ "$skip_hyprland" = false ]; then
        configure_hyprland
    fi
    
    # Start Bluetooth manager
    start_bluetooth_manager
    
    # Show final status
    show_final_status
    
    print_header "TROUBLESHOOTING COMPLETE"
    print_success "Bluetooth troubleshooting completed!"
    print_status "If issues persist, try rebooting your system."
    print_status "For manual testing, use: bluetoothctl"
}

# Run main function with all arguments
main "$@"
