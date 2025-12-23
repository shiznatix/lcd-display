#!/bin/bash

# Fix console to display on TFT (fb1) instead of HDMI (fb0)

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"
source ./vars.sh

echo "=========================================="
echo "  Configure Console for TFT Display"
echo "=========================================="
echo ""

# Backup cmdline.txt
if [ -f "$BOOT_CMDLINE" ]; then
	cp "$BOOT_CMDLINE" "$BOOT_CMDLINE.backup-$(date +%Y%m%d)"
	echo "✓ Backed up cmdline.txt"
fi

# Read current cmdline
CMDLINE=$(cat "$BOOT_CMDLINE")

# Remove existing fbcon settings
CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=[^ ]*//g' | sed 's/  */ /g')

# Add fbcon to use fb1 (the TFT display)
CMDLINE="$CMDLINE fbcon=map:10 fbcon=font:VGA8x8"

# Write back
echo "$CMDLINE" > "$BOOT_CMDLINE"

echo "✓ Updated $BOOT_CMDLINE"
echo ""
echo "Added parameters:"
echo "  - fbcon=map:10   (maps console to fb1, the TFT)"
echo "  - fbcon=font:VGA8x8   (smaller font for small display)"
echo ""

# Also ensure we're not disabling the console
if grep -q "console=.*tty0" "$BOOT_CMDLINE"; then
	echo "✓ Console output enabled"
else
	CMDLINE=$(cat "$BOOT_CMDLINE")
	if ! echo "$CMDLINE" | grep -q "console="; then
		# Add console output if completely missing
		echo "$CMDLINE console=tty1" > "$BOOT_CMDLINE"
		echo "✓ Added console=tty1 to cmdline.txt"
	fi
fi

echo ""
echo "=========================================="
echo "  Configuration Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Reboot: sudo reboot"
echo "2. The console should now appear on your TFT display"
echo "3. The backlight should be on and show text"
echo ""
echo "To test before rebooting:"
echo "  cat /dev/urandom > /dev/fb1"
echo "  (Press Ctrl+C to stop)"
echo ""
echo "Optional: To disable HDMI completely, add to $BOOT_CONFIG:"
echo "  hdmi_blanking=2"
echo ""
