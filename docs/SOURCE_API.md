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
  final SourceId sourceId;
  final String displayName;
  final Set<SourceCapability> capabilities;
}
```

Capabilities may include:
- search
- explore
- bookDetail
- catalog
- chapterContent
- images
- authentication
- cookies
- filters
- updates

`catalog` is one capability. It means that the Source can return an ordered
chapter catalog and may additionally provide volume/grouping information. It is
not the intersection of separate `volumes` and `chapters` capabilities.

A Source with chapters but no provider volume structure still advertises
`catalog` and returns a flat ordered chapter sequence. Grouping or presentation
labels that have no stable provider VolumeId are optional non-identity metadata;
they must not be represented as a fabricated `SourceVolumeRef`. A
`SourceVolumeRef` is emitted only for a verified provider volume identity or an
approved durable surrogate mapping. Chapter identity remains a verified opaque
`ChapterId`; ordinal/index and display order are ordering metadata only.

`cookies` is an infrastructure capability. It means that the Source may issue
or require source-scoped HTTP cookies for anonymous or authenticated requests;
it does not grant UI or callers access to cookie values, imply authentication,
or authorize plaintext persistence. `authentication` separately means that the
Source exposes an explicit credential/session operation. `updates` means that an
explicit refresh can return update hints in normalized metadata or catalog
results; it does not promise a scheduler, push notifications, or a background
update service. `images` means content may reference scoped assets; image
retrieval belongs to the later image phase.

UI derives operation availability from capabilities. Capabilities never change
the identity tuples or make an unsupported operation look like an empty success.

## 4. Contract sketch

```dart
abstract interface class BookSource {
  SourceDescriptor get descriptor;

  Future<SourcePage<SourceBookSummary>> search(
    SearchQuery query,
    SourceOperationContext context,
  );

  Future<ExploreResult> explore(
    ExploreRequest request,
    SourceOperationContext context,
  );

  Future<SourceBook> getBook(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<SourceCatalog> getCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<ChapterContent> getChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  );
}
```

Methods may be optional/capability-gated rather than returning meaningless empty
defaults. Every returned SourceBook, catalog entry, chapter ref and content
value must be owned by the Source instance's descriptor ID. The catalog method
is the source-aware contract for both flat and volume-grouped chapter listings;
it does not require a SourceVolumeRef when the provider has no stable volume ID.

The F3.1 dependency-free API uses `SourceOperationContext` for operation kind,
opaque request identity, session-generation binding and `SourceCancellation`.
Authentication is exposed separately through `SourceAuthenticator`; it is not a
credential method on `BookSource`.

Paged results use immutable items and an optional opaque continuation. A
continuation is bound to the Source, operation, query/filter identity and session
generation; failed or cancelled requests do not advance it. Stable-ref
deduplication preserves first-seen order, while malformed page metadata cannot
turn an error into exhaustion or move a cursor backward.

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
- approved target URL and host/scheme policy
- headers
- body
- cookie/session scope
- redirect policy
- timeout
- bounded response size and retry policy
- cancellation
- sourceId
- safe diagnostic tags

Transport owns request execution and maps library exceptions to the Source error
contract. Redirect hops are revalidated; credentials and cookies are never
forwarded blindly to a different host or downgraded scheme. Parsers receive
bounded bytes or decoded text and do not perform networking or persistence.

## 8. Authentication/session

Each source has explicit session ownership.

Do not rely on accidental global cookie jars.

Authentication state is source-scoped.

Session state has an explicit generation. Logout, disposal or a newer operation
invalidates stale completions before they can publish data or install cookies.
Approved provider hosts may share one source session only under explicit cookie
scope; there is no global cookie jar or dual session authority.

Credential retention is source-neutral and must be explicit for each Source. Any
durable secret requires approved cross-platform secure storage and is never put
in Drift, shared_preferences, logs or fixtures. Wenku8 specifically never retains
passwords, never imports Legacy cookies/accounts, and may remember only approved
session material through that secure-storage contract. Secure-store failure is a
typed failure; a memory-only sign-in is allowed only when explicitly selected,
never as a silent plaintext fallback.

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
- sourceUnavailable
- invalidRequest
- securityPolicy
- secureStorage

Raw library exceptions, response HTML, credentials and arbitrary server messages
are mapped or redacted at the boundary. Retryability and bounded retry-after
metadata are explicit. A login/challenge page with HTTP 200, a missing required
DOM element, a valid empty result and an unsupported response shape remain
distinct outcomes.

## 11. Cancellation

Cancellation is part of the API.

Leaving a screen, starting a newer search, changing chapter, or disabling a plugin may obsolete work.

Old results must not overwrite new state. Cancellation stops queued work,
backoff and body reads where supported; it is never converted into a retry. Each
caller and source session checks its captured generation before committing a
result, cookie or durable mapping.

## 12. SourceRegistry

Registry resolves `SourceId` to an implementation.

Source IDs are immutable and unique. Duplicate registration fails; an unavailable,
disabled or unresolved Source returns typed unavailability without deleting its
durable source-associated state or silently falling back to another Source.

Implementations:
F3 implements a built-in Dart source and test fakes. A future plugin source
adapter may implement the same boundary after the Plugin Runtime phase; F3 does
not include a plugin runtime or downloadable plugin code.

No UI branch on concrete source type.

## 13. F3 reference source and neutrality proof

F3 implements only the built-in Wenku8 Source, migrated from frozen Legacy
behavior and sanitized fixtures. Contract neutrality is tested with in-memory
fake Sources using non-Wenku8 IDs, catalog shapes and capability combinations.
A second real Source is an F8 deliverable and is outside F3.

The F3 fixture corpus must prove ordered text/image output, image-only content,
flat catalogs, grouped catalogs with stable volume IDs, and grouped catalogs
whose presentation labels have no stable VolumeId.
