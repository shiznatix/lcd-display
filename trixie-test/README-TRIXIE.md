# 3.5" TFT Display Setup for Raspberry Pi OS Trixie

This guide explains how to set up a 3.5" ILI9486 TFT display with ADS7846 touch controller on Raspberry Pi OS Trixie (Debian 13).

## What Changed from Bookworm?

Raspberry Pi OS Trixie uses a newer Linux kernel that **deprecated the old fbtft framebuffer drivers**. The modern approach uses **DRM (Direct Rendering Manager)** drivers which are:
- Better integrated with the graphics stack
- More efficient
- Properly supported in Wayland and modern X11

## Hardware Supported

- **Display Controller**: ILI9486 (480x320)
- **Touch Controller**: ADS7846 (resistive touch)
- **Interface**: SPI
- **Common Names**: 3.5" TFT, Waveshare 3.5", MHS35, etc.

## Prerequisites

- Fresh Raspberry Pi OS Trixie installation (CLI or Desktop)
- Raspberry Pi Zero 2W, Pi 3, Pi 4, or Pi 5
- SPI-based 3.5" TFT display
- Root/sudo access

## Installation Steps

### 1. Clone or download this repository

```bash
cd ~
git clone <your-repo-url>
cd lcd-display
```

### 2. Run the installation script

```bash
sudo ./install-trixie.sh
```

The script will:
- Create a modern device tree overlay for the ILI9486 DRM driver
- Configure /boot/firmware/config.txt
- Set up touch input configuration
- Install required packages

### 3. Reboot

```bash
sudo reboot
```

### 4. Verify the display is working

After reboot, check if the DRM driver loaded:

```bash
ls /dev/dri/
# Should show: card0  card1  renderD128 (or similar)

dmesg | grep ili9486
# Should show the driver loading

cat /sys/class/graphics/fb*/name
# Should show the ili9486 framebuffer
```

## Display Rotation

To rotate the display, edit `/boot/firmware/config.txt` and modify the overlay parameters:

```ini
dtoverlay=ili9486-drm,rotation=90
```

Rotation values:
- `rotation=0` - Landscape (default)
- `rotation=90` - Portrait (recommended for 3.5" display)
- `rotation=180` - Inverted landscape
- `rotation=270` - Inverted portrait

After changing rotation, reboot for changes to take effect.

## Touch Calibration

The default touch calibration is set for 90-degree rotation. If you need to recalibrate:

### For X11 (if you have a desktop environment):

```bash
sudo apt-get install xinput-calibrator
xinput_calibrator
```

Follow the on-screen instructions, then update `/etc/X11/xorg.conf.d/99-calibration.conf` with the output.

### For console/CLI only:

The touch input works through the standard Linux input system. You can test it with:

```bash
sudo evtest /dev/input/event0
# (or event1, event2, etc. - find the ADS7846 device)
```

## Troubleshooting

### Display shows nothing/stays white

1. Check if SPI is enabled:
```bash
lsmod | grep spi
# Should show: spi_bcm2835
```

2. Check if the overlay loaded:
```bash
dtoverlay -l
# Should show: ili9486-drm
```

3. Check dmesg for errors:
```bash
dmesg | grep -i ili
dmesg | grep -i spi
```

### Touch doesn't work

1. Find the touch input device:
```bash
ls /dev/input/
# Look for event devices

cat /proc/bus/input/devices | grep -A 5 ADS7846
```

2. Test touch input:
```bash
sudo evtest /dev/input/eventX  # Replace X with the correct number
```

### Console text is too large

Create or edit `/boot/firmware/cmdline.txt` and add:
```
fbcon=font:VGA8x8
```

Or for even smaller font:
```
fbcon=font:ProFont6x11
```

### Display is slow/laggy

You can try increasing the SPI speed in the device tree overlay. Edit the overlay source and change:
```
spi-max-frequency = <32000000>;  # Try 48000000 or 64000000
```

Then recompile and reboot.

## Advanced Configuration

### Adjusting FPS

Edit `/boot/firmware/config.txt` and modify:
```ini
dtoverlay=ili9486-drm,rotation=90,fps=60
```

Default is 30fps. Higher values may cause flickering.

### Using with Wayland

The DRM driver works natively with Wayland compositors. If you install a desktop environment, it should automatically work.

### Using as Primary Display

The ili9486 DRM driver will automatically become available as a display output. To make it the primary console:

1. It should automatically become the console after boot
2. If you have HDMI connected, you can switch consoles with `Ctrl+Alt+F1`, `F2`, etc.

## Technical Details

### DRM Driver vs FBTFT

The old setup used:
- **fbtft** kernel module (deprecated)
- **fbcp** to copy framebuffer (CPU intensive)
- Required hacky device tree overlays

The new setup uses:
- **panel-mipi-dbi** DRM driver (modern, maintained)
- Direct rendering to display (more efficient)
- Standard device tree overlay format
- Works with KMS, Wayland, and modern graphics stack

### GPIO Pin Configuration

Default pins (can be changed in device tree overlay):
- **DC (Data/Command)**: GPIO 25
- **Reset**: GPIO 24
- **Touch IRQ**: GPIO 17
- **SPI CS0**: Display (CE0)
- **SPI CS1**: Touch controller (CE1)

### Files Created/Modified

- `/boot/firmware/overlays/ili9486-drm.dtbo` - Device tree overlay
- `/boot/firmware/config.txt` - Boot configuration
- `/etc/X11/xorg.conf.d/99-calibration.conf` - Touch calibration

## Uninstallation

To remove the display configuration:

```bash
sudo rm /boot/firmware/overlays/ili9486-drm.dtbo
```

Edit `/boot/firmware/config.txt` and remove the lines:
```ini
dtoverlay=ili9486-drm
dtparam=spi=on
```

Then reboot.

## References

- [Linux DRM Panel Driver Documentation](https://www.kernel.org/doc/html/latest/gpu/drm-kms.html)
- [ILI9486 Datasheet](https://www.ilitek.com/)
- [Raspberry Pi Device Tree Documentation](https://www.raspberrypi.com/documentation/computers/configuration.html#device-trees-overlays-and-parameters)

## Contributing

If you find issues or improvements for Trixie support, please submit a pull request!

## License

Same as original repository
