# ADR 0007 — F3.4 Controlled Charset Decoder Strategy

Status: **ACCEPTED**. Human approval: **APPROVED** by the Human project owner
on **2026-09-18**. Accepted baseline:
`d4c74a6874779ea2558a97fdcf25ec9da976fa58`.
Proposal date: **2026-09-18**. Source baseline:
`8eec93a6d6fc8842a24f8cc060215e6d0bf0b8a7`.

This ADR records the Human-approved controlled project-owned charset strategy.
It authorizes the charset foundation only; it does not accept F3.4, authorize
the Wenku8 parser or runtime, or approve F3 Exit. The decoder portion of ADR
0006 is superseded by this ADR. No dependency is added or required by this
decision.

## Context

ADR 0006 previously accepted `charset_codec: 0.1.1` as the F3.4 decoder
dependency. Its realization failed for two independent reasons:

```text
charset_codec 0.1.1: hooks >=2.0.2 <2.1.0
sqlite3 3.6.0:      hooks ^2.2.0

charset_codec 0.1.1, Legacy GBK vector: aaa1 -> rejected
required result:                             U+E000
```

The existing evidence also found that `charset_converter` uses different
native charset APIs and labels on the three target platforms. The Windows
probe passed the frozen vectors through `gb2312` (code page 936) and
`GB18030`, but did not provide a common strict/replacement contract and
rejected the labels `GBK`, `CP936` and `windows-936`.

This proposal evaluates whether a small project-owned Dart codec can provide a
single deterministic contract for the exact legacy behavior required by the
frozen F3.2 corpus.

## Proposed boundary

The proposed source-neutral boundary is:

```text
RawBytes
   |
   v
CharsetDecoder
   |
   v
DecodedDocument
```

The internal strategies would be:

```text
LegacyCP936Decoder
GB18030Decoder
```

`LegacyCP936Compatible` is the public mode name proposed for the first
strategy. The name deliberately does not claim that every implementation
called “GBK” has one identical table. It records the frozen `aaa1 -> U+E000`
behavior, the Windows/CP936 compatibility requirement and the frozen legacy
fixture semantics. `GB18030` remains a separate mode and must never be used as
a fallback for the first mode.

The boundary may expose a symmetric encode operation for source-neutral query
construction, but that operation is part of the same codec contract and is
not provider logic. The parser receives decoded Unicode text only. No codec
type may mention Wenku8 selectors, URLs, cookies, HTML nodes, domain models,
Reader state or persistence.

`DecodedDocument` should retain the accepted F3.4 provenance fields:

* selected encoding mode;
* evidence/reason for the selection; and
* safe decoding failure metadata, without retaining credentials, cookies or
  arbitrary response data.

The caller must select the mode from trusted source evidence. The codec must
not guess a charset at runtime or silently retry another mode.

## Required behavior

Both strategies must define the same explicit error policy:

| Input or operation | Strict mode | Replacement mode |
| --- | --- | --- |
| valid bytes | decode normally | decode normally |
| invalid byte sequence | typed decoding failure | U+FFFD for the invalid sequence, with deterministic progress |
| truncated multibyte sequence | typed decoding failure | U+FFFD for the incomplete sequence |
| unrepresentable code point during encode | typed encoding failure | a documented replacement policy, if encoding replacement is required; no silent UTF-8 fallback |

The mandatory frozen vectors are:

```text
LegacyCP936Compatible: d6d0cec4d0a1cbb5 -> 中文小说
LegacyCP936Compatible: aaa1             -> U+E000
GB18030:               81308130         -> U+0080
strict invalid:        8130ff           -> failure
strict truncated:      813081           -> failure
query encoding:        中文小说          -> d6d0cec4d0a1cbb5
```

The six-node ordered content contract and all F2 identity/content semantics
remain outside the codec and unchanged.

## Mapping sources and provenance

