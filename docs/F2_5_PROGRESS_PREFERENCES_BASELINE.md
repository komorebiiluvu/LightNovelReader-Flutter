# F2.5 — Reading Progress + Preferences Persistence Repositories

Status: **IMPLEMENTED — REVIEW PENDING**.

F2.5 Exit Approval: **PENDING**. This slice is not self-approved.
F2.6: **NOT STARTED / NOT AUTHORIZED**.

## Entry and scope

Starting SHA: `b717c2632183130d3e6f11b7796bd00949aa460a`.
Frozen legacy reference: `d90d4d090c85a0a9c374684696c34befe12636d1`.

F2.1 and F2.2 are IMPLEMENTED / ACCEPTED; F2.3 and F2.4 are EXIT APPROVED.
The worktree was clean on `main` at the F2.5 entry gate and this implementation
is limited to progress metadata, legacy locator retention, preferences, tests,
and factual governance evidence. No legacy data or network was accessed.

## Models, codecs and contracts

`ReadingProgressV1` is a pure-Dart immutable record with `bookRef`, `hasRead`,
optional `chapterRef`, optional `legacyLocator`, and optional `lastReadAt`.
Its strict JSON envelope is `kind: "readingProgress"`, `version: 1`, with
required `bookRef` and `hasRead`; unknown, missing, wrong-type and malformed
fields are rejected. The existing `LegacyChapterLocatorV1` model is reused
without redesign.

`ProgressRepository` exposes only `get(SourceBookRef)`, deterministic `list()`
and `save(ReadingProgressV1)`. Saving requires an existing `LibraryEntry` and
never creates a Source registration, library stub or migration dataset. The
repository has no Reader-specific API.

`ReaderPreferencesV1` has ten validated fields and exact defaults: font size
22, line spacing 8, `paperWhite`, `pageCurl`, `kaiti`, bold false, and margins
left/right 35, top 72, bottom 24. Its strict envelope is
`kind: "readerPreferences"`, `version: 1`, with all ten fields required.
Stable wire tokens are `paperWhite`, `parchment`, `darkGray`, `black`,
`eyeCare`; `pageCurl`, `scroll`; and `system`, `songti`, `kaiti`, `yuanti`.
Finite numeric validation requires font size > 0 and all other numeric values
to be nonnegative.

`AppPreferencesV1` has required theme tokens `system`, `light`, `dark`, and
nullable optional `preferredSourceId`, `selectedShelfId`, and accent tokens
`purple`, `blue`, `teal`, `pink`, `orange`, `red`. Optional absence remains
absence; no accent, source or shelf default is invented. Its strict envelope is
`kind: "appPreferences"`, `version: 1`.

`PreferencesRepository` exposes nullable reads and complete-state saves for
reader and app preferences. Reads are side-effect free. A missing database row
is distinct from a row explicitly storing domain defaults. The durable
authority is only the existing `reader_preferences` and `app_preferences`
tables; no shared preferences, settings file, Riverpod persistence, local
storage or second database was added.

## Progress semantics and locator policy

Modern `chapterRef` and legacy `legacyLocator` are independently preserved.
Each must belong to the same source/book as `bookRef`, but no equality or
resolution is inferred. Chapter IDs remain opaque; legacy chapter index,
fraction, raw offsets and catalog/title evidence remain evidence only. The
implementation does not create a Reader anchor, resolve a chapter, interpret a
fraction, contact a Source, or add Reader position algorithms.

Progress may contain only `hasRead`, including with no location or timestamp.
A timestamp may exist without a locator. Missing timestamps remain null and are
never replaced with the current time. Timestamps use one deterministic durable
format, `yyyy-MM-ddTHH:mm:ss.SSSZ`, normalized to UTC with no local timezone
stored.

When a legacy locator is present, its existing `datasetId` must already exist
in `migration_datasets`; the repository does not create datasets or perform
import/source lookup. All supported locator columns are persisted exactly.
The internal SQL `locator_id` is not part of the domain API. It is
`legacyLocator.v1.` plus the locator's deterministic v1 JSON encoded as UTF-8
unpadded base64url. This reversible encoding preserves exact Unicode, gives the
same ID to the same canonical locator, and avoids hash/UUID/counter semantics.
Identical saves are idempotent. When progress changes from locator A to B, A's
row remains; F2.5 never garbage-collects legacy evidence.

Progress list order is binary `source_id`, then binary `book_id`. Progress save
atomically validates the library owner, upserts/reuses a locator if present,
and replaces the current progress snapshot. It does not change library saved
state, metadata, tags, shelves, groups, split overrides, source registrations,
or preferences. A second repository instance observes committed state.

## Preferences references, transactions and failures

`preferredSourceId` must reference an existing `source_registrations` row and
`selectedShelfId` must reference an existing `shelves` row. Missing references
return the existing typed `RepositoryFailure.invalidReference` and are never
auto-created. Saving null optional values intentionally clears their stored
values. Progress locator writes plus progress replacement, and each complete
preference replacement, are transaction-boundary operations.

Repository boundaries reuse the existing `RepositoryFailure` reasons. SQLite
and internal failures become safe typed storage failures without leaking SQL,
paths or exception details.

## Tests and validation

Focused tests use isolated in-memory SQLite databases and close every database.
They cover strict progress/reader/app codecs, defaults and tokens, ownership,
opaque Unicode/delimiter/whitespace values, deterministic ordering, UTC
normalization, missing-vs-default preferences, existing-only FKs, locator
idempotency and distinction, old locator retention, cross-repository reads,
unrelated state preservation, and injected progress/locator/preference failure
rollback. No network, real backup or user data is used.

The focused F2.5 suite contains **18 tests**. Local validation on 2026-09-17
(Flutter 3.47.4 / Dart 3.13.3) completed as follows:

- `flutter pub get --enforce-lockfile`: PASS; manifests/lockfile unchanged.
- `dart format --output=none --set-exit-if-changed .`: PASS.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub`: PASS, **148 tests**.
- `./tool/verify_generated.ps1`: PASS; generated code and schema snapshots
  reproduce the approved F2.3 outputs with no diff.
- `git diff --check`: PASS.

The Dart `Object?` codecs operate after `jsonDecode` has produced a Map and
therefore cannot detect duplicate object keys that were already collapsed.
Duplicate-key-aware parsing belongs to the F2.6 importer input boundary; F2.5
does not claim to solve it.

F2.3 schema v1, including `reading_progress`,
`legacy_chapter_locators`, `reader_preferences`, and `app_preferences`, was
not changed. No generated Drift code, dependency, lockfile, workflow, platform
file, native product implementation or schema snapshot was changed.

## Limitations and status

F2.5 does not implement legacy import planning/execution, Source/network/auth,
Reader behavior or rendering, images/offline/downloads, product UI, plugin
runtime, or release-readiness guarantees. It does not implement Reading
position restoration, chapter resolution, pagination or renderer behavior.

F2.5: **IMPLEMENTED — REVIEW PENDING**.
F2.6: **NOT STARTED / NOT AUTHORIZED**.
