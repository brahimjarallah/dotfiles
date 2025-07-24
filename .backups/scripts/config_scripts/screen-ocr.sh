#!/bin/bash

# Advanced Screen OCR Script for Hyprland
# Features: Multiple OCR engines, language detection, preprocessing

# Dependencies check
check_deps() {
    local deps=("grim" "slurp" "tesseract" "wl-copy" "notify-send" "convert")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo "Error: $dep is not installed"
            exit 1
        fi
    done
}

# OCR with preprocessing for better accuracy
ocr_with_preprocessing() {
    local temp_file=$(mktemp --suffix=.png)
    
    # Capture screen region
    grim -g "$(slurp)" "$temp_file"
    
    if [ ! -f "$temp_file" ]; then
        notify-send "OCR Error" "Failed to capture screen"
        exit 1
    fi
    
    # Preprocess image for better OCR
    convert "$temp_file" \
        -modulate 100,0 \
        -resize 400% \
        -sharpen 0x1 \
        -contrast-stretch 0.1x0.1% \
        "$temp_file"
    
    # OCR with multiple engines fallback
    local text=""
    
    # Try tesseract first
    text=$(tesseract "$temp_file" stdout 2>/dev/null)
    
    # If tesseract fails or returns empty, try easyocr (if available)
    if [ -z "$text" ] && command -v easyocr &> /dev/null; then
        text=$(easyocr -l en "$temp_file" --detail=0 --paragraph 2>/dev/null)
    fi
    
    # Clean up
    rm -f "$temp_file"
    
    if [ -n "$text" ]; then
        # Copy to clipboard
        echo "$text" | wl-copy
        
        # Show notification with preview
        local preview=$(echo "$text" | head -c 100)
        [ ${#text} -gt 100 ] && preview="$preview..."
        notify-send "OCR Success" "Text copied to clipboard:\n$preview"
        
        # Optional: also save to file
        echo "$text" >> ~/Documents/ocr_history.txt
        echo "$(date): $text" >> ~/Documents/ocr_history.txt
    else
        notify-send "OCR Failed" "No text found in selection"
    fi
}

# Multi-language OCR
ocr_multilang() {
    local lang=${1:-"eng"}
    local temp_file=$(mktemp --suffix=.png)
    
    grim -g "$(slurp)" "$temp_file"
    
    # Use tesseract with specified language
    local text=$(tesseract "$temp_file" stdout -l "$lang" 2>/dev/null)
    
    rm -f "$temp_file"
    
    if [ -n "$text" ]; then
        echo "$text" | wl-copy
        notify-send "OCR Success ($lang)" "Text copied to clipboard"
    else
        notify-send "OCR Failed" "No text found"
    fi
}

# Interactive mode with rofi/wofi
interactive_ocr() {
    local options="Standard OCR
Arabic OCR
French OCR
German OCR
Japanese OCR
Chinese OCR
Full Screen OCR
Window OCR"
    
    local choice=$(echo "$options" | wofi --dmenu --prompt "Select OCR mode:")
    
    case "$choice" in
        "Standard OCR") ocr_with_preprocessing ;;
        "Arabic OCR") ocr_multilang "ara" ;;
        "French OCR") ocr_multilang "fra" ;;
        "German OCR") ocr_multilang "deu" ;;
        "Japanese OCR") ocr_multilang "jpn" ;;
        "Chinese OCR") ocr_multilang "chi_sim" ;;
        "Full Screen OCR") 
            grim - | tesseract stdin stdout | wl-copy
            notify-send "OCR Success" "Full screen text copied"
            ;;
        "Window OCR")
            local window=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
            grim -g "$window" - | tesseract stdin stdout | wl-copy
            notify-send "OCR Success" "Window text copied"
            ;;
    esac
}

# Main execution
main() {
    check_deps
    
    case "${1:-interactive}" in
        "quick"|"q") ocr_with_preprocessing ;;
        "lang") ocr_multilang "$2" ;;
        "interactive"|"i") interactive_ocr ;;
        *) 
            echo "Usage: $0 [quick|lang <language>|interactive]"
            echo "Languages: eng, ara, fra, deu, jpn, chi_sim, etc."
            ;;
    esac
}

main "$@"
