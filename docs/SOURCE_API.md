# Source API

## 1. Principle

Core does not know websites.

A Source converts a remote content provider into normalized domain models.

## 2. Identity

F2 froze distinct immutable opaque value types: `SourceId`, `BookId`,
`VolumeId`, `ChapterId`, and `AssetId`; these are not String typedefs.
Use the implemented domain types and exact serialization rules in
[F2 Entry Contract sections 2–4](F2_ENTRY_CONTRACT.md).

References include the full source/book scope: `SourceBookRef(sourceId, bookId)`,
`SourceVolumeRef(sourceId, bookId, volumeId)`,
`SourceChapterRef(sourceId, bookId, chapterId)`, and
`SourceAssetRef(sourceId, bookId, assetId)`. Preserve exact opaque values,
including legacy `wk8-<aid>` BookIds. Chapter ordinal/index and volume membership
are ordering metadata, never modern chapter identity.

## 3. Descriptor and capabilities

```dart
class SourceDescriptor {
  final SourceId id;
  final String name;
  final Set<SourceCapability> capabilities;
}
```

Capabilities may include:
- search
- explore
- bookDetail
- volumes
- chapters
- chapterContent
- images
- authentication
- cookies
- filters
- updates

UI derives availability from capabilities.

## 4. Contract sketch

```dart
abstract interface class BookSource {
  SourceDescriptor get descriptor;

  Future<SearchResult> search(
    SearchQuery query,
    CancellationToken cancellation,
  );

  Future<ExploreResult> explore(
    ExploreRequest request,
    CancellationToken cancellation,
  );

  Future<SourceBook> getBook(
    BookId id,
    CancellationToken cancellation,
  );

  Future<List<SourceVolume>> getVolumes(
    BookId id,
    CancellationToken cancellation,
  );

  Future<ChapterContent> getChapterContent(
    SourceChapterRef chapter,
    CancellationToken cancellation,
  );
}
```

Methods may be optional/capability-gated rather than returning meaningless empty defaults.

## 5. Models

Separate:
- remote source model
- local library entity
- reading progress
- download state

Do not repeat the legacy pattern where one Book model mixes all concerns.

## 6. Content

Canonical output:

```dart
class ChapterContent {
  final SourceChapterRef chapterRef;
  final List<ContentNode> nodes;
}
```

Required nodes:
- `TextNode`
- `ImageNode`

F2 `ImageNode` carries a `SourceAssetRef` and optional `altText`, not a
`SourceImageRequest`, URL, headers, cookies or local path. Its source/book scope
matches the chapter. The separate request-resolution/image contract belongs to
F3/F6 and does not change node identity. F2 codecs preserve exact node order,
text, empty text and repeated images; unknown node kinds reject the entire
chapter. Successfully obtained empty content is distinct from a parse failure.

## 7. Transport

Source logic must not directly scatter HTTP library calls.

Use `SourceTransport`.

Request supports:
- method
- URL
- headers
- body
- cookie/session scope
- redirect policy
- timeout
- sourceId
- safe diagnostic tags

## 8. Authentication/session

Each source has explicit session ownership.

Do not rely on accidental global cookie jars.

Authentication state is source-scoped.

Secrets are stored via secure storage and are never logged.

## 9. Parsing

Separate transport from parser.

Parser should be fixture-testable from bytes/HTML.

Wenku8-specific encoding/DOM rules stay inside the Wenku8 source.

## 10. Errors

Source returns structured failures:
- network
- authentication
- rateLimit
- notFound
- parse
- incompatibleResponse
- cancelled
- unsupportedCapability

Raw library exceptions are mapped at the boundary.

## 11. Cancellation

Cancellation is part of the API.

Leaving a screen, starting a newer search, changing chapter, or disabling a plugin may obsolete work.

Old results must not overwrite new state.

## 12. SourceRegistry

Registry resolves `SourceId` to an implementation.

Implementations:
- built-in Dart source
- plugin source adapter

No UI branch on concrete source type.

## 13. First reference sources

A:
- Wenku8, migrated from legacy behavior/fixtures

B:
- a structurally different real source

Also include fixtures proving:
- ordered text/image
- image-only content

The purpose is contract validation, not source count.
