# F2 — Domain + Persistence Foundation entry contract

Status: **ACCEPTED**

Contract revision: **1**. Prepared: **2026-09-16**.

Human approval: **APPROVED**. Approval date: **2026-09-16**.
Approved by: Human project owner.
Current implementation status: **F2.1 IMPLEMENTED / ACCEPTED; F2.2 IMPLEMENTED /
ACCEPTED; F2.3 EXIT APPROVED; F2.4 EXIT APPROVED; F2.5 EXIT APPROVED; F2.6
EXIT APPROVED; F2.7 EXIT APPROVED**.
F2.4 human exit approval: **2026-09-17**, recorded in
[Library / Groups Baseline](F2_4_LIBRARY_GROUPS_BASELINE.md).
F2.3 human exit approval: **2026-09-17**, recorded in
[F2.3 Persistence Baseline](F2_3_PERSISTENCE_BASELINE.md).
The proposal-stage approval conditions below are satisfied by this record;
they do not authorize implementation beyond the current slice or F2 exit.

F2.6 implementation and exit evidence are recorded in the
[Migration Framework Baseline](F2_6_MIGRATION_FRAMEWORK_BASELINE.md). F2.6
human exit approval is recorded there for **2026-09-17**.
F2.7 implementation evidence and the aggregate F2 review record are recorded
in the [F2.7 Legacy Import Baseline](F2_7_LEGACY_IMPORT_BASELINE.md) and
[F2 Exit Evidence](F2_EXIT_EVIDENCE.md). F2 Overall Exit: **APPROVED**.
Approved by: Human project owner. Approval date: **2026-09-17**. F2.1–F2.7
satisfy the accepted F2 Entry Contract revision 1 within its defined scope.
F2.7's evidence retains the final iOS packaged-storage **HUMAN-APPROVED
EVIDENCE WAIVER**, not PASS. F3 remains **NOT STARTED / NOT AUTHORIZED**.

This is a proposed normative contract: MUST/MUST NOT become implementation
requirements only after explicit human acceptance of this document and
[ADR 0003](adr/0003-f2-persistence-stack.md). Publishing this proposal does not
approve F2 entry, implementation, exit, or F3 entry. The Constitution and accepted
ADRs retain their precedence. No Constitution conflict was found.

## 1. Entry evidence and scope

Entry verification: F1 is **EXIT APPROVED**, recorded in the tracked
[Flutter baseline](FLUTTER_BASELINE.md). Before this work, `main` was clean and
HEAD, local `origin/main` and remote `refs/heads/main` all equalled
`53d4723883539ae7acbdd3aabd745c93c2d47d6a` (`docs: approve F1 Flutter foundation exit`).
F1 implementation `3d0392249719eb51fb42f29f820af730051e849e` and initial baseline
`278f3ec814fdb158331ee3b2294a2d4addd41c23` are preserved.

Legacy evidence is solely commit `d90d4d090c85a0a9c374684696c34befe12636d1` in the
read-only legacy repository. The [data inventory](legacy/swift/LEGACY_DATA_MIGRATION_INVENTORY.md)
records observed representations, storage locations and source permalinks.

F2 scope: pure Dart identity and ordered content serialization, transactional
library/shelf/group storage, progress **metadata** and preferences, source
identity mappings, versioned schema/import infrastructure, and the committed
legacy-state importer. All three targets are first-class users of the same
implementation. Domain imports neither Flutter nor persistence/source packages.

Non-goals: live Source/network/auth semantics (F3), Reader position algorithms
and rendering (F4/F5), image requests/cache/downloads (F6), feature/import UI
(F7), plugin runtime (F9), and numerical performance targets (F11). No production
code, dependency, schema implementation or platform runner changes are included
in this proposal.

## 2. Identity Contract v1

### Values and references

`SourceId`, `BookId`, `VolumeId`, `ChapterId` are distinct immutable opaque string
value types. Valid values are nonempty, well-formed Unicode scalar sequences
without U+0000. Preserve exact values: no trimming, case folding, Unicode
normalization, URL decoding, integer conversion or prefix removal. Inputs that
cannot satisfy this rule remain failed/unresolved legacy records; never truncate
or silently repair them. IDs MUST NOT contain credentials or session tokens.

