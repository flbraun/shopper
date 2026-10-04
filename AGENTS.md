# AGENTS.md

Guidance for coding agents working on this repository. `README.md` covers setting up the development environment, and `PLAN.md` holds the product decisions and their reasons.

## Project

Shopper is a dead-simple shopping list app for Android 16+ (API 36), written in Flutter.

- Application ID / namespace: `de.flbraun.shopper`, app label `Shopper`
- Material 3 via the `material_ui` package. Since Flutter 3.47, Material is no longer `package:flutter/material.dart`, so import `package:material_ui/material_ui.dart`.
- List data lives in SQLite (`sqflite`), app-wide settings in `shared_preferences`.
- License: GPL-3.0. Version: `0.x` until the maintainer declares 1.0.

## Ground rules

- **Don't invent features.** Implement exactly what was asked. If something is unspecified or a change would add behavior, ask the maintainer instead of deciding. Report any deviation or new dependency explicitly.
- **Offline, no tracking.** No `INTERNET` permission, no analytics, no network code. The one accepted exception is Android's app backup (`allowBackup`, left at its default).
- **F-Droid compatible.** Only FOSS dependencies (no Play Services, Firebase or Play Core). Keep `dependenciesInfo` disabled in `android/app/build.gradle.kts`. Ask before adding any dependency.
- **No home screen widgets** for now.

## Tooling

Flutter is pinned in `.fvmrc`; always run it through fvm:

```fish
fvm flutter pub get
fvm dart format lib test
fvm flutter analyze             # must report no issues
fvm flutter test                # must pass
fvm flutter build apk --debug
```

The Android SDK is in `~/Android/Sdk`. Its tools may not be on `PATH`, so call them by full path, e.g. `~/Android/Sdk/platform-tools/adb`.

## Code layout

```
lib/
  main.dart, app.dart       bootstrap, theme (dynamic color, system dark mode), localizations
  data/                     database schema, repositories, models, item sorting
  settings/settings.dart    app-wide settings (ChangeNotifier over shared_preferences)
  ui/                       screens and widgets
  l10n/                     ARB files + generated AppLocalizations (committed)
test/
  data/                     repository/sorting tests (sqflite_common_ffi, in-memory DB)
  ui/                       widget tests; test_app.dart boots the app on a fresh DB
```

## Conventions

- **State:** plain `ChangeNotifier`/`setState`; no state-management packages.
- **Strings:** every user-visible string goes into both `lib/l10n/app_en.arb` (template, with `@key` descriptions) and `lib/l10n/app_de.arb`. Then run `fvm flutter gen-l10n` and commit the generated files.
- **Input:** trim list names and item texts before storing them, and reject empty ones.
- **Case-insensitive matching** (unique list names, dictionary entries, duplicate items) uses Dart's `toLowerCase()` via `textKey()`, stored in `*_key` columns. Don't use SQLite `NOCASE`, which only folds ASCII.
- **Dictionary:** insert-only. Never delete from it.
- **Database changes:** bump the schema version in `lib/data/database.dart` and add an `onUpgrade` migration. Never break existing user data.
- **Tests:** new behavior gets unit or widget tests. Widget tests use `pumpApp`/`settle` from `test/ui/test_app.dart`.

## Verifying on the emulator

Test on the Android 16 emulator (AVD `shopper_api36`, see README), not on a real phone:

- Install the build with `adb install -r …`.
- Drive the app with `adb shell input tap/text/keyevent`, and use `input motionevent DOWN/MOVE/UP` for long-press drags.
- Inspect the UI with `uiautomator dump` and take screenshots with `adb exec-out screencap -p`.
- For debug builds, the database is at `/data/data/de.flbraun.shopper/databases/shopper.db` (`adb root`, then `sqlite3`).

## Release

- Release signing reads `android/key.properties` and `keystore/shopper-release.jks`. **Never commit, print or move these files**, and never regenerate the keystore: updates must be signed with the same key.
- Without `key.properties`, the release build is unsigned (for F-Droid).
- Build releases with `fvm flutter build apk --release --split-per-abi`: one APK per architecture, copied to `build/release/shopper-<abi>-<version>.apk` by the `copyReleaseApks` Gradle task. Keep Flutter's original names in `build/app/outputs/flutter-apk/` untouched; the Flutter tool looks them up there. Don't force splits in Gradle; it breaks the Flutter tool and `flutter run`.
- Only English and German resources are bundled (`localeFilters`). Adding a language means updating the ARB files, `localeFilters` and `android/app/src/main/res/xml/locales_config.xml`.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/):

```
<type>(<optional scope>): <description>

<optional body>

<optional footer(s)>
```

- **Types:**
  - `feat`: a new user-facing feature
  - `fix`: a bug fix
  - `docs`: documentation only
  - `style`: formatting, no code change
  - `refactor`: neither fixes a bug nor adds a feature
  - `perf`: performance
  - `test`: tests only
  - `build`: build system, Gradle, dependencies, signing
  - `ci`: CI configuration
  - `chore`: maintenance (license, version bumps, …)
  - `revert`: reverts an earlier commit
- **Scopes (optional):** the affected area, e.g. `lists`, `items`, `dictionary`, `settings`, `db`, `l10n`, `android`, `plan`.
- **Description:** imperative mood, lower case, no trailing period, ≤ 72 characters for the whole header.
- **Body:** use it to explain *why* when that isn't obvious.
- **Breaking changes:** mark with `!` after the type/scope (`feat(db)!: …`) and a `BREAKING CHANGE:` footer.
- **One logical change per commit.** Commit only when the maintainer asks, and work on `main` unless told otherwise.
