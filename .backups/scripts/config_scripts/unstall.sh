#!/bin/bash

# Complete xremap uninstall script
# Run with: bash xremap-uninstall.sh

set -e

echo "🗑️ Completely removing xremap and all related settings..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Stop and disable xremap service
echo -e "${YELLOW}🛑 Stopping xremap service...${NC}"
if sudo systemctl is-active --quiet xremap 2>/dev/null; then
    sudo systemctl stop xremap
    echo -e "${GREEN}✅ xremap service stopped${NC}"
else
    echo -e "${YELLOW}ℹ️ xremap service was not running${NC}"
fi

echo -e "${YELLOW}🚫 Disabling xremap service...${NC}"
if sudo systemctl is-enabled --quiet xremap 2>/dev/null; then
    sudo systemctl disable xremap
    echo -e "${GREEN}✅ xremap service disabled${NC}"
else
    echo -e "${YELLOW}ℹ️ xremap service was not enabled${NC}"
fi

# Stop and disable user xremap service
echo -e "${YELLOW}🛑 Stopping user xremap service...${NC}"
if systemctl --user is-active --quiet xremap 2>/dev/null; then
    systemctl --user stop xremap
    echo -e "${GREEN}✅ User xremap service stopped${NC}"
else
    echo -e "${YELLOW}ℹ️ User xremap service was not running${NC}"
fi

echo -e "${YELLOW}🚫 Disabling user xremap service...${NC}"
if systemctl --user is-enabled --quiet xremap 2>/dev/null; then
    systemctl --user disable xremap
    echo -e "${GREEN}✅ User xremap service disabled${NC}"
else
    echo -e "${YELLOW}ℹ️ User xremap service was not enabled${NC}"
fi

# Remove systemd service files
echo -e "${YELLOW}🗑️ Removing systemd service files...${NC}"
if [[ -f /etc/systemd/system/xremap.service ]]; then
    sudo rm -f /etc/systemd/system/xremap.service
    echo -e "${GREEN}✅ System service file removed${NC}"
else
    echo -e "${YELLOW}ℹ️ System service file not found${NC}"
fi

if [[ -f ~/.config/systemd/user/xremap.service ]]; then
    rm -f ~/.config/systemd/user/xremap.service
    echo -e "${GREEN}✅ User service file removed${NC}"
else
    echo -e "${YELLOW}ℹ️ User service file not found${NC}"
fi

# Remove systemd user directory if empty
if [[ -d ~/.config/systemd/user ]]; then
    if [[ -z "$(ls -A ~/.config/systemd/user)" ]]; then
        rm -rf ~/.config/systemd/user
        echo -e "${GREEN}✅ Empty systemd user directory removed${NC}"
    fi
fi

# Reload systemd daemon
echo -e "${YELLOW}🔄 Reloading systemd daemon...${NC}"
sudo systemctl daemon-reload
systemctl --user daemon-reload
sudo systemctl reset-failed
systemctl --user reset-failed

# Remove xremap config directory
echo -e "${YELLOW}🗑️ Removing xremap config directory...${NC}"
if [[ -d ~/.config/xremap ]]; then
    rm -rf ~/.config/xremap
    echo -e "${GREEN}✅ Config directory removed${NC}"
else
    echo -e "${YELLOW}ℹ️ Config directory not found${NC}"
fi

# Remove system-wide config directory (if exists)
echo -e "${YELLOW}🗑️ Removing system config directory...${NC}"
if [[ -d /etc/xremap ]]; then
    sudo rm -rf /etc/xremap
    echo -e "${GREEN}✅ System config directory removed${NC}"
else
    echo -e "${YELLOW}ℹ️ System config directory not found${NC}"
fi

# Remove xremap package
echo -e "${YELLOW}📦 Uninstalling xremap package...${NC}"
if pacman -Q xremap &>/dev/null; then
    yay -R xremap --noconfirm
    echo -e "${GREEN}✅ xremap package removed${NC}"
