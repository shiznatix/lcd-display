#!/bin/bash

set -eu
trap 'echo "!!! Command failed: $BASH_COMMAND"; exit 1' ERR
if [ "$(id -u)" -ne 0 ]; then
	echo "This script must be run as root."
	exit 1
fi
cd "$(dirname "$0")"
source ./vars.sh

if [ ! -f $INSTALLED_OPTS_FILE ]; then
	echo "Please install the LCD driver first"
	exit 1
fi

print_info() {
	echo "Usage:./rotate.sh [0] [90] [180] [270] [360] [450]"
	echo "0-Screen rotation 0 degrees"
	echo "90-Screen rotation 90 degrees"
	echo "180-Screen rotation 180 degrees"
	echo "270-Screen rotation 270 degrees"
	echo "360-Screen flip horizontal(Valid only for HDMI screens)"
	echo "450-Screen flip vertical(Valid only for HDMI screens)"
}

if [ $# -eq 0 ]; then
	echo "Please input parameter:0,90,180,270,360,450"
	print_info
	exit 1
elif [ $# -eq 1 ]; then
	if [ ! -n "$(echo $1| sed -n "/^[0-9]\+$/p")" ]; then
		echo "Invalid parameter"
		print_info
		exit 1
	else
		if [ $1 -ne 0 ] && [ $1 -ne 90 ] && [ $1 -ne 180 ] && [ $1 -ne 270 ] && [ $1 -ne 360 ] && [ $1 -ne 450 ]; then
			echo "Invalid parameter"
			print_info
			exit 1
		fi
	fi
else
	echo "Too many parameters, only one parameter allowed"
	exit 1
fi

# get screen parameter
tmp=$(cat $INSTALLED_OPTS_FILE)
output_type=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $1}')
touch_type=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $2}')
device_id=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $3}')
default_value=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $4}')
width=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $5}')
height=$(cat $INSTALLED_OPTS_FILE | awk -F ':' '{printf $6}')

result=$(grep -rn "^dtoverlay=" $BOOT_CONFIG | grep ":rotate=" | tail -n 1)
line=$(echo -n $result | awk -F: '{printf $1}')
str=$(echo -n $result | awk -F: '{printf $NF}')
old_rotate_value=$(echo -n $result | awk -F= '{printf $NF}')
if [ $1 -eq 0 ] || [ $1 -eq 90 ] || [ $1 -eq 180 ] || [ $1 -eq 270 ]; then
	new_rotate_value=$[($default_value+$1)%360]
else
	echo "Invalid parameter: only for HDMI screens"
	exit 1
fi

# setting LCD rotate
sed -i --follow-symlinks -e ''"$line"'s/'"$str"'/rotate='"$new_rotate_value"'/' $BOOT_CONFIG
resultr=$(grep -rn "^hdmi_cvt" $BOOT_CONFIG | tail -n 1 | awk -F' ' '{print $1,$2,$3}')
if [ -n "$resultr" ]; then
	liner=$(echo -n "$resultr" | awk -F: '{printf $1}')
	strr=$(echo -n "$resultr" | awk -F: '{printf $2}')
	if [ $new_rotate_value -eq $default_value ] || [ $new_rotate_value -eq $[($default_value+180+360)%360] ]; then
		sed -i --follow-symlinks -e ''"$liner"'s/'"$strr"'/hdmi_cvt '"$width"' '"$height"'/' $BOOT_CONFIG
	elif [ $new_rotate_value -eq $[($default_value-90+360)%360] ] || [ $new_rotate_value -eq $[($default_value+90+360)%360] ]; then
		sed -i --follow-symlinks -e ''"$liner"'s/'"$strr"'/hdmi_cvt '"$height"' '"$width"'/' $BOOT_CONFIG
	fi
fi

# setting touch screen rotate
if [ $new_rotate_value -eq 0 ]; then
	cp ./usr/99-calibration.conf-$device_id-0 /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to $1"
elif [ $new_rotate_value -eq 90 ]; then
	cp ./usr/99-calibration.conf-$device_id-90 /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to $1"
elif [ $new_rotate_value -eq 180 ]; then
	cp ./usr/99-calibration.conf-$device_id-180 /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to $1"
elif [ $new_rotate_value -eq 270 ]; then
	cp ./usr/99-calibration.conf-$device_id-270 /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to $1"
elif [ $new_rotate_value -eq 360 ]; then
	cp ./usr/99-calibration.conf-$device_id-FLIP-H /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to flip horizontally"
elif [ $new_rotate_value -eq 450 ]; then
	cp ./usr/99-calibration.conf-$device_id-FLIP-V /etc/X11/xorg.conf.d/99-calibration.conf
	echo "LCD rotate value is set to flip vertically"
fi

sync
sync
sleep 1

echo "Reboot system to complete rotation"
echo "**Rotate completed**"
