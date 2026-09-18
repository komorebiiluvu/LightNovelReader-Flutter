# ADR 0006 — F3.4 Parser Dependencies

Status: **ACCEPTED**. Human approval: **APPROVED** by the Human project owner
on **2026-09-18**. Accepted baseline:
`c0ad8a3b64166c0a95a52aaa9caa9c9d9d04dd51`.
Proposal date: **2026-09-18**. Slice: **F3.4 — Wenku8 Pure Parser + Request
Builder**.

This ADR records the accepted F3.4 dependency set. It does not add a package,
change the lockfile, implement a decoder, implement an HTML parser, or
implement a Wenku8 request builder. F3.4 is authorized only for the accepted
decoder, HTML parser, request builder and provider-neutral parsed-structure
foundations. F3.5–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains **NOT
APPROVED**.

## Context

F3.2 established the sanitized, independently authored Wenku8 corpus at
`test/fixtures/sources/wenku8`. It contains truthful UTF-8, GBK-compatible and
GB18030 byte vectors, malformed and truncated sequences, encoding-declaration
disagreement, malformed legacy HTML, search/detail/catalog/content pages and
the ordered `Text / Text / Image / Text / Image / Text` content case. F3.3
already exposes bounded raw response bytes through the source-neutral
`SourceTransport` boundary.

The F3.4 pipeline must therefore remain two separate layers:

```text
raw bytes + encoding evidence -> decoder -> decoded text
decoded document -> HTML parser -> source-neutral parsed structures
source-neutral request intent -> request builder -> SourceHttpRequest
```

The decoder must not know Wenku8 identifiers, URLs, selectors, chapters or
Reader models. The HTML parser must not perform decoding, networking,
authentication, persistence or UI work. The request builder must not parse
HTML or own credentials.

## Requirements

### Decoder

The boundary accepts bounded `RawBytes` plus explicit encoding evidence and
returns `DecodedText`. Required encodings are UTF-8, GBK-compatible Chinese
encodings and GB18030. The implementation must provide:

* an explicit encoding override;
* deterministic evidence precedence;
* strict failure for invalid and truncated sequences by default;
* an explicitly selected replacement mode using U+FFFD;
* no silent guessing, ignored bytes or conversion of failure to empty text;
* a typed, redacted error containing the canonical encoding, byte offset and
  failure kind, without raw bytes, response bodies or credentials; and
* deterministic whole-buffer tests, with bounded incremental behavior only if
  a later implementation needs it.

The proposed precedence is: a trusted explicit override, then a recognized
UTF-8 BOM, then trusted transport charset metadata. If none is available, the
decoder returns an encoding-required/incompatible-response failure. A
conflicting untrusted declaration is recorded as disagreement and does not
silently change the selected encoding. The decoder does not inspect HTML meta
elements; a source adapter may supply separately reviewed evidence. Unsupported
or ambiguous evidence is a failure, not a guess.

UTF-8 uses `dart:convert` directly. GBK, GB2312-compatible aliases and
GB18030 require a codec with explicit deterministic support. F3.2's independent
vectors, including `d6d0cec4d0a1cbb5`, `aaa1 -> U+E000` and
`81308130 -> U+0080`, are mandatory acceptance cases.

#### Decoder provenance design note

The future `DecodedDocument` result is a design concept only; this ADR does not
implement it. The decoder result should preserve enough safe provenance for
debugging and fixture comparison:

* decoded text;
* selected canonical encoding;
* decoding evidence/reason, such as an explicit override, BOM, trusted
  transport metadata or a recorded disagreement; and
* decoding failure metadata where safe, such as a stable failure kind and byte
  offset.

This provenance must not retain raw response bytes, credentials, cookies,
arbitrary server messages or whole-response dumps. It must remain outside F2
`ChapterContent`, Reader models and persistence.

### HTML parser

The parser accepts `DecodedDocument` text and returns source-neutral parsed
structures such as `ParsedSearchPage`, `ParsedBookDetail`, `ParsedCatalog` and
`ParsedChapterContent`. Concrete Dart types and normalization rules are an
F3.4 deliverable, but they must preserve ordered content nodes and opaque F2
identity evidence.

