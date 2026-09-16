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

## 9. Generated platform code

`ios/`, `android/`, `windows/` may contain Flutter-generated build/bootstrap code.

Do not hand-build separate product logic inside these folders.

## 10. Claims

Never claim platform support unless that target was actually built/tested for the referenced commit.
