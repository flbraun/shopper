# Development image: pinned JDK, Android SDK and Flutter for building,
# testing and releasing Shopper. See README "Development setup".
FROM eclipse-temurin:17.0.20.1_1-jdk-noble

# Android SDK parts. Versions are pinned; archives are checked against the
# SHA-1 checksums from Google's repository index.
ARG CMDLINE_TOOLS_ZIP=commandlinetools-linux-16111833_latest.zip
ARG CMDLINE_TOOLS_SHA1=e025545c62a8e64c7559119566a569fb1dec5f60
ARG PLATFORM_TOOLS_ZIP=platform-tools_r37.0.1-linux.zip
ARG PLATFORM_TOOLS_SHA1=477254aa5f903c15cf51001717bdf347fb6b53e0
ARG ANDROID_PLATFORM=platforms;android-36
ARG ANDROID_BUILD_TOOLS=build-tools;36.0.0
ARG ANDROID_NDK=ndk;28.2.13676358

# Owner of files written to the mounted repository.
ARG UID=1000
ARG GID=1000

ENV ANDROID_HOME=/opt/android-sdk \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/dev/.pub-cache
ENV PATH=$FLUTTER_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/build-tools/36.0.0:$PATH

# Prefer IPv6 where available (glibc tools via gai.conf, Java/Gradle via the
# system property): on some networks dl.google.com is unreachable over IPv4.
# Without IPv6 everything falls back to IPv4.
ENV JAVA_TOOL_OPTIONS=-Djava.net.preferIPv6Addresses=true
COPY docker/dev/gai.conf /etc/gai.conf

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      ca-certificates clang curl git jq libsqlite3-0 sqlite3 unzip xz-utils \
 && rm -rf /var/lib/apt/lists/*

# The base image ships a user with UID 1000; replace it with "dev".
RUN (userdel -r ubuntu 2>/dev/null || true) \
 && groupadd -g "$GID" dev \
 && useradd -m -u "$UID" -g "$GID" -s /bin/bash dev \
 && mkdir -p "$ANDROID_HOME" "$FLUTTER_HOME" /workspace \
      /home/dev/.gradle /home/dev/.pub-cache /home/dev/.android \
 && chown -R dev:dev "$ANDROID_HOME" "$FLUTTER_HOME" /workspace /home/dev

USER dev
WORKDIR /tmp

RUN curl -fsSL --retry 5 --retry-all-errors -o cmdline-tools.zip "https://dl.google.com/android/repository/$CMDLINE_TOOLS_ZIP" \
 && echo "$CMDLINE_TOOLS_SHA1  cmdline-tools.zip" | sha1sum -c - \
 && unzip -q cmdline-tools.zip -d "$ANDROID_HOME/cmdline-tools" \
 && mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" \
 && curl -fsSL --retry 5 --retry-all-errors -o platform-tools.zip "https://dl.google.com/android/repository/$PLATFORM_TOOLS_ZIP" \
 && echo "$PLATFORM_TOOLS_SHA1  platform-tools.zip" | sha1sum -c - \
 && unzip -q platform-tools.zip -d "$ANDROID_HOME" \
 && rm cmdline-tools.zip platform-tools.zip \
 && yes | sdkmanager --licenses >/dev/null \
 && sdkmanager --install "$ANDROID_PLATFORM" "$ANDROID_BUILD_TOOLS" "$ANDROID_NDK" >/dev/null

# Flutter at the version pinned in .fvmrc.
COPY --chown=dev:dev .fvmrc /tmp/.fvmrc
RUN git clone --quiet --depth 1 --branch "$(jq -r .flutter /tmp/.fvmrc)" \
      https://github.com/flutter/flutter.git "$FLUTTER_HOME" \
 && flutter config --no-analytics --no-cli-animations --android-sdk "$ANDROID_HOME" \
      --no-enable-web --no-enable-linux-desktop \
 && dart --disable-analytics \
 && flutter precache --android \
 && flutter --version

COPY --chmod=755 docker/dev/fvm /usr/local/bin/fvm
COPY --chmod=755 docker/dev/entrypoint.sh /usr/local/bin/dev-entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/dev-entrypoint"]
CMD ["bash"]
