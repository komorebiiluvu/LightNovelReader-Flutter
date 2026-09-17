# F2.6 Migration Framework Baseline

Status: **IMPLEMENTED — REVIEW PENDING**

Starting SHA: `d7e0279121d1aa342fe6cc95a8f386e0daec208b`

This baseline records the F2.6 implementation slice authorized on 2026-09-17.
The single implementation commit is `feat: add legacy migration framework`.
F2.1 and F2.2 remain implemented/accepted; F2.3, F2.4 and F2.5 remain exit
approved. F2.6 is not self-approved by this record.

## Scope and boundary

F2.6 implements the platform-neutral migration engine boundary: raw bytes,
duplicate-aware bounded parsing, explicit legacy input selection, digest and
run identity, deterministic sanitized planning, receipts/outcomes, safe typed
evidence, per-unit transactions, retry/resume, conflict preservation and
verification. It does not perform the concrete legacy product conversion.

F2.7 remains responsible for converting books/library, saved IDs, shelves,
manual groups, split flags, progress, reader preferences, app preferences,
statistics, search history and catalog recovery into product repositories.
F2.6 does not add Source/network/auth behavior, Reader behavior, images/offline
storage, product UI, plugin runtime, or release-readiness claims.

## Frozen supported inputs

The frozen legacy reference is the read-only repository
`C:\Projects\LightNovelReader-Legacy` at
`d90d4d090c85a0a9c374684696c34befe12636d1`.

The exact portable backup v1 envelope verified in `Sources/Store/AppStore.swift`
is a Codable object with these fields:

```text
format: String                 required, exactly "lightnovelreader-backup"
version: Int                   required, exactly 1
exportedAt: String             required
wenku8Cookie: String?          optional and excluded
state: AppStateSnapshot        required
```

`legacyBackupV1` validates that envelope and frames its `state`. The second
supported type, `legacyIosSnapshotV1`, is explicitly selected by the caller and
accepts the extracted `AppStateSnapshot` object without a backup wrapper. It
does not auto-detect arbitrary JSON. There is no plist parser, private-container
scan, zip extraction, file picker, network access, or native migration shim.

The input API copies caller bytes. It never rewrites the source, stores the
whole input, or infers a dataset ID from a path, filename, title, time, or
random value. Dataset registration is explicit.

## Raw parser and safety limits

`RawJsonParser` is a migration-only pure Dart parser. It strictly decodes UTF-8,
retains object/array/string/integer/number/boolean/null types, validates JSON
escapes including surrogate pairs, rejects lone surrogates, malformed numbers,
truncated values, multiple roots and trailing bytes, and does not call
`jsonDecode` before duplicate handling.

The normal parser mode rejects duplicate keys. Planning uses a preserving mode
that records duplicate fields without collapsing them; envelope and state
objects then fail as a whole when duplicated, while each independently framed
record can become a record-local failed unit. This is the explicit framing
boundary used for `state.bookLibrary[]` and `state.shelves[]`; sibling records
remain eligible.

Default injectable limits are:

| Resource | Limit |
| --- | ---: |
| Input bytes | 16 MiB |
| Nesting depth | 64 |
| Fields per object | 4,096 |
| Elements per array | 10,000 |
| String length | 1 MiB |
| Parsed nodes | 100,000 |
| Planned units | 10,000 |

Resource-limit failures are typed and content-free. They perform no writes and
do not log input content.

## Identity and versions

The exact original bytes are hashed with the existing `crypto` package's
SHA-256 implementation. The digest is lowercase hexadecimal, 64 characters,
and is not a normalized or re-encoded JSON digest. Initial `importerVersion`
and `mappingVersion` are explicit independent values, both `1`.

The canonical run key is `(datasetId, importerVersion, inputDigest)`. Repeating
the same bytes under the same supplied dataset and importer reuses the run;
changed bytes, dataset, or importer version create a distinct run. No random
run UUID is used.

## Planning and sanitization

The flow is:

```text
raw bytes -> duplicate-aware bounded parser -> explicit envelope validation
-> known record framing -> recursive allowlist -> typed MigrationUnit
-> per-unit application -> receipt/outcome/evidence -> verification
```

`MigrationUnit` carries only an entity kind, deterministic legacy key, typed
allowlisted scalar evidence and omission metadata. It never carries a raw JSON
object into application. The initial framework has synthetic-capable planners
for book, shelf, source, reader-preference and app-preference evidence; it does
not claim those as completed F2.7 product conversions.

