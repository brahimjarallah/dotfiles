#!/usr/bin/env bash

LAT=36.5731
LON=10.6722

# Get raw output (skip first line)
RAW=$(prayer-times --latitude "$LAT" --longitude "$LON" list-prayers | tail -n +2)

# Remove "Adhan", remove "at", remove seconds
CLEANED=$(echo "$RAW" | sed -E 's/Adhan //g' | sed -E 's/ at //g' | sed -E 's/:([0-9]{2})$//')

# Replace prayer names with Arabic
ARABIC=$(echo "$CLEANED" | sed -e 's/Fajr/ الفجر    /' \
                               -e 's/Dhuhr/ الظهر    /' \
                               -e 's/Asr/ العصر    /' \
                               -e 's/Maghrib/المغرب    /' \
                               -e 's/Isha/العشاء    /')

# Show to terminal
echo -e "🕌  الصلاة أوقات - سليمان\n"
echo "$ARABIC"

