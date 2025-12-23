#!/bin/bash

# Simple screen test for TFT display - confirms framebuffer writes work

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

echo "=========================================="
echo "  TFT Display Screen Test"
echo "=========================================="
echo ""

# Find the TFT framebuffer
TFT_FB=""
for fb in /dev/fb*; do
	if [ -e "$fb" ]; then
		fbname=$(basename "$fb")
		if [ -f "/sys/class/graphics/$fbname/name" ]; then
			fb_driver=$(cat "/sys/class/graphics/$fbname/name")
			if echo "$fb_driver" | grep -q "ili9486"; then
				TFT_FB="$fb"
				echo "✓ Found TFT display: $TFT_FB"
				break
			fi
		fi
	fi
done

if [ -z "$TFT_FB" ]; then
	echo "✗ ERROR: ILI9486 display not found!"
	echo ""
	echo "Run diagnostics: sudo ./diagnostics.sh"
	exit 1
fi

fbname=$(basename "$TFT_FB")
width=$(cat /sys/class/graphics/$fbname/virtual_size | cut -d, -f1)
height=$(cat /sys/class/graphics/$fbname/virtual_size | cut -d, -f2)
bpp=$(cat /sys/class/graphics/$fbname/bits_per_pixel)

echo "  Display: ${width}x${height}, ${bpp}-bit color"
echo ""

# Calculate framebuffer size
fb_size=$((width * height * bpp / 8))

echo "Running screen tests (watch your TFT display)..."
echo ""

echo "1. BLACK screen..."
dd if=/dev/zero of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null
sleep 3

echo "2. WHITE screen..."
tr '\0' '\377' < /dev/zero | dd of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null
sleep 3

echo "3. RED screen..."
printf '\x00\xF8' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 3

echo "4. GREEN screen..."
printf '\xE0\x07' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 3

echo "5. BLUE screen..."
printf '\x1F\x00' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 3

echo "6. Random pattern (3 seconds)..."
timeout 3 cat /dev/urandom > $TFT_FB 2>/dev/null

echo ""
echo "=========================================="
echo "  Test Complete"
echo "=========================================="
echo ""
echo "✓ Display is working if you saw:"
echo "  - Black, white, red, green, blue screens"
echo "  - Colorful random pixels"
echo ""
echo "If the screen stayed blank/white:"
echo "  - Run diagnostics: sudo ./diagnostics.sh"
echo "  - Check connections and reinstall: sudo ./install.sh"
echo ""
