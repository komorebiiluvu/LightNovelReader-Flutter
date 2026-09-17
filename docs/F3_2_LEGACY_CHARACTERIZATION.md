# F3.2 — Legacy Characterization and Fixture Harness

Status: **IMPLEMENTED — HUMAN REVIEW REQUIRED**

Slice: **F3.2 — Legacy Characterization + Fixture Harness**

Frozen Legacy commit: `d90d4d090c85a0a9c374684696c34befe12636d1`
Implementation starting SHA: `557ef34a1869daac4172268e154d2d6b959423e1`

This record is the deterministic evidence boundary for F3.2. It characterizes
the frozen Swift/KMP implementation by read-only source inspection and a
fixture corpus. It does not claim that the Legacy app was executed, that a
provider was contacted, or that a production parser exists.

## Evidence rules

Every manifest entry under
`test/fixtures/sources/wenku8/manifest.json` has an immutable SHA-256 for its
raw input and independently authored expected sidecar. Entries are either
`synthetic` or `reconstructed_from_frozen_evidence`; no authenticated capture
is included. The frozen commit and source path/section are recorded per entry.
Expected sidecars describe contract outcomes and were not produced by a
production parser. The harness rejects paths outside the fixture root,
unexpected provenance, changed hashes, secret-like material, and references to
production parser code.

The corpus contains **80 entries**: 31 search, 9 explore, 7 book-detail, 9
catalog, 15 chapter-content, and 9 authentication entries. Provenance is 60
synthetic and 20 reconstructed. Classifications are 15 `PRESERVE`, 23 `FIX`,
37 `REGRESSION_TEST`, 5 `DEFER`, and **0 `DROP`**.

## Review integrity correction

Review baseline: `fb5060a497cadbce205269cddfff9852d74aac73`.
F3.2 remains unaccepted; F3.3 has not started.

All 27 GBK/GB18030 entries were audited. Textual inputs previously saved as
UTF-8 were transcoded with strict .NET code pages 936/54936 into `.bin` files.
Every non-UTF entry now pins its complete raw hex in `byteExpectation`; the
harness checks those bytes and rejects non-ASCII UTF-8 masquerading as these
encodings even when its hash and hex have been updated. ASCII-only pages are
valid in both encodings. Raw and expected files have byte-preserving Git
attributes so checkout line-ending conversion cannot invalidate hashes.

Independent Node ICU `TextDecoder` verification matched all 25 valid non-UTF
inputs against their separately authored Unicode or original DOM text. The
remaining two intentionally invalid/truncated vectors retain `8130ff` and
`813081`. No product decoder or package was added.

| Vector | Independently verified bytes | Unicode expectation |
| --- | --- | --- |
| GBK / GB2312-compatible Chinese | `d6d0cec4d0a1cbb5` | 中文小说 |
| GB18030 four-byte vector | `81308130` (unchanged bytes) | U+0080; previous U+20000 sidecar was false |
| GBK PUA | `aaa1` | U+E000; previous `8140` encoded U+4E02 instead |
| Declaration disagreement | ASCII meta declaring UTF-8, then `d6d0cec4` inside the paragraph | GBK 中文; declaration conflicts with actual bytes |

The dedicated `content-multi-interleaved` fixture requires exactly
Text / Text / Image / Text / Image / Text in one `nodes` array. The test checks
all six distinct values in order, not just the coverage tag. Locators are
adapter metadata and no AssetId is fabricated.

Security checks now traverse every corpus file, manifest JSON values and
expected sidecars. Negative tests inject secret-bearing headers, assignments
and nested JSON through each surface; harmless prose and exact existing inert
sentinels remain allowed. This is a structural guard against accidental secret
inclusion, not proof that arbitrary free prose can never conceal a secret.
Provenance is unchanged for existing entries; the new fixture is synthetic.
No entry is a capture and no DROP classification was introduced.

The path check resolves actual filesystem paths without lowercasing them,
preserving case-sensitive checkout compatibility and detecting symlink escapes.
Review validation: focused tests **17 passed**, full suite **418 passed**;
format and static analysis passed. Production code, dependencies, schemas,
workflows and platform files remain unchanged.

## Characterization matrix

