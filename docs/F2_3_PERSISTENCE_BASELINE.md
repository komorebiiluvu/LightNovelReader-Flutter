# F2.3 Persistence Baseline

Status: IMPLEMENTED — VALIDATION PENDING

This document records observed F2.3 implementation and validation evidence. It
does not approve F2.3 and does not start F2.4.

## Scope and starting point

- Starting commit: `83757cc3571b4f7f63fc80eecdebc504def7c045`.
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

`safe_legacy_values` is a typed, finite field allowlist for unresolved evidence
and conflict alternatives. It is not a generic JSON or backup column. The
synthetic migration test fixture is test-only: no historical pre-v1 Flutter SQL
schema is claimed.

## Local validation evidence

Observed on the Windows development host:

- `flutter pub get --enforce-lockfile`: PASS.
- `dart format --set-exit-if-changed .`: PASS.
- `flutter analyze --no-pub`: PASS.
- `flutter test --no-pub`: PASS, 99 tests.
- Drift generation, schema dump/generation, and clean second-generation check:
  PASS using `tool/verify_generated.ps1` and the supported JIT build-runner mode.
- `git diff --check`: PASS before commit.
- `flutter build windows --debug --no-pub`: PASS.
- `flutter build apk --debug --no-pub`: PASS.

The database tests cover clean creation, schema snapshot verification,
composite opaque identity, foreign-key restrictions, transaction rollback,
reopen, settings constraints, migration retry/idempotency behavior, future
version refusal, unversioned-file refusal, storage failure, and secret/cache
boundaries. All database handles use isolated memory or temporary roots.

## Platform smoke status

The smoke test opens the production boundary, writes source-aware data,
reopens it, checks exact opaque values and SQLite pragmas, and exercises a
rollback. It uses a unique test root and removes only that root afterward.

- Windows storage smoke: **PASS**.
- Android storage smoke: **PENDING** — Android APK build passed, but no local
  emulator/device was available for execution.
- iOS storage smoke: **PENDING** — this Windows host cannot execute an iOS
  simulator/device test.

Build success is not counted as runtime-storage smoke success.

## CI evidence and remaining review

The workflow retains the existing quality, Android build, Windows build, and
unsigned iOS build jobs. It adds Drift generation verification, Windows smoke,
Android emulator smoke, and iOS simulator smoke. The Android emulator action is
pinned to immutable commit
`a421e43855164a8197daf9d8d40fe71c6996bb0d`.

Remote CI results must be recorded only after they are observed for the pushed
commit. Until Android and iOS device/simulator execution is observed, the
overall F2.3 status remains **IMPLEMENTED — VALIDATION PENDING**. Human F2.3
schema review and approval are still required; F2.4 is **NOT STARTED**.