Equality/hash use the value type and exact string; ref equality/hash use the
complete tuple below. A `BookId` by itself is not a globally unique key.

| Reference | Identity tuple | Excluded from identity |
| --- | --- | --- |
| SourceBookRef | `(sourceId, bookId)` | Name, URL, title, current registry availability |
| SourceVolumeRef | `(sourceId, bookId, volumeId)` | Volume title, catalog index/order |
| SourceChapterRef | `(sourceId, bookId, chapterId)` | Volume membership, chapter title/index/order |
| SourceAssetRef | `(sourceId, bookId, assetId)` | Resolved URL, local path, headers, cache placement |

AssetId follows the same opaque-value rules. Chapter identity is scoped by
**both Source and Book**. Identical remote IDs in different Sources or books
must not collide. Changing chapter order or volume membership does not change
chapter identity. If a Source has no stable volume/chapter ID, an explicit
durable mapping may assign an opaque surrogate; a current list index alone is
never persistent identity. F3 owns the evidence/reconciliation rules; unresolved
legacy progress needs no fabricated ChapterId or VolumeId in F2.

Source registry entries keep immutable SourceId separately from mutable display
names and aliases. Renaming leaves all refs intact. Losing/uninstalling a Source
does not delete its library data. Source IDs must be unique in the registry;
conflicting registrations fail rather than take over stored refs. A plugin
Source receives a host-controlled immutable registration ID, preserved through
approved upgrades/reinstallation of that same registration. Display names,
plugin versions and remote IDs cannot authorize impersonation of an existing
Source. F9 freezes manifest/ownership validation; no plugin runtime is built now.

### Legacy mapping policy

Preserve `wk8-<aid>` **exactly as an opaque source-local BookId**. Do not strip it
to a number or replace it with a new global identifier. For verified legacy
`文库8(在线)` records, propose stable SourceId `builtin.wenku8`; only the migration
adapter/registry seed knows that mapping. Future built-in F3 outputs must reuse
these IDs or provide an explicit reversible alias map, never create duplicates.

The candidate legacy association uses `sourceByID[bookId]` when present,
otherwise the record's `Book.source`. If both differ and are not an explicitly
verified alias pair, retain both as candidates in an unresolved migration record;
do not commit a resolved association or guess from global `preferredSource`.
The old `文库8` rename is evidence of historical intent, not proof that mock and
real records are interchangeable.
Unknown/historical/mock names get a stable **unresolved** registry entry and
preserved raw alias. The adapter's deterministic unresolved SourceId is
`legacy.ios.name.` plus unpadded base64url of the exact UTF-8 legacy source name;
missing source uses reserved `legacy.ios.unassigned`. This is an adapter-owned
compatibility encoding; Core must not parse it. Empty/invalid source names stay
unresolved and their raw evidence remains in the safe migration record.

Import identity mappings record legacy dataset ID, original key/name, target
ref, mapping version and resolution status. Multiple conflicting records with
the same legacy key are retained as conflicts; neither a numeric prefix nor a
title permits an automatic merge. Manual grouping relates distinct source-aware
books and does not collapse their identity. Internal SQL row IDs may be used
later but cannot replace refs in domain APIs, exports or migration receipts.

### Legacy progress locator

F2 defines `LegacyChapterLocatorV1` with `kind:"legacyIosChapterLocator"`,
`version:1`, `datasetId`, `bookRef`, `legacyBookId`, `chapterIndex` (zero-based,
nonnegative), and optional `rawOffsetKey`, `fraction`, `remoteIdEvidence`,
`chapterTitleEvidence`, `volumeTitleEvidence`, `catalogDigest`. Optional fields
are omitted when absent. `fraction` must be finite and in [0,1]; retain an
invalid original in a conflict record instead of clamping it silently.
`remoteIdEvidence` is an opaque string from an actual catalog value, never
`index+1`; a catalog alongside a backup is evidence, not proof of contemporaneity.

