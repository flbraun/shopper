#!/usr/bin/env bash
# Healthy once Android has finished booting. Uses the shared adb key, so
# the emulator accepts this connection too.
export ADB_VENDOR_KEYS=/home/ubuntu/.android/adbkey
[ "$(adb -s emulator-5554 shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = 1 ]
