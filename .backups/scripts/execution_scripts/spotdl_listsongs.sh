#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

while IFS= read -r line; do
  spotdl download "$line" --output "/home/ibrahim/media/msc/Liked_songs"
done < ~/media/msc/spotify_songs.txt