Snapshot `lastChapterByID` takes precedence when valid; `Book.lastChapter` is
the fallback. Preserve/report a disagreement. Offset-map keys must be matched
against an exact known book ID plus a final `#` and decimal index; preserve the
raw key. Ambiguous or orphan keys are unresolved records, not discarded data.
Do not fetch today's catalog and reinterpret an old index as a confirmed cid.
F2 stores locators without asserting a modern anchor. F3 may resolve chapter
identity from evidence; F4 alone decides how a legacy fraction restores reading.

## 3. Serialization and persistence-key rules

Canonical interchange uses UTF-8 JSON objects with exact `kind` and integer
`version:1`. Standalone refs serialize as flat objects; field names are normative:

```json
{"kind":"sourceBookRef","version":1,"sourceId":"example.a","bookId":"42"}
```

Volume/chapter refs use `kind:"sourceVolumeRef"`/`"sourceChapterRef"` and add
`volumeId`/`chapterId`; assets use `kind:"sourceAssetRef"` and add `assetId`.
Nested refs use the same complete shape. Opaque IDs are always JSON strings,
including numeric-looking values. Object key order and JSON escape spelling are
not meaningful; arrays are ordered. Decoders reject duplicate object keys,
wrong types, nonfinite numbers, missing required fields and unknown v1 fields.
Optional absent values are omitted (not written as null) unless a specific
record contract says otherwise. Equality tests compare values, not JSON bytes.

Unknown version/kind/field produces a typed unsupported result. Never reinterpret
it as v1 or silently round-trip only recognized fields. Durable input stays
untouched; unsupported records do not get overwritten by default values. A
caller may preserve unsupported input externally for a newer importer, subject
to the credential rules in section 6; arbitrary input must not be dumped into
the general database. Future required behavior uses an explicit new version
and an upgrade path. Legacy formats have their own decoder and are not subjected
to v1 domain-envelope requirements.

SQL uses separately bound TEXT columns with exact/BINARY comparison and unique
constraints on the full tuples. Never join IDs with `#`, `/` or `-` to make a
database key. If a string key is required outside SQL, encode each ID's UTF-8
bytes independently as unpadded base64url and join those encoded components
with `.` after `sourceBookRef.v1.` (or `sourceVolumeRef.v1.`,
`sourceChapterRef.v1.`, `sourceAssetRef.v1.`), in identity-tuple order. Dots
cannot occur inside the encoded components, so the encoding is reversible and
does not depend on a JSON encoder's whitespace/escaping choices. No domain ID
is a filesystem path. File adapters use an independently assigned safe name
with a recorded association; they must not reuse legacy `safe()` as identity.

Database schema version, each JSON record version, legacy backup version,
importer version and mapping version are **independent**. New timestamps are
UTC ISO-8601 strings with `Z`; legacy Date numbers are decoded as seconds since
2001, with original numbers retained in migration provenance if conversion
loses precision. Calendar-day statistics retain their original day string;
do not invent a timezone or event history.

## 4. Ordered ChapterContent / ContentNode v1

The following JSON shape is normative. `title` and image `altText` are optional
strings; `chapterRef`, `nodes`, text `text` and image `assetRef` are required.
Node versions follow the containing chapter version, not a separate counter.

```json
{
  "kind": "chapterContent",
  "version": 1,
  "chapterRef": {"kind":"sourceChapterRef","version":1,"sourceId":"example.a","bookId":"42","chapterId":"intro"},
  "title": "Example",
  "nodes": [
    {"kind":"text","text":"First paragraph"},
    {"kind":"image","assetRef":{"kind":"sourceAssetRef","version":1,"sourceId":"example.a","bookId":"42","assetId":"illustration-a"}},
    {"kind":"text","text":"Following paragraph"}
  ]
}
```

`TextNode` contains plain Unicode text, not executable markup. Text, whitespace,
line breaks and **empty text nodes are retained exactly**; v1 codecs do not
trim, merge, split, reorder or deduplicate nodes. Index is position within this
specific content value, not stable identity or an F4 Reader anchor.
`nodes:[]` is valid successfully obtained empty content, distinguishable from a
fetch/parse failure. A text-only or image-only chapter is valid.

