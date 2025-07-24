#!/bin/bash

query=$(wl-paste --no-newline)
# Uses wl-paste to get the current clipboard content, removes trailing newline

if [ -n "$query" ]; then
  # Checks if the clipboard is not empty

  brave "https://www.google.com/search?q=$(printf '%s' "$query" | jq -sRr @uri)"
  # Opens Brave with a Google search URL, encoding the query using jq for URL safety
fi

