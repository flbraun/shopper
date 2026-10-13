# Shopper

A dead-simple shopping list app for Android 16+. No ads, no tracking, local on your phone, no feature bloat.

## Development setup

The whole toolchain runs in Docker containers (`compose.yaml`), so the host only needs:

- **Docker** with the Compose and Buildx plugins
- **KVM** for the emulator (`/dev/kvm`; check with `ls -l /dev/kvm`)

### Toolchain container

`./dev` runs commands in the development container. The repository is mounted at `/workspace`, and files are written as your user. The first call builds the images, which takes a while and needs about 18 GB of disk space.

```bash
./dev                                 # interactive shell
./dev flutter pub get
./dev flutter test                    # unit and widget tests
./dev flutter analyze
./dev dart format lib test
./dev flutter build apk --release --split-per-abi   # release APKs in build/release/, see below
```

`./dev fvm flutter …` works as well: inside the container, `fvm` is a stand-in that runs the preinstalled Flutter.

All versions are pinned, and SDK downloads are verified against Google's checksums:

| Component | Version | Defined in |
|---|---|---|
| JDK | Temurin 17.0.20.1 | `docker/dev/Dockerfile` |
| Flutter | from `.fvmrc` (3.47.6) | `.fvmrc` |
| Android command-line tools | 23.0 (build 16111833) | `docker/dev/Dockerfile` |
| Android platform / build-tools / NDK | 36 / 36.0.0 / 28.2.13676358 | `docker/dev/Dockerfile` |
| platform-tools (adb) | 37.0.1 | both Dockerfiles |
| Emulator / system image | 37.2.12 / Android 16 Google APIs x86_64 r07 | `docker/emulator/Dockerfile` |

Gradle and pub caches live in Docker volumes, so later builds are fast. After changing a pinned version, rebuild with `./dev build` (both images) or `./dev build dev` / `./dev build emulator`.

### Emulator

```bash
./dev emulator start    # starts the Android 16 emulator, waits until it has booted
./dev adb devices       # shows emulator:5555
./dev flutter run       # debug build with hot reload
./dev emulator logs
./dev emulator stop
```

The emulator screen is shown in the browser: <http://localhost:6080/vnc.html?autoconnect=1&resize=scale>. It's only reachable from your own machine.

The dev container connects adb to the emulator automatically. Apps and data on the emulator survive `stop`/`start`; `docker compose down` resets it.

### Notes

- **IPv6:** image builds use the host network, and the containers get an IPv6-enabled network that prefers IPv6. On some networks (e.g. DS-Lite connections), `dl.google.com` is unreachable over IPv4, which would break SDK and Google Maven downloads. Without IPv6, everything falls back to IPv4.
- **Switching between container and native builds:** `build/` and `.dart_tool/` contain absolute paths of the environment that created them. After switching, the first build can fail; run `flutter clean` first.
- **Image builds** go through `docker buildx bake` (called by `./dev build`), because Compose can't grant builds access to the host network.

### Native setup (without Docker)

The toolchain can also be installed directly on the host. Use the versions from the table above.

#### 1. System packages

You need **JDK 17** (required by the Android Gradle Plugin) and **fvm** (Flutter Version Management). On Arch/CachyOS:

```bash
sudo pacman -S jdk17-openjdk
# fvm: install the fvm package (e.g. from the AUR) or follow https://fvm.app
```

#### 2. Flutter (via fvm)

The Flutter version is pinned in `.fvmrc`. In the repository root, run:

```bash
fvm install          # installs the pinned Flutter version
fvm flutter --version
fvm flutter --disable-analytics   # optional
```

Always call Flutter as `fvm flutter …` inside this repository, so the pinned version is used.

#### 3. Android SDK

Install the SDK into your home directory with Google's command-line tools. Android Studio is not required. Avoid a root-owned SDK (e.g. `/opt/android-sdk`), because Gradle needs to be able to download missing SDK components during builds.

1. Download *Command line tools only* for Linux from <https://developer.android.com/studio#command-tools>.
2. Unpack it into the folder layout `sdkmanager` expects and install the required components:

```bash
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
unzip ~/Downloads/commandlinetools-linux-*_latest.zip
mv cmdline-tools latest

cat >> ~/.bashrc <<'EOF'
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator:$PATH"
EOF
source ~/.bashrc

sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "emulator" "system-images;android-36;google_apis;x86_64"
sdkmanager --licenses
```

3. Point Flutter to the SDK and check the setup:

```bash
fvm flutter config --android-sdk ~/Android/Sdk
fvm flutter doctor -v
```

Only the *Flutter* and *Android toolchain* sections matter. Chrome and Linux toolchain warnings can be ignored, or hidden with `fvm flutter config --no-enable-web --no-enable-linux-desktop`.

