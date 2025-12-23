#!/bin/bash

# Verification script for 3.5" TFT display on Trixie
# Run this after installation and reboot to check if everything is working

echo "=========================================="
echo "  3.5\" TFT Display Verification"
echo "=========================================="
echo ""

check_passed=0
check_failed=0

# Check 1: SPI module loaded
echo -n "✓ Checking SPI module... "
if lsmod | grep -q spi_bcm2835; then
	echo "✓ PASS (spi_bcm2835 loaded)"
	((check_passed++))
else
	echo "✗ FAIL (spi_bcm2835 not loaded)"
	((check_failed++))
fi

# Check 2: Device tree overlay loaded
echo -n "✓ Checking device tree overlay... "
if [ -f /boot/firmware/overlays/ili9486-drm.dtbo ]; then
	echo "✓ PASS (overlay file exists)"
	((check_passed++))
else
	echo "✗ FAIL (overlay file missing)"
	((check_failed++))
fi

# Check 3: DRM devices
echo -n "✓ Checking DRM devices... "
if ls /dev/dri/card* &> /dev/null; then
	echo "✓ PASS ($(ls /dev/dri/card* | wc -l) card(s) found)"
	((check_passed++))
else
	echo "✗ FAIL (no DRM cards found)"
	((check_failed++))
fi

# Check 4: ILI9486 in kernel messages
echo -n "✓ Checking kernel messages for ili9486... "
if dmesg | grep -qi ili9486; then
	echo "✓ PASS (ili9486 found in dmesg)"
	((check_passed++))
else
	echo "⚠ WARNING (ili9486 not found in dmesg)"
	echo "   This might be normal if driver loaded without messages"
fi

# Check 5: Framebuffer devices
echo -n "✓ Checking framebuffer devices... "
if ls /dev/fb* &> /dev/null; then
	fb_count=$(ls /dev/fb* | wc -l)
	echo "✓ PASS ($fb_count framebuffer(s) found)"
	((check_passed++))

	# Show framebuffer info
	echo "  Framebuffer details:"
	for fb in /dev/fb*; do
		if [ -f /sys/class/graphics/$(basename $fb)/name ]; then
			fb_name=$(cat /sys/class/graphics/$(basename $fb)/name)
			echo "    - $(basename $fb): $fb_name"
		fi
	done
else
	echo "✗ FAIL (no framebuffer devices found)"
	((check_failed++))
fi

# Check 6: Touch input device
echo -n "✓ Checking touch input device... "
if grep -q "ADS7846" /proc/bus/input/devices 2>/dev/null; then
	echo "✓ PASS (ADS7846 touchscreen found)"
	((check_passed++))

	# Find the event device
	touch_event=$(grep -B 5 "ADS7846" /proc/bus/input/devices | grep -o "event[0-9]*" | head -1)
	if [ -n "$touch_event" ]; then
		echo "    Touch device: /dev/input/$touch_event"
	fi
else
	echo "✗ FAIL (ADS7846 not found)"
	((check_failed++))
fi

# Check 7: Config.txt
echo -n "✓ Checking /boot/firmware/config.txt... "
if grep -q "ili9486-drm" /boot/firmware/config.txt; then
	echo "✓ PASS (ili9486-drm overlay configured)"
	((check_passed++))
else
	echo "✗ FAIL (ili9486-drm overlay not in config.txt)"
	((check_failed++))
fi

# Check 8: X11 calibration file
echo -n "✓ Checking X11 touch calibration... "
if [ -f /etc/X11/xorg.conf.d/99-calibration.conf ]; then
	echo "✓ PASS (calibration file exists)"
	((check_passed++))
else
	echo "⚠ WARNING (calibration file not found)"
	echo "   This is only needed if you use X11/desktop environment"
fi

echo ""
echo "=========================================="
echo "  Summary"
echo "=========================================="
echo "Passed: $check_passed"
echo "Failed: $check_failed"
echo ""

if [ $check_failed -eq 0 ]; then
	echo "✓ All critical checks passed!"
	echo ""
	echo "Your display should be working. To test:"
	echo "1. You should see console output on the TFT"
	echo "2. Try: cat /dev/urandom > /dev/fb0"
	echo "   (This will show random pixels - Ctrl+C to stop)"
	echo "3. Test touch: sudo evtest /dev/input/$touch_event"
	echo ""
else
	echo "✗ Some checks failed. Please review the output above."
	echo ""
	echo "Troubleshooting tips:"
	echo "1. Make sure you rebooted after installation"
	echo "2. Check dmesg for errors: dmesg | grep -i 'spi\|ili\|ads'"
	echo "3. Verify SPI is enabled: grep 'dtparam=spi' /boot/firmware/config.txt"
	echo "4. Check overlay loaded: dtoverlay -l"
	echo ""
fi

echo "For detailed troubleshooting, see README-TRIXIE.md"
echo ""
