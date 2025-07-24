#!/bin/bash
# Tell the system to use the Bash shell to run this script

query=$(wl-paste --no-newline)
# Get clipboard content using wl-paste (Wayland clipboard tool)
# --no-newline removes trailing newline that might break the URL

if [ -n "$query" ]; then
  # Check if clipboard content is not empty

  brave "https://translate.google.com/?sl=auto&tl=fr&text=$(printf '%s' "$query" | jq -sRr @uri)&op=translate"
  # Launch Brave with the Google Translate URL
  # sl=auto → detect source language
  # tl=fr → translate to French (you can change "fr" to any language code like "en", "ar", etc.)
  # text=... → clipboard content, safely URL-encoded using jq
  # op=translate → ensures it opens in "Translate" mode
fi
# End the condition

