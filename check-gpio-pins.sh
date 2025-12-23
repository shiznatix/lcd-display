#!/bin/bash

# Check device tree configuration for GPIO pins

echo "=========================================="
echo "  Checking Device Tree Configuration"
echo "=========================================="
echo ""

echo "=== Checking /boot/firmware/config.txt ==="
echo "Active overlays:"
grep -E "^dtoverlay" /boot/firmware/config.txt
echo ""

echo "=== Checking loaded device tree ==="
if [ -d /proc/device-tree/soc/spi@3f204000/spidev@0 ]; then
    echo "SPI device 0 configured in device tree"
fi

if [ -d /proc/device-tree/soc/spi@3f204000/ili9486@0 ]; then
    echo "ILI9486 device found in device tree"
    echo ""
    echo "Properties:"
    if [ -f /proc/device-tree/soc/spi@3f204000/ili9486@0/dc-gpios ]; then
        echo "  DC GPIO configured"
        xxd /proc/device-tree/soc/spi@3f204000/ili9486@0/dc-gpios | head -2
    fi
    if [ -f /proc/device-tree/soc/spi@3f204000/ili9486@0/reset-gpios ]; then
        echo "  Reset GPIO configured"
        xxd /proc/device-tree/soc/spi@3f204000/ili9486@0/reset-gpios | head -2
    fi
fi

echo ""
echo "=== Checking SPI device binding ==="
if [ -L /sys/bus/spi/devices/spi0.0/driver ]; then
    echo "spi0.0 driver: $(readlink /sys/bus/spi/devices/spi0.0/driver | xargs basename)"
fi

echo ""
echo "=== Checking fbtft debug info ==="
dmesg | grep -E "fbtft.*gpio|dc.*gpio|reset.*gpio" | tail -10

echo ""
echo "=== Comparing with original working config ==="
echo "The original tft35a-overlay.dtb used these pins:"
strings /var/lib/lcd-display/usr/tft35a-overlay.dtb | grep -A5 -B5 "gpio"

echo ""
