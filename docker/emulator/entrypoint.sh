#!/usr/bin/env bash
# Starts the virtual display, VNC/noVNC, the adb relay and the emulator, and
# shuts Android down cleanly when the container is stopped.
set -euo pipefail

EMU_USER=ubuntu
EMU_HOME="/home/$EMU_USER"
AVD_DIR="$EMU_HOME/.android/avd/shopper_api36.avd"
DISPLAY_SIZE="${DISPLAY_SIZE:-480x920}"
export DISPLAY=:0 ANDROID_SDK_ROOT="$ANDROID_HOME"

# /dev/kvm must be usable by the emulator user. Join its group, whatever
# GID it has on this host.
kvm_gid="$(stat -c %g /dev/kvm)"
groups="$(id -G "$EMU_USER" | tr ' ' ',')"
[ "$kvm_gid" != 0 ] && groups="$groups,$kvm_gid"

run_as() {
  setpriv --reuid="$EMU_USER" --regid="$EMU_USER" --groups="$groups" --reset-env -- \
    env HOME="$EMU_HOME" PATH="$PATH" ANDROID_HOME="$ANDROID_HOME" \
    ANDROID_SDK_ROOT="$ANDROID_HOME" DISPLAY="$DISPLAY" "$@"
}

# Leftovers from a previous run of this container (stop/start).
rm -f /tmp/.X0-lock /tmp/.X11-unix/X0 "$AVD_DIR"/*.lock

# adb key shared with the dev container (volume at /adbkeys), so the
# emulator trusts it without an on-screen confirmation.
chown "$ADB_KEY_OWNER" /adbkeys
if [ ! -f /adbkeys/adbkey ]; then
  run_as adb keygen /adbkeys/adbkey >/dev/null
  chown "$ADB_KEY_OWNER" /adbkeys/adbkey /adbkeys/adbkey.pub
fi
install -o "$EMU_USER" -g "$EMU_USER" -m 600 /adbkeys/adbkey /adbkeys/adbkey.pub "$EMU_HOME/.android/"

run_as Xvfb :0 -screen 0 "${DISPLAY_SIZE}x24" -nolisten tcp &
for _ in $(seq 50); do [ -S /tmp/.X11-unix/X0 ] && break; sleep 0.1; done
run_as x11vnc -display :0 -forever -shared -nopw -quiet -rfbport 5900 -localhost &
run_as websockify --web /usr/share/novnc 6080 localhost:5900 >/dev/null 2>&1 &

# The emulator's adbd only listens on localhost; relay it to the container
# network so the dev container can "adb connect emulator:5555".
container_ip="$(hostname -I | awk '{print $1}')"
socat "TCP-LISTEN:5555,bind=$container_ip,fork,reuseaddr" TCP:127.0.0.1:5555 &

run_as emulator -avd shopper_api36 -no-audio -no-boot-anim -no-snapshot -no-metrics \
  -gpu swiftshader_indirect -accel on ${EMULATOR_ARGS:-} &
emulator_pid=$!

# On "docker stop", power Android off so data written to the virtual disk
# isn't lost; the emulator exits once the guest is down.
shutdown() {
  echo "Shutting down Android..."
  ADB_VENDOR_KEYS="$EMU_HOME/.android/adbkey" timeout 10 \
    adb -s emulator-5554 shell reboot -p >/dev/null 2>&1 || kill "$emulator_pid" 2>/dev/null || true
}
trap shutdown TERM INT

# "wait" returns early when a trapped signal arrives; keep waiting until the
# emulator has actually exited.
while kill -0 "$emulator_pid" 2>/dev/null; do
  wait "$emulator_pid" || true
done
