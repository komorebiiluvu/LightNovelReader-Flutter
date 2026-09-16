# F1 Flutter Foundation Baseline

Recorded: 2026-09-16, Asia/Shanghai (UTC+08:00)

Status: **F1 — Flutter Foundation: EXIT APPROVED**.

The F1 exit was approved by the human project owner on 2026-09-16. This closes
the foundation phase only; it is not product-complete or release-ready. No F2
work has started.

## 1. Revision and repository identity

- Development repository: `C:\Projects\LightNovelReader-Flutter`
- Origin: `https://github.com/komorebiiluvu/LightNovelReader-Flutter.git`
- Initial baseline commit: `278f3ec814fdb158331ee3b2294a2d4addd41c23`
- Baseline subject: `chore: establish cross-platform Flutter baseline`
- F1 implementation commit: `3d0392249719eb51fb42f29f820af730051e849e`
  (`feat: establish Flutter application foundation`).
- F1 exit documentation commit: the documentation-only commit with subject
  `docs: approve F1 Flutter foundation exit`; its full SHA is reported in the
  final closure message. It is distinct from both earlier milestones.
- The initial baseline commit is preserved and neither earlier commit was amended,
  rewritten, or squashed.
- Legacy reference: `C:\Projects\LightNovelReader-Legacy`, read-only.
- Legacy HEAD and frozen commit both verified as
  `d90d4d090c85a0a9c374684696c34befe12636d1`; its worktree was clean and unchanged.

## 2. Environment and toolchain evidence

| Item | Observed value |
| --- | --- |
| Host | Windows 11 Pro, 64-bit, 25H2; CLI reports `10.0.26200.9457` |
| Flutter path | `C:\flutter` |
| Flutter | `3.47.4`, channel `stable` |
| Framework revision | `9584c6713b` |
| Engine revision | `06a2e2a110` |
| Dart | `3.13.3` |
| DevTools | `2.60.0` |
| Android SDK | `C:\Users\Only酱\AppData\Local\Android\sdk` |
| Android SDK/tooling | SDK/build-tools `36.0.0`; platform `android-36.1`; licenses accepted |
| Android Java | Android Studio bundled OpenJDK `21.0.10` |
| Windows toolchain | Visual Studio Community 2026 `18.10.12201.205` |
| Windows SDK | `10.0.26100.0` |
| macOS / Xcode | GitHub Actions `macos-15` runner used for the unsigned iOS Debug build |

Local `flutter doctor -v` reported no issues for the available Windows environment:
Flutter, Windows, Android toolchain, Visual Studio, network resources and proxy
configuration passed. Connected local targets listed Windows, Chrome and Edge; no
Android physical device/emulator was connected. iOS was validated separately by
the macOS CI job described in section 5. No device install/run, signed
distribution or release-performance claim is made.

Environment notes: an HTTP proxy is configured; its value is not recorded.
Pub reported four newer versions outside existing constraints. No unrelated
dependency upgrades were performed. Generated iOS/Android/Windows runner source
was not changed by this implementation.

## 3. Dependency support matrix

Support was checked before adding the one new direct dependency. Platform
declarations are distinct from actual project build evidence in section 5.

| Package / API | Purpose | iOS | Android | Windows | Required/Optional |
| --- | --- | --- | --- | --- | --- |
| `flutter_riverpod` `3.4.3` (new) | Root dependency/state composition | Declared support | Declared support | Declared support | Required |
| Flutter SDK `3.47.4` (existing) | Widgets, built-in Navigator, runner tooling | macOS CI unsigned Debug build passed | Local debug build passed | Local debug build passed | Required |
| `cupertino_icons` `1.0.8` (existing) | Template icon assets | Portable assets | Portable assets | Portable assets | Existing runtime dependency; not used by F1 home |
| `flutter_test` (SDK, existing) | Unit/widget verification | Shared Dart test layer | Shared Dart test layer | Shared Dart test layer | Required for development |
| `flutter_lints` `6.0.0` (existing) | Static analysis rules | Platform-neutral | Platform-neutral | Platform-neutral | Required for development |

