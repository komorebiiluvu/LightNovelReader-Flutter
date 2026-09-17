# F2.3 Persistence Baseline

Status: F2.3 — Persistence Infrastructure + Schema v1 — EXIT APPROVED

This document records F2.3 implementation, final validation evidence, and human
exit approval. It does not start F2.4 or approve full F2 completion or release
readiness. Repositories, the legacy migration importer, Reader, and Source
implementations remain outside this persistence foundation/schema closure.

## Scope and starting point

- Starting commit: `83757cc3571b4f7f63fc80eecdebc504def7c045`.
- Approved implementation / final validation commit: `619658150a803299f70e50c758e0329eb7bcadf1` (`fix: close F2.3 persistence validation gaps`).
- Review-fix commit: `6da74f8` (`fix: close F2.3 persistence review gaps`).
- Branch at entry: `main`; `origin/main` matched the starting commit.
- Legacy reference inspected by the preceding F2 work: `d90d4d090c85a0a9c374684696c34befe12636d1`.
- F2.3 boundary: Drift/SQLite connection lifecycle, schema v1, migration
  infrastructure, generated outputs, safety tests, and packaged storage smoke.
  No repositories, import service, Reader, Source, or UI behavior was added.

## Dependencies and opening strategy

The lockfile resolves the accepted direct versions:

- Runtime: `drift 2.35.0`, `path_provider 2.1.6`, `sqlite3 3.6.0`.
- Development: `drift_dev 2.35.0`, `build_runner 2.16.1`, Flutter SDK
  `integration_test`.
- Flutter/Dart baseline used locally: Flutter `3.47.4`, Dart `3.13.3`.

`sqlite3` is direct because the opening boundary uses its typed database API to
set/check SQLite pragmas. The production boundary resolves the application
support directory with `path_provider`, creates the deterministic filename
`light_novel_reader.sqlite`, and opens it with Drift's
`NativeDatabase.createInBackground`. Tests can inject a temporary root or a
`QueryExecutor` (including an in-memory executor). Open and migration errors
are surfaced; there is no reset, delete-and-recreate, or in-memory fallback.

The transitive `jni` FFI plugin is registered by Flutter's generated Windows
plugin file as part of the current package graph. No project-owned native
business or persistence code was added.

## Architecture review correction

The accepted migration contract requires a typed accepted legacy baseline to be
kept separately from unresolved evidence and conflict alternatives. Schema v1
now gives `safe_legacy_values` the constrained `purpose` values
`accepted-baseline`, `unresolved-evidence`, and `conflict-candidate`, and
includes that discriminator in the primary key. This is the smallest change
needed to preserve a previous accepted value when the current application value
and a new legacy value differ. The allowlisted typed value columns and secret
exclusions are unchanged.

The remaining invariant is enforced by the SQLite partial unique index
`safe_legacy_values_one_accepted_baseline` over
`dataset_id, importer_version, entity_kind, legacy_key, field, map_key, ordinal`
when `purpose = 'accepted-baseline'`. `candidate_id` remains in the table's
primary key so unresolved evidence and conflict candidates may retain multiple
alternatives, but it cannot bypass accepted-baseline uniqueness.

## Schema v1 evidence

Schema version is `1`. The review snapshot is
`drift_schemas/drift_schema_v1.json`; generated Drift code is committed and CI
rebuilds it to detect stale outputs.

The normalized tables are:

| Area | Tables |
| --- | --- |
| Source/library | `source_registrations`, `library_entries`, `book_tags`, `legacy_book_metadata` |
| Shelves/groups | `shelves`, `shelf_members`, `manual_groups`, `group_members`, `split_overrides` |
| Migration evidence | `migration_datasets`, `migration_runs`, `record_receipts`, `record_outcomes`, `safe_legacy_values`, `legacy_identity_mappings`, `legacy_chapter_locators` |
| Progress/settings | `reading_progress`, `reader_preferences`, `app_preferences` |

Opaque IDs are separate `TEXT COLLATE BINARY` columns. Book and chapter data
uses source-aware composite keys/FKs; duplicate remote IDs under different
sources are therefore distinct. Foreign keys are enabled and all declared
foreign keys use `ON DELETE RESTRICT ON UPDATE RESTRICT`. Boolean and enum
tokens are constrained in SQL. Timestamps stored by the new boundary are
deterministic UTC ISO-8601 strings; legacy Apple-reference-date values remain
legacy evidence for the later importer.

Reader and app preferences are separate logical tables in the same SQLite
database and are only schema infrastructure in this slice. Search/Explore
state, HTTP/image caches, downloads, credentials, cookies, tokens, passwords,
and arbitrary raw backup blobs have no durable schema authority here.

`safe_legacy_values` is a typed, finite field allowlist for accepted baselines,
unresolved evidence, and conflict alternatives. It is not a generic JSON or
backup column. The synthetic migration test fixture is test-only: no historical
pre-v1 Flutter SQL schema is claimed.

## Local validation evidence

Observed on the Windows development host:

