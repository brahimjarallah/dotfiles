#!/bin/bash

# Swappy Screen Annotation Setup for Hyprland
# Author: Arch Linux Hyprland Expert
# Description: Complete installation and configuration script

set -e

echo "🚀 Starting Swappy installation for Hyprland..."

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

# Check if running Arch Linux
if ! command -v pacman &> /dev/null; then
    print_error "This script is designed for Arch Linux systems with pacman"
    exit 1
fi

# Check if Hyprland is installed
if ! command -v hyprctl &> /dev/null; then
    print_warning "Hyprland not found. Make sure it's installed and running."
fi

print_status "Installing required packages..."

# Install packages
sudo pacman -S --needed --noconfirm swappy grim slurp wl-clipboard

print_success "Packages installed successfully"

# Create config directories
print_status "Creating configuration directories..."
mkdir -p ~/.config/swappy
mkdir -p ~/Downloads
mkdir -p ~/.config/hypr/scripts

print_success "Directories created"

# Create Swappy configuration
print_status "Creating Swappy configuration..."
cat > ~/.config/swappy/config << 'EOF'
[Default]
save_dir=$HOME/Downloads
save_filename_format=swappy-%Y%m%d-%H%M%S.png
show_panel=true
line_size=5
text_size=20
text_font=sans-serif
paint_mode=brush
early_exit=true
fill_shape=false
EOF

print_success "Swappy configuration created"

# Backup existing keybindings config if it exists
if [ -f ~/.config/hypr/keybindings.conf ]; then
    print_status "Backing up existing keybindings configuration..."
    cp ~/.config/hypr/keybindings.conf ~/.config/hypr/keybindings.conf.backup.$(date +%Y%m%d-%H%M%S)
    print_success "Backup created"
fi

# Check if keybindings already exist
if [ -f ~/.config/hypr/keybindings.conf ] && grep -q "swappy" ~/.config/hypr/keybindings.conf; then
    print_warning "Swappy keybindings already exist in keybindings.conf"
    read -p "Do you want to add them anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping keybinding addition"
        SKIP_KEYBINDS=true
    fi
fi

if [ "$SKIP_KEYBINDS" != true ]; then
    print_status "Adding keybindings to keybindings.conf..."
    
    # Add keybindings to keybindings.conf
    cat >> ~/.config/hypr/keybindings.conf << 'EOF'

# Swappy Screen Annotation Keybindings
# Screenshot and annotate selected area
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" - | swappy -f -
# Screenshot and annotate full screen
bind = $mainMod SHIFT, F, exec, grim - | swappy -f -
# Screenshot area to file then annotate
bind = $mainMod SHIFT, A, exec, grim -g "$(slurp)" /tmp/screenshot.png && swappy -f /tmp/screenshot.png
EOF

    print_success "Keybindings added to keybindings.conf"
fi

# Create a test script
print_status "Creating test script..."
cat > ~/.config/hypr/scripts/test-swappy.sh << 'EOF'
#!/bin/bash
echo "Testing Swappy functionality..."

echo "1. Testing grim..."
if command -v grim &> /dev/null; then
    echo "✓ grim is installed"
else
    echo "✗ grim is NOT installed"
fi

echo "2. Testing slurp..."
if command -v slurp &> /dev/null; then
    echo "✓ slurp is installed"
else
    echo "✗ slurp is NOT installed"
fi

echo "3. Testing swappy..."
if command -v swappy &> /dev/null; then
    echo "✓ swappy is installed"
else
    echo "✗ swappy is NOT installed"
fi

echo "4. Testing wl-clipboard..."
if command -v wl-copy &> /dev/null; then
    echo "✓ wl-clipboard is installed"
else
    echo "✗ wl-clipboard is NOT installed"
fi

echo ""
echo "Configuration files:"
echo "Swappy config: ~/.config/swappy/config"
echo "Screenshots dir: ~/Downloads"
echo "Keybindings: ~/.config/hypr/keybindings.conf"
echo ""
echo "Keybindings:"
echo "Super + Shift + S: Screenshot selected area and annotate"
echo "Super + Shift + F: Screenshot full screen and annotate"
echo "Super + Shift + A: Screenshot area to file then annotate"
echo ""
echo "To reload Hyprland config: hyprctl reload"
EOF

chmod +x ~/.config/hypr/scripts/test-swappy.sh

print_success "Test script created at ~/.config/hypr/scripts/test-swappy.sh"

echo ""
print_success "🎉 Swappy installation completed successfully!"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Reload Hyprland config: hyprctl reload"
echo "2. Test with: Super + Shift + S (select area and annotate)"
echo "3. Test with: Super + Shift + F (full screen and annotate)"
echo "4. Test with: Super + Shift + A (area to file then annotate)"
echo ""
echo -e "${BLUE}Files created:${NC}"
echo "• ~/.config/swappy/config"
echo "• ~/Downloads/ (directory)"
echo "• ~/.config/hypr/scripts/test-swappy.sh"
echo "• Keybindings added to ~/.config/hypr/keybindings.conf"
echo ""
echo -e "${BLUE}To test installation:${NC}"
echo "~/.config/hypr/scripts/test-swappy.sh"
echo ""

# Optional: Reload Hyprland if it's running
if pgrep -x "Hyprland" > /dev/null; then
    read -p "Reload Hyprland configuration now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        hyprctl reload
        print_success "Hyprland configuration reloaded"
    fi
fi

print_success "Installation complete! 🚀"