| Area | Frozen evidence inspected | Corpus coverage and expected policy | Classification |
| --- | --- | --- | --- |
| Encoding | `Wenku8DataSource.kt`; `KMP-TROUBLESHOOTING.md` sections 14, 20–23 | ASCII, simplified Chinese, GBK/GB18030 extension bytes, PUA, invalid/truncated bytes, declaration disagreement, and GBK percent-encoded query bytes. Preserve code points; malformed input is typed parse evidence. | PRESERVE / FIX / REGRESSION_TEST |
| Authentication and cookies | `Wenku8Client.kt`, `KmpBookSourceAdapter.swift` | Login success/rejection, expired redirect, PHPSESSID-only and jieqi-only states, multiple `Set-Cookie`, `Expires` commas, logout deletion, and inert HTTP-200 challenge. Cookie handling is session infrastructure; fixture values are synthetic sentinels only. | PRESERVE / FIX / REGRESSION_TEST |
| Search | `Wenku8DataSource.kt`, `KmpBookSourceAdapter.swift` | Multi-result pages, direct-detail result, empty success, stable-ref deduplication, malformed/missing fields, login-required, rate-limit/throttle, HTTP-200 WAF and timeout metadata. Results carry source-aware opaque IDs. | PRESERVE / FIX / REGRESSION_TEST |
| Explore | `Wenku8DataSource.kt`, adapter home/category methods | Home, category, tag/filter descriptors, multiple ordered blocks, pagination, duplicate/whitespace normalization, missing optionals, malformed block and valid empty. Descriptor and selection identity stay opaque. | PRESERVE / FIX / REGRESSION_TEST |
| Pagination | `Wenku8DataSource.kt` page-stat and page-link parsing | `pagestats`, whitespace links, largest-linked-page fallback, missing/malformed metadata, duplicate books, and exhausted pages. A malformed cursor is failure; an exhausted page is explicit and cannot roll state backward. | PRESERVE / FIX / REGRESSION_TEST |
| Detail | `Wenku8DataSource.kt`; `KMP-TROUBLESHOOTING.md` sections 21–22 | Required title, optional fields, cover locator, copyright-unavailable branch, description boundary, and table-cell boundaries. Provider locators remain adapter evidence, not domain identity. | PRESERVE / FIX / REGRESSION_TEST |
| Catalog | `Wenku8DataSource.kt`, adapter `fetchChapters` | Stable chapter/volume IDs, flat catalog, multiple volumes, label-only grouping, reordered chapters, duplicate IDs, and missing chapter IDs. Ordinal/index is ordering only; no fabricated modern ChapterId or VolumeId. Reconciliation receipt is deferred. | PRESERVE / FIX / DEFER |
| Ordered content | `Wenku8DataSource.kt`; `KMP-TROUBLESHOOTING.md` section 23 | Interleaved text/image, `<br>` flush, consecutive breaks, image-only, repeated images, text around images, valid empty, missing container, malformed DOM, page chrome and nested DOM. `ChapterContent.nodes` order is authoritative. | PRESERVE / FIX / REGRESSION_TEST |
| Asset locators | `Wenku8DataSource.kt` image handling | Relative, protocol-relative and absolute locators are retained as adapter metadata. Stable AssetId mapping and retrieval are deferred; invalid hosts prevent accidental traffic. | DEFER |
| Hosts, retry and WAF | `Wenku8DataSource.kt`, `Wenku8Client.kt` | `.net` search/explore and `.cc` detail/catalog/content host policy, unapproved-host security failure, 15s connect/20s request timeout intent, bounded server-error retry, and HTTP-200 WAF. This is characterization metadata only, not transport implementation. | PRESERVE / REGRESSION_TEST |
| Reconciliation | F2 identity baseline and adapter mapping boundary | Opaque `wk8-<aid>` examples, ordinal-only evidence, receipt shape and schema deferral. No migration, overwrite or schema code is included in F3.2. | DEFER |

## Fixture manifest and harness

The manifest is the source of truth for fixture membership, provenance,
encoding, HTTP context, sanitization state, classification, expected contract
outcome and hashes. Raw inputs and JSON sidecars are deliberately small so a
reviewer can inspect them in a normal diff. `fixture_harness_test.dart` adds
no package dependency: it uses the Dart SDK `dart:io`/`dart:convert` libraries
and the repository's existing `flutter_test` runner, with an independent
SHA-256 implementation. It validates:

* manifest schema, unique IDs, allowed operations/classifications and the
  frozen Legacy commit;
* fixture/sidecar existence, root containment and both SHA-256 values;
* independent sidecars (no production parser imports or implementation names);
* inert authentication metadata and a whole-corpus secret scan for credentials, bearer
  headers, non-synthetic cookie values and password-like assignments;
* byte vectors for the GBK/GB18030 cases and invalid/truncated input;
* required operation/category/edge-case coverage and zero `DROP` entries; and
* URL checks allowing the characterized provider hosts and reserved `.invalid`
  examples, without executing requests.

No test performs HTTP, secure-storage access, DOM decoding, image retrieval,
Legacy execution, or live Wenku8 smoke. Those are later-slice concerns.

## Classification and deferred decisions

`PRESERVE` records behavior to carry into a pure adapter; `FIX` records a
characterized defect or ambiguity that must be resolved before production
parsing; `REGRESSION_TEST` records a stable boundary; and `DEFER` records a
decision intentionally owned by F3.3, F3.4, F3.6 or F6. There are no `DROP`
entries. Deferred items include production GBK/GB18030 decoder choice, secure
cookie persistence and session generations, stable asset identity/mapping,
provider-to-modern chapter/volume reconciliation and any schema extension.

F3.2 does not authorize F3.3–F3.7, network dependencies, secure storage,
decoder/DOM dependencies, a second Source, plugin runtime, Reader, image
download/cache/offline work, schema changes, or F3 Exit.

## Validation boundary

The harness is intended to run identically on iOS, Android and Windows through
the normal Flutter test command. Platform builds, packaged runtime evidence and
any controlled real-provider live smoke remain F3.7 work; live smoke is manual,
bounded and supplemental, never a CI dependency or deterministic F3 exit gate.
