# F2.7 — Committed Legacy State Import Baseline

Status: **EXIT APPROVED**.

Starting SHA: `412c2ae7d48828b3d25b2114e430ca9545b21676`.
Frozen legacy SHA: `d90d4d090c85a0a9c374684696c34befe12636d1`.
Implementation / review-fix starting SHA:
`94ce8ce069af9309721c23c9a8505c48cf640e85`.
Implementation / review-fix history:

- `94ce8ce069af9309721c23c9a8505c48cf640e85` — `feat: add committed legacy state importer`
- `f0687fe015edb0c51d79e33894ffc130310c4d66` — `fix: close F2.7 legacy import review gaps`
- `be64ab071f714003010e2ea974ecce5823d6c80e` — `fix: preserve unknown legacy set state`
- `286c710c39b3fb58a8668b8b5e0f72caa489b7f0` — `fix: distinguish migration-created legacy stubs`

Final implementation SHA: `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`.
Final reviewed validation date: 2026-09-17.
F2.7 exit approval: **APPROVED** by the Human project owner on **2026-09-17**.

F2.7 is implemented under the explicit F2.7 authorization and is now exit
approved. This document does not approve the overall F2 exit. F2 overall
remains **EXIT REVIEW PENDING / NOT APPROVED**. F3 remains **NOT STARTED /
NOT AUTHORIZED**.

## Scope and boundary

F2.7 connects the accepted F2.6 raw-input, planning, receipt, evidence,
transaction, retry and verification framework to the frozen Swift v1
`AppStateSnapshot`. The concrete, offline Dart service is
`LegacyStateImportService`. It converts committed library state, source
associations, shelves, manual groups, split flags, progress metadata and
preferences into the existing F2 repositories/schema. It also preserves
recognized statistics and search history as allowlisted deferred evidence.

The importer does not implement Source/network/auth, cookies or secure
credential storage, catalog refresh, modern chapter resolution, Reader
restoration or rendering, fraction interpretation, image/cache/download or
offline chapter conversion, picker/import UI, grouping/stats/search UI, plugin
runtime, or release readiness. It performs no network or private-container
access and does not begin F3.

## Input and legacy semantics

The supported inputs are explicitly selected `legacyBackupV1` and
`legacyIosSnapshotV1`. Backup v1 requires the accepted envelope
`format = lightnovelreader-backup`, `version = 1`, `exportedAt` and a
`state` object. Snapshot v1 requires the extracted `AppStateSnapshot` object.
Both paths copy the original bytes, use the F2.6 duplicate-aware bounded
`RawJsonParser`, and pass only sanitized typed payloads to handlers. The whole
input is never persisted.

The frozen state fields are `theme`, `preferredSource`, `savedIDs`,
`searchHistory`, `readerPreferences`, `lastChapterByID`, `updateFlagIDs`,
`sourceByID`, `shelves`, `selectedShelfID`, `dailyStats`,
`bookReadingSeconds`, `chapterOffsetByID`, `knownTotalChaptersByID`,
`bookLibrary`, `readBookIDs`, `lastReadAtByID`, `manualGroupByID`,
`groupDisplayName` and `splitBookIDs`. Missing fields use the frozen Swift
defaults: system theme, builtin Wenku8 preferred source, empty collections,
null selected shelf and the legacy Reader defaults. A present malformed field
is not treated as absent; its valid siblings continue where safe evidence and
the nonfatal diagnostic policy allow.

## Sanitized conversion and outcomes

Pure-Dart immutable payloads cover sources, books, shelves, groups, auto-group
rename evidence, splits, progress, orphan progress, Reader/app preferences and
deferred statistics/search history. No raw JSON object is passed to a concrete
handler, and payloads are held in memory only. The F2.6 repository persists
only scalar allowlisted evidence, receipts and outcomes.

`MigrationApplyResult` explicitly carries the desired outcome and diagnostic.
Materialized outcomes require durable product readback. Preservation-only
outcomes (`deferred-preserved` and auto-group rename preservation) verify the
accepted allowlisted evidence itself. Typed verification distinguishes
`verified`, `targetConflict` and `verificationFailure`; target/user edits are
conflicts, not storage failures. A receipt or outcome alone cannot make a
materialized run complete.

Every unit applies product state, mapping rows, receipt/evidence and outcome in
the coordinator's transaction. Failed units roll back their product effect
and remain retryable. Exact repeats reuse the same run and mappings; changed
accepted evidence remains a conflict candidate. Existing target values win:
missing fields may be filled, differing fields are never overwritten, and
ordered arrays are not silently unioned.

