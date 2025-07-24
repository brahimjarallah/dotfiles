# Audio plugins & multimedia support
echo "🔌 Installing audio plugins and codec libraries..."
sudo pacman -S --needed --noconfirm \
    ladspa \
    lv2 \
    calf \
    gstreamer \
    gst-plugins-base \
    gst-plugins-good \
    gst-plugins-bad \
    gst-plugins-ugly \
    gst-libav \
    pipewire \
    pipewire-alsa \
    pipewire-pulse \
    pipewire-jack \
    ffmpeg \
    lame \
    flac \
    opus-tools \
    vorbis-tools \
    sox \
    libsamplerate \
    libsndfile \
    soundtouch

sudo pacman -S lame libvorbis libmad

