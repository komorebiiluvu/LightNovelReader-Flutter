# ADR 0003 — F2 persistence stack and migration boundary

Status: **ACCEPTED**

Date / research checked: 2026-09-16.

Human approval: **APPROVED**. Approval date: **2026-09-16**.
Approved by: Human project owner. Approved direction: **Drift + SQLite NativeDatabase**.
The approval gate described below has been satisfied. Current implementation
status is **F2.1 IMPLEMENTED / ACCEPTED; F2.2 IMPLEMENTED / ACCEPTED; F2.3
EXIT APPROVED; F2.4 EXIT APPROVED; F2.5 EXIT APPROVED; F2.6 EXIT APPROVED;
F2.7 NOT STARTED / NOT AUTHORIZED**.
F2.4 human exit approval on **2026-09-17** is recorded in the
[Library / Groups Baseline](../F2_4_LIBRARY_GROUPS_BASELINE.md).
F2.3 human exit approval on
**2026-09-17** is recorded in the
[F2.3 Persistence Baseline](../F2_3_PERSISTENCE_BASELINE.md); this ADR alone does
not grant exit approval.
F2.6 human exit approval on **2026-09-17** is recorded in the
[Migration Framework Baseline](../F2_6_MIGRATION_FRAMEWORK_BASELINE.md).

This proposal implements the Constitution's versioned, cross-platform storage
policy. It does not override the Constitution or authorize dependencies/code
until explicitly accepted together with [F2 Entry Contract](../F2_ENTRY_CONTRACT.md).
It also proposes the concrete predecessor migration guarantees required by
Governance section 2; the detailed commitment matrix is in that contract.

## Context and decision drivers

F2 needs durable library records, memberships, progress metadata, settings and
retryable legacy imports. Relations must keep their identity across source
renaming and database upgrades. Required qualities are iOS/Android/Windows
support, transactions, enforceable uniqueness, versioned migrations, temporary
and in-memory testing, active maintenance, and one Dart implementation without
project-owned native business code. Baseline: Flutter **3.47.4**, Dart **3.13.3**.

## Candidates and current support

“Yes” below is maintainer-declared support, **not a project build/test PASS**.
All three structured options use SQLite; the relevant choice is how much
query, migration and concurrency infrastructure the project must maintain.

| Candidate | iOS | Android | Windows | Migration support | Testability | Maintenance | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Drift 2.35.0 + sqlite3 3.6.0**, NativeDatabase | Yes | Yes | Yes | schemaVersion, migration strategies, schema snapshots/test tooling | NativeDatabase.memory; injected executor and temporary files | Published 2026-09-09 / 2026-09-13; active maintainer releases | Recommended: relational queries, generated type checks, one FFI backend across targets; adds code generation |
| sqflite_common_ffi 2.4.3 + sqlite3 3.6.0 | Yes | Yes | Yes | version/onCreate/onUpgrade callbacks; explicit SQL migrations | inMemoryDatabasePath, Dart VM tests, temporary files | Published 2026-09-10; active tekartik releases | Serious simpler-SQL alternative on **all** targets; more manual mappings/schema checks; do not assume mobile-only sqflite alone covers Windows |
| sqlite3 3.6.0 directly | Yes | Yes | Yes | SQLite transactions/user_version; project writes migration runner | openInMemory and temporary files | Published 2026-09-13; active maintainer | Small API surface but project owns SQL mapping, scheduling, schema verification and error boundaries |
| shared_preferences 2.5.5 (small preferences only) | Yes | Yes | Yes | Per-key/app-controlled; not relational migrations | Injectable preferences facade/platform mocks; actual backing store requires platform tests | Flutter publisher; published 2026-03-25 | Evaluated separately; asynchronous disk persistence is unsuitable as sole authority for committed migration data |

