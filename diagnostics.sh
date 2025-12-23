#!/bin/bash

# Detailed diagnostics for 3.5" TFT display issues

echo "=========================================="
echo "  Detailed Display Diagnostics"
echo "=========================================="
echo ""

echo "=== 1. Kernel Modules ==="
echo "Loaded SPI modules:"
lsmod | grep spi
echo ""

echo "Loaded DRM modules:"
lsmod | grep drm
echo ""

echo "Loaded display-related modules:"
lsmod | grep -E "ili|panel|mipi|tft"
echo ""

echo "=== 2. Kernel Messages for ILI9486 ==="
dmesg | grep -i ili
echo ""

echo "=== 3. SPI Device Messages ==="
dmesg | grep -i "spi.*ili\|spi.*panel" | tail -20
echo ""

echo "=== 4. DRM Messages ==="
dmesg | grep -i drm | tail -20
echo ""

echo "=== 5. Framebuffer Devices ==="
for fb in /dev/fb*; do
    if [ -e "$fb" ]; then
        echo "Device: $fb"
        if [ -f /sys/class/graphics/$(basename $fb)/name ]; then
            echo "  Name: $(cat /sys/class/graphics/$(basename $fb)/name)"
        fi
        if [ -f /sys/class/graphics/$(basename $fb)/virtual_size ]; then
            echo "  Virtual Size: $(cat /sys/class/graphics/$(basename $fb)/virtual_size)"
        fi
        if [ -f /sys/class/graphics/$(basename $fb)/bits_per_pixel ]; then
            echo "  BPP: $(cat /sys/class/graphics/$(basename $fb)/bits_per_pixel)"
        fi
        if [ -f /sys/class/graphics/$(basename $fb)/mode ]; then
            echo "  Mode: $(cat /sys/class/graphics/$(basename $fb)/mode)"
        fi
        if [ -f /sys/class/graphics/$(basename $fb)/device/driver ]; then
            echo "  Driver: $(readlink /sys/class/graphics/$(basename $fb)/device/driver)"
        fi
        echo ""
    fi
done

echo "=== 6. DRM Cards ==="
if [ -d /sys/class/drm ]; then
    for card in /sys/class/drm/card*; do
        if [ -d "$card" ]; then
            echo "Card: $(basename $card)"
            if [ -f "$card/status" ]; then
                echo "  Status: $(cat $card/status)"
            fi
            if [ -f "$card/enabled" ]; then
                echo "  Enabled: $(cat $card/enabled)"
            fi
            if [ -d "$card/device" ]; then
                echo "  Device path: $(readlink -f $card/device)"
            fi
            echo ""
        fi
    done
else
    echo "No DRM devices found!"
fi

echo "=== 7. SPI Devices ==="
if [ -d /sys/bus/spi/devices ]; then
    ls -la /sys/bus/spi/devices/
    echo ""
    for dev in /sys/bus/spi/devices/*; do
        if [ -d "$dev" ]; then
            echo "SPI Device: $(basename $dev)"
            if [ -f "$dev/modalias" ]; then
                echo "  Modalias: $(cat $dev/modalias)"
            fi
            if [ -L "$dev/driver" ]; then
                echo "  Driver: $(readlink $dev/driver)"
            else
                echo "  Driver: NOT BOUND!"
            fi
            echo ""
        fi
    done
else
    echo "No SPI devices found!"
fi

echo "=== 8. Device Tree Overlays ==="
if command -v dtoverlay &> /dev/null; then
    echo "Loaded overlays:"
    dtoverlay -l
else
    echo "dtoverlay command not found"
fi
echo ""

echo "=== 9. Boot Configuration ==="
echo "Relevant config.txt entries:"
grep -E "ili|spi|dtoverlay.*35|dtoverlay.*tft" /boot/firmware/config.txt || echo "No relevant entries found"
echo ""

echo "=== 10. Available Modules ==="
echo "Looking for display driver modules:"
find /lib/modules/$(uname -r) -name "*ili*" -o -name "*panel*mipi*" -o -name "*drm*" | grep -E "ili|panel" | head -10
echo ""

echo "=== 11. Test Framebuffer Write ==="
echo "Attempting to write to each framebuffer..."
for fb in /dev/fb*; do
    if [ -e "$fb" ]; then
        echo -n "Testing $fb... "
        if dd if=/dev/zero of=$fb bs=1024 count=1 2>/dev/null; then
            echo "SUCCESS (can write)"
        else
            echo "FAILED (cannot write)"
        fi
    fi
done
echo ""

echo "=========================================="
echo "  Diagnostics Complete"
echo "=========================================="
echo ""
echo "Please share this output for further troubleshooting."
echo ""
