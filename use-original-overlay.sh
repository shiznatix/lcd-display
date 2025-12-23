#!/bin/bash

# Use the ORIGINAL tft35a overlay that should work

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"
source ./vars.sh

echo "=========================================="
echo "  Using Original tft35a Overlay"
echo "=========================================="
echo ""

echo "** Backing up current config **"
cp "$BOOT_CONFIG" "$BOOT_CONFIG.backup-$(date +%Y%m%d-%H%M%S)"

echo "** Copying original overlay **"
cp ./usr/tft35a-overlay.dtb "$BOOT_OVERLAYS/"
cp ./usr/tft35a-overlay.dtb "$BOOT_OVERLAYS/tft35a.dtbo"

echo "** Updating config.txt **"

# Remove any ili9486 overlays we added
sed -i '/^dtoverlay=ili9486/d' "$BOOT_CONFIG"
sed -i '/^dtoverlay=fbtft/d' "$BOOT_CONFIG"

# Add the original tft35a overlay
if ! grep -q "^dtoverlay=tft35a" "$BOOT_CONFIG"; then
    echo "" >> "$BOOT_CONFIG"
    echo "# TFT35a 3.5\" display - original overlay" >> "$BOOT_CONFIG"
    echo "dtoverlay=tft35a:rotate=90" >> "$BOOT_CONFIG"
fi

# Ensure SPI is enabled
if ! grep -q "^dtparam=spi=on" "$BOOT_CONFIG"; then
    echo "dtparam=spi=on" >> "$BOOT_CONFIG"
fi

# Configure console
CMDLINE=$(cat "$BOOT_CMDLINE")
CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=[^ ]*//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
echo "$CMDLINE fbcon=font:VGA8x8" > "$BOOT_CMDLINE"

echo "** Configuring touch controller **"
if ! grep -q "^dtoverlay=ads7846" "$BOOT_CONFIG"; then
    echo "dtoverlay=ads7846,penirq=17,speed=2000000,swapxy=1" >> "$BOOT_CONFIG"
fi

echo ""
echo "=========================================="
echo "  Configuration Updated"
echo "=========================================="
echo ""
echo "Using the ORIGINAL overlay that should work."
echo ""
echo "REBOOT NOW:"
echo "  sudo reboot"
echo ""
echo "After reboot, check:"
echo "  ls -la /dev/fb*"
echo "  sudo ./test-display.sh"
echo ""