The parser must tolerate malformed HTML deterministically, support DOM
traversal and fixed CSS-selector/equivalent queries, and stay bounded by the
transport/document limits. It must not execute scripts, fetch resources,
resolve external entities, follow links, access the network or create hidden
side effects. Selectors are fixed adapter code, never user-provided commands.
The parser receives a `String`, not raw bytes, so encoding remains testable in
isolation.

### Request builder

The builder accepts a source-neutral request intent and returns an existing
`SourceHttpRequest`. It may construct an approved URI, encode query
parameters, and add an adapter-owned allowlisted header set. It must not know
HTML, decoding, Reader/UI models, database entities or authentication storage.
It must not import Dio; the existing `SourceTransport` adapter remains the
only library boundary. No live Wenku8 URL, selector, login flow or identifier
extraction is implemented by this ADR.

## Candidate evaluation

Evidence was checked on **2026-09-18** against the package pages, changelogs,
API documentation and upstream repositories linked below. Versions are exact
candidates reviewed for this ADR; the accepted choices are recorded below.

### Decoder candidates

| Candidate | Version / license | Compatibility and maintenance | Encoding and error behavior | Dependencies / assessment |
| --- | --- | --- | --- | --- |
| Dart SDK `dart:convert` | SDK bundled with Dart 3.13.3 and Flutter; Dart SDK is BSD-3-Clause | Available on all targets; actively maintained with the SDK | `Utf8Decoder` supports strict failure by default, explicit replacement with `allowMalformed`, and chunked streams. It is UTF-8 only and does not provide GBK or GB18030. | No dependencies. Deterministic unit-test surface. **Use for UTF-8 only.** [`Utf8Decoder` API](https://api.dart.dev/dart-convert/Utf8Decoder-class.html) |
| `charset_codec` | `0.1.1`; MIT | Min Dart 3.11; pub.dev lists Dart/Flutter support for Android, iOS, Windows, Linux, macOS and web. Published recently and has 150/160 pub points, but the publisher is unverified and adoption is currently low. | Documents 103 codecs and aliases including `gbk` and `gb18030`; strict/replace modes, byte validation, whole-buffer async APIs and bounded incremental decoders. `CodecException` includes codec/operation/position. The true GB18030 fixture must still pass independently. | `code_assets`, `crypto`, `ffi`, `hooks`, `native_toolchain_rust` plus transitive packages. Deterministic list-of-bytes tests are possible, but native-asset builds require all target smoke. Native assets/Rust toolchain are the principal platform and supply-chain risk. [Package](https://pub.dev/packages/charset_codec), [changelog](https://pub.dev/packages/charset_codec/changelog), [score](https://pub.dev/packages/charset_codec/score) |
| `charset_converter` | `2.5.1`; BSD-3-Clause | Min Dart 3.12; Flutter package lists Android, iOS, Windows, Linux and macOS. Recent releases include Flutter 3.44 compatibility and Windows support. | Uses platform charset APIs and exposes async whole-buffer conversion plus availability checks. GBK may be present, but names, aliases, malformed behavior and GB18030 availability are platform-specific; the package does not establish one deterministic GB18030 result across iOS, Android and Windows. Native integration tests are mandatory. | No Dart dependencies, but it is a native platform plugin. Rejected for this boundary unless a later review proves identical target behavior for every required vector. [Package](https://pub.dev/packages/charset_converter), [README](https://github.com/pr0gramista/charset_converter) |
| `fast_gbk` | `1.0.0`; BSD-3-Clause | Dart/Flutter package with null safety; published five years ago by an unverified uploader; low adoption and no recent maintenance signal. | GBK codec with stream support and optional malformed replacement. It does not claim GB18030 or provide the required four-byte proof. Pure-Dart unit tests are straightforward. | No relevant platform dependency is documented. Rejected because GBK is not full GB18030 and maintenance is insufficient. [API](https://pub.dev/documentation/fast_gbk/latest/index.html) |
| `gbk_codec` | `0.4.0`; MIT | Dart/Flutter package, min Dart 2.13; published five years ago by an unverified uploader. | GBK-only byte codec; no GB18030 support or current maintenance evidence. Pure-Dart unit tests are possible, but the required codec coverage is absent. | Depends on `html`, creating an unnecessary parser coupling. Rejected. [Versions](https://pub.dev/packages/gbk_codec/versions) |

`flutter_chardet` and similar detector packages are not proposed. Detection is
not a substitute for explicit evidence and would make malformed or ambiguous
pages nondeterministic; F3.4 must not silently guess.

### HTML parser candidates

| Candidate | Version / license | Compatibility and maintenance | Parsing and selectors | Dependencies / assessment |
| --- | --- | --- | --- | --- |
| `html` | `0.15.7`; pub metadata license is unavailable/unknown; the upstream `dart-lang/tools` repository carries BSD-3-Clause evidence for the maintained `html` package | Min Dart 3.6; pub.dev lists Dart/Flutter support for Android, iOS, Windows, Linux, macOS and web. Published recently by `tools.dart.dev`; 150/160 pub points and a maintained Dart tools repository. | HTML5 tree builder with malformed-input tolerance, DOM traversal, `querySelector`/`querySelectorAll` and deterministic String parsing. The package intentionally dropped non-UTF-8 input support, which reinforces the separate decoder boundary. | `csslib` and `source_span`; no network or browser runtime. **Accepted with upstream BSD-3-Clause license evidence; resolved archive/license inventory remains required before addition.** [Package](https://pub.dev/packages/html/versions/0.15.7), [changelog](https://pub.dev/packages/html/changelog), [upstream tools package](https://github.com/dart-lang/tools/tree/main/pkgs/html) |

No alternative HTML dependency meets a stronger requirement for this slice.
`package:xml` is an XML parser, not an HTML5 error-correcting parser; browser
or WebView parsing is nondeterministic and violates the pure parser boundary.

The accepted license evidence for `html: 0.15.7` is explicit:

```yaml
html: 0.15.7
pub_metadata_license: unavailable_or_unknown
upstream_repository_license: BSD-3-Clause
license_decision: accept upstream BSD-3-Clause evidence
```

Pub metadata does not expose a recognized package license for this version.
The `dart-lang/tools` upstream repository carries BSD-3-Clause evidence and
contains the maintained `html` package, so that upstream evidence is accepted
for this dependency decision. Before any dependency addition, the resolved
archive and license inventory must be recorded and must agree; otherwise the
dependency addition remains blocked and this ADR must be amended.

## Accepted decision

Use the following exact accepted dependency set in F3.4:

| Concern | Package | Status |
| --- | --- | --- |
| UTF-8 decoding | Dart SDK `dart:convert` | Existing capability; no dependency addition |
| GBK/GB2312-compatible and GB18030 decoding | `charset_codec: 0.1.1` | Accepted |
| HTML5 parsing and DOM querying | `html: 0.15.7` | Accepted |
| Request building | Existing source-neutral Dart contracts and `SourceHttpRequest` | No new dependency |

The F3.4 adapter must expose one source-neutral decoder facade and one parser
facade. Provider code may depend on those facades but not on package types.
`charset_codec` must be configured only for strict or explicit replacement
behavior; its `ignore` and other lossy modes are not part of the contract.
The exact resolved dependency graph, license inventory, native-toolchain
requirements and three-target build/runtime evidence must be reviewed before
any `pubspec` or lockfile change.

## Security and boundary controls

* Decode only bounded bytes supplied by F3.3. Enforce response and DOM-size
  limits before parsing; never log raw bytes or decoded authenticated content.
* Strict decoding is the default. Replacement is an explicit fixture/request
  policy and is visible in the typed result. Invalid data never becomes empty
  content.
* `package:html` is used only as an in-process tree builder. No script engine,
  resource loader, URL fetch, external entity resolver or WebView is allowed.
* Fixed selectors and normalization code are source infrastructure. They do
  not expose HTML, CSS or URI commands to UI or plugins.
* Parser and decoder failures map to the existing typed Source failure boundary;
  package exceptions and server HTML do not escape as diagnostics.
* Request builders use approved HTTPS host policy and safe headers. Cookies,
  Authorization and credential storage remain F3.3 session/transport concerns.

## Testing and acceptance gate

Before F3.4 implementation acceptance, tests must include:

1. UTF-8 valid, BOM and malformed vectors using strict and explicit replacement
   modes.
2. GBK/GB2312-compatible Chinese vectors, GBK PUA, the audited GB18030 four-byte
   vector, mixed ASCII, malformed/truncated sequences and declaration
   disagreement. Expected Unicode is independently authored from F3.2.
3. Search (including direct-detail responses), home/category/tag exploration,
   pagination and duplicates, detail, flat/grouped catalog and content pages;
   malformed required fields, missing containers, valid empty results and
   ordered/repeated/image-only node cases.
4. Exact parsed structures, opaque source-aware IDs, safe asset-locator
   metadata and the complete ordered `ChapterContent.nodes` sequence. Tests
   must not compare split paragraph/image arrays.
5. Request-builder tests for query encoding, approved host/scheme construction,
   method/body rules, allowlisted headers and rejection of credentials or
   unapproved targets. Tests use scripted transport and never require a public
   provider.
6. Deterministic VM tests plus package/build smoke on iOS, Android and Windows;
   no platform result may be inferred from another target.

Fixtures remain the F3.2 corpus: raw bytes, provenance, expected decoded text
and expected parsed structures are independently authored. No production
parser may generate its own expected sidecar.

## Rejected and deferred approaches

* **Hand-written HTML parser:** rejected because maintaining HTML5 error
  recovery, selector semantics and security boundaries would duplicate a mature
  parser and expand the malformed-input attack surface.
* **Decode inside the HTML parser:** rejected because it couples byte encoding,
  invalid-byte policy and DOM behavior, preventing independent fixture tests.
* **Provider-specific parsing directly from bytes:** rejected because it
  couples transport, decoding, selectors and provider semantics and would
  bypass the source-neutral boundary.
* **Browser/WebView parsing:** rejected/deferred because it is nondeterministic,
  executes a larger runtime, can fetch resources and is difficult to test
  without platform divergence.
* **Platform charset conversion:** `charset_converter` remains a documented
  fallback candidate only. It is not selected because platform alias tables
  and GB18030 behavior are not one deterministic contract.
* **GBK-only codecs:** `fast_gbk` and `gbk_codec` are rejected because GBK is
  not GB18030 and their maintenance evidence is stale.

## Risks and migration policy

| Risk | Mitigation / disposition |
| --- | --- |
| `charset_codec` is new, unverified and uses native assets/Rust | Require a clean resolved graph, license/SBOM review, toolchain review and deterministic iOS/Android/Windows smoke before package addition/use. If any target fails, stop and amend this ADR; do not silently substitute. |
| GB18030 mapping differs from the F3.2 oracle | Pin the true four-byte and additional independent vectors; strict byte/Unicode assertions block acceptance. |
| `html` pub metadata leaves the license unknown | The upstream `dart-lang/tools` repository provides BSD-3-Clause evidence, which is the accepted license decision. Record the resolved archive/license inventory before any addition and amend this ADR if the archive disagrees. |
| DOM memory or selector complexity grows with hostile pages | Keep F3.3 byte limits, add parser node/attribute budgets and use fixed selectors; record bounded failure as typed parse/incompatible response. |
| Package behavior changes under a version update | Pin exact versions. Any upgrade or replacement requires an amended ADR, fixture rerun and Human approval. |
| Encoding metadata is absent or contradictory | Require explicit evidence or return a typed failure; never guess or silently prefer a document declaration. |

The neutral decoder/parser/request-builder facades are the migration seam. A
future replacement must preserve the same F3.2 expected outputs and failure
semantics. A pure-Dart decoder, `charset_converter`, or another HTML parser may
be reconsidered only through a new or amended Human-approved dependency
decision. No additional parser or decoder dependency is approved by this ADR.

## Approval record

ADR 0006: **ACCEPTED** at baseline
`c0ad8a3b64166c0a95a52aaa9caa9c9d9d04dd51`.
Human approval: **APPROVED** by the Human project owner on **2026-09-18**.
F3.4 is **AUTHORIZED** for the accepted dependency set and foundations only.
F3.5–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains **NOT APPROVED**. No
dependency was added and no F3.4 production implementation was started by this
governance commit.
