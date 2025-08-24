#!/bin/bash

# extend_tablet.sh
# Usage: ./extend_tablet.sh start|stop

WAYVNC_CONFIG="$HOME/.config/wayvnc/config"
RESOLUTION="1280x720@60"
POSITION="-1280x0"  # always left of main monitor

case "$1" in
    start)
        echo "Destroying old HEADLESS monitors..."
        for old in $(hyprctl monitors | grep HEADLESS- | awk '{print $2}'); do
            echo "Destroying $old..."
            hyprctl output destroy "$old"
        done

        # Create new headless monitor
        hyprctl output create headless

        # Wait for Hyprland to register the output
        timeout=5
        for i in $(seq 1 $timeout); do
            HEADLESS_NAME=$(hyprctl monitors | grep HEADLESS- | awk '{print $2}' | head -n1)
            [ -n "$HEADLESS_NAME" ] && break
            sleep 0.2
        done

        if [ -z "$HEADLESS_NAME" ]; then
            echo "Failed to detect HEADLESS monitor"
            exit 1
        fi

        echo "Setting resolution for $HEADLESS_NAME..."
        hyprctl keyword monitor "$HEADLESS_NAME,$RESOLUTION,$POSITION,1"

        echo "Starting WayVNC on $HEADLESS_NAME..."
        wayvnc -o "$HEADLESS_NAME" -f 60 -v &
        echo "WayVNC server running on $HEADLESS_NAME (PID $!)"
        ;;
    stop)
        echo "Stopping WayVNC..."
        pkill -f "wayvnc -o HEADLESS-"
        echo "Destroying HEADLESS monitors..."
        for old in $(hyprctl monitors | grep HEADLESS- | awk '{print $2}'); do
            echo "Destroying $old..."
            hyprctl output destroy "$old"
        done
        ;;
    *)
        echo "Usage: $0 start|stop"
        exit 1
        ;;
esac

