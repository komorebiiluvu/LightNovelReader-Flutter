# F3.4.3 Wenku8 Request Builder Foundation

Status: **IMPLEMENTED / HUMAN REVIEW REQUIRED**

This slice is a pure, synchronous request-description boundary. It consumes an
explicit Wenku8 intent and returns a source-neutral `SourceHttpRequest` wrapped
with reviewed construction evidence. It performs no I/O and has no asynchronous
work. F3.4 remains HUMAN REVIEW REQUIRED, F3.5–F3.7 remain NOT AUTHORIZED, and
F3 Exit remains NOT APPROVED. Android and iOS charset runtime evidence are
still UNPROVEN and remain an F3.7 gate; this implementation does not convert
that gap into a PASS or waiver.

## Boundary

```text
Wenku8 request intent
        |
        v
Wenku8RequestBuilder
        |
        v
SourceHttpRequest + redacted construction evidence
```

The implementation is isolated under `lib/src/sources/wenku8/`. Source
contracts, domain identity types, transport execution, session state and
persistence are not extended with Wenku8 concepts.

## Intents and characterized routes

The builder exposes explicit intents for search, explore, book detail, catalog
and chapter content. Book and chapter locators remain strings. Catalog and
chapter routes receive the characterized `novel` directory as separate opaque
route evidence; the builder never parses a book locator or turns it into an
integer. A path segment is percent-escaped before URI construction so an
opaque locator cannot add path structure.

F3.2 froze the following HTTPS origin and path policy:

| Operation | Origin | Path construction |
| --- | --- | --- |
| Search | `www.wenku8.net` | `/modules/article/search.php` |
| Explore | `www.wenku8.net` | `/index.php`, `modules/article/articlelist.php`, `modules/article/toplist.php`, or `modules/article/tags.php` |
| Book detail | `www.wenku8.cc` | `/book/<book-locator>.htm` |
| Catalog | `www.wenku8.cc` | `/novel/<directory>/<book-locator>/index.htm` |
| Chapter content | `www.wenku8.cc` | `/novel/<directory>/<book-locator>/<chapter-locator>.htm` |

Only the characterized origin for an operation is accepted. An override must
be a bare approved HTTPS origin with no path, query, fragment or user-info.
Arbitrary hosts, non-HTTPS schemes and caller-supplied absolute URLs are
rejected before a request is created.

## Query construction

Search uses the frozen title-search query order:

```text
searchtype=articlename&searchkey=<legacy-percent-bytes>&page=<positive-page>
```

The `searchkey` value is encoded by the existing
`CharsetEncoder` with `SourceEncoding.legacyCp936Compatible`, then each byte is
percent-encoded with uppercase hexadecimal digits. The same approved path is
used for tag selection. URI UTF-8 query helpers are not used for these fields.
ASCII operation parameters use deterministic ASCII percent encoding. Empty
search text is represented by an explicit empty `searchkey` value, and a
character that the legacy encoder cannot represent produces a typed build
failure.

`Wenku8QueryEvidence` retains field names, encoded query text and byte length
for test and review inspection. Its `toString` contains only field names and
length, so ordinary diagnostics do not expose query values.

## Request safety

The builder creates GET requests with immutable empty headers, generation zero,
no session binding and the neutral transport policy required by the existing
request model. It does not add per-request credentials or session state. The
request object is a description for a later runtime owner; this slice never
executes it or reads any external state.

## Evidence and tests

Focused tests cover:

* the independently authored F3.2 request fixture and exact CP936-compatible
  percent bytes for `中文` (`D6 D0 CE C4`);
* ASCII, spaces, reserved characters, empty input and unsupported characters;
* frozen origins and paths for every operation;
* exploration category, tag and page query ordering;
* non-HTTPS, unapproved host, user-info and absolute-URL rejection;
* leading-zero and slash-containing opaque locators; and
* immutable, credential-free request metadata and redacted debug output.

No live provider availability is assumed. Runtime composition, session binding,
transport policy selection, response decoding and provider parsing are deferred
to their authorized later slices.
