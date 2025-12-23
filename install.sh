#!/bin/bash

# Use the ORIGINAL tft35a overlay that should work

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"

boot_path="/boot/firmware"
boot_config="$boot_path/config.txt"
boot_cmdline="$boot_path/cmdline.txt"
boot_overlays="$boot_path/overlays"
backups_dir="./system-backups"

echo "=========================================="
echo "  Using Original tft35a Overlay"
echo "=========================================="
echo ""

echo "** Backing up current config **"
mkdir -p "$backups_dir"
cp "$boot_config" "${backups_dir}/boot-config.backup-$(date +%Y%m%d-%H%M%S)"

echo "** Copying original overlay **"
cp ./tft35a-overlay.dtb "$boot_overlays/"
cp ./tft35a-overlay.dtb "$boot_overlays/tft35a.dtbo"

echo "** Updating config.txt **"

# Remove any ili9486 overlays we added
sed -i '/^dtoverlay=ili9486/d' "$boot_config"
sed -i '/^dtoverlay=fbtft/d' "$boot_config"

# Add the original tft35a overlay
if ! grep -q "^dtoverlay=tft35a" "$boot_config"; then
    echo "" >> "$boot_config"
    echo "# TFT35a 3.5\" display - original overlay" >> "$boot_config"
    echo "dtoverlay=tft35a:rotate=90" >> "$boot_config"
fi

# Ensure SPI is enabled
if ! grep -q "^dtparam=spi=on" "$boot_config"; then
    echo "dtparam=spi=on" >> "$boot_config"
fi

# Configure console
cmdline=$(cat "$boot_cmdline")
cmdline=$(echo "$cmdline" | sed 's/fbcon=[^ ]*//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')
echo "$cmdline fbcon=font:VGA8x8" > "$boot_cmdline"

echo "** Configuring touch controller **"
if ! grep -q "^dtoverlay=ads7846" "$boot_config"; then
    echo "dtoverlay=ads7846,penirq=17,speed=2000000,swapxy=1" >> "$boot_config"
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
echo "  sudo ./screen-test.sh"
echo ""
