# Quick Start Guide: 3.5" TFT on Raspberry Pi OS Trixie

## Overview

This is a **step-by-step guide** to get your 3.5" ILI9486 TFT display working on Raspberry Pi OS Trixie (Debian 13).

The old method using fbtft framebuffer drivers doesn't work on Trixie. This new approach uses modern **DRM drivers** which are better integrated and more efficient.

---

## Step 1: Connect Your Display

1. Power off your Raspberry Pi completely
2. Connect the 3.5" TFT display to the GPIO header
3. Make sure it's firmly seated on all pins
4. Power on the Pi

---

## Step 2: Verify Fresh Trixie Installation

```bash
cat /etc/os-release
```

You should see:
- `VERSION_ID="13"` (Debian 13 = Trixie)
- `PRETTY_NAME="Debian GNU/Linux trixie/sid"` (or similar)

---

## Step 3: Clone This Repository (if not done)

```bash
cd ~
git clone <your-repo> lcd-display
cd lcd-display
```

---

## Step 4: Run Installation Script

```bash
sudo ./install-trixie.sh
```

This will:
- ✓ Create a modern device tree overlay for ILI9486
- ✓ Configure boot parameters
- ✓ Set up touch input
- ✓ Install required packages

**Duration**: ~2-3 minutes

---

## Step 5: Reboot

```bash
sudo reboot
```

**Wait 30-60 seconds for the system to boot**

---

## Step 6: Verify Everything Works

After reboot, run the verification script:

```bash
cd ~/lcd-display
sudo ./verify-display.sh
```

This will check:
- ✓ SPI module loaded
- ✓ DRM driver active
- ✓ Display framebuffer available
- ✓ Touch controller detected

---

## Step 7: Test the Display

### Visual Test
You should already see the console on the TFT display!

### Test with random pixels (fun test):
```bash
cat /dev/urandom > /dev/fb1
```
Press `Ctrl+C` to stop. You should see colorful random pixels on the display.

**Note**: The TFT is `/dev/fb1` (fb0 is HDMI). Always use fb1 for the TFT display!

### Test touch input:
```bash
# Find your touch device
cat /proc/bus/input/devices | grep -A 5 ADS7846

# Test it (replace eventX with your device)
sudo evtest /dev/input/event1
```

Touch the screen and you should see coordinate events.

---

## Rotation (Optional)

If you want the display in portrait mode (recommended for 3.5"):

1. Edit the boot config:
```bash
sudo nano /boot/firmware/config.txt
```

2. Find the line:
```ini
dtoverlay=ili9486-drm
```

3. Change it to:
```ini
dtoverlay=ili9486-drm,rotation=90
```

4. Save and reboot:
```bash
sudo reboot
```

**Rotation options:**
- `rotation=0` → Landscape (default, 480x320)
- `rotation=90` → Portrait (320x480) ← **Recommended**
- `rotation=180` → Inverted landscape
- `rotation=270` → Inverted portrait

---

## Touch Calibration (If Needed)

The default calibration should work for 90° rotation. If touch is inaccurate:

### For Console/CLI:
The touch coordinates might need adjustment. Edit:
```bash
sudo nano /etc/X11/xorg.conf.d/99-calibration.conf
```

### For Desktop (X11):
If you install a desktop environment later:
```bash
sudo apt-get install xinput-calibrator
xinput_calibrator
```

---

## Troubleshooting

### Problem: Display stays white/blank

**Solution:**
```bash
# Check if SPI is enabled
lsmod | grep spi

# Check kernel messages
dmesg | grep ili9486

# Verify overlay loaded
dtoverlay -l

# Check config
cat /boot/firmware/config.txt | grep ili9486
```

### Problem: Touch doesn't work

**Solution:**
```bash
# List input devices
ls /dev/input/

# Check for ADS7846
cat /proc/bus/input/devices | grep ADS7846

# Test raw input
sudo evtest /dev/input/event1  # Try event0, event1, etc.
```

### Problem: Console text too big

**Solution:**
```bash
sudo nano /boot/firmware/cmdline.txt
```
Add to the end of the line: `fbcon=font:VGA8x8`

---

## What's Different from Bookworm?

| Aspect | Old (Bookworm) | New (Trixie) |
|--------|----------------|--------------|
| Driver | fbtft (deprecated) | DRM panel-mipi-dbi |
| Framebuffer copy | fbcp (CPU intensive) | Direct rendering |
| Device tree | Hackish overlays | Standard DT format |
| Graphics stack | Legacy FB only | KMS/DRM/Wayland ready |
| Performance | Slower, CPU overhead | Faster, more efficient |
| Maintenance | Unmaintained | Active kernel support |

---

## Next Steps

### Using with Desktop Environment

The DRM driver works with:
- **Xorg** (X11) - Configure in xorg.conf.d
- **Wayland** - Works automatically
- **Console** - Already working!

To install a lightweight desktop:
```bash
sudo apt-get install xfce4 lightdm
sudo systemctl set-default graphical.target
sudo reboot
```

### Auto-start Applications

The display appears as a standard DRM device, so any application can use it:
```bash
# Example: Show images
fbi -T 1 -a image.jpg

# Example: Play video (with framebuffer)
mpv --vo=drm --drm-connector=1 video.mp4
```

---

## Files Modified/Created

- `/boot/firmware/overlays/ili9486-drm.dtbo` - Display driver overlay
- `/boot/firmware/config.txt` - Boot configuration
- `/etc/X11/xorg.conf.d/99-calibration.conf` - Touch calibration
- `./system-backups/` - Your original configs (backup)

---

## Need Help?

1. Read the full documentation: `README-TRIXIE.md`
2. Run verification: `sudo ./verify-display.sh`
3. Check kernel logs: `dmesg | grep -i 'ili\|spi\|ads'`
4. Check GitHub issues in the repository

---

## Success Checklist

- [ ] Raspberry Pi OS Trixie installed
- [ ] Display connected to GPIO
- [ ] Ran `sudo ./install-trixie.sh`
- [ ] Rebooted system
- [ ] Ran `sudo ./verify-display.sh` - all checks passed
- [ ] Can see console on TFT display
- [ ] Touch input responds
- [ ] (Optional) Adjusted rotation if needed
- [ ] (Optional) Calibrated touch if needed

---

**🎉 Congratulations! Your 3.5" TFT display is now working on Trixie with modern DRM drivers!**

No hacks, no deprecated drivers, just clean kernel support. 🚀