elif pacman -Q xremap-bin &>/dev/null; then
    yay -R xremap-bin --noconfirm
    echo -e "${GREEN}✅ xremap-bin package removed${NC}"
elif pacman -Q xremap-git &>/dev/null; then
    yay -R xremap-git --noconfirm
    echo -e "${GREEN}✅ xremap-git package removed${NC}"
else
    echo -e "${YELLOW}ℹ️ xremap package not found${NC}"
fi

# Remove user from input group (optional - ask user)
echo -e "${YELLOW}👤 Checking input group membership...${NC}"
if groups $USER | grep -q "input"; then
    echo -e "${YELLOW}⚠️ You are in the 'input' group. Remove yourself? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        sudo gpasswd -d $USER input
        echo -e "${GREEN}✅ Removed from input group${NC}"
        echo -e "${YELLOW}ℹ️ You may need to log out and back in for group changes to take effect${NC}"
    else
        echo -e "${YELLOW}ℹ️ Keeping input group membership${NC}"
    fi
else
    echo -e "${YELLOW}ℹ️ You are not in the input group${NC}"
fi

# Check for any remaining xremap processes
echo -e "${YELLOW}🔍 Checking for remaining xremap processes...${NC}"
if pgrep -f xremap &>/dev/null; then
    echo -e "${RED}⚠️ Found running xremap processes. Killing them...${NC}"
    sudo pkill -f xremap
    echo -e "${GREEN}✅ Processes killed${NC}"
else
    echo -e "${GREEN}✅ No xremap processes found${NC}"
fi

# Clean up any xremap virtual devices
echo -e "${YELLOW}🧹 Cleaning up virtual input devices...${NC}"
if ls /dev/input/by-id/*xremap* &>/dev/null; then
    echo -e "${YELLOW}ℹ️ Found xremap virtual devices (they will be removed on reboot)${NC}"
else
    echo -e "${GREEN}✅ No xremap virtual devices found${NC}"
fi

# Remove any udev rules if they exist
echo -e "${YELLOW}🗑️ Checking for udev rules...${NC}"
if [[ -f /etc/udev/rules.d/99-xremap.rules ]]; then
    sudo rm -f /etc/udev/rules.d/99-xremap.rules
    sudo udevadm control --reload-rules
    echo -e "${GREEN}✅ udev rules removed${NC}"
else
    echo -e "${YELLOW}ℹ️ No udev rules found${NC}"
fi

# Remove any desktop files
echo -e "${YELLOW}🗑️ Checking for desktop files...${NC}"
if [[ -f ~/.local/share/applications/xremap.desktop ]]; then
    rm -f ~/.local/share/applications/xremap.desktop
    echo -e "${GREEN}✅ Desktop file removed${NC}"
else
    echo -e "${YELLOW}ℹ️ No desktop files found${NC}"
fi

# Remove any log files
echo -e "${YELLOW}🗑️ Removing log files...${NC}"
if [[ -f ~/.local/share/xremap/xremap.log ]]; then
    rm -rf ~/.local/share/xremap
    echo -e "${GREEN}✅ Log files removed${NC}"
else
    echo -e "${YELLOW}ℹ️ No log files found${NC}"
fi

# Final cleanup
echo -e "${YELLOW}🧹 Final cleanup...${NC}"
sudo systemctl daemon-reload
systemctl --user daemon-reload

echo ""
echo -e "${GREEN}🎉 xremap completely removed!${NC}"
echo ""
echo -e "${YELLOW}Summary of what was removed:${NC}"
echo "• xremap package"
echo "• systemd service files (system and user)"
echo "• Config directories (~/.config/xremap and /etc/xremap)"
echo "• Any running xremap processes"
echo "• udev rules (if present)"
echo "• Desktop files"
echo "• Log files"
echo ""
echo -e "${YELLOW}Optional next steps:${NC}"
echo "• Reboot to ensure all virtual devices are cleaned up"
echo "• Check if you want to remove other key remapping tools"
echo ""
echo -e "${GREEN}✅ System restored to original state${N}"