Evidence: [Drift package](https://pub.dev/packages/drift/versions/2.35.0),
[platforms](https://drift.simonbinder.eu/platforms/),
[migrations](https://drift.simonbinder.eu/migrations/),
[repository tests](https://drift.simonbinder.eu/testing/),
[migration verification](https://drift.simonbinder.eu/migrations/tests/);
[sqflite FFI](https://pub.dev/packages/sqflite_common_ffi/versions/2.4.3) and
[migration callbacks](https://pub.dev/documentation/sqflite_common/latest/sqlite_api/OpenDatabaseOptions-class.html);
[sqlite3](https://pub.dev/packages/sqlite3/versions/3.6.0) and
[in-memory API](https://pub.dev/documentation/sqlite3/latest/sqlite3/Sqlite3/openInMemory.html);
[shared_preferences](https://pub.dev/packages/shared_preferences/versions/2.5.5).
Recent publisher changelogs were also inspected:
[Drift](https://pub.dev/packages/drift/changelog),
[sqlite3](https://pub.dev/packages/sqlite3/changelog),
[sqflite FFI](https://pub.dev/packages/sqflite_common_ffi/changelog).

## Recommended decision

Use **Drift over SQLite through NativeDatabase** for structured state, behind
Dart repository interfaces. Domain objects must not be generated database rows
and must not import Drift/Flutter. Open the database in a background isolate;
inject the connection/storage root for testing. Required storage failure is a
visible failure, not a silent switch to volatile storage or another database.

Use a separate **PreferencesRepository** with an allowlisted, versioned
preferences table in the same transactional database for F2 Reader/app settings.
Small size does not make a promised Reader setting disposable. This keeps
preferences separate in ownership/API while allowing settings and migration
receipts to commit atomically. It does not collapse caches, files or secrets
into the database. No shared_preferences dependency is recommended for F2;
that package may later serve expendable convenience preferences under review.
Its documented disk-write limitation drives this decision, not a lack of target
support. Do not maintain two writable authorities for the same setting.

Runtime dependency proposal: `drift` 2.35.0, `sqlite3` 3.6.0 when its API is
directly used, and `path_provider` 2.1.6 for an app-owned Application Support
root. Development tooling proposal: `drift_dev` 2.35.0 and `build_runner` 2.16.1.
No package has been added. Resolve and lock the complete graph only after
approval, including all transitive/native build inputs.

Current sqlite3 3.x bundles SQLite through build hooks; Drift's current platform
guide says the old sqlite3_flutter_libs setup is unnecessary. Do not add that
package or copy a DLL based on old tutorials. Third-party SQLite native internals
are permitted by the Constitution; first-party schema, migration, repositories
and error handling remain Dart. Packaging failures block adoption and must not
be worked around by writing project-owned native product code.

## Compatibility evidence and remaining validation

Published manifests fetched directly from pub.dev on the research date:

| Package | Declared environment | Implication for the baseline |
| --- | --- | --- |
| drift / drift_dev 2.35.0 | Dart >=3.10.0 <4.0.0 | Dart 3.13.3 meets declared range |
| sqlite3 3.6.0 | Dart >=3.10.0 <4.0.0 | Meets declared range; bundled native assets still require build/run proof |
| sqflite_common_ffi 2.4.3 | Dart ^3.12.0 | Alternative meets declared range |
| build_runner 2.16.1 | Dart ^3.11.0 | Meets range; analyzer/build dependency solution untested here |
| path_provider 2.1.6 | Dart ^3.10.0, Flutter >=3.38.0 | Meets ranges; Application Support listed for all three targets |
| shared_preferences 2.5.5 | Dart ^3.9.0, Flutter >=3.35.0 | Meets ranges; documented OS floors Android 24 / iOS 13; not selected |

Reproducible metadata endpoints:
[drift](https://pub.dev/api/packages/drift/versions/2.35.0),
[drift_dev](https://pub.dev/api/packages/drift_dev/versions/2.35.0),
[sqlite3](https://pub.dev/api/packages/sqlite3/versions/3.6.0),
[sqflite_common_ffi](https://pub.dev/api/packages/sqflite_common_ffi/versions/2.4.3),
[build_runner](https://pub.dev/api/packages/build_runner/versions/2.16.1),
[path_provider](https://pub.dev/api/packages/path_provider/versions/2.1.6),
[shared_preferences](https://pub.dev/api/packages/shared_preferences/versions/2.5.5).
[path_provider's support table](https://pub.dev/packages/path_provider/versions/2.1.6)
and the sqlite3 platform/ABI table support the proposed root/backend choice.
The proposed path_provider release declares Android SDK 24+, iOS 13+ and
Windows 10+. Current iOS project settings specify 15.0; Android delegates to
Flutter's minSdkVersion, which the pinned local Flutter SDK declares as 24;
the recorded Windows host is Windows 11. These meet the declared floors.
F2.3 must still check all resolved plugin minima and native packaging before adoption.

No dependency solver, generator, FFI load, migration or three-platform execution
was run for this documentation task. Metadata compatibility is a prerequisite,
not proof of the complete graph. F2.3 must verify locked resolution, generation,
native assets and temporary-file reopen on Windows, Android and iOS. Final
minimum supported OS versions remain the release-matrix decision; current
toolchain success must not be presented as support for every older OS/device.

## Migration/versioning and trade-offs

SQL schema versions, domain JSON versions, legacy input versions and importer
versions are separate. F2 starts a new schema v1, not a reused Swift schema.
Every subsequent released version requires an explicit transaction-safe upgrade
and schema/data preservation tests. Unsupported newer databases must remain
untouched; do not reset, downgrade destructively or delete on open failure.
Foreign-key enforcement and source-aware unique keys are acceptance conditions.

Drift adds generated code and generator/toolchain maintenance. Review schema
snapshots and migration code, and verify generation is reproducible in CI.
SQLite does not choose import conflict resolution, secure secrets, offline-file
integrity or backup policy for the project. Those remain explicit contracts.
The alternatives reduce generator overhead but increase handwritten mappings
and migration verification work; that trade-off is less attractive for this
project's relational user-state and recovery obligations.

The proposed migration route is a non-destructive import of the frozen legacy
v1 backup's committed state. Preserve `wk8-<aid>` opaquely, preserve unresolved
chapter locators, reject secrets, and retain deferred recognized data for its
owning phase. Current iOS bundle IDs differ, so direct private-container access
is not promised. Offline body/image continuity is deferred to F6 with original
data protected; acquisition/UI and real upgrade tests are F7/F11 obligations.

## Human decision required

Accept or revise this stack, generator tooling, database-backed preference
responsibility, and the concrete migration commitment/acquisition limits in
the F2 Entry Contract. Record human approval and change both proposal statuses
through governance before **any F2 production implementation**, including pure
Dart slices. Final SQL table/column DDL and schema snapshots must additionally
be reviewed in F2.3 before dependent repository slices. This ADR proposes no
change to bundle IDs, the Constitution, first-class platforms or native-code
boundaries. F1 commits remain intact.
