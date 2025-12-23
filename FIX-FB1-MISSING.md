# Fix for Missing /dev/fb1

## Important: Run Commands on Raspberry Pi!

All commands must be run **on the Raspberry Pi itself**, not on your development machine. SSH into your Pi or use a direct connection.

## Current Situation

Your diagnostic showed the driver loaded successfully initially, but after reboot `/dev/fb1` disappeared. This means the kernel modules aren't loading automatically at boot.

## Solution

I've created a new, more reliable installation script that uses a systemd service to ensure the driver loads at boot.

### Step 1: Clean Install (On the Raspberry Pi)

```bash
cd ~/lcd-display
sudo ./install-fbtft-simple.sh
```

This will:
- Configure fbtft modules to load at boot via systemd
- Set up console to use fb1
- Configure touch controller
- Create proper boot parameters

### Step 2: Reboot

```bash
sudo reboot
```

### Step 3: Verify (After Reboot)

```bash
ls -la /dev/fb1
```

If `/dev/fb1` exists, test it:
```bash
cat /dev/urandom > /dev/fb1
# Press Ctrl+C to stop
```

## If /dev/fb1 Still Missing After Reboot

Run the manual loader to see what's failing:

```bash
sudo ./manual-load.sh
```

This will:
- Manually load all required modules
- Show detailed error messages
- Help diagnose what's preventing the driver from loading

## Common Issues and Fixes

### Issue 1: SPI Not Enabled

Check if SPI is enabled:
```bash
ls /dev/spidev0.0
```

If it doesn't exist, add to `/boot/firmware/config.txt`:
```
dtparam=spi=on
```

Then reboot.

### Issue 2: fbtft Modules Not Available

Check if the modules exist:
```bash
find /lib/modules/$(uname -r) -name "fbtft*.ko*"
find /lib/modules/$(uname -r) -name "fb_ili9486.ko*"
```

If not found, your kernel might not have fbtft compiled. Check kernel version:
```bash
uname -r
```

Expected: `6.12.x+rpt-rpi-v8` or similar

### Issue 3: Wrong GPIO Pins

The default configuration uses:
- **GPIO 24**: Reset
- **GPIO 25**: DC (Data/Command)
- **GPIO 17**: Touch IRQ

If your display uses different pins, edit the pin assignments in `install-fbtft-simple.sh`.

## Diagnostic Commands (Run on Pi)

```bash
# Check SPI is working
ls -la /sys/bus/spi/devices/

# Check loaded modules
lsmod | grep -E "fbtft|ili|spi"

# Check kernel messages
dmesg | grep -i ili

# Check systemd service status
sudo systemctl status fbtft-ili9486.service

# View service logs
sudo journalctl -u fbtft-ili9486.service
```

## Manual Loading for Testing

If you want to test without rebooting:

```bash
# Load modules manually
sudo modprobe fbtft
sudo modprobe fb_ili9486
sudo modprobe fbtft_device name=ili9486 gpios=reset:24,dc:25 speed=32000000 rotate=90 fps=30 bgr=1 buswidth=8

# Check if it worked
ls -la /dev/fb1
dmesg | tail -20
```

## What the Systemd Service Does

The installation creates `/etc/systemd/system/fbtft-ili9486.service` which:
1. Loads `fbtft` module
2. Loads `fb_ili9486` module
3. Loads `fbtft_device` with your display configuration
4. Runs early in boot sequence
5. Logs success/failure

Check service status:
```bash
sudo systemctl status fbtft-ili9486.service
```

## Getting More Help

If the display still doesn't work after trying the above, run these on the Pi and share the output:

```bash
sudo ./diagnose-display.sh > full-diagnostic.txt
sudo systemctl status fbtft-ili9486.service >> full-diagnostic.txt
sudo journalctl -u fbtft-ili9486.service >> full-diagnostic.txt
cat full-diagnostic.txt
```

## Reference: Your Previous Diagnostic

Your earlier diagnostic (from the Pi) showed:
- ✅ fbtft modules available in `/lib/modules/.../staging/fbtft/`
- ✅ Display loaded as `/dev/fb1` successfully
- ✅ Touch controller working
- ✅ SPI communication working

The modules CAN work, they just need to be loaded reliably at boot. The new systemd service approach should fix this.
