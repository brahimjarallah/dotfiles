#!/bin/bash

# Get the active window address
window=$(hyprctl activewindow -j | jq -r '.address')

# Check if window is currently floating
is_floating=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$is_floating" = "true" ]; then
    # If floating, check if it's pinned (on top)
    is_pinned=$(hyprctl activewindow -j | jq -r '.pinned')
    
    if [ "$is_pinned" = "true" ]; then
        # If pinned, unpin and make it tiled
        hyprctl dispatch pin
        hyprctl dispatch togglefloating
    else
        # If floating but not pinned, just make it tiled
        hyprctl dispatch togglefloating
    fi
else
    # If tiled, make it floating and pin to top
    hyprctl dispatch togglefloating
    hyprctl dispatch pin
fi
