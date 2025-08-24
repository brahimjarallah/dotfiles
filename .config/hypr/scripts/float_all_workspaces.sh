#!/bin/bash

window_info=$(hyprctl activewindow -j)
window_class=$(echo "$window_info" | jq -r '.class')
window_title=$(echo "$window_info" | jq -r '.title')

# Make floating and pinned
hyprctl dispatch togglefloating
hyprctl dispatch pin

# Store this window info for a daemon to track
echo "$window_class:$window_title" >> ~/.config/hypr/sticky_windows.txt

# You would need a separate daemon/script to move these windows
# to new workspaces when you switch to them
