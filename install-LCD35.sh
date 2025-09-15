#!/bin/bash

set -eu
trap 'echo "!!! Command failed: $BASH_COMMAND"; exit 1' ERR
if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi
cd "$(dirname "$0")"
source ./vars.sh

echo "** Installing dependencies **"
rm -rf rpi-fbcp
git clone https://github.com/tasanakorn/rpi-fbcp.git
mkdir ./rpi-fbcp/build
cd ./rpi-fbcp/build/
cmake ..
make
install fbcp /usr/local/bin/fbcp
cd - > /dev/null

echo "** Installing Display **"
rm -rf /etc/X11/xorg.conf.d/40-libinput.conf
mkdir -p /etc/X11/xorg.conf.d
cp ./usr/tft35a-overlay.dtb $BOOT_OVERLAYS/
cp ./usr/tft35a-overlay.dtb $BOOT_OVERLAYS/tft35a.dtbo

cp ./usr/99-calibration.conf-35-90  /etc/X11/xorg.conf.d/99-calibration.conf
cp ./usr/inittab /etc/
cp -rf ./etc/rc.local /etc/rc.local
mv /usr/share/X11/xorg.conf.d/10-evdev.conf /usr/share/X11/xorg.conf.d/45-evdev.conf

echo "gpio:resistance:35:90:480:320" > $INSTALLED_OPTS_FILE

sync
sync
sleep 1

echo "Reboot system to complete installation"
echo "**Installation completed**"