`ImageNode` carries a SourceAssetRef and optional altText. Its source/book must
match the chapter's source/book; a Source adapter maps external assets into
that namespace. Repeated asset refs are valid and stay at each original position.
The reference is a minimum stable locator for later resolution, **not a network
request descriptor**. Bare URLs, local absolute paths, cookies and headers are
not node identity fields. F3/F6 will supply the SourceImageRequest described by
the Constitution, including source/session/request/cache semantics. F2 neither
requires nor chooses headers, retries, cache keys, decoding or downsampling.

An unknown node kind or chapter version makes the **entire chapter unsupported**;
do not return only known nodes, drop an image, or reorder around an unknown
node. Original durable content remains untouched. Explicit adapters may later
convert versions with tests. No parallel canonical `paragraphs[]`/`images[]`.
Legacy split arrays cannot establish original inline positions: preserve the
legacy payload for F6, and require explicit provenance/user-visible conversion
policy before presenting any synthesized ordering as a migrated reading copy.
F2 defines the model/codec, not chapter-body download persistence.

## 5. Persistence responsibilities and F2 records

| Category | Owner and contents | F2 boundary |
| --- | --- | --- |
| A. Structured durable state | LibraryRepository, Shelf/GroupRepository, ProgressRepository, migration coordinator | Source registry/mappings, source-aware library metadata/membership, manual groups/split decisions, progress metadata, schema/import receipts and safe deferred records |
| B. Small preferences | PreferencesRepository | Versioned Reader/app settings; dedicated allowlisted table in proposed SQLite database for transactional durability. Separate responsibility, same backend. No whole AppStore snapshot |
| C. User-owned/offline files | Future Offline/Export services | Preserve originals and transfer provenance only; actual offline bodies/images F6, export/import UI F7; no download/storage engine now |
| D. Cache | Future Source/Image cache adapters | Rebuildable covers, Explore/search results, HTTP/cache entries; excluded from durable repositories |
| E. Secrets / credentials | Future Source/Auth secure storage | F2 excludes credentials from database/preferences/staging/logs; F3 accepts secure-storage details |
| F. Ephemeral runtime state | Controllers/sessions | Search/Explore page state, loading/errors, active requests, selected runtime chapter, download tasks; memory only |

Minimum **logical records**, independent of final SQL table names:

| Record | Required durable meaning |
| --- | --- |
| SourceRegistration / IdentityMapping | Immutable source key, display name separate, available/unresolved state; versioned legacy aliases/ref mapping |
| LibraryEntry / BookMetadataSnapshot | Book ref and saved/default-shelf flag; metadata availability `known` or `stub`; optional title/author/tags/description/cover asset ref; retained legacy metadata for L2 fields not yet normalized. Preserve all valid legacy bookLibrary entries without making them saved. A missing referenced book is a stub, not a dropped membership. New transient search results do not enter this repository automatically |
| Shelf / ShelfMember | Opaque local shelf ID, name, shelf order; source-book refs in explicit member order. No title-based key. Default saved membership is a set; legacy Set iteration is not meaningful user order |
| ManualGroup / Membership / SplitOverride | Stable local group ID, optional display name, distinct book refs and split preference; split wins for presentation but does not erase preserved raw membership. Auto-title group rename remains legacy display metadata for F7 |
| ReadingProgressV1 | `kind:"readingProgress",version:1,bookRef,hasRead:bool`; optional `chapterRef`, `legacyLocator`, `lastReadAt`; at least one chapter locator if a last chapter is recorded. Store additional legacy per-chapter fractions separately; no page/paragraph anchor. Optional known-total/update hints remain snapshot metadata |
| ReaderPreferencesV1 | `kind:"readerPreferences",version:1`, all ten fields below; unresolved legacy field values kept separately, never silently rewritten |
| AppPreferencesV1 | `kind:"appPreferences",version:1,theme` (`system/light/dark`); optional preferredSourceId, selectedShelfId, accent token if supplied through a supported future input |
| MigrationRun / RecordReceipt / DeferredLegacyRecord | Versioned import/mapping identities, state, counts, nonsecret diagnostics, per-record outcomes and only allowlisted unresolved/deferred legacy fields |

