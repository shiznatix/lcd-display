#!/bin/bash

# Modern installation script for 3.5" ILI9486 TFT display on Raspberry Pi OS Trixie
# This uses DRM drivers instead of deprecated fbtft framebuffer drivers

set -eu
trap 'echo "!!! Command failed: $BASH_COMMAND"; exit 1' ERR

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"
source ./vars.sh

echo "=========================================="
echo "  3.5\" TFT Display Installer for Trixie"
echo "  Using modern DRM drivers"
echo "=========================================="
echo ""

# Backup existing configuration
echo "** Creating backup **"
rm -rf $BACKUP_DIR
mkdir -p $BACKUP_DIR
if [ -f "$BOOT_CONFIG" ]; then
	cp "$BOOT_CONFIG" "$BACKUP_DIR/config.txt.backup"
fi

# Create device tree overlay for ILI9486 with DRM driver
echo "** Creating modern device tree overlay **"
cat > /tmp/ili9486-drm.dts << 'EOF'
/dts-v1/;
/plugin/;

/ {
	compatible = "brcm,bcm2835";

	fragment@0 {
		target = <&spi0>;
		__overlay__ {
			status = "okay";
		};
	};

	fragment@1 {
		target = <&spidev0>;
		__overlay__ {
			status = "disabled";
		};
	};

	fragment@2 {
		target = <&spidev1>;
		__overlay__ {
			status = "disabled";
		};
	};

	fragment@3 {
		target = <&gpio>;
		__overlay__ {
			ili9486_pins: ili9486_pins {
				brcm,pins = <25 24>;
				brcm,function = <1 1>; /* out out */
			};
		};
	};

	fragment@4 {
		target = <&spi0>;
		__overlay__ {
			#address-cells = <1>;
			#size-cells = <0>;

			ili9486: ili9486@0 {
				compatible = "ilitek,ili9486";
				reg = <0>;
				pinctrl-names = "default";
				pinctrl-0 = <&ili9486_pins>;

				spi-max-frequency = <32000000>;
				rotation = <90>;
				bgr;
				fps = <30>;
				buswidth = <8>;
				dc-gpios = <&gpio 25 0>;
				reset-gpios = <&gpio 24 1>;

				width = <320>;
				height = <480>;
			};
		};
	};

	fragment@5 {
		target = <&spi0>;
		__overlay__ {
			#address-cells = <1>;
			#size-cells = <0>;

			ads7846: ads7846@1 {
				compatible = "ti,ads7846";
				reg = <1>;
				spi-max-frequency = <2000000>;
				interrupts = <17 2>; /* GPIO 17, falling edge */
				interrupt-parent = <&gpio>;
				pendown-gpio = <&gpio 17 0>;
				ti,x-plate-ohms = /bits/ 16 <100>;
				ti,pressure-max = /bits/ 16 <255>;
				ti,swap-xy;
			};
		};
	};

	__overrides__ {
		speed = <&ili9486>,"spi-max-frequency:0";
		rotation = <&ili9486>,"rotation:0";
		fps = <&ili9486>,"fps:0";
		width = <&ili9486>,"width:0";
		height = <&ili9486>,"height:0";
	};
};
EOF

# Compile device tree overlay
echo "** Compiling device tree overlay **"
if ! command -v dtc &> /dev/null; then
	echo "Installing device-tree-compiler..."
	apt-get update -qq
	apt-get install -y device-tree-compiler
fi

dtc -@ -I dts -O dtb -o /tmp/ili9486-drm.dtbo /tmp/ili9486-drm.dts
mkdir -p "$BOOT_OVERLAYS"
cp /tmp/ili9486-drm.dtbo "$BOOT_OVERLAYS/"

echo "** Configuring boot parameters **"
# Remove old fbtft configurations if they exist
sed -i '/^dtoverlay=tft35a/d' "$BOOT_CONFIG" || true
sed -i '/^dtoverlay=mhs35/d' "$BOOT_CONFIG" || true
sed -i '/^dtoverlay=ads7846/d' "$BOOT_CONFIG" || true

# Add new DRM configuration
if ! grep -q "^dtoverlay=ili9486-drm" "$BOOT_CONFIG"; then
	echo "" >> "$BOOT_CONFIG"
	echo "# 3.5\" TFT Display (ILI9486) - DRM driver" >> "$BOOT_CONFIG"
	echo "dtoverlay=ili9486-drm" >> "$BOOT_CONFIG"
fi

# Enable SPI
if ! grep -q "^dtparam=spi=on" "$BOOT_CONFIG"; then
	echo "dtparam=spi=on" >> "$BOOT_CONFIG"
fi

# Configure console for small display
if ! grep -q "^# TFT Console settings" "$BOOT_CONFIG"; then
	echo "" >> "$BOOT_CONFIG"
	echo "# TFT Console settings" >> "$BOOT_CONFIG"
	echo "# Smaller font for 3.5\" display" >> "$BOOT_CONFIG"
fi

# Ensure console is on the TFT
CMDLINE_FILE="$BOOT_CMDLINE"
if [ -f "$CMDLINE_FILE" ]; then
	# Remove any existing fbcon settings
	sed -i 's/fbcon=[^ ]*//g' "$CMDLINE_FILE"
	# The DRM driver will automatically become the primary console
fi

echo "** Installing required packages **"
apt-get update -qq
apt-get install -y \
	xserver-xorg-input-evdev \
	xinput-calibrator \
	libinput-tools

# Configure touch input
echo "** Configuring touch input **"
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
echo "Next steps:"
echo "1. Reboot your system: sudo reboot"
echo "2. After reboot, the display should show the console"
echo "3. If you need to rotate the display, edit $BOOT_CONFIG"
echo "   and change the 'rotation' parameter in the ili9486-drm overlay"
echo "   rotation=0   (default landscape)"
echo "   rotation=90  (portrait)"
echo "   rotation=180 (inverted landscape)"
echo "   rotation=270 (inverted portrait)"
echo ""
echo "4. To calibrate the touchscreen in X11, run:"
echo "   xinput_calibrator"
echo ""
echo "5. To check the display is working:"
echo "   ls /dev/dri/"
echo "   You should see card0 and card1 (or similar)"
echo ""
echo "Backup saved to: $BACKUP_DIR"
echo ""
