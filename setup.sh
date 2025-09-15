#!/bin/bash

set -eu
trap 'echo "!!! Command failed: $BASH_COMMAND"; exit 1' ERR
if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi
cd "$(dirname "$0")"
source ./vars.sh

backup() {
	local filepath="$1"
	local ignore_rm="${2:-}"
	if [ -f "$filepath" ] || [ -d "$filepath" ]; then
		echo ">> Backup $filepath"
		cp -rf "$filepath" $BACKUP_DIR
		if [ -z "$ignore_rm" ]; then
			echo "<< Remove $filepath"
			rm -rf "$filepath"
		fi
	fi
}

rm -rf $BACKUP_DIR
mkdir $BACKUP_DIR

backup /etc/X11/xorg.conf.d

result=$(grep -rn "^dtoverlay=" $BOOT_CONFIG | grep ":rotate=" | tail -n 1)
if [ -n "$result" ]; then
	str=$(echo -n "$result" | awk -F: '{printf $2}' | awk -F= '{printf $NF}')
	backup $BOOT_OVERLAYS/$str-overlay.dtb
	backup $BOOT_OVERLAYS/$str.dtbo
fi

backup $BOOT_CONFIG ignore_rm
backup $BOOT_CMDLINE ignore_rm

backup /etc/rc.local ignore_rm
cp -rf ./etc/rc.local-original /etc/rc.local

backup /etc/modprobe.d/fbtft.conf
backup /etc/inittab

if type fbcp > /dev/null 2>&1; then
	touch $BACKUP_DIR/have_fbcp
	rm -rf /usr/local/bin/fbcp
fi

if [ -f /usr/share/X11/xorg.conf.d/10-evdev.conf ]; then
	backup /usr/share/X11/xorg.conf.d/10-evdev.conf ignore_rm
	dpkg -P xserver-xorg-input-evdev
fi

backup /usr/share/X11/xorg.conf.d/45-evdev.conf
backup $INSTALLED_OPTS_FILE

echo "**Setup completed**"
