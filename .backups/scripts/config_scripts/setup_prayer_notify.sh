#!/usr/bin/env bash

set -e

echo "📦 Installing dependencies..."
yay -S --needed --noconfirm prayer-time paplay alsa-utils mpv

echo "🔊 Downloading ding.wav..."
mkdir -p ~/.local/share/sounds
wget -qO ~/.local/share/sounds/ding.wav https://www.soundjay.com/button/beep-07.wav

echo "⚙️ Creating prayer_notify.sh..."
mkdir -p ~/.local/bin

cat > ~/.local/bin/prayer_notify.sh << 'EOF'
#!/usr/bin/env bash

CITY="Tunis"
ADVANCE_MINUTES=5
SOUND="$HOME/.local/share/sounds/ding.wav"

while true; do
    mapfile -t PRAYERS < <(prayer-time --city "$CITY" | awk 'NF==2 {print $1 " " $2}')
    
    for ENTRY in "${PRAYERS[@]}"; do
        NAME=$(echo "$ENTRY" | awk '{print $1}')
        TIME=$(echo "$ENTRY" | awk '{print $2}')
        
        PRAYER_SEC=$(date -d "$TIME today" +%s)
        NOW_SEC=$(date +%s)
        ADVANCE_SEC=$((ADVANCE_MINUTES * 60))
        WAIT_SEC=$((PRAYER_SEC - NOW_SEC - ADVANCE_SEC))

        if (( WAIT_SEC > 0 )); then
            sleep "$WAIT_SEC"

            notify-send "🕌 $NAME in $ADVANCE_MINUTES min" "Prayer at $TIME"

            # Try playing the sound with fallback
            if command -v paplay &>/dev/null; then
                paplay "$SOUND"
            elif command -v aplay &>/dev/null; then
                aplay "$SOUND"
            elif command -v mpv &>/dev/null; then
                mpv --quiet "$SOUND"
            fi
        fi
    done

    # Sleep to wait for next day's cycle
    sleep 3600
done
EOF

chmod +x ~/.local/bin/prayer_notify.sh

echo "🔧 Adding to Hyprland config if not already present..."
HYPRCONF="$HOME/.config/hypr/hyprland.conf"
if ! grep -q prayer_notify.sh "$HYPRCONF"; then
    echo "exec-once = ~/.local/bin/prayer_notify.sh" >> "$HYPRCONF"
    echo "✅ Added to $HYPRCONF"
else
    echo "ℹ️ Already present in $HYPRCONF"
fi

echo "✅ All set!"
echo "➡️ You will get prayer time notifications with sound on next Hyprland login."

