#!/bin/bash

# Manually load the fbtft driver if it didn't load at boot

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

echo "=========================================="
echo "  Manually Loading ILI9486 Driver"
echo "=========================================="
echo ""

echo "Current framebuffer devices:"
ls -la /dev/fb* 2>/dev/null || echo "No framebuffers found"
echo ""

echo "Loading kernel modules..."

# Load modules in order
echo "  - Loading fbtft..."
modprobe fbtft || echo "fbtft already loaded or failed"

echo "  - Loading fb_ili9486..."
modprobe fb_ili9486 || echo "fb_ili9486 already loaded or failed"

echo "  - Checking if display already bound via device tree..."
echo "    (fbtft_device module not needed with device tree overlay)"

echo ""
echo "Waiting for device to initialize..."
sleep 1

echo ""
echo "=========================================="
echo "  Results"
echo "=========================================="
echo ""

echo "Framebuffer devices:"
ls -la /dev/fb*
echo ""

# Check each framebuffer to see which is the TFT
TFT_FB=""
for fb in /dev/fb*; do
	if [ -e "$fb" ]; then
		fbname=$(basename "$fb")
		if [ -f "/sys/class/graphics/$fbname/name" ]; then
			fb_driver=$(cat "/sys/class/graphics/$fbname/name")
			echo "  $fb -> $fb_driver"
			if echo "$fb_driver" | grep -q "ili9486"; then
				TFT_FB="$fb"
			fi
		fi
	fi
done
echo ""

if [ -n "$TFT_FB" ]; then
	echo "✓ SUCCESS! TFT display found on $TFT_FB"
	echo ""

	# Show info about the display
	fbname=$(basename "$TFT_FB")
	if [ -f "/sys/class/graphics/$fbname/name" ]; then
		echo "Display info:"
		echo "  Name: $(cat /sys/class/graphics/$fbname/name)"
		echo "  Size: $(cat /sys/class/graphics/$fbname/virtual_size)"
		echo "  BPP: $(cat /sys/class/graphics/$fbname/bits_per_pixel)"
	fi
	echo ""
	echo "Test it with:"
	echo "  cat /dev/urandom > $TFT_FB"
	echo ""
	echo "Note: Your TFT is $TFT_FB (usually fb0 when no HDMI connected)"
else
	echo "✗ FAILED - ILI9486 display not found"
	echo "Loaded modules:"
	lsmod | grep -E "fbtft|ili"
	echo ""

	echo "Kernel messages:"
	dmesg | grep -i "ili\|fbtft" | tail -20
	echo ""

	echo "SPI devices:"
	ls -la /sys/bus/spi/devices/
fi

echo ""
