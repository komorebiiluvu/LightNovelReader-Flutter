# First Agent Task — Cross-Platform Flutter Bootstrap

## Mission

Prepare the repository for one canonical Flutter/Dart application targeting iOS, Android, and Windows.

## Read first

- `AGENTS.md`
- `docs/PROJECT_CONSTITUTION.md`
- `docs/GOVERNANCE.md`
- `docs/LEGACY_BASELINE.md`
- `docs/CONTRACT_FREEZE_PLAN.md`
- `docs/ARCHITECTURE.md`
- `docs/MIGRATION_FROM_SWIFT.md`
- `docs/REGRESSION_CHECKLIST.md`

## Hard constraints

Do not:
- implement native platform product code
- add custom Swift/Kotlin/C++ Reader code
- implement full Reader
- implement Wenku8 live networking
- implement Plugin Runtime
- redesign UI
- claim platform parity without builds/tests

## Step 1 — Inspect repository

Report:
- whether the repo still contains the imported Swift project as active root content
- current Git state
- current docs
- whether Flutter is already initialized
- stale repository naming such as `-Swift`

Do not delete legacy code before presenting a cleanup plan.

## Step 2 — Validate toolchain

Run where possible:

```bash
flutter --version
flutter doctor -v
```

Record which target toolchains are available on the current machine.

Do not treat unavailable iOS/Android/Windows tooling on one machine as a project architecture failure.

## Step 3 — Propose safe Flutter bootstrap

Target active root:

```text
lib/
test/
integration_test/
fixtures/
ios/
android/
windows/
docs/
```

Use one project.

Do not create separate product source trees per platform.

## Step 4 — Dependency proposal

Before adding packages, provide a table:

| Package | Purpose | iOS | Android | Windows | Required/Optional |

Do not add a required package lacking Windows support.

Default architecture:
- Riverpod
- Flutter routing
- cross-platform persistence selected only after support verification

## Step 5 — After approval

Initialize Flutter safely.

Establish:
- app bootstrap
- Riverpod composition
- routing shell
- error/logging primitives
- default test
- iOS/Android/Windows project targets

Do not pre-create dozens of empty files.

## Step 6 — Baseline

Create:

`docs/FLUTTER_BASELINE.md`

Record:
- commit
- Flutter/Dart versions
- `flutter doctor -v`
- format/analyze/test
- iOS build result where macOS toolchain exists
- Android build result where Android toolchain exists
- Windows build result where Windows toolchain exists
- unresolved tooling blockers

## Stop

Stop after the cross-platform Flutter foundation/baseline.

Do not automatically begin Reader, Source, persistence migration, or UI redesign.


## Governance v0.2 F1 entry gate

Before initializing Flutter, confirm:

- governance status is v0.2 / Active for Foundation Development
- legacy baseline commit is recorded
- repository identity is correct
- no higher-priority rule conflicts with the task
- proposed required packages have an iOS/Android/Windows support matrix
- no project-owned native core implementation is proposed

If these pass, F1 may begin.

Future contracts listed in `CONTRACT_FREEZE_PLAN.md` do not block F1 unless they are explicitly F1 prerequisites.
