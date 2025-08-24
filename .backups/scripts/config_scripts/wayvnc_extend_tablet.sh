#!/usr/bin/env bash
##############################
# Toggle WayVNC on HEADLESS-3
##############################

HEADLESS="HEADLESS-3"
WAYVNC_LOG="$HOME/.local/share/wayvnc.log"

# Detect USB tether IP (replace enp0s20f0u1 if different)
USB_IP=$(ip -4 addr show enp0s20f0u1 2>/dev/null | grep -oP 'inet \K[0-9.]+')

if [[ -z "$USB_IP" ]]; then
    notify-send "USB tether not detected"
    exit 1
fi

# Check if WayVNC is running
if pgrep -x wayvnc >/dev/null; then
    # Stop server
    pkill wayvnc
    hyprctl output destroy "$HEADLESS" 2>/dev/null
    notify-send "WayVNC stopped"
else
    # Start server
    # Create headless monitor if it doesn't exist
    EXIST=$(hyprctl monitors | grep "$HEADLESS")
    if [[ -z "$EXIST" ]]; then
        hyprctl output create headless
        MAIN=$(hyprctl monitors | grep "eDP" | awk '{print $1}')
        hyprctl keyword monitor "$HEADLESS,1920x1080@60,${MAIN}_right,1"
    fi

    wayvnc -f 60 -o "$HEADLESS" &> "$WAYVNC_LOG" &
    notify-send "WayVNC started" "Connect to $USB_IP:5900"
fi

