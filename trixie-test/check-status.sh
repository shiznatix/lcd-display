#!/bin/bash

# Quick check of current display status

echo "=== Current Status ==="
echo ""

echo "Framebuffer devices:"
ls -la /dev/fb* 2>/dev/null || echo "No framebuffer devices found!"
echo ""

echo "Loaded modules:"
lsmod | grep -E "ili|fbtft|spi_bcm" || echo "No display modules loaded"
echo ""

echo "SPI devices:"
ls -la /sys/bus/spi/devices/ 2>/dev/null || echo "No SPI devices"
echo ""

echo "Device tree overlays loaded:"
dtoverlay -l 2>/dev/null || vcgencmd get_config dtoverlay
echo ""

echo "Config.txt overlays:"
grep -E "^dtoverlay|^dtparam=spi" /boot/firmware/config.txt
echo ""

echo "Overlay file exists?"
ls -la /boot/firmware/overlays/ili9486* 2>/dev/null || echo "No ili9486 overlay files found"
echo ""

echo "Recent kernel messages about ili9486:"
dmesg | grep -i ili | tail -10
echo ""
