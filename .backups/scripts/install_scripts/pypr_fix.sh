#!/bin/bash
# Create this as ~/fix_pypr.sh and make executable
echo "Cleaning up pypr sockets and processes..."
pkill -f pypr
find /run/user/$(id -u)/hypr -name "*.pyprland.sock" -delete 2>/dev/null
sleep 1
echo "Starting pypr daemon..."
pypr &
sleep 2
echo "Testing..."
pypr toggle term