The primary normative algorithm source considered here is the [WHATWG
Encoding Standard](https://encoding.spec.whatwg.org/). It defines GBK as a
distinct encoder mode over the GB18030 decoder and explicitly avoids fully
aliasing GBK with GB18030. It also defines the GB18030 four-byte state machine,
fatal/replacement error modes and range algorithms.

The standard's GBK decoder relationship is useful as a reference, but this
proposal does not silently inherit every GB18030 four-byte behavior into
`LegacyCP936Compatible`. The project mode must freeze its CP936-compatible
two-byte domain and its handling of four-byte input separately from the
`GB18030` strategy before implementation.

The investigation downloaded the dated source indexes outside the repository
for measurement only; no table was generated or committed:

| Source | Evidence measured | Implication |
| --- | --- | --- |
| `index-gb18030.txt` | 23,940 mapped entries, 843,967 bytes of dated text (`2024-09-18`, identifier pinned in the source file) | A dense 32-bit runtime table has a lower-bound payload of about 95,760 bytes before reverse maps and representation overhead |
| `index-gb18030-ranges.txt` | 207 range entries, 3,110 bytes of dated text | The four-byte space is represented by ranges instead of materializing more than a million rows |
| GBK pointer rules | `0xAA 0xA1` resolves to the frozen pointer for U+E000 when the 0x7F gap is handled correctly | The PUA vector is implementable without treating GBK as GB18030 |
| GB18030 range rules | pointer zero maps `81308130` to U+0080 | The four-byte vector is implementable independently of the two-byte mode |

The WHATWG standard states that the standard is CC BY 4.0 and that portions
incorporated into source code are BSD 3-Clause. A future implementation must
retain the required attribution/license notices and pin the exact index
identifiers and hashes used to generate the shipped data. This is evidence that
the normative source can be incorporated, subject to the project completing
the notice review; it is not a blanket license for unrelated CP936 data.

The project must treat any CP936 compatibility additions outside the WHATWG
index as a separate data source. Each added mapping needs a redistributable
license or a project-owned derivation from permissible evidence, a recorded
source identifier/hash, and an independent test. Windows or Android runtime
tables must not be copied into the product without that provenance review.

### Update policy

Mapping data must be pinned and updated manually. A future update requires:

1. a reviewed source revision and license notice;
2. regenerated data with a reproducible generator;
3. a diff review for two-byte, four-byte and PUA mappings;
4. all frozen F3.2 vectors plus malformed, encode and round-trip tests; and
5. a new ADR amendment if the supported mapping semantics change.

There must be no network fetch, runtime table update or automatic charset-table
refresh in the application.

## Size and implementation estimate

These are planning estimates, not an implementation commitment:

* decoder/encoder state machines, error policy and provenance plumbing:
  approximately 400–800 Dart lines;
* reproducible table generator and audit tool, kept outside runtime code:
  approximately 200–400 lines;
* packed two-byte index and reverse-map data: approximately 0.1–0.3 MB in
  runtime form, depending on sparse/dense representation and encoder map;
* generated Dart source: approximately 0.3–1.0 MB if emitted as literals rather
  than a compact binary asset.

The main maintenance cost is reviewing mapping provenance and preserving
compatibility exceptions, not the small state machine. A pure Dart codec has
higher initial implementation and audit cost than calling one platform API,
but it removes platform label drift, native plugin behavior differences and
the `hooks` dependency conflict. Whether it is lower total maintenance is
therefore **UNPROVEN until the implementation, generator and update policy are
reviewed**; it is the lower-risk runtime shape for this project's narrow
cross-platform contract if those gates pass.

## Comparison

The matrix records the evidence available at this proposal. `PASS` means the
criterion is established by the architecture or an exact probe; `FAIL` means
the candidate contradicts a mandatory requirement; `UNPROVEN` means the
required implementation or target runtime evidence does not yet exist.

| Criterion | Controlled pure Dart | `charset_codec: 0.1.1` | `charset_converter: 2.5.1` |
| --- | --- | --- | --- |
| Single source-neutral contract | PASS as proposed boundary; implementation UNPROVEN | PASS at API level | FAIL for one common contract: platform labels and errors differ |
| GB18030 `81308130 -> U+0080` | PASS by normative range algorithm; implementation UNPROVEN | PASS in probe | PASS on Windows; Android/iOS UNPROVEN |
| CP936-compatible `aaa1 -> U+E000` | PASS as a pinned mapping requirement; implementation UNPROVEN | FAIL for its GBK mode | PASS on Windows via `gb2312`; Android/iOS UNPROVEN |
| Deterministic strict errors | PASS by owned state machine design; implementation UNPROVEN | PASS in probe | FAIL on Windows; plugin has no common strict mode |
| Deterministic replacement | PASS by owned policy design; implementation UNPROVEN | PASS in probe | UNPROVEN as a common cross-platform contract |
| Android | PASS for pure Dart execution shape; runtime proof deferred to implementation | UNPROVEN in this project | UNPROVEN |
| iOS | PASS for pure Dart execution shape; runtime proof deferred to implementation | UNPROVEN in this project | UNPROVEN |
| Windows | PASS for pure Dart execution shape; runtime proof deferred to implementation | UNPROVEN in this project | FAIL for canonical aliases/strict behavior observed |
| Dependency graph | PASS: no new package | FAIL with `sqlite3: 3.6.0` hooks resolution | PASS with current `sqlite3` in temporary graph |
| Native toolchain | PASS: none required | FAIL for the current graph and Rust hook burden | UNPROVEN as a uniform build/runtime surface; native APIs are required |
| Long-term mapping maintenance | UNPROVEN until project data policy is approved | UNPROVEN and package behavior cannot satisfy PUA | UNPROVEN; behavior is platform-owned |

The pure Dart column is intentionally not marked implemented. Its `PASS`
entries establish feasibility and architectural fit; all runtime behavior must
become `PASS` through deterministic tests before implementation can be
accepted.

## Answers to the decision questions

### Can pure Dart satisfy both required vectors without platform differences?

Yes as a design feasibility result. The WHATWG two-byte index and GB18030
range algorithm provide the required `aaa1 -> U+E000` and `81308130 -> U+0080`
results when implemented as two explicit strategies. The current repository
has no implementation, so runtime correctness remains **UNPROVEN** until the
vectors, malformed cases, query encoding and cross-platform test matrix pass.

### Can generated mapping tables be legally included?

The WHATWG standard provides an auditable path: CC BY 4.0 for the standard and
BSD 3-Clause for portions incorporated into source code. Inclusion is
conditionally feasible with attribution, pinned identifiers and license
notices. Additional CP936 data is **UNPROVEN** until its own source and
redistribution terms are reviewed. No generated table is approved by this ADR.

### Can strict malformed handling be deterministic?

Yes as a pure Dart design. The decoder owns byte boundaries, pending lead-byte
state, end-of-input handling and a typed strict/replacement policy. The
WHATWG algorithm explicitly models malformed and truncated sequences as
errors. A future implementation must prove that the same input produces the
same result on Android, iOS and Windows; this ADR does not claim that proof.

### What is the estimated implementation size?

The planning estimate is 400–800 lines for the runtime state machines and
provenance/error boundary, 200–400 lines for reproducible generation/audit
tooling, and roughly 0.1–0.3 MB of packed mapping data, with a larger source
form if literals are used. These estimates exclude the existing fixture corpus
and the future exhaustive tests.

### Is this lower maintenance than depending on platform APIs?

It is not lower initial maintenance. It is expected to reduce runtime and
release maintenance caused by platform-specific aliases, native replacement
rules and OS behavior drift. That tradeoff is **UNPROVEN** until the project
has a reviewed generator, update policy, legal notices and target-platform
tests. The proposal recommends the pure Dart path because it removes the
known graph conflict and gives the project ownership of the mandatory legacy
semantics, subject to those gates.

## Rejected shortcuts

* Decoding all legacy bytes as GB18030 is rejected because it erases the
  `LegacyCP936Compatible`/GB18030 distinction and violates frozen PUA and
  query-encoding semantics.
* UTF-8 fallback is rejected because it silently corrupts legacy bytes and
  converts a codec error into apparently valid text.
* Platform charset guessing is rejected because aliases and malformed behavior
  differ between Android, iOS and Windows.
* Runtime charset detection is rejected because it makes ambiguous input and
  error handling nondeterministic. The caller must supply trusted evidence.
* Modifying `sqlite3` only to make a codec dependency resolve is rejected.
  Storage, ABI, Drift compatibility and migration safety require their own
  decision and must not be changed to hide a decoder incompatibility.

## Recommendation and gates

**Accepted decision:** use a controlled project-owned Dart decoder with the two
explicit strategies `LegacyCP936Decoder` and `GB18030Decoder`. The runtime
foundation and its independent vectors are implemented in the repository, but
remain subject to implementation review and the unresolved Android/iOS runtime
evidence gate.

For implementation and later acceptance, this ADR freezes:

1. the exact mapping source revisions, hashes, notices and CP936 overlay rule;
2. the generated-data representation and reproducible generator boundary;
3. strict and replacement error objects and progress semantics;
4. encode behavior for query construction and unrepresentable code points;
5. the full Android, iOS and Windows deterministic test plan; and
6. the acceptance rule for changes to mapping data.

The mapping, generator, strict/replacement, encode and platform gates remain
acceptance requirements for the charset foundation. Android and iOS runtime
vector evidence are still **UNPROVEN**; Windows evidence is recorded
separately. This gap is not a PASS or waiver and remains an F3.7/F3 Exit
blocker. F3.4.2 and F3.4.3 implementation status is recorded in the current
F3 governance checkpoint and is not accepted by this ADR.

## Approval record

ADR 0007: **ACCEPTED** at baseline
`d4c74a6874779ea2558a97fdcf25ec9da976fa58`.
Human approval: **APPROVED** by the Human project owner on **2026-09-18**.
The accepted strategy supersedes the decoder dependency portion of ADR 0006.
