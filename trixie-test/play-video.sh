#!/bin/bash

# Play video on the TFT display

if [ $# -eq 0 ]; then
    echo "Usage: $0 <video-file>"
    echo ""
    echo "Example:"
    echo "  $0 testvideo.mp4"
    echo ""
    echo "Supported formats: mp4, avi, mkv, webm, etc."
    exit 1
fi

VIDEO_FILE="$1"

if [ ! -f "$VIDEO_FILE" ]; then
    echo "ERROR: Video file not found: $VIDEO_FILE"
    exit 1
fi

# Find the TFT framebuffer
TFT_FB=""
for fb in /dev/fb*; do
    if [ -e "$fb" ]; then
        fbname=$(basename "$fb")
        if [ -f "/sys/class/graphics/$fbname/name" ]; then
            fb_driver=$(cat "/sys/class/graphics/$fbname/name")
            if echo "$fb_driver" | grep -q "ili9486"; then
                TFT_FB="$fb"
                break
            fi
        fi
    fi
done

if [ -z "$TFT_FB" ]; then
    echo "ERROR: ILI9486 display not found!"
    exit 1
fi

echo "Playing on TFT display: $TFT_FB"
echo "Press 'q' to quit, space to pause"
echo ""

# Check if mpv is installed
if command -v mpv &> /dev/null; then
    echo "Using mpv..."
    # Use DRM output for best performance
    mpv --vo=drm --drm-connector=0 "$VIDEO_FILE"
elif command -v mplayer &> /dev/null; then
    echo "Using mplayer..."
    mplayer -vo fbdev2:$TFT_FB "$VIDEO_FILE"
else
    echo "No video player found!"
    echo ""
    echo "Install mpv (recommended):"
    echo "  sudo apt-get install mpv"
    echo ""
    echo "Or install mplayer:"
    echo "  sudo apt-get install mplayer"
    exit 1
fi
