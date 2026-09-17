# F2.4 — Library / Shelves / Manual Groups Persistence Repositories

Status: **IMPLEMENTED — REVIEW PENDING**.
F2.4 Exit Approval: **PENDING**.
F2.5: **NOT STARTED**.

## Entry and scope

Starting SHA: `7ea8d213aa1135cb2cd213c529bca09aaa4c4280`.
At entry, `main` and fetched `origin/main` matched this SHA and the worktree
was clean. F2.3 was EXIT APPROVED; the human owner's F2.4 task authorizes this
slice only. Frozen legacy reference remains
`d90d4d090c85a0a9c374684696c34befe12636d1`; no legacy data was accessed or imported.

Only domain repository contracts/models, their Drift adapters, repository tests,
and factual governance evidence are added. F2.3 schema v1, constraints, indexes,
generated artifacts, version and migration strategy are unchanged. Dependencies,
lockfile, platform configuration, workflow, UI, Source and Reader are unchanged.
This does not establish full F2 completion or application release readiness.

## Domain and contracts

`lib/src/domain/library/` defines `ShelfId` and `ManualGroupId` using the existing
opaque ID validation/equality rules (exact Unicode, no trimming, no NUL, no
unpaired surrogates). Callers supply IDs; there is no generator dependency.

Immutable records are `LibraryEntry`, `MetadataState`, `BookMetadataSnapshot`,
`Shelf`, `ShelfMember`, `ManualGroup`, `ManualGroupMember`, and `SplitOverride`.
Tags are defensively copied into an unmodifiable ordered list. Cover references
must match their owning source/book and are checked before any metadata write.

`LibraryRepository`, `ShelfRepository`, and `ManualGroupRepository` are pure Dart
contracts. They expose no Drift rows, SQL, executor, platform or SQLite types.
Each implementation under `data/persistence/repositories/` receives an
`AppDatabase` through its constructor. Its owner remains responsible for closing
that database. Repository instances have no authoritative in-memory cache.

## Library semantics

- `get` returns null when absent; `list` and other reads never persist transient
  objects. Writes require a registered Source; none create a Source registration.
- `ensureStub` creates an unsaved stub only when missing. Repeating it preserves
  known metadata, tags and saved status.
- `saveMetadata` creates a known entry if missing, or fully replaces normalized
  metadata and tags while preserving saved. Omitted optional fields clear prior
  metadata values. Tags retain duplicates, whitespace and exact order.
- `setSaved` requires an existing entry and changes only its saved flag.
  Unsave never deletes books, metadata, tags, memberships, progress or overrides.
- No book-delete/cascade API exists. `legacy_book_metadata` remains untouched
  migration compatibility state, not normal domain metadata.

## Shelves

Create takes a caller-provided ID, display name and nonnegative ordinal.
Duplicate IDs and duplicate memberships are typed conflicts. Members must
already exist in the library; later import work must explicitly ensure stubs.
One book may belong to multiple shelves.

Adding appends after the last ordinal. Removal leaves remaining ordinals intact;
replacement/reorder assigns contiguous ordinals beginning at zero. Reorder
requires an exact permutation, while replacement may add/remove existing books.
Duplicate replacement inputs are invalid. Shelf reordering similarly requires
all existing shelf IDs. Shelf names do not determine identity.

Member replacement uses transactional delete/reinsert to avoid intermediate
member-ordinal UNIQUE violations. Shelf ordinals have no UNIQUE constraint in
the approved schema, so shelf reorder safely updates them in one transaction.
Deletion removes only that shelf's members and shelf. External references from
app preferences or existing legacy mappings produce `invalidReference` and
preserve everything. F2.4 does not rewrite those references to allow deletion.

## Manual groups and split overrides

Groups relate complete source-aware identities without merging them. Names are
optional display data. Duplicate group IDs/memberships are typed conflicts.
Replacement accepts a duplicate-free set of existing library refs. Removing an
absent membership is idempotent if its owner exists. Deletion removes only the
group and its members, and rejects existing legacy mapping references without
rewriting compatibility state. No group/member ordinal is invented.

Split overrides require a library entry. Stored `true`, stored `false`, and
absent (`getSplitOverride` returns null) remain distinct. Clear physically removes
only the override and is idempotent. Changing or clearing it never removes raw
group membership. F7 owns the later “split wins” presentation behavior.

## Determinism, transactions and failures

Collection order is explicit SQL order: library by binary source ID then book
ID; shelves by ordinal then binary shelf ID; shelf members by ordinal; groups
by binary group ID; group members by binary source ID then book ID; tags by
ordinal. Identity ordering is not claimed as user order.

Every repository operation uses a database transaction, including multi-query
reads so metadata and tags share a consistent snapshot. Metadata/tag replacement,
shelf/member reorders, shelf/member deletion, group member replacement, and
group deletion are atomic. Input order/set lists are copied at invocation.
SQLite remains the durable authority; concurrent operations use Drift/SQLite
transaction serialization without a second mutable store.

`RepositoryFailure` extends the existing safe `AppFailure` philosophy with
`notFound`, `conflict`, `invalidReference`, `invalidInput`, and `storage` reasons.
Missing singular reads return null; missing collection owners/mutation targets
fail as notFound. Missing membership references fail as invalidReference.
SQLite exceptions are converted to safe typed failures with stable codes and
fixed messages; raw exceptions, SQL, paths and arbitrary exception text never
cross the repository boundary. External RESTRICT references are checked inside
the transaction because SQLite may report these as a generic trigger constraint.
No logging of rejected values is introduced.

## Tests and validation

The focused repository suite has **29 tests**, all using isolated
`NativeDatabase.memory()` connections with teardown closure. It covers opaque
IDs, defensive tags, source-aware identity, source registration rejection,
metadata round-trips, stub idempotency, saved-state preservation, deterministic
ordering, member swaps, duplicate/missing references, set replacement, split
true/false/absence, concurrent appends, shared database authority, and deletion
boundaries including a directly seeded progress record.

Test-only temporary SQLite triggers inject failures after metadata changes,
after member deletion/partial reinsertion, during shelf reorder, and during
shelf/group deletion. Assertions verify complete rollback. Other tests seed
external FK references to prove protected deletion and safe errors. No importer,
progress repository, network or real user storage is used.

Local validation on 2026-09-17 (Flutter 3.47.4 / Dart 3.13.3):

- `flutter pub get --enforce-lockfile`: PASS; manifests/lockfile unchanged.
- `dart format --output=none --set-exit-if-changed .`: PASS, no changes.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub`: PASS, **130 tests** (29 new repository tests).
- `./tool/verify_generated.ps1`: PASS; generated code and schema snapshots
  reproduce the approved F2.3 outputs with no diff.
- `git diff --check`: PASS; changed-file review is limited to F2.4 scope.

Push CI remains **PENDING** until a run for the implementation commit is
observed. Local platform rebuilds
are not required for this slice because schema, dependencies and platform
configuration are unchanged; existing CI provides cross-platform regression.

## Limitations and approval

Queries currently favor simple per-entry tag reads over batching; no pagination,
watch API, product UI or performance target is claimed. Referenced shelf/group
deletion requires future owning code to resolve references explicitly.
No source registration service, repositories for progress/preferences,
migration/import execution, Reader, Source networking, images/downloads or
plugin runtime is implemented here. F2.4 awaits human review; F2.5 is not started.