- `flutter pub get --enforce-lockfile`: PASS.
- `dart format --set-exit-if-changed .`: PASS.
- `flutter analyze`: PASS.
- `flutter test`: PASS, 101 tests.
- Drift generation, schema dump/generation, and clean second-generation check:
  PASS using `tool/verify_generated.ps1` and the supported JIT build-runner mode.
- `git diff --check`: PASS before commit.
- `flutter build windows --debug --no-pub`: PASS.
- `flutter build apk --debug --no-pub`: PASS with an ASCII `PUB_CACHE` root.
  With the default cache under the Unicode Windows user path, the transitive
  `jni` CMake build fails in its ANSI file lookup; this is a host path/tooling
  limitation, not an application or schema failure.
- Closure-patch recheck: `flutter build windows --debug --no-pub` PASS. The
  Android APK recheck was blocked by the same host-side JNI CMake ANSI lookup
  against the Unicode Android SDK path; no Android application/schema compile
  error was reported. Android runtime smoke remains a CI-only validation here.
- Exact AOT command `dart run build_runner build --delete-conflicting-outputs`:
  fails on this Windows host while reading the build script's temporary
  `program.dill`; the supported `--force-jit` generation path passes and is the
  path used by `tool/verify_generated.ps1`.

The database tests cover clean creation, schema snapshot verification,
composite opaque identity, foreign-key restrictions, transaction rollback,
reopen, settings constraints, migration retry/idempotency behavior, future
version refusal, unversioned-file refusal, storage failure, and secret/cache
boundaries. The safe-value tests prove that a second accepted baseline for the
same logical cell is rejected by SQLite even with a different candidate ID,
while unresolved and conflict alternatives remain readable and independent;
they also cover the legacy-key, field, map-key, and ordinal boundaries. All
database handles use isolated memory or temporary roots.

## Platform smoke status

The smoke test opens the production boundary, writes source-aware data,
reopens it, checks exact opaque values and SQLite pragmas, and exercises a
rollback. It uses a unique test root and removes only that root afterward.

- Windows storage smoke: **PASS**.
- Android storage smoke: **PASS** — the packaged integration test actually
  executed successfully on a GitHub Actions Android emulator in Run #9.
- iOS simulator storage smoke: **PASS** — executed successfully on the macOS
  GitHub Actions runner in Run #9.

Build success is not counted as runtime-storage smoke success.

## CI evidence and exit approval

The workflow retains the existing quality, Windows build, unsigned iOS build,
and iOS simulator smoke jobs. Android debug build and Android packaged storage
smoke are now separate matrix entries, so each runs on a fresh
`ubuntu-24.04` hosted runner. Both Android entries set up JDK 21, configure
Flutter with `JAVA_HOME`, and restore locked dependencies. The smoke entry then
enables KVM, records `df -h`/lightweight `du -sh` diagnostics, starts the
emulator, and directly runs the integration test without a preceding APK build.
The Android emulator action is pinned to immutable commit
`a421e43855164a8197daf9d8d40fe71c6996bb0d`.

`storage_smoke_test.dart` does not use Google APIs, but the lighter `default`
image was not reliably verifiable from this Windows host for the API 35 hosted
runner setup. The workflow therefore retains the known `google_apis` target and
the `1024M` data disk; runner-level isolation, rather than an extreme partition
size, addresses the observed host resource failure.

Observed run: [GitHub Actions run 35110324488](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35110324488) for implementation commit
`1aecee148002ae1969cd03dab5e781f222ca60b4`.

| Check | Observed result |
| --- | --- |
| Quality | PASS |
| Windows debug build | PASS |
| Windows packaged storage smoke | PASS |
| Android debug build | PASS |
| Android packaged storage smoke | FAIL — emulator did not boot because the hosted runner reported insufficient disk space after the Android build; the smoke test did not execute |
| iOS debug unsigned build | PASS |
| iOS simulator packaged storage smoke | PASS |

The historical failure was hosted-runner disk exhaustion, not an Android APK
compile failure: the APK build itself passed. The final implementation moves
the emulator work to its own runner and adds diagnostics.

Final validation evidence, supplied and confirmed by the human project owner:
[GitHub Actions Run #9, Run ID 35170388187](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35170388187),
for implementation commit `619658150a803299f70e50c758e0329eb7bcadf1`.
Overall workflow result: **SUCCESS**.

| Final check | Result |
| --- | --- |
| Quality | PASS |
| Android debug | PASS |
| Android packaged storage smoke | PASS — integration test executed on an emulator |
| Windows debug | PASS |
| Windows packaged storage smoke | PASS |
| iOS debug unsigned | PASS |
| iOS simulator packaged storage smoke | PASS |

This evidence validates the persistence infrastructure, schema v1, and packaged
SQLite runtime on all three targets. It does not establish full F2 completion.

F2.3 Exit Approval: **APPROVED**.

Approved by: Human project owner.
Approval date: **2026-09-17**.

F2.4: **NOT STARTED / NOT AUTHORIZED**.
