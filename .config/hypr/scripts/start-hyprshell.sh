#!/bin/bash
# Wait a few seconds to ensure Hyprland is ready
sleep 5
export XDG_CURRENT_DESKTOP=Hyprland
/usr/bin/hyprshell run &

