#!/bin/bash

# Test if the display is actually showing output

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

echo "=========================================="
echo "  Testing TFT Display Output"
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
				echo "Found TFT display: $TFT_FB ($fb_driver)"
				break
			fi
		fi
	fi
done

if [ -z "$TFT_FB" ]; then
	echo "ERROR: ILI9486 display not found!"
	exit 1
fi

fbname=$(basename "$TFT_FB")
width=$(cat /sys/class/graphics/$fbname/virtual_size | cut -d, -f1)
height=$(cat /sys/class/graphics/$fbname/virtual_size | cut -d, -f2)
bpp=$(cat /sys/class/graphics/$fbname/bits_per_pixel)

echo "Display: ${width}x${height}, ${bpp} bpp"
echo ""

# Calculate framebuffer size
fb_size=$((width * height * bpp / 8))
echo "Framebuffer size: $fb_size bytes"
echo ""

echo "Test 1: Fill screen with BLACK"
dd if=/dev/zero of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null
sleep 1
echo "  -> Screen should be completely black"
echo ""

echo "Test 2: Fill screen with WHITE"
tr '\0' '\377' < /dev/zero | dd of=$TFT_FB bs=1024 count=$((fb_size / 1024 + 1)) 2>/dev/null
sleep 1
echo "  -> Screen should be completely white"
echo ""

echo "Test 3: Fill screen with RED"
# For 16-bit color (RGB565): red is 0xF800 (11111 000000 00000)
printf '\x00\xF8' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 1
echo "  -> Screen should be completely red"
echo ""

echo "Test 4: Fill screen with GREEN"
# For 16-bit color (RGB565): green is 0x07E0 (00000 111111 00000)
printf '\xE0\x07' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 1
echo "  -> Screen should be completely green"
echo ""

echo "Test 5: Fill screen with BLUE"
# For 16-bit color (RGB565): blue is 0x001F (00000 000000 11111)
printf '\x1F\x00' | dd of=$TFT_FB bs=2 count=$((width * height)) 2>/dev/null
sleep 1
echo "  -> Screen should be completely blue"
echo ""

echo "Test 6: Random pattern (5 seconds)"
timeout 5 cat /dev/urandom > $TFT_FB 2>/dev/null
echo "  -> Screen should have shown random colorful pixels"
echo ""

echo "=========================================="
echo "  Test Complete"
echo "=========================================="
echo ""
echo "Did you see the colors change on your TFT display?"
echo ""
read -p "Did the display show BLACK? (y/n): " test1
read -p "Did the display show WHITE? (y/n): " test2
read -p "Did the display show RED? (y/n): " test3
read -p "Did the display show GREEN? (y/n): " test4
read -p "Did the display show BLUE? (y/n): " test5
read -p "Did the display show random pixels? (y/n): " test6
echo ""

if [[ "$test1" == "y" && "$test2" == "y" ]]; then
	echo "✓ Display is working correctly!"
	echo ""
	echo "The 'No space left on device' message is NORMAL."
	echo "It just means the framebuffer filled up."
elif [[ "$test1" == "n" && "$test2" == "n" ]]; then
	echo "✗ Display is NOT working - screen stays blank"
	echo ""
	echo "Possible issues:"
	echo "1. Wrong GPIO pins (Reset/DC pins)"
	echo "2. Display not properly connected"
	echo "3. Display requires different initialization"
	echo "4. Hardware issue"
	echo ""
	echo "Checking hardware configuration..."
	echo ""
	dmesg | grep -i "ili9486\|fbtft" | tail -20
else
	echo "⚠ Partial display function"
	echo ""
	echo "Some tests worked but not all. This might indicate:"
	echo "- Timing issues"
	echo "- Incorrect color format"
	echo "- Partial hardware problem"
fi

echo ""
