#!/bin/bash
set -e

SERIAL="${OUYA_SERIAL:-015d4906e123f807}"
ZIMAGE="${1:-zImage}"
ADB_WAIT=5
FASTBOOT_WAIT=10

echo "==> Killing adb server..."
adb kill-server
sleep 2

echo "==> Looking for OUYA via adb..."
if adb devices | grep -w device; then
    echo "==> Rebooting to bootloader..."
    adb -s "$SERIAL" reboot bootloader
else
    echo "ERROR: OUYA not found via adb"
    exit 1
fi

echo "==> Waiting ${FASTBOOT_WAIT}s for fastboot..."
sleep "$FASTBOOT_WAIT"

echo "==> Looking for OUYA via fastboot..."
if fastboot devices | grep -w fastboot; then
    echo "==> Booting $ZIMAGE..."
    fastboot boot "$ZIMAGE"
else
    echo "ERROR: OUYA not found via fastboot"
    exit 1
fi
