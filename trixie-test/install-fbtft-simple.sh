#!/bin/bash

# Simplified installation using fbtft modules directly (most reliable for Trixie)

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"
source ./vars.sh

echo "=========================================="
echo "  ILI9486 Display - fbtft Installation"
echo "=========================================="
echo ""

# Check we're on a Raspberry Pi
if [ ! -d "/sys/firmware/devicetree/base" ]; then
    echo "ERROR: This doesn't appear to be a Raspberry Pi!"
    echo "This script must be run ON the Raspberry Pi, not on your development machine."
    exit 1
fi

echo "** Creating backup **"
mkdir -p "$BACKUP_DIR"
[ -f "$BOOT_CONFIG" ] && cp "$BOOT_CONFIG" "$BACKUP_DIR/config.txt.backup-$(date +%Y%m%d-%H%M%S)"
[ -f "$BOOT_CMDLINE" ] && cp "$BOOT_CMDLINE" "$BACKUP_DIR/cmdline.txt.backup-$(date +%Y%m%d-%H%M%S)"

echo "** Configuring kernel modules **"

# Remove any existing fbtft configuration
rm -f /etc/modprobe.d/fbtft.conf

# Create new modprobe configuration for manual loading
cat > /etc/modprobe.d/fbtft.conf << 'EOF'
# ILI9486 3.5" TFT Display Configuration
# This file is created by the installation script

# Options for fbtft_device module
# These parameters configure the display when loaded manually
options fbtft_device name=ili9486 gpios=reset:24,dc:25 speed=32000000 rotate=90 fps=30 bgr=1 buswidth=8
EOF

echo "** Configuring boot settings **"

# Enable SPI in config.txt
if ! grep -q "^dtparam=spi=on" "$BOOT_CONFIG"; then
	echo "" >> "$BOOT_CONFIG"
	echo "# Enable SPI for TFT display" >> "$BOOT_CONFIG"
	echo "dtparam=spi=on" >> "$BOOT_CONFIG"
fi

# Remove old overlay attempts
sed -i '/^dtoverlay=ili9486/d' "$BOOT_CONFIG"
sed -i '/^dtoverlay=tft35/d' "$BOOT_CONFIG"
sed -i '/^dtoverlay=mhs35/d' "$BOOT_CONFIG"

# Add fbtft device tree overlay if it exists in kernel
if [ -f "$BOOT_OVERLAYS/fbtft.dtbo" ]; then
	if ! grep -q "^dtoverlay=fbtft" "$BOOT_CONFIG"; then
		echo "dtoverlay=fbtft,ili9486,speed=32000000,rotate=90,fps=30,bgr=1,reset_pin=24,dc_pin=25" >> "$BOOT_CONFIG"
	fi
else
	echo "Note: fbtft.dtbo not found, will use modprobe method"
fi

# Configure console on fb1 (TFT display)
if [ -f "$BOOT_CMDLINE" ]; then
	# Read current cmdline
	CMDLINE=$(cat "$BOOT_CMDLINE")

	# Remove existing fbcon settings
	CMDLINE=$(echo "$CMDLINE" | sed 's/fbcon=[^ ]*//g' | sed 's/  */ /g' | sed 's/^ *//;s/ *$//')

	# Add fbcon settings for TFT on fb1
	CMDLINE="$CMDLINE fbcon=map:10 fbcon=font:VGA8x8"

	# Write back
	echo "$CMDLINE" > "$BOOT_CMDLINE"
	echo "✓ Configured console to use TFT display"
fi

echo "** Setting up module autoload **"

# Create a systemd service to load fbtft at boot
cat > /etc/systemd/system/fbtft-ili9486.service << 'EOF'
[Unit]
Description=Load ILI9486 TFT Display Driver
After=multi-user.target
Before=display-manager.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/modprobe fbtft
ExecStart=/usr/sbin/modprobe fb_ili9486
ExecStart=/usr/sbin/modprobe fbtft_device name=ili9486 gpios=reset:24,dc:25 speed=32000000 rotate=90 fps=30 bgr=1 buswidth=8
ExecStart=/bin/sleep 2
ExecStartPost=/bin/bash -c 'if [ -e /dev/fb1 ]; then echo "TFT display loaded on /dev/fb1"; fi'

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
systemctl daemon-reload
systemctl enable fbtft-ili9486.service

echo "** Configuring touch controller **"

# Load ADS7846 touch controller
if ! grep -q "^dtoverlay=ads7846" "$BOOT_CONFIG"; then
	echo "" >> "$BOOT_CONFIG"
	echo "# Touch controller" >> "$BOOT_CONFIG"
	echo "dtoverlay=ads7846,penirq=17,speed=2000000,swapxy=1,xmin=300,xmax=3932,ymin=294,ymax=3801" >> "$BOOT_CONFIG"
fi

echo "** Installing required packages **"
apt-get update -qq
apt-get install -y xserver-xorg-input-evdev xinput-calibrator libinput-tools 2>/dev/null || true

echo "** Configuring X11 touch calibration **"
mkdir -p /etc/X11/xorg.conf.d

cat > /etc/X11/xorg.conf.d/99-calibration.conf << 'EOF'
Section "InputClass"
	Identifier "calibration"
	MatchProduct "ADS7846 Touchscreen"
	Option "Calibration" "3932 300 294 3801"
	Option "SwapAxes" "1"
	Option "InvertX" "1"
	Option "InvertY" "1"
EndSection
EOF

echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "The display driver will load automatically on next boot."
echo ""
echo "IMPORTANT: You MUST reboot for changes to take effect:"
echo "  sudo reboot"
echo ""
echo "After reboot:"
echo "1. Check if /dev/fb1 exists: ls -la /dev/fb1"
echo "2. Test display: cat /dev/urandom > /dev/fb1"
echo "3. Console should appear on TFT display"
echo ""
echo "If /dev/fb1 doesn't appear after reboot, run:"
echo "  sudo ./manual-load.sh"
echo ""
echo "Logs saved to: $BACKUP_DIR"
echo ""