Reader preference fields: `fontSize`, `lineSpacing`, `background`, `mode`,
`fontFamily`, `bold`, `marginLeft`, `marginRight`, `marginTop`, `marginBottom`.
Numeric fields are finite; fontSize >0; spacing/margins >=0. Defaults retain
legacy numeric values 22/8/35/35/72/24, bold false. Background tokens in legacy
index order 0–4 are `paperWhite/parchment/darkGray/black/eyeCare`.
Modes `仿真翻页`/`滚动` map to `pageCurl`/`scroll`; fonts `系统/宋体/楷体/圆体`
map to `system/songti/kaiti/yuanti`. Defaults: paperWhite, pageCurl, kaiti.
These preserve intent, not native font availability or a completed renderer.
F4/F5 own supported rendering and explicit fallback behavior. Invalid or unknown
legacy preference values get per-field conflicts with safe originals retained;
defaults may be presented as fallback but must not mark that field migrated.

If progress contains both a modern chapter ref and a legacy locator, both must
belong to its bookRef; a legacy fraction is not automatically attached to a
modern chapter without resolution evidence. Absent lastReadAt is unknown, not
the import time. App accent tokens map `浅紫/蓝/青绿/粉/橙/红` to
`purple/blue/teal/pink/orange/red`; a missing accent is not a verified migrated
default. A missing/invalid selected shelf falls back to default presentation
while its original selection remains a reported best-effort outcome.

Repositories must commit related state atomically, enforce ref integrity and
surface storage errors. Removing shelf membership must not cascade-delete book
progress, other memberships or offline assets. Database open/migration failure
must not recreate an empty database. F2.3 reviews the concrete schema v1,
constraints, migration snapshots and connection lifecycle before downstream
repositories; schema/data safety tests must pass before F2 exit.

## 6. Explicit legacy migration commitment

This predecessor is a real product. Approval adopts the following commitments,
not “where promised.” MUST MIGRATE means F2 must preserve every valid committed
field **present in a supplied frozen-format v1 backup** without live network
access. It does not assert access to another installed app's private container.
Missing assets and unresolved meaning must be reported explicitly. Full product
continuity includes the deferred obligations; F2 exit is not migration-release
approval. The inventory details each key/location and the acquisition gaps.

| Legacy asset | Classification | Delivery and preserved meaning |
| --- | --- | --- |
| Library, saved IDs, book metadata | **MUST MIGRATE** | F2: entries, default-shelf flags, retained metadata and stubs; never silently discard unknown-source books |
| Custom shelves/manual groups/renames/splits | **MUST MIGRATE** | F2: identity mappings, explicit order and user choices; F7 grouping presentation |
| Last chapter, chapter fractions, read flag/time | **MUST MIGRATE** | F2: lossless progress metadata/legacy locators; F3 identity resolution and F4 restore behavior |
| Reader preferences and app theme | **MUST MIGRATE** | F2 values/intent; F4/F5 apply Reader settings |
| Source association/aliases and update hints | **MUST MIGRATE** | F2 retain associations/conflicts; F3 live Source behavior |
| Offline catalog/body files | **DEFER TO LATER PHASE** | F6 acquisition, format conversion and integrity; preserve originals, including ambiguous read-through/download files |
| Offline/downloaded images | **DEFER TO LATER PHASE** | F6 transfer and association verification; no “complete” claim based only on chapter count |
| Cover/Explore/HTTP caches | **CACHE — SAFE TO REBUILD** | F3/F6/F7; absent cache never fails user-state import |
| Statistics and search history | **DEFER TO LATER PHASE** | F2 stores allowlisted payload once for preservation; F7 materializes without summing repeated totals. Recent-reading metadata above remains F2 |
| Accent setting / selected shelf / supplied catalog-only metadata | **BEST-EFFORT IMPORT** | Selection and explicitly supplied metadata in F2; separate accent acquisition F7. Missing optional evidence reported; no invented value claimed as migrated |
| Authentication/cookies/embedded credentials | **DO NOT MIGRATE** | F2 strips secret fields from accepted input before any owned persistence; F3 reauthentication/secure storage |
| Ephemeral state, old crash reports, KMP bridge as presumed iOS data | **DO NOT MIGRATE** | No state import; leave originals untouched |
| Already exported EPUB/TXT | **DO NOT MIGRATE** | No reconstruction of app state; leave user-owned files intact; future file import F7 |

