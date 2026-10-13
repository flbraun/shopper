#!/usr/bin/env bash
# Connects adb to the emulator service when it is running, then runs the
# given command.
if getent hosts emulator >/dev/null; then
  timeout 10 adb connect emulator:5555 >/dev/null 2>&1 || true
fi
exec "$@"