Set membership is explicitly tri-state at the concrete import boundary. A
missing `savedIDs` or `updateFlagIDs` field uses the frozen empty-Set default,
so false is known and may be accepted. A valid Set establishes true/false
membership. A present malformed Set produces unknown (`bool? == null`), never
false. Migration-created stubs may therefore carry the schema's physical
`saved=0` default or a null update flag without that value becoming semantic
legacy evidence. Their unresolved provenance remains in existing migration
evidence; a later valid Set in the same dataset lineage may fill that state.
Genuine preexisting target/user state still wins and conflicts. The same audit
applies to `readBookIDs` and `splitBookIDs`: malformed input creates no
negative accepted baseline or invented split effect.

## Source and identity policy

Legacy book IDs remain exact opaque values, including `wk8-<aid>` and IDs that
contain `#`. For the exact source name `文库8(在线)`, the target is
`builtin.wenku8`; a fresh registration is `unavailable` because F3 is not
implemented. Historical/mock names such as `文库8`, `轻小说源A/B` and
`示例...` are not aliases.

Other nonempty valid source names map to
`legacy.ios.name.<unpadded-base64url(exact UTF-8 name)>` and are registered as
`unresolved`. Missing or unusable source names map to
`legacy.ios.unassigned`, also `unresolved`, while safe original evidence is
retained. For a book, `sourceByID[bookId]` is primary and `Book.source` is the
fallback. If both exact candidates differ, both are retained and the mapping
is `conflict`; a target reference does not imply resolution.

Source, book, shelf and group mappings are keyed by
`(datasetId, entityKind, exact legacyKey, mappingVersion)`. Mapping IDs use
deterministic SHA-256 material and never use a random UUID, clock, path,
title, truncation or integer conversion. Shelf and group target IDs are
deterministic, dataset- and mapping-version-scoped opaque IDs. An unrelated
preexisting target collision is a conflict; an existing mapping is authoritative
on retry.

## Library, shelves and groups

Every valid `bookLibrary` entry survives. `savedIDs` controls only the saved
flag; a saved orphan, shelf/group member, source-map-only ID or progress
reference becomes an unsaved/saved source-aware stub as appropriate. Titles,
authors, introductions and tag content/order are preserved exactly. Cover URLs
are retained only in `legacy_book_metadata.cover_reference`; no cover asset ID
or download is fabricated. The allowlisted legacy metadata fields are merged
only into absent target fields, and later differing evidence becomes a conflict.

Shelves retain exact source-aware shelf order and exact member order. Same-name
shelves remain distinct. Duplicate members, invalid selected references and
unresolvable records are not silently deduplicated or repaired. `selectedShelfID`
resolves through the durable shelf mapping; null, missing and the legacy
default selection remain null, while a missing named shelf is preserved as
unresolved evidence.

Manual groups retain deterministic identity, exact display name and source-aware
members. Split flags persist independently and do not remove group membership.
`auto:*` display names are deferred evidence only; no automatic grouping or
title-based rename is generated.

## Progress and preferences

`lastChapterByID` takes precedence over a book's `lastChapter`; both are kept as
evidence when they disagree. Chapter indices remain zero-based and no modern
`ChapterId` is fabricated. Offset keys are parsed at the final `#`, so `#` in a
book ID is preserved. A matching fraction is attached to the retained legacy
locator, additional offsets remain separate allowlisted evidence, and invalid
fractions are not clamped. Orphan offsets remain unresolved. `readBookIDs`
alone controls `hasRead`, including true at chapter zero; read state is not
inferred from a location. Apple Date seconds use the 2001-01-01T00:00:00Z
epoch, with the original numeric evidence retained. No locator is allowed to
invent a modern chapter or Reader anchor. Known-total and update hints are
preserved.

Reader preferences cover all ten legacy fields. Defaults are font size 22,
line spacing 8, background index 0, mode `仿真翻页`, font `楷体`, bold false,
and margins 35, 35, 72, 24. Background indices 0..4 map to the five v1
backgrounds; modes are `仿真翻页` and `滚动`; fonts are `系统`, `宋体`, `楷体`
and `圆体`. Invalid fields fall back independently and retain safe evidence.
App theme maps to system/light/dark, preferred source uses the same exact
source rules, and selected shelves resolve through mapping. Accent remains
null and is reported unavailable; no color is invented.

Statistics and search history are preserved once as ordered, allowlisted
deferred evidence (`deferred-preserved`). No statistics/search product rows or
UI are claimed. Offline bodies, images and downloads are unavailable/deferred
and do not become a false import success.

## Fixtures and validation

### Review-fix policies

The frozen Swift `Book`, `DailyStat` and `AppStateSnapshot` at the frozen SHA
were re-read. Both full fixtures now include required integer `coverIndex`
for every Book, integer daily seconds (12, not 12.5), and integer book seconds
(88, not 88.25). Tests assert all eleven required Book fields and aggregate
integer types; optional Book fields may be absent/null.