### Import safety and input boundary

F2 required public import input is bytes of `lightnovelreader-backup`, version 1,
with its `state`. Also support the extracted AppStateSnapshot JSON bytes via an
explicit `legacyIosSnapshotV1` input type for fixtures/recovery; never auto-detect
a random JSON object as a backup. No scanning private containers, plist decoder,
zip extraction, networking, or file-picker UI is required in F2. Explicitly
supplied catalog metadata uses a separate optional recovery input with declared
source/book association; it cannot prove current catalog alignment by itself.

Import is non-destructive, versioned, idempotent, retryable and verifiable:

1. Read without modifying the input. Validate envelope/format/version and
   bounded input structure before writing. An unreadable/truncated JSON envelope
   fails without touching target data; a malformed individual record in a valid
   envelope must not discard its valid siblings. Duplicate envelope keys fail
   the envelope; duplicate keys inside an independently framed record fail that
   record, preserving other records.
2. Recursively allowlist known fields and validate their expected types before
   staging (including nested book/preference/deferred records); discard backup
   `wenku8Cookie`, defaults cookie fields and all unknown envelope/state fields.
   Record only omitted field names/counts, never their values. Never persist a
   whole original backup to the normal database, preferences, logs or fixtures.
   Original user file remains under the user's control. No new secret store in F2.
3. A caller supplies an opaque `datasetId` for the legacy library lineage (or
   receives a new one); it is stored, not inferred from filename, book title or
   device clock. The run key is `(datasetId, importerVersion, inputDigest)`, where
   inputDigest is SHA-256 of the original input bytes; retries reuse that run.
   Subsequent exports from that lineage use the existing datasetId. Bind local
   shelf/group mappings by `(datasetId, entity kind, exact legacy ID)`; allocate a local ID
   once, reuse it thereafter. Conflicting duplicate IDs in one input stay pending.
4. Plan independent record units with dependency order (sources/books before
   memberships/progress), using stubs/unresolved entries where necessary.
   Receipts key `(datasetId, importerVersion, entity kind, legacy key)` and retain
   accepted typed field values for semantic comparison. Exact repeats are no-ops;
   changed payload is a conflict/review item, not silent replacement of existing user edits.
   Initial import fills missing records/fields; preexisting values win until an
   explicit conflict resolution. Do not union changed ordered shelves implicitly
   or add aggregate statistics twice. Preserve both safe alternatives.
5. Commit each valid record unit and its receipt in one transaction; a run can
   resume after interruption. State transitions: `pending -> applying -> verifying
   -> complete`, with `partial` for record conflicts/errors and `failed` for run
   failure. On restart, reverify committed receipts and retry unfinished units;
   never replay destructive clears. A successful unit cannot be lost because
   another unit is corrupt. Existing data deletion is never a recovery strategy.
6. Read back identities, memberships/order, progress values and settings, check
   expected counts and outcomes, and only then mark committed coverage complete.
   Every input unit has an outcome: imported/unchanged, preserved-unresolved,
   deferred-preserved, intentionally excluded, or failed/conflict. Failed and
   conflict outcomes block complete status for committed data. A safely retained
   unresolved locator verifies preservation, **not** successful Reader restoration.
   Report absent offline files/accent as unavailable, not imported. Completion of
   F2 committed coverage never claims completion of deferred asset migration.

Only recognized nonsecret legacy fields may enter unresolved/deferred storage.
No arbitrary raw payload escape hatch. Unknown formats remain in the original
input for later handling. Tests set safe input-size/depth limits in the importer
and prove rejection is non-destructive; this is resource safety, not an F11
performance target. No migration failure may delete or overwrite legacy data.

## 7. iOS legacy-container feasibility