Sources: [Riverpod package metadata](https://pub.dev/packages/flutter_riverpod/versions/3.4.3),
[Riverpod setup](https://riverpod.dev/docs/introduction/getting_started),
[Flutter navigation guidance](https://docs.flutter.dev/ui/navigation).
The installed Riverpod manifest requires Dart `^3.12.0` and Flutter `>=3.0.0`;
the local SDK satisfies these requirements. The package has no native plugin
registration and is consumed through its Flutter/Dart API.

`pubspec.yaml` pins Riverpod to `3.4.3`; `pubspec.lock` is committed and enforced
in CI. Newly resolved transitive packages: `riverpod 3.4.3`, `state_notifier 1.0.0`,
`listen 1.0.1`, `uuid 4.6.0`, `crypto 3.0.7`, `fixnum 1.1.1`, `typed_data 1.4.0`.
No routing, logging, database, parsing, code-generation or plugin-runtime package
was added. Dependency resolution failure blocks the build; Riverpod is not an
optional integration with a fallback. See `docs/adr/0002-f1-foundation-composition.md`.

## 4. Deliverables and ownership

```text
lib/
  main.dart
  src/
    app/
      app.dart
      app_providers.dart
      app_router.dart
      bootstrap.dart
      home_screen.dart
    core/
      app_error.dart
      app_logger.dart
test/
  app/bootstrap_test.dart
  core/app_diagnostics_test.dart
  widget_test.dart
.github/workflows/flutter.yml
```

- `main` delegates to bootstrap. Bootstrap initializes the binding and `runApp`
  in the same zone, owns framework/root-isolate error handlers, and supplies one
  root `ProviderScope` with shared logger/error reporter instances.
- `app_providers` composes services; `app_router` owns the single home route and
  safe unknown-route fallback. The app has only a neutral placeholder home.
- `core` uses Dart primitives, without Flutter or Riverpod imports. `AppFailure`
  supplies a stable code and safe message; unknown errors normalize to a generic
  failure. Diagnostics retain runtime type and runtime stack without arbitrary
  exception messages or incoming route/argument data.
- Logging is local `dart:developer` output, not persistent crash storage or
  remote telemetry. Runtime stacks can contain source paths; callers must supply
  traces from runtime/framework boundaries, not user-generated strings.
- No future feature trees, schema, parser, Reader, source host, image pipeline,
  download system or plugin runtime was created.

Governance A–E clarifications were applied: Constitution/ADR precedence and native
boundaries; platform integration test wording; explicit CI in F1; successful
three-platform F1 exit; F2 identity/serialization and F9 Plugin API freeze timing;
release PASS/N/A/waiver rules with non-waivable blockers preserved.

## 5. Acceptance criteria, tests and platform evidence

Final local validation was performed after the diagnostic-source-context fix.
Every command below exited with code `0` where marked PASS.

| Check | Actual result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | PASS |
| `dart format --set-exit-if-changed .` | PASS — 11 Dart files, 0 changed |
| `flutter analyze` | PASS — No issues found |
| `flutter test` | PASS — 5 tests |
| `flutter build windows --debug` | PASS — completed 2026-09-16 16:04:20 +08:00 |
| `flutter build apk --debug` | PASS — completed 2026-09-16 16:04:44 +08:00 |
| iOS build | **PASS** — GitHub Actions macOS runner, unsigned iOS Debug build |
| CI configuration | PASS — YAML parsed; four matrix entries and embedded PowerShell syntax checked |
| Remote GitHub Actions run | **PASS** — implementation commit validated; Quality, Android debug, Windows debug and iOS debug unsigned all passed; overall workflow `SUCCESS` |

The five tests verify root-scope/router home rendering, unknown-route fallback
and back navigation with provider override, structured diagnostic records with
exception-payload exclusion and retained stack, preservation of known failures,
and bootstrap wiring of both global error hooks to the shared logger. Tests
restore framework handlers before normal widget assertions.

Local evidence is in `.buildlog/f1/`: `dependencies.log`, `format.log`,
`analyze.log`, `test.log`, `windows-debug.log`, `android-debug.log`, and the two
build-result JSON records. This directory is ignored and is not part of the
commit; the tracked command/result summary and reproduction steps are above/below.

### Build artifacts

| Artifact | SHA-256 of the observed local debug artifact |
| --- | --- |
| `build/windows/x64/runner/Debug/light_novel_reader.exe` | `FEAE7D3BBB1580A3D83AC937E726E1C72E235FF2AA4B3D71AA5C1667FEBB99B5` |
| `build/app/outputs/flutter-apk/app-debug.apk` | `FB01FF509939DA6088B85AE45A47D19CB8F93865AF3CA88067BD4D45079CA58D` |

The Windows executable requires its generated bundle alongside it. These hashes
identify this local build; byte-for-byte reproduction across hosts is not claimed.

## 6. Exact reproduction commands

On the configured Windows host, from the development repository:

```powershell
Set-Location -LiteralPath 'C:\Projects\LightNovelReader-Flutter'
git rev-parse HEAD
flutter --version
flutter doctor -v
flutter pub get --enforce-lockfile
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build windows --debug
flutter build apk --debug
git diff --check
```

Check each command's exit code before proceeding. Use the pinned Flutter 3.47.4
SDK and the committed lockfile. The CI format check adds `--output=none` so it
cannot rewrite files. Do not run the iOS build on Windows.

CI is triggered by push, pull request or manual dispatch. The successful remote
run for the F1 implementation revision used the workflow's separate assignments:

- quality to `ubuntu-24.04`;
- Android debug to `ubuntu-24.04` with Temurin JDK 21;
- Windows debug to `windows-2025`;
- unsigned iOS debug to `macos-15`.

The macOS job ran `flutter build ios --debug --no-codesign --no-pub` after locked
dependency restoration. This proves the Flutter iOS project builds successfully
on macOS for an unsigned Debug configuration. It does **not** prove App Store
signing, physical-device installation, Simulator interaction, a production
release archive, Reader behavior, performance, or real-device regressions. No
signing, upload, deployment or release automation is included.

The exact Actions run URL was not safely determinable from the available local
repository metadata, so no URL or run ID is invented here. The verified run was
triggered from the F1 implementation commit above.

## 7. Known exceptions, blockers and exit approval

- Local Windows/Android implementation validation: PASS.
- No known local F1 implementation blocker remains.
- iOS unsigned Debug build evidence: PASS on the GitHub Actions macOS runner.
- No iOS physical-device validation or signed release validation has occurred.
- No performance validation has occurred.
- Remote CI matrix: PASS for the implementation revision; exact URL was not
  available from local metadata.
- Human owner F1 exit approval: APPROVED on 2026-09-16.
- No future-phase contract was promoted to an F1 blocker. No F2 work is authorized
  by this baseline record.

**Exit Approval: APPROVED — Human project owner, 2026-09-16.**

Foundation implementation is complete for F1. The application is not described
as product-complete or release-ready; Reader, Source, persistence/domain,
plugins, performance and real-device validation belong to later phases.
