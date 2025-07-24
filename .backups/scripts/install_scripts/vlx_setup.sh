#!/usr/bin/env bash
set -euo pipefail

echo "Hello from $0"

#!/bin/bash

# Ensure yay is installed
command -v yay >/dev/null 2>&1 || {
  echo "❌ yay is not installed. Installing yay first..."
  sudo pacman -S --needed base-devel git
  git clone https://aur.archlinux.org/yay.git
  cd yay && makepkg -si && cd .. && rm -rf yay
}

# Update package list
echo "🔄 Updating package database..."
yay -Sy

# Install VLC-bin and full plugin support
echo "🎥 Installing vlc-bin and all recommended plugins/codecs..."

yay -S --noconfirm --needed \
  vlc-bin \
  ffmpeg \
  gst-libav \
  gst-plugins-base \
  gst-plugins-good \
  gst-plugins-bad \
  gst-plugins-ugly \
  libdvdcss \
  libbluray \
  libaom \
  libvpx \
  x264 x265 \
  dav1d \
  a52dec \
  faac \
  faad2 \
  flac \
  lame \
  libmad \
  libmpeg2 \
  libtheora \
  libvorbis \
  opusfile \
  speex \
  libdvbpsi \
  libdc1394 \
  twolame \
  zvbi \
  samba \
  libshout \
  ncurses \
  libpulse \
  alsa-lib \
  jack \
  libsamplerate \
  sdl2 \
  qt5-base \
  qt5-x11extras \
  qt5-svg \
  libnotify \
  libdvdread libdvdnav \
  lua52 \
  chromaprint \
  freetype2 \
  harfbuzz \
  libarchive \
  libssh2

echo "🎉 VLC-bin installed with all major multimedia plugins and codecs!"
echo "✅ Ready to play virtually any media format!"

