#!/bin/bash

BOOT_PATH="/boot/firmware"
BOOT_CONFIG="$BOOT_PATH/config.txt"
BOOT_CMDLINE="$BOOT_PATH/cmdline.txt"
BOOT_OVERLAYS="$BOOT_PATH/overlays"

BACKUP_DIR="./system-backups"
INSTALLED_OPTS_FILENAME="installed-opts"
INSTALLED_OPTS_FILE="./$INSTALLED_OPTS_FILENAME"
