# F2.2 — Ordered chapter content implementation evidence

Starting commit: `c2d8a802c1a21aa7cb60e804fb013870aed18bae`
Status: **IMPLEMENTED** under the accepted F2 entry authorization.

F2.2 adds only pure Dart chapter content values and their v1 codecs. It does not
advance F2 exit and does not authorize F2.3 or any persistence implementation.

## Delivered model

- `ChapterContent` contains a `SourceChapterRef`, optional exact title, and one
  defensive, unmodifiable ordered `List<ContentNode>`.
- v1 has exactly `TextNode(text)` and `ImageNode(assetRef, altText?)`.
- Text is retained exactly, including empty strings, whitespace, line breaks,
  Unicode, and adjacent repeated nodes. No trim, normalization, merge, split,
  deduplication, or reordering occurs.
- An image carries only `SourceAssetRef` and optional alt text. Its source and
  book must equal the containing chapter reference; URLs, request metadata,
  local paths, cache data and decoding policy remain outside this model.
- Empty, text-only, image-only, and mixed chapters are valid successful content.
  Content order is equality- and hash-significant; list position is not identity.

## Serialization and failures

The codec implements the accepted `kind`/integer `version: 1` chapter envelope,
strict top-level and node field sets, nested F2.1 references, omission of absent
optional fields, and typed safe failures for missing fields, wrong types, wrong
kinds, unsupported versions and unknown fields. An unknown node rejects the
entire chapter; no partial content is returned.

As recorded in [F2.1 evidence](F2_1_IDENTITY_BASELINE.md), normal Dart
`jsonDecode` collapses duplicate object keys before a `Map` reaches these
codecs. F2.2 does not add a raw duplicate-key parser. F2.6's importer must
reject duplicates before ordinary object decoding.

The legacy iOS representation stored paragraphs and images separately. That is
unordered evidence and cannot prove original inline positions. F2.2 performs
no synthetic “all text then all images” conversion; F6 owns the later historical
content/image migration policy.

## Verification and boundary

The focused content suite contains 15 tests covering round trips, ordering,
text preservation, repeated assets, source/book mismatch, strict validation,
nested opaque IDs, defensive list copying, and the duplicate-key limitation.
The implementation imports only Dart/domain code. No dependency, `pubspec`,
database, platform runner, Source, Reader, networking, image cache or offline
storage files changed. The work stops before F2.3.
