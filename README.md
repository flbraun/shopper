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
fvm flutter build apk --release # release APK in build/app/outputs/flutter-apk/
```

Release signing reads `android/key.properties` and the keystore it references. Neither file is committed.