A missing/wrong-type required Book field cannot produce known metadata. With
a usable ID, allowlisted scalar evidence is retained and the record becomes
a preserved-unresolved stub; without a usable ID, a deterministic record-local
failure preserves available safe scalar evidence. Siblings continue. Every
tag is baseline evidence at its exact ordinal; tag replacement or reordering
creates conflict-candidate evidence and never overwrites the accepted tags.

Absent fields retain frozen defaults. Present malformed Set/array/map
containers and invalid members receive deterministic field/entry-local failed
receipts, with allowlisted scalar candidates retained. Malformed saved/read
Sets block successful Book/progress outcomes rather than verifying false
flags. Valid Set duplicates collapse. Malformed maps do not reset unrelated
state. Non-string/null/unknown themes retain safe evidence and use an
unresolved system fallback; non-object or duplicate-key Reader containers
fail without writing defaults, while invalid individual Reader fields are
isolated. Daily/book statistics use integer evidence only; malformed decimal
or incomplete aggregate records are failed candidates, not valid aggregates.

Selected shelves must be uniquely and safely planned and actually have a
resolved durable mapping; malformed, duplicated, missing or colliding shelves
leave selection null with unresolved original evidence. No invented shelf or
expected FK exception is used to handle selection.

Progress verification checks the locator pointer, locator identity/version,
dataset/source/book/legacy-book IDs, chapter index, exact offset key, fraction,
and all additional locator evidence columns. Missing required state fails;
different durable state conflicts. A no-locator payload requires a null
pointer. Explicit corruption tests cover every field, missing rows/pointers
and wrong pointers; no modern chapter identity is fabricated.

Each invocation captures an immutable `LegacyImportExecutionContext`
(datasetId, mappingVersion) in its apply/verify closures and owns its planner.
No mutable per-import state or global mutex exists on the service. Concurrent
imports on one service with two datasets and different mapping versions pass
mapping, locator and receipt isolation assertions.

Synthetic fixtures are:

- `test/fixtures/f2_7_full_backup_v1.json`
- `test/fixtures/f2_7_full_snapshot_v1.json`

The F2.7 focused suites contain **195 passing tests**: the original 5 in
`test/migration/legacy_state_import_test.dart`, plus 190 targeted/table-driven
tests in `test/migration/legacy_import_review_test.dart`, including the
targeted provenance regressions. They cover exact
source identities/non-aliases, all required Book fields, optional fields,
tags, missing-field fill/existing-target precedence, Set/map corruption,
shelf/group/split ordering and identity, selected shelf validity, progress
precedence/offsets/dates/full locator readback, all Reader fields and enum
values, themes, integer statistics, search fidelity, fatal input zero writes,
all-column secret/blob exclusion, unchanged bytes, concurrent isolation, and
malformed-versus-missing Set provenance across saved, update, read and split
state. The saved shelf/group/progress dependency paths, corrected later valid
inputs, and genuine preexisting target protection are explicit regressions.
The original failure-injection/retry and file-backed close/reopen tests remain.
Both corrected full fixtures still plan 21 units, independently asserted by
tests (the count is not a format acceptance rule). Expected and actual
happy-path counts for each fixture are:

| Entity kind | Expected | Actual |
| --- | ---: | ---: |
| source | 5 | 5 |
| book | 4 | 4 |
| shelf | 2 | 2 |
| group | 2 | 2 |
| split | 1 | 1 |
| progress | 3 | 3 |
| readerPreferences | 1 | 1 |
| appPreferences | 1 | 1 |
| statistics | 1 | 1 |
| searchHistory | 1 | 1 |

The happy-path outcomes are imported **10**, preserved-unresolved **8**,
deferred-preserved **3**, intentionally-excluded **0**, unchanged **0**,
conflict **0** and failed **0**. The repeated exact import reuses the run,
does not duplicate shelves/groups, and remains complete. The reopen test
reuses the same run/mappings. Failure injection rolls back the failed unit,
leaves a partial run, and a retry completes. Secret sentinel input is absent
from all migration/product storage and no whole input blob is retained.

Local validation completed:

| Check | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | PASS |
| `dart format .` / no-change format check | PASS |
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --no-pub` | PASS, 370 tests |
| `./tool/verify_generated.ps1` | PASS; generated/schema outputs unchanged |
| `git diff --check` | PASS |
| Windows packaged `integration_test/storage_smoke_test.dart -d windows --no-pub` | PASS, actual F2.7 import/readback and reopen |
| Dependencies | UNCHANGED |
| `schema.drift` | UNCHANGED |
| Generated Drift | UNCHANGED |
| Schema snapshots | UNCHANGED |
| Migration history | UNCHANGED |
| Workflow | UNCHANGED |
| Platform files | UNCHANGED |

The packaged smoke executes a frozen-valid inline snapshot import and now
explicitly checks progress/locator, ordered tag and app preference readback
after reopening the production SQLite adapter. Windows executed successfully;
Android and iOS packaged smoke are CI responsibilities. The prior F2.6 Run #18
Android smoke instability is an existing CI/runtime harness issue and is not
changed or repaired by F2.7.

[Run #19 / 35214416354](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35214416354),
for `94ce8ce069af9309721c23c9a8505c48cf640e85`, remains historical
pre-execution FAILURE evidence with empty job step lists.

[Run #20 / 35217367323](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35217367323),
for `f0687fe015edb0c51d79e33894ffc130310c4d66`, executed successfully after
repository visibility/billing recovery: Quality, Android debug, Android
packaged storage smoke, Windows debug, Windows packaged storage smoke, iOS
debug unsigned and iOS simulator packaged storage smoke all PASS.

[Run #21 / 35223587242](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35223587242),
for `be64ab071f714003010e2ea974ecce5823d6c80e`, observed the same seven
checks all PASS.

[Run #22 / 35226294436](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35226294436),
for final SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`, observed Quality,
Android debug, Android packaged storage smoke, Windows debug, Windows
packaged storage smoke, iOS debug unsigned build and iOS simulator boot PASS.
The iOS simulator packaged-storage smoke was **NOT PASS, NOT FAIL,
HUMAN-WAIVED / CANCELLED OR ABANDONED AFTER STALL**.

### Final iOS packaged-storage smoke evidence waiver

The final reviewed SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`
successfully completed the iOS unsigned build and simulator boot. The
subsequent iOS simulator packaged-storage integration test stalled after
successful Xcode build completion and did not produce a final PASS result
within the accepted review window.

The Human project owner explicitly approved proceeding without a final-SHA iOS
packaged-smoke PASS on 2026-09-17. Supporting evidence includes final-SHA
Quality PASS, Android packaged smoke PASS, Windows packaged smoke PASS, iOS
unsigned build PASS and iOS simulator boot PASS; immediately preceding
reviewed SHA `be64ab0` Run #21 completed the same iOS simulator
packaged-storage smoke successfully; and the final provenance fix changed
only Dart migration logic/tests, not workflow, native iOS code, platform
configuration, schema or dependencies.

Classification: **HUMAN-APPROVED EVIDENCE WAIVER**, not PASS. This waiver
applies only to F2.7 exit evidence and does not permanently waive future iOS
validation requirements. No smoke gate is changed, skipped or retried here.

## Final human-reviewed behavior

The Human project owner accepted the final implementation behavior covering:

- frozen Swift-compatible backup/snapshot fixture semantics;
- required legacy Book validation and ordered tag baseline evidence;
- missing legacy field versus malformed legacy field, including malformed Set
  UNKNOWN semantics and missing Set frozen Swift empty-Set defaults;
- corrected savedIDs recovery, updateFlagIDs/readBookIDs/splitBookIDs unknown
  protection, migration-created unresolved stub provenance and preexisting
  product-stub protection;
- preexisting user state wins and changed valid later exports become conflict
  candidates;
- exact source mapping, unresolved/unassigned source preservation, opaque
  BookId preservation and deterministic identity mappings;
- shelf/group conversion, split/group coexistence, progress locator
  preservation and complete durable locator verification;
- Apple Date, Reader preference, App preference, statistics and search-history
  conversion/preservation;
- no secret or whole-input persistence, exact retry idempotency,
  close/reopen recovery, failure rollback/retry and concurrent dataset
  isolation;
- no network requirement, offline data deferred and accent acquisition
  deferred.

These accepted behaviors do not claim later-phase Source, Reader, image,
offline/download, UI, plugin or release-readiness behavior.

## Freeze and limitations

Dependencies are unchanged; the already-approved direct `crypto 3.0.7`
dependency is reused. `schema.drift`, generated Drift code, schema snapshots,
schema version, migration history, workflow, pubspec, lockfile and platform
files are unchanged. No native business logic was added.

F2.7 proves the offline persistence foundation's concrete legacy conversion and
durable readback. It does not prove predecessor replacement, release
readiness, real installed-app upgrade/recovery, F3 source/auth/reconciliation,
F4 Reader restoration, F6 offline bodies/images, F7 statistics/search/group UI
or accent acquisition, or F11 production upgrade validation.

Final status:

F2.7: **EXIT APPROVED**

F2 overall: **EXIT REVIEW PENDING / NOT APPROVED**

F3: **NOT STARTED / NOT AUTHORIZED**