Legacy bundle ID: `com.komorebiiluv.LightNovelReader`.
Flutter bundle ID: `com.komorebiiluvu.lightNovelReader`.
No shared App Group configuration was found; no signed profile/archive was
verified. **Current configuration cannot directly read the legacy private
sandbox.** See the inventory's file evidence and
[Apple sandbox rules](https://support.apple.com/guide/security/security-of-runtime-process-sec15bfe098e/web).

Proposed route: legacy app exports its existing v1 JSON, user transfers it,
Flutter imports it. F2 supplies a platform-neutral import service; F7 supplies
the user-facing transfer flow. The existing backup omits offline files and
accent settings. An in-place update requires verified continuity of the actual
app's bundle/signing/distribution identity and access to old UserDefaults Data;
it is conditional and not promised. A future transfer mechanism requires its
own feasibility evidence and approval. F6/F7 must resolve offline acquisition
before promising replacement-product continuity; F11 verifies real upgrades.
Neither installing a shared_preferences package nor changing a bundle ID string
alone grants access. No native migration shim is authorized.

## 8. Proposed stack and acceptance gate

[ADR 0003](adr/0003-f2-persistence-stack.md) recommends Drift/SQLite NativeDatabase,
with separate database-backed preference ownership and injected storage roots.
Current package metadata supports the SDK/target prerequisites; actual locked
resolution, generation and platform runtime checks remain F2 implementation work.

**Blocking human decisions before any F2 production code:** accept this contract
and ADR 0003, including opaque legacy-ID preservation, migration classifications,
file-import delivery boundary and database-backed durable settings. Revision of
a proposal is allowed; it does not silently become accepted when committed.

## 9. Required tests

| Area | Required observable assertions before F2 exit |
| --- | --- |
| Identity | Same remote ID in two Sources does not collide; same chapter ID in two books does not collide; source rename changes no ref; type/equality/hash and delimiter/Unicode/leading-zero cases; serialize/deserialize exact values; duplicate registry IDs rejected |
| Serialization | All versioned F2 record codecs round-trip; wrong types, duplicate keys, unknown kind/version/field fail explicitly; newer durable payload/database remains untouched; old optional fields have documented defaults |
| Content | Text/Text/Image/Text/Image/Text retains exact order and data; repeated images/empty text/empty chapter round-trip; unknown middle node rejects whole chapter; split-array legacy content cannot be marked as proven ordered content |
| Database | Clean schema-v1 creation; constraints, transactions, CRUD and close/reopen with temporary files; verify schema against snapshot; data-preserving migration and rollback on injected failure; newer-version refusal |
| Migration infrastructure | A test-only older schema fixture exercises the migration runner if no earlier production SQL version exists; do not label fresh creation as a historical upgrade. Receipt/data atomicity, interruption before/after commit, reopen/resume, repeated import idempotency, conflict against existing user edit |
| Legacy library/groups | Fixtures for all committed snapshot fields, backup v1 and explicit snapshot input; missing optional fields, unresolved/renamed sources, duplicate IDs, orphan memberships/stubs, ordered shelves, manual group names and split flags; no network required |
| Legacy progress/preferences | Zero-based index is not cid; offset key parsing, no-cid locator, conflicting index evidence, exact fractions, read-at-chapter-zero flag, Swift Date epoch, all ten Reader fields/raw enums and app theme; unknown preference isolated without discarding siblings |
| Corruption | Malformed record among valid records imports valid siblings; malformed whole JSON writes nothing; failed verification leaves partial state/retry available; originals byte-identical; no empty reset fallback |
| Security/scope | Sentinel cookie/credential fields never reach DB/preferences/staging/logs; no original full backup retention; unknown input fields excluded; missing caches never block valid state migration; offline assets not auto-deleted or reported complete |
| Isolation | Every data/migration test injects in-memory connection or fresh temporary root; forbidden access to real app/user/legacy storage; all connections/files closed before cleanup |

Required platform validation after dependencies are approved: format/analyze/tests
and three platform builds at the tested revision; actual F2 storage smoke on
Windows desktop, Android emulator/device and iOS simulator/device on macOS.
The smoke exercises packaged SQLite loading, app-owned temporary root, create,
write, close/reopen, transactional import/readback, and injected failure recovery.
An unsigned iOS build alone is insufficient evidence of persistence execution.
CI/another host may supply missing tools. F11 owns broader signed-upgrade,
real-device/performance validation, not F2 Reader/navigation behavior.

## 10. Independently reviewable implementation slices (not started)

| Slice | Deliverable and local acceptance boundary |
| --- | --- |
| F2.1 | Pure Dart IDs/refs/mapping value types, versioned serialization rules; collision/equality/round-trip tests |
| F2.2 | ChapterContent/TextNode/ImageNode codec; exact ordering, empty and unsupported-input tests |
| F2.3 | Approved dependencies, storage-root/connection infrastructure, concrete schema v1 and snapshots; clean creation, transaction/migration-runner/rollback/newer-version tests and three-platform package smoke |
| F2.4 | Library/source mapping, custom shelves/manual groups repositories; constraints, order, stubs and deletion-boundary tests |
| F2.5 | Progress metadata/legacy locators and preferences repositories; per-field codec, durable reopen and atomic-setting tests; no Reader algorithm |
| F2.6 | Import planning/receipts/recovery and sanitized frozen-format fixtures; corrupt siblings, idempotency and failure injection |
| F2.7 | Committed legacy import conversions plus deferred-field preservation; offline-free end-to-end fixture import/readback and platform smoke; produce F2 exit evidence for human review |

Each slice is a separate reviewable change with appropriate tests. Any schema
refinement preserves earlier accepted semantics and updates snapshots/migration
tests; once a schema has shipped, upgrades are mandatory. No single F2 mega patch.

## 11. F2 exit model

| Governance item | Required evidence |
| --- | --- |
| Deliverables | Accepted entry contract/ADR; Dart value/record codecs, repositories, schema v1 and version history, migration services, sanitized fixtures and evidence record |
| Acceptance Criteria | Source-aware opaque identity, ordered content and serialization accepted; committed legacy fields survive offline import and reopen; original/target data protected on failure; no known data-loss blocker; no Source/Reader/native business implementation introduced |
| Required Automated Tests | Section 9 passes, including migration preservation/recovery, negative serialization cases and secret exclusion; exact commands/results recorded |
| Required Platform Validation | Section 9 builds and actual storage smoke on iOS/Android/Windows; tested commit, SDK, package lock, OS/device/runner recorded |
| Evidence / Artifacts | CI job URLs or identifiable run evidence, generated schema snapshot/diff, fixture expected/actual counts and outcomes, temporary-root logs, hashes where meaningful; no secrets or user backup attached |
| Known Exceptions | Named owner, scope, reason and follow-up phase; unresolved future-phase contracts listed below. Missing required F2 migration/platform evidence is pending, not PASS |
| Exit Approval | Explicit human review after evidence; no automatic advance to F3. Proposed entry approval does not equal exit approval |

## 12. Deferred decisions and owners

| Owner phase | Deferred contract / obligation |
| --- | --- |
| F3 | Source capabilities, transport/session/auth/cookies, secure credentials, live stable catalog IDs and evidence-based legacy locator reconciliation |
| F4 | Reader logical position/anchor, interpreting legacy fraction, navigation/restoration, font/layout fallback and preference application |
| F5 | Cross-platform page-curl rendering and visual acceptance |
| F6 | SourceImageRequest resolution, image cache/retry/downsampling, offline transfer/body/image conversion and completeness; explicit policy for unavailable historical inline order |
| F7 | User export/import/picker/transfer flow, grouping presentation, statistics/search-history materialization, accent acquisition, export completeness |
| F9 | Plugin manifest/Source ownership binding, host API/runtime/security; immutable existing Source IDs remain protected |
| F11 / pre-release matrix | Quantified performance, real installed-app migration/recovery, signing/distribution identity, supported OS versions and complete predecessor continuity verification |

These are not reasons to implement future phases in F2. Failure to deliver
committed preservation or the F2 platform tests is an F2 exit blocker; a missing
future Reader/image/plugin specification by itself is not. Human entry approval
is still required. **Stop after publishing this proposal.**
