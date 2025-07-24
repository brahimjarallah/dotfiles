#!/usr/bin/env bash

file="$1"
mime=$(file -Lb --mime-type "$file")

# Image previews
if [[ "$mime" =~ image/* ]]; then
  if [[ -n "$KITTY_WINDOW_ID" ]]; then
    kitty +kitten icat --transfer-mode=file "$file"
    exit
  elif command -v ueberzugpp &>/dev/null; then
    ueberzugpp layer --parser bash --silent < <(
      printf 'add [identifier]="preview" [path]="%s" [x]="0" [y]="0" [width]=40 [height]=20\n' "$file"
      sleep 1
    )
    exit
  elif command -v swayimg &>/dev/null; then
    swayimg "$file"
    exit
  fi
fi

# PDF preview
if [[ "$mime" == application/pdf ]]; then
  if command -v pdftotext &>/dev/null; then
    pdftotext "$file" - | head -n 100
  elif command -v zathura &>/dev/null; then
    zathura "$file" &
    exit
  fi
  exit
fi

# Office files
if [[ "$file" == *.docx || "$file" == *.pptx || "$file" == *.xlsx ]]; then
  pandoc "$file"
  exit
fi

# Audio / Video preview
if [[ "$mime" =~ audio/* ]]; then
  mediainfo "$file" || exiftool "$file"
  exit
elif [[ "$mime" =~ video/* ]]; then
  ffmpegthumbnailer -i "$file" -o /tmp/thumb.png -s 0
  [[ -f /tmp/thumb.png ]] && kitty +kitten icat /tmp/thumb.png
  exit
fi

# JSON, XML, code files
case "$file" in
  *.json) jq . "$file" ;;
  *.xml)  bat --language=xml "$file" ;;
  *)      bat --paging=never --color=always "$file" ;;
esac
