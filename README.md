# 3.5" TFT Display for Raspberry Pi OS Trixie

Simple setup for ILI9486-based 3.5" TFT displays on Raspberry Pi OS Trixie (Debian 13).

## Quick Start

### 1. Install the display driver

```bash
sudo ./install.sh
sudo reboot
```

### 2. Test the display

After reboot, run a screen test to verify the display works:

```bash
sudo ./screen-test.sh
```

You should see black, white, red, green, blue, and random colors on the display.

### 3. Run diagnostics (if needed)

If the screen test fails, run full diagnostics:

```bash
sudo ./diagnostics.sh
```

## What This Does

The installation script:
- Uses the original `tft35a-overlay.dtb` device tree overlay
- Configures the ILI9486 display driver (fbtft)
- Sets up the ADS7846 touch controller
- Configures console output for the TFT

## Hardware

- **Display Controller**: ILI9486 (480x320, rotated to 320x480)
- **Touch Controller**: ADS7846 (resistive touch)
- **Interface**: SPI via GPIO
- **Supported Models**: Raspberry Pi Zero 2W, Pi 3, Pi 4, Pi 5

## Display Device

The TFT appears as `/dev/fb0` (when no HDMI connected) or `/dev/fb1` (when HDMI is connected).

The console automatically uses the display after installation.

## Troubleshooting

### Display shows only white screen

Run diagnostics:
```bash
sudo ./diagnostics.sh
```

Check if the driver loaded:
```bash
dmesg | grep ili9486
ls -la /dev/fb*
```

### Display not found

Make sure SPI is enabled in `/boot/firmware/config.txt`:
```
dtparam=spi=on
```

### Touch not working

Test touch input:
```bash
sudo apt-get install evtest
sudo evtest /dev/input/event1
```

Touch the screen and you should see coordinate events.

## Development Files

Additional test scripts and documentation are in the `trixie-test/` directory.

## Files

- **install.sh** - Main installation script
- **screen-test.sh** - Test display with color patterns
- **diagnostics.sh** - Complete system diagnostic
- **rotate.sh** - Change display rotation (legacy)
- **setup.sh** - Reset to original config (legacy)
- **trixie-test/** - Development and testing files (includes play-video.sh)

## Legacy Scripts

The original scripts for Bookworm (`install-LCD35.sh`, `setup.sh`, `rotate.sh`) are kept for reference but are not needed for Trixie.

## Requirements

- Raspberry Pi OS Trixie (Debian 13)
- Raspberry Pi with GPIO header (Zero 2W, Pi 3, 4, or 5)
- 3.5" ILI9486 TFT display

## License

Same as original repository.
