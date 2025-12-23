#!/bin/bash

# Alternative installation using fbtft modules (if available in Trixie)
# Run this if the DRM approach didn't work

set -eu

if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi

cd "$(dirname "$0")"
source ./vars.sh

echo "=========================================="
echo "  Alternative Install: Checking fbtft"
echo "=========================================="
echo ""

# Check if fbtft modules are available
echo "Checking for fbtft kernel modules..."
if find /lib/modules/$(uname -r) -name "fbtft.ko*" | grep -q .; then
    echo "✓ fbtft modules found!"
    FBTFT_AVAILABLE=1
else
    echo "✗ fbtft modules NOT found"
    FBTFT_AVAILABLE=0
fi

if find /lib/modules/$(uname -r) -name "fb_ili9486.ko*" | grep -q .; then
    echo "✓ fb_ili9486 module found!"
    FB_ILI9486_AVAILABLE=1
else
    echo "✗ fb_ili9486 module NOT found"
    FB_ILI9486_AVAILABLE=0
fi

echo ""

if [ $FBTFT_AVAILABLE -eq 1 ] && [ $FB_ILI9486_AVAILABLE -eq 1 ]; then
    echo "=========================================="
    echo "  Installing with fbtft modules"
    echo "=========================================="
    echo ""

    # Create modprobe configuration
    cat > /etc/modprobe.d/fbtft.conf << 'EOF'
# ILI9486 display configuration
options fbtft_device name=ili9486 gpios=reset:24,dc:25 speed=32000000 fps=30 rotate=90 bgr=1 custom=1
EOF

    # Load modules
    echo "Loading fbtft modules..."
    modprobe fbtft
    modprobe fb_ili9486
    modprobe fbtft_device name=ili9486 gpios=reset:24,dc:25 speed=32000000 fps=30 rotate=90 bgr=1 custom=1

    # Make it load at boot
    if ! grep -q "^fbtft$" /etc/modules; then
        echo "fbtft" >> /etc/modules
    fi
    if ! grep -q "^fb_ili9486$" /etc/modules; then
        echo "fb_ili9486" >> /etc/modules
    fi
    if ! grep -q "^fbtft_device$" /etc/modules; then
        echo "fbtft_device" >> /etc/modules
    fi

    # Enable SPI
    if ! grep -q "^dtparam=spi=on" "$BOOT_CONFIG"; then
        echo "dtparam=spi=on" >> "$BOOT_CONFIG"
    fi

    # Configure ADS7846 touch
    cat > /etc/modprobe.d/ads7846.conf << 'EOF'
options ads7846 swapxy=1 x_min=300 x_max=3932 y_min=294 y_max=3801
EOF

    echo ""
    echo "✓ fbtft installation complete!"
    echo ""
    echo "Reboot and check /dev/fb1 for the display"

else
    echo "=========================================="
    echo "  fbtft NOT available - using modprobe approach"
    echo "=========================================="
    echo ""

    # Check what display-related modules ARE available
    echo "Available display/panel modules:"
    find /lib/modules/$(uname -r) -type f \( -name "*ili*.ko*" -o -name "*panel*.ko*" -o -name "*mipi*.ko*" \) | while read mod; do
        basename "$mod" | sed 's/.ko.*//'
    done
    echo ""

    echo "Available DRM modules:"
    find /lib/modules/$(uname -r)/kernel/drivers/gpu/drm -type f -name "*.ko*" | while read mod; do
        basename "$mod" | sed 's/.ko.*//'
    done | grep -E "panel|mipi" || echo "None found with panel/mipi"
    echo ""

    # Try to load any available panel-mipi-dbi or similar
    echo "Attempting to load DRM panel drivers..."
    modprobe drm 2>/dev/null || true
    modprobe drm_kms_helper 2>/dev/null || true
    modprobe panel-mipi-dbi 2>/dev/null || echo "panel-mipi-dbi not available"
    modprobe ili9486 2>/dev/null || echo "ili9486 module not available"

    echo ""
    echo "Check lsmod output:"
    lsmod | grep -E "drm|ili|panel" || echo "No relevant modules loaded"
fi

echo ""
echo "=========================================="
echo "Run diagnose-display.sh to see results"
echo "=========================================="
