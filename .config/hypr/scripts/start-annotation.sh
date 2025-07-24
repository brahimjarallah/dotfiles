#!/bin/bash

# REAL-TIME SCREEN ANNOTATION FOR HYPRLAND/WAYLAND
# Using actually available tools!

echo "🎨 Real-time Screen Annotation Setup"
echo "===================================="

# Check and install required tools
install_tools() {
    echo "📦 Installing required annotation tools..."
    
    # Install gromit-mpx (the main working annotation tool)
    if ! command -v gromit-mpx &> /dev/null; then
        echo "Installing gromit-mpx..."
        yay -S gromit-mpx --noconfirm
    fi
    
    # Install other tools
    if ! command -v wf-recorder &> /dev/null; then
        echo "Installing wf-recorder..."
        sudo pacman -S wf-recorder --noconfirm
    fi
    
    # Install alternative annotation tools
    yay -S ardesia --noconfirm 2>/dev/null || echo "Ardesia not available"
    yay -S ksnip --noconfirm 2>/dev/null || echo "Ksnip installing..."
    
    echo "✅ Tools installation complete!"
}

# Method 1: gromit-mpx (ACTUALLY WORKS on Wayland!)
start_gromit_annotation() {
    echo "🖊️  Starting Gromit-MPX annotation..."
    
    # Kill any existing instance
    pkill gromit-mpx 2>/dev/null
    
    # Start gromit-mpx in background
    gromit-mpx &
    GROMIT_PID=$!
    
    echo "✅ Gromit-MPX started!"
    echo ""
    echo "🔥 HOTKEYS:"
    echo "  F9        = Toggle annotation mode ON/OFF"
    echo "  SHIFT+F9  = Clear all annotations"
    echo "  CTRL+F9   = Quit annotation"
    echo "  F10       = Change pen color"
    echo "  F11       = Change pen size"
    echo "  F12       = Switch to eraser"
    echo ""
    echo "🎯 RIGHT-CLICK = Context menu with tools!"
}

# Method 2: Using Ardesia (if available)
start_ardesia_annotation() {
    echo "🎨 Starting Ardesia annotation..."
    
    if command -v ardesia &> /dev/null; then
        ardesia &
        ARDESIA_PID=$!
        echo "✅ Ardesia started! Use the floating toolbar to draw."
    else
        echo "❌ Ardesia not available. Using gromit-mpx instead."
        start_gromit_annotation
    fi
}

# Method 3: Ksnip with annotation (screenshot + annotate workflow)
start_ksnip_annotation() {
    echo "📸 Starting Ksnip annotation workflow..."
    
    if command -v ksnip &> /dev/null; then
        # Take screenshot and annotate
        ksnip --rectarea &
        echo "✅ Ksnip started! Select area to screenshot and annotate."
    else
        echo "❌ Ksnip not available. Using gromit-mpx instead."
        start_gromit_annotation
    fi
}

# Method 4: Custom overlay with wf-recorder (for recording with annotation)
start_recording_annotation() {
    echo "🎬 Starting recording with annotation overlay..."
    
    # Start gromit-mpx for overlay
    gromit-mpx &
    GROMIT_PID=$!
    
    # Start recording
    wf-recorder -g "$(slurp)" -f ~/screen-annotation-$(date +%Y%m%d-%H%M%S).mp4 &
    RECORDER_PID=$!
    
    echo "✅ Recording started with annotation overlay!"
    echo "Draw with gromit-mpx hotkeys, recording will capture everything."
}

# Setup gromit-mpx config for better experience
setup_gromit_config() {
    mkdir -p ~/.config/gromit-mpx
    
    cat > ~/.config/gromit-mpx/gromit-mpx.cfg << 'EOF'
# Gromit-MPX Configuration for better annotation

# Red pen
"red Pen" = PEN (size=5 color="red");
"red Pen" = KEY (key="F9" keycode=67);

# Blue pen  
"blue Pen" = PEN (size=5 color="blue");
"blue Pen" = KEY (key="F10" keycode=68);

# Green pen
"green Pen" = PEN (size=5 color="green"); 
"green Pen" = KEY (key="F11" keycode=69);

# Yellow marker
"yellow Marker" = PEN (size=15 color="yellow" alpha=0.5);
"yellow Marker" = KEY (key="F12" keycode=70);

# Eraser
"Eraser" = ERASER (size=20);
"Eraser" = KEY (key="e" keycode=26);

# Clear all
"Clear" = KEY (key="c" keycode=54);
"Clear" = ACTIVATE ("clear");

# Toggle visibility
"Toggle" = KEY (key="t" keycode=28);
"Toggle" = ACTIVATE ("toggle");
EOF
    
    echo "✅ Gromit-MPX configuration created!"
}

# Cleanup function
cleanup_annotation() {
    echo "🧹 Cleaning up annotation tools..."
    pkill gromit-mpx 2>/dev/null
    pkill ardesia 2>/dev/null  
    pkill ksnip 2>/dev/null
    pkill wf-recorder 2>/dev/null
    echo "✅ Cleanup complete!"
}

# Trap for cleanup
trap cleanup_annotation EXIT INT TERM

# Main menu
echo ""
echo "Choose annotation method:"
echo "1) 🖊️  Gromit-MPX (Recommended - works on Wayland!)"
echo "2) 🎨 Ardesia (Alternative drawing tool)"  
echo "3) 📸 Ksnip (Screenshot + annotate)"
echo "4) 🎬 Record with annotation overlay"
echo "5) ⚙️  Install/setup tools"
echo "6) 🧹 Cleanup and exit"
echo ""

read -p "Enter choice (1-6): " choice

case $choice in
    1)
        setup_gromit_config
        start_gromit_annotation
        ;;
    2)
        start_ardesia_annotation
        ;;
    3)
        start_ksnip_annotation
        ;;
    4)
        setup_gromit_config
        start_recording_annotation
        ;;
    5)
        install_tools
        setup_gromit_config
        echo "✅ Setup complete! Run script again to start annotation."
        exit 0
        ;;
    6)
        cleanup_annotation
        exit 0
        ;;
    *)
        echo "❌ Invalid choice. Using Gromit-MPX (recommended)."
        setup_gromit_config
        start_gromit_annotation
        ;;
esac

echo ""
echo "🎯 ANNOTATION ACTIVE!"
echo "Press Ctrl+C to stop annotation and cleanup."
echo ""

# Keep script running
wait
