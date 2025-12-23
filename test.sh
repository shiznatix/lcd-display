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

test_black="dd if=/dev/zero of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null"
test_white="tr '\0' '\377' < /dev/zero | dd of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null"
test_red="printf '\x00\xF8' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null"
test_green="printf '\xE0\x07' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null"
test_blue="printf '\x1F\x00' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null"
test_random="timeout 3 cat /dev/urandom > $TFT_FB 2>/dev/null"

echo "Running screen tests in random order (watch your TFT display)..."
echo ""

# Create array of test commands with labels
tests=("BLACK:$test_black" "WHITE:$test_white" "RED:$test_red" "GREEN:$test_green" "BLUE:$test_blue" "RANDOM:$test_random")

# Shuffle the array using shuf
readarray -t shuffled < <(printf '%s\n' "${tests[@]}" | shuf)

# Run each test in random order
count=1
for test in "${shuffled[@]}"; do
	color="${test%%:*}"
	command="${test#*:}"
	echo "$count. $color screen..."
	eval "$command"
	sleep 3
	((count++))
done

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
