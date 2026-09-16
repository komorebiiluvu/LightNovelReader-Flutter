# Build and Tooling — iOS / Android / Windows

## 1. Target matrix

First-class:
- iOS
- Android
- Windows

## 2. Common tools

- Flutter stable
- Dart bundled with Flutter
- Git

Check:

```bash
flutter --version
flutter doctor -v
git --version
```

## 3. Common quality gate

```bash
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## 4. iOS

Requires macOS + Xcode.

```bash
flutter build ios --debug --no-codesign
flutter build ios --release --no-codesign
```

## 5. Android

Requires Android SDK/toolchain.

```bash
flutter build apk --debug
flutter build appbundle --release
```

## 6. Windows

Requires Windows Flutter desktop toolchain/Visual Studio components reported by `flutter doctor`.

```powershell
flutter config --enable-windows-desktop
flutter build windows --debug
flutter build windows --release
```

## 7. Dependency gate

Before adopting a core Flutter package, verify it supports:
- iOS
- Android
- Windows

Record exceptions/optional fallbacks in an ADR.

## 8. CI

Minimum logical matrix:

Common:
- format
- analyze
- unit/widget/fixture tests

Platform jobs:
- macOS: iOS build/integration where possible
- Windows: Windows build/integration
- Android-capable runner: Android build/integration

Do not require one OS runner to prove another OS build.

### F1 workflow

`.github/workflows/flutter.yml` runs on push, pull request, or manual dispatch.
It pins Flutter in `FLUTTER_VERSION`, restores the committed `pubspec.lock` with
`flutter pub get --enforce-lockfile`, and uses four independent jobs:

| Check | Runner | Command |
| --- | --- | --- |
| Common quality | `ubuntu-24.04` | format check, analyze, unit/widget tests |
| Android debug | `ubuntu-24.04`, Temurin JDK 21, hosted Android SDK | `flutter build apk --debug --no-pub` |
| Windows debug | `windows-2025`, hosted Visual Studio desktop tools | `flutter build windows --debug --no-pub` |
| iOS debug unsigned | `macos-15`, hosted Xcode | `flutter build ios --debug --no-codesign --no-pub` |

The workflow uses the official Flutter Git repository and GitHub's
[checkout](https://github.com/actions/checkout) and
[setup-java](https://github.com/actions/setup-java) actions. PowerShell steps run
one native command each, or explicitly check its exit code, so an earlier failure
cannot be hidden by a later successful command. Each job records SDK versions and
`flutter doctor -v`; runner image contents can change between runs.

Reproduce the common CI gate using the pinned SDK:

```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed .
flutter analyze --no-pub
flutter test --no-pub
```

Run each platform build on the corresponding host with its toolchain. CI only
checks unsigned/debug builds; it does not sign, deploy, or establish device-level
behavior or release readiness. A workflow file is implementation, not execution
evidence. Record actual run links/results against the validated commit in
`docs/FLUTTER_BASELINE.md`. iOS remains **Validation Pending — requires macOS**
until a macOS build succeeds; F1 exit also requires successful Android and Windows
build evidence and human approval.

## 9. Generated platform code

`ios/`, `android/`, `windows/` may contain Flutter-generated build/bootstrap code.

Do not hand-build separate product logic inside these folders.

## 10. Claims

Never claim platform support unless that target was actually built/tested for the referenced commit.
