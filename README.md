# Shopper

A dead-simple shopping list app for Android 16+. No ads, no tracking, local on your phone, no feature bloat.

## Development setup

The commands below use fish syntax. For bash/zsh, replace `set -Ux VAR value` with `export VAR=value` in your shell rc file, and `fish_add_path DIR` with `export PATH="DIR:$PATH"`.

### 1. System packages

You need **JDK 17** (required by the Android Gradle Plugin) and **fvm** (Flutter Version Management). On Arch/CachyOS:

```fish
sudo pacman -S jdk17-openjdk
# fvm: install the fvm package (e.g. from the AUR) or follow https://fvm.app
```

### 2. Flutter (via fvm)

The Flutter version is pinned in `.fvmrc`. In the repository root, run:

```fish
fvm install          # installs the pinned Flutter version
fvm flutter --version
fvm flutter --disable-analytics   # optional
```

Always call Flutter as `fvm flutter …` inside this repository, so the pinned version is used.

### 3. Android SDK

Install the SDK into your home directory with Google's command-line tools. Android Studio is not required. Avoid a root-owned SDK (e.g. `/opt/android-sdk`), because Gradle needs to be able to download missing SDK components during builds.

1. Download *Command line tools only* for Linux from <https://developer.android.com/studio#command-tools>.
2. Unpack it into the folder layout `sdkmanager` expects and install the required components:

```fish
mkdir -p ~/Android/Sdk/cmdline-tools
cd ~/Android/Sdk/cmdline-tools
unzip ~/Downloads/commandlinetools-linux-*_latest.zip
mv cmdline-tools latest

set -Ux ANDROID_HOME ~/Android/Sdk
fish_add_path ~/Android/Sdk/cmdline-tools/latest/bin ~/Android/Sdk/platform-tools ~/Android/Sdk/emulator

sdkmanager --install "platform-tools" "platforms;android-36" "build-tools;36.0.0" \
  "emulator" "system-images;android-36;google_apis;x86_64"
sdkmanager --licenses
```

3. Point Flutter to the SDK and check the setup:

```fish
fvm flutter config --android-sdk ~/Android/Sdk
fvm flutter doctor -v
```

Only the *Flutter* and *Android toolchain* sections matter. Chrome and Linux toolchain warnings can be ignored, or hidden with `fvm flutter config --no-enable-web --no-enable-linux-desktop`.

### 4. Emulator

Development and testing use an Android 16 (API 36) emulator with the *Google APIs* x86_64 image. Unlike the Play Store image, it allows `adb root`. Hardware acceleration needs KVM; `/dev/kvm` must be readable and writable by your user.

Create the virtual device once:

```fish
avdmanager create avd -n shopper_api36 -k "system-images;android-36;google_apis;x86_64" -d pixel_8
```

Start it with a window:

```fish
emulator -avd shopper_api36
```

Or start it headless (e.g. for automated runs):

```fish
emulator -avd shopper_api36 -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect
```

Wait until the emulator has booted, then check that it is connected:

```fish
adb wait-for-device
adb devices
```

### 5. Run, test, build

```fish
fvm flutter pub get
fvm flutter run                 # debug build on the running emulator
fvm flutter test                # unit and widget tests
fvm flutter build apk --release --split-per-abi # release APKs in build/release/, see below
```

### 6. Release

Release builds are signed with the keystore in `keystore/` via `android/key.properties`. Both are git-ignored:

```properties
storePassword=…
keyPassword=…
keyAlias=shopper
storeFile=../../keystore/shopper-release.jks
```

**Back up both files somewhere safe.** Updates can only be installed over an existing installation if they are signed with the same key. Without `key.properties`, release builds are unsigned (e.g. for F-Droid, which signs with its own key).

Release builds produce one APK per CPU architecture:

```fish
fvm flutter build apk --release --split-per-abi
```

The APKs are written to `build/release/` as `shopper-<abi>-<version>.apk`:

| APK | For | versionCode |
|---|---|---|
| `shopper-arm64-v8a-<version>.apk` | almost all current phones | 2000 + build number |
| `shopper-armeabi-v7a-<version>.apk` | old 32-bit ARM devices | 1000 + build number |
| `shopper-x86_64-<version>.apk` | x86 emulators / devices | 4000 + build number |

`<version>` is the version name from `pubspec.yaml` (e.g. `0.1.0`). Identical copies under Flutter's names (`app-<abi>-release.apk`) remain in `build/app/outputs/flutter-apk/`, because the Flutter tool looks them up there by name. Older versions are not deleted from `build/release/`.

Flutter adds the per-architecture offset to the `versionCode` automatically. The build number is the part after `+` in `pubspec.yaml`'s `version`.

Always pass `--split-per-abi`. It can't be set in the Gradle config: the Flutter tool would still expect a single APK, and `flutter run` would break. Install directly with `adb install build/release/shopper-arm64-v8a-0.1.0.apk`, or copy the APK to the phone.

Check the signature with:

```fish
~/Android/Sdk/build-tools/36.0.0/apksigner verify --print-certs build/release/shopper-arm64-v8a-0.1.0.apk
```

### 7. Publishing a release

Releases are built by GitHub Actions (`.github/workflows/release.yml`) when a version tag is pushed. `pubspec.yaml` is the single source of the version; the tag must match it.

1. In `pubspec.yaml`, raise the version name and add 1 to the build number (the part after `+`, keep it below 1000), e.g. `0.1.0+1` → `0.2.0+2`.
2. Commit: `git commit -am "chore(release): 0.2.0"`
3. Tag and push: `git tag v0.2.0 && git push origin main v0.2.0`

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

```fish
base64 -w0 keystore/shopper-release.jks | gh secret set SHOPPER_KEYSTORE_BASE64
sed -n 's/^storePassword=//p' android/key.properties | gh secret set SHOPPER_KEYSTORE_PASSWORD
```

Every push and pull request also runs `.github/workflows/check.yml`: generated translations up to date, format check, lint and tests.

## License

Shopper is free software, licensed under the [GNU General Public License v3.0](LICENSE).

## AI disclosure

This app's code is entirely written by AI. All changes are reviewed, tested and fully understood by human maintainers before they end up in a public release.