#### 4. Emulator

Development and testing use an Android 16 (API 36) emulator with the *Google APIs* x86_64 image. Unlike the Play Store image, it allows `adb root`. Hardware acceleration needs KVM; `/dev/kvm` must be readable and writable by your user.

Create the virtual device once:

```bash
avdmanager create avd -n shopper_api36 -k "system-images;android-36;google_apis;x86_64" -d pixel_8
```

Start it with a window:

```bash
emulator -avd shopper_api36
```

Or start it headless (e.g. for automated runs):

```bash
emulator -avd shopper_api36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect
```

Wait until the emulator has booted, then check that it is connected:

```bash
adb wait-for-device
adb devices
```

#### 5. Run, test, build

Same commands as in the container, with `fvm flutter …` instead of `./dev flutter …`.

### Release

Release builds are signed with the keystore in `keystore/` via `android/key.properties`. Both are git-ignored:

```properties
storePassword=…
keyPassword=…
keyAlias=shopper
storeFile=../../keystore/shopper-release.jks
```

**Back up both files somewhere safe.** Updates can only be installed over an existing installation if they are signed with the same key. Without `key.properties`, release builds are unsigned (e.g. for F-Droid, which signs with its own key).

Release builds produce one APK per CPU architecture:

```bash
./dev flutter build apk --release --split-per-abi
```

The APKs are written to `build/release/` as `shopper-<abi>-<version>.apk`:

| APK | For | versionCode |
|---|---|---|
| `shopper-arm64-v8a-<version>.apk` | almost all current phones | 2000 + build number |
| `shopper-armeabi-v7a-<version>.apk` | old 32-bit ARM devices | 1000 + build number |
| `shopper-x86_64-<version>.apk` | x86 emulators / devices | 4000 + build number |

`<version>` is the version name from `pubspec.yaml` (e.g. `0.1.0`). Identical copies under Flutter's names (`app-<abi>-release.apk`) remain in `build/app/outputs/flutter-apk/`, because the Flutter tool looks them up there by name. Older versions are not deleted from `build/release/`.

Flutter adds the per-architecture offset to the `versionCode` automatically. The build number is the part after `+` in `pubspec.yaml`'s `version`.

Always pass `--split-per-abi`. It can't be set in the Gradle config: the Flutter tool would still expect a single APK, and `flutter run` would break. Install directly with `./dev adb install build/release/shopper-x86_64-0.1.0.apk` (emulator) or `adb install build/release/shopper-arm64-v8a-0.1.0.apk` (phone), or copy the APK to the phone.

Check the signature with:

```bash
./dev apksigner verify --print-certs build/release/shopper-arm64-v8a-0.1.0.apk
```

### Publishing a release

Releases are built by GitHub Actions (`.github/workflows/release.yml`) when a version tag is pushed. `pubspec.yaml` is the single source of the version; the tag must match it.

1. On a branch `chore/release-0.2.0`, raise the version name in `pubspec.yaml` and add 1 to the build number (the part after `+`, keep it below 1000), e.g. `0.1.0+1` → `0.2.0+2`.
2. Commit `chore(release): 0.2.0`, open a pull request and merge it into `master`.
3. Tag the merged commit and push the tag:
   ```bash
   git switch master && git pull
   git tag v0.2.0 && git push origin v0.2.0
   ```

The workflow:
- checks that the tag matches `pubspec.yaml`,
- runs format check, lint and tests,
- builds the signed per-ABI APKs and verifies they are signed with the release key,
- publishes a GitHub Release with `shopper-<abi>-<version>.apk`, a `SHA256SUMS` file and notes generated from the commits.

The workflow needs two repository secrets (*Settings → Secrets and variables → Actions*):

| Secret | Value |
|---|---|
| `SHOPPER_KEYSTORE_BASE64` | `base64 -w0 keystore/shopper-release.jks` |
| `SHOPPER_KEYSTORE_PASSWORD` | `storePassword` from `android/key.properties` |

With the GitHub CLI:

```bash
base64 -w0 keystore/shopper-release.jks | gh secret set SHOPPER_KEYSTORE_BASE64
sed -n 's/^storePassword=//p' android/key.properties | gh secret set SHOPPER_KEYSTORE_PASSWORD
```

Every push and pull request also runs `.github/workflows/check.yml`: generated translations up to date, format check, lint and tests.

## Contributing

`master` only changes through pull requests. Use a branch named `<type>/<description>` (e.g. `feat/item-editing`) and [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) for commit messages and PR titles; details are in `AGENTS.md`.

## License

Shopper is free software, licensed under the [GNU General Public License v3.0](LICENSE).

## AI disclosure

This app's code is entirely written by AI. All changes are reviewed, tested and fully understood by human maintainers before they end up in a public release.
