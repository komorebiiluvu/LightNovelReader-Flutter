# F2.1 — Identity implementation evidence

Status: **IMPLEMENTED** under the accepted F2 entry authorization (2026-09-16).

F2.1 adds only framework-independent Dart value objects and tests. The entry
contract and persistence ADR remain the governing documents; this slice does
not accept F2 as a whole and does not authorize F2.2 or later work.

## Delivered contract

- `SourceId`, `BookId`, `VolumeId`, `ChapterId`, and `AssetId` are immutable,
  distinct opaque Unicode-scalar string types. Values are preserved exactly;
  empty strings, NUL and unpaired UTF-16 surrogates fail with safe typed
  `IdentityFailure` values.
- `SourceBookRef`, `SourceVolumeRef`, `SourceChapterRef`, and `SourceAssetRef`
  use complete source-aware tuple identity. Titles, names, order, URLs and
  other metadata are not identity.
- Refs implement strict v1 JSON envelopes and a reversible external-key codec
  using independently encoded unpadded UTF-8 base64url components.
- `LegacyChapterLocatorV1` stores zero-based chapter index and optional legacy
  evidence without resolving a modern chapter or Reader position. Legacy
  `wk8-123` remains exactly that opaque `BookId`.
- `LegacySourceMapping` represents raw candidates and unresolved/resolved/
  conflict status; it performs no source lookup or migration execution.

## Duplicate JSON keys

The shared codec validates a decoded `Map<String, Object?>`. Dart's standard
`jsonDecode` has already collapsed duplicate object keys (the last value wins),
so this layer cannot detect duplicates after decoding. A focused test records
that actual behavior. F2.6's legacy/import boundary MUST use a duplicate-aware
syntax pass and reject duplicates before invoking these value codecs. No claim
of strict duplicate-key rejection is made for F2.1's public `fromJson(Object?)`
entry points.

## Verification

The focused identity/legacy suite contains 59 tests and exercises exact-value
preservation, namespace and tuple collision boundaries, malformed envelopes,
future fields/versions, key reversibility, Unicode and delimiter handling,
legacy evidence and safe diagnostics. Tests use the existing Flutter test
runner only as a Dart unit harness; they access no storage, database, network,
platform API or real user path.

`flutter analyze`, `flutter test`, `dart format --set-exit-if-changed .`, and
`git diff --check` are required gates for this commit. No runtime dependency,
`pubspec`, platform runner, database schema, migration executor, ContentNode,
Source, Reader, or download implementation is part of F2.1.