Unknown fields are omitted and may increment the safe omission count. Suspicious
unknown names may produce the stable `secret-excluded` diagnostic, but neither
unknown values nor arbitrary nested objects are persisted. Known cookie fields,
cookie-like fields, credentials and token-like fields are excluded recursively.
No secret values enter tables, diagnostics, errors, logs or fixtures.

## Run state machine and transactions

The only run states are `pending`, `applying`, `verifying`, `complete`,
`partial` and `failed`. Creation is `new -> pending`; legal transitions are:

```text
pending -> applying
applying -> verifying | partial | failed
verifying -> complete | partial | failed
partial -> applying
failed -> applying
```

There are no arbitrary backward transitions and a partial or failed run is not
silently completed. Run creation/reuse, each unit application, state changes and
verification are transactional. A unit transaction includes the future
product-effect handler, receipt, accepted/candidate safe evidence and outcome.
An injected handler failure rolls back the product effect and evidence; the
coordinator records a safe failed outcome so other units can proceed.

## Receipts, outcomes and evidence

Receipt identity is exactly `(datasetId, importerVersion, entityKind, legacyKey)`
and intentionally excludes `inputDigest`. Receipt lists and outcome/evidence
lists use stable composite ordering. Outcomes are limited to:

```text
imported, unchanged, preserved-unresolved, deferred-preserved,
intentionally-excluded, failed, conflict
```

Diagnostics are limited to the schema enum:

```text
invalid-field, unknown-field, unsupported, missing-evidence,
conflicting-evidence, verification-failed, secret-excluded
```

`SafeLegacyValue` has exactly one typed slot: string, integer, number, boolean
or null. Evidence uses only the existing schema field allowlist and one of
`accepted-baseline`, `unresolved-evidence` or `conflict-candidate`. Strings are
stored exactly, without trimming, Unicode normalization or enum rewriting.

The first accepted evidence becomes the immutable accepted baseline. An exact
semantic repeat is `unchanged`. Changed safe evidence never overwrites the
baseline; it is stored as a conflict candidate and receives a `conflict`
outcome. Candidate IDs are deterministic SHA-256 identifiers over an ordered
field/map-key/ordinal/type/typed-value encoding, calculated after secret
exclusion and without JSON map stringification.

## Recovery and verification

Retries reuse the same run and existing receipts. A receipt without an accepted
baseline does not make a failed unit complete; the unit can be retried. Valid
sibling units are not replayed destructively. Verification counts outcomes for
the planned run: all expected units with acceptable outcomes produce
`complete`; failed or conflict coverage produces `partial`; incomplete coverage
cannot produce `complete`. Verification failures use a safe typed failure and
never claim completion.

The focused tests include a temporary file-backed database that closes and
reopens before resuming the same run. No production Application Support root,
real backup, UserDefaults, app container, cookie, or personal data is used.

## Fixtures, dependency and schema

Sanitized synthetic fixtures are committed at:

- `test/fixtures/f2_6_synthetic_backup_v1.json`
- `test/fixtures/f2_6_synthetic_snapshot_v1.json`

`crypto 3.0.7` was promoted from the already locked transitive dependency to a
direct dependency solely for SHA-256; no broad dependency upgrade was made.
`lib/src/data/persistence/schema.drift`, generated Drift code, schema snapshots,
schema version, tables, indexes and migration history are unchanged.

## Validation and limitations

Focused F2.6 validation covers scalar/parser cases, malformed input and limits,
explicit envelope selection, envelope-fatal zero-write behavior, duplicate
record isolation, run identity, atomic handler rollback, baseline conflicts,
secret exclusion, byte immutability, state transitions and temporary-file
reopen/resume. The local validation results are:

| Command | Result |
| --- | --- |
| `flutter pub get --enforce-lockfile` | PASS after the controlled direct-dependency classification change |
| `dart format .` | PASS |
| `dart format --output=none --set-exit-if-changed .` | PASS |
| `flutter analyze --no-pub` | PASS, no issues |
| `flutter test --no-pub` | PASS, 168 tests |
| `./tool/verify_generated.ps1` | PASS; generated/schema snapshots unchanged |
| `git diff --check` | PASS |

The focused F2.6 file contains 15 tests. Remote platform CI is reported only
after the implementation commit is pushed and actually observed.

This slice proves migration infrastructure and safe persistence mechanics only.
It does not prove a complete legacy import, product-state conversion, Reader or
Source behavior, offline continuity, UI flow, or release readiness.

F2.6: **IMPLEMENTED — REVIEW PENDING**

F2.7: **NOT STARTED / NOT AUTHORIZED**
