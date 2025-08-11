#!/bin/bash

if [ -f ~/.scrcpy_pid ]; then
  PID=$(cat ~/.scrcpy_pid)
  if kill -0 $PID 2>/dev/null; then
    kill $PID
    rm ~/.scrcpy_pid
    echo "scrcpy stopped."
  else
    echo "scrcpy process not found."
    rm ~/.scrcpy_pid
  fi
else
  echo "scrcpy is not running."
fi

