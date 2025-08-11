#!/bin/bash

# Check if scrcpy is already running
if pgrep -x scrcpy > /dev/null; then
  echo "scrcpy is already running."
  exit 0
fi

# Start scrcpy in background
scrcpy &
# Save PID to file
echo $! > ~/.scrcpy_pid

