# Android 16 emulator for testing Shopper. The screen is shown in the
# browser via noVNC (http://localhost:6080); adb connects on port 5555.
FROM ubuntu:24.04

# Pinned emulator, system image and platform-tools, checked against the
# SHA-1 checksums from Google's repository index.
ARG EMULATOR_ZIP=emulator-linux_x64-16428233.zip
ARG EMULATOR_SHA1=cd7362ea55dfb86a418958138dc396e74165dd01
ARG SYSTEM_IMAGE_ZIP=x86_64-36_r07.zip
ARG SYSTEM_IMAGE_SHA1=c6bf44bdcd885bb902b4ba752d111a073ad7a817
ARG PLATFORM_TOOLS_ZIP=platform-tools_r37.0.1-linux.zip
ARG PLATFORM_TOOLS_SHA1=477254aa5f903c15cf51001717bdf347fb6b53e0

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH=$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$PATH

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates curl unzip socat \
      xvfb x11vnc novnc websockify \
      libasound2t64 libdbus-1-3 libdrm2 libegl1 libfontconfig1 libgbm1 libgl1 \
      libnspr4 libnss3 libpulse0 libx11-xcb1 libxcb-cursor0 libxcb-icccm4 \
      libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 \
      libxcb-shape0 libxcb-xinerama0 libxcb-xinput0 libxcomposite1 libxcursor1 \
      libxdamage1 libxi6 libxkbcommon-x11-0 libxkbfile1 libxrandr2 \
      libxshmfence1 libxtst6 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN mkdir -p "$ANDROID_HOME/system-images/android-36/google_apis" \
 && curl -fsSL --retry 5 --retry-all-errors -o emulator.zip "https://dl.google.com/android/repository/$EMULATOR_ZIP" \
 && echo "$EMULATOR_SHA1  emulator.zip" | sha1sum -c - \
 && unzip -q emulator.zip -d "$ANDROID_HOME" \
 && curl -fsSL --retry 5 --retry-all-errors -o system-image.zip "https://dl.google.com/android/repository/sys-img/google_apis/$SYSTEM_IMAGE_ZIP" \
 && echo "$SYSTEM_IMAGE_SHA1  system-image.zip" | sha1sum -c - \
 && unzip -q system-image.zip -d "$ANDROID_HOME/system-images/android-36/google_apis" \
 && curl -fsSL --retry 5 --retry-all-errors -o platform-tools.zip "https://dl.google.com/android/repository/$PLATFORM_TOOLS_ZIP" \
 && echo "$PLATFORM_TOOLS_SHA1  platform-tools.zip" | sha1sum -c - \
 && unzip -q platform-tools.zip -d "$ANDROID_HOME" \
 && rm emulator.zip system-image.zip platform-tools.zip

# The emulator runs as an unprivileged user; the base image's "ubuntu" user
# (UID 1000) is reused.
COPY docker/emulator/avd /home/ubuntu/.android/avd
RUN mkdir -p /adbkeys && chown -R ubuntu:ubuntu /home/ubuntu/.android /adbkeys

COPY --chmod=755 docker/emulator/entrypoint.sh /usr/local/bin/emulator-entrypoint
COPY --chmod=755 docker/emulator/healthcheck.sh /usr/local/bin/emulator-healthcheck

EXPOSE 5555 6080
ENTRYPOINT ["/usr/local/bin/emulator-entrypoint"]
