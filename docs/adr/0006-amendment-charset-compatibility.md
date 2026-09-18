# ADR 0006 Amendment — F3.4 Charset Compatibility

Status: **PROPOSED**. Human approval: **PENDING**.
Proposal date: **2026-09-18**. Source baseline:
`4026967a400954b06bcbf8904d0c9d353f3c1390`.

This is a documentation-only compatibility amendment proposal. It does not
add a dependency, change `pubspec.yaml` or `pubspec.lock`, implement a decoder,
or start F3.4 parser/request-builder work. ADR 0006 remains accepted as the
current dependency decision, but F3.4 is **BLOCKED — DEPENDENCY COMPATIBILITY
REVIEW REQUIRED** until the questions in this amendment are resolved by a new
or amended Human-approved decision.

## Current governance state

F3.1, F3.2 and F3.3 are **IMPLEMENTED / ACCEPTED**. F3.4 remains
**AUTHORIZED but BLOCKED**. F3.5–F3.7 remain **NOT AUTHORIZED** and F3 Exit
remains **NOT APPROVED**.

The accepted ADR 0006 baseline is
`c0ad8a3b64166c0a95a52aaa9caa9c9d9d04dd51`. This amendment does not replace or
silently weaken that decision.

## Realization evidence

An external temporary Dart probe resolved the exact accepted candidates:

```text
charset_codec: 0.1.1
html: 0.15.7
```

The resolved `charset_codec` archive identifies MIT licensing and introduces
native-assets tooling through `hooks 2.0.2` and
`native_toolchain_rust 1.0.4+0`. Its build hook invokes Rust tooling. The
`html` archive resolves `csslib 1.0.2` and `source_span 1.10.2`; its package
license evidence remains consistent with the accepted BSD-3-Clause upstream
evidence recorded in ADR 0006.

The probe reached the package runtime after installing the package's pinned
Rust 1.94.0 toolchain outside the repository. It verified the Chinese GBK
vector, the GB18030 four-byte vector, strict malformed-input failure,
replacement mode and a small HTML parse. It also exposed the required PUA
compatibility failure recorded below.

## Blocker A — unsatisfiable repository dependency graph

The current repository contains:

```text
sqlite3: 3.6.0
  requires hooks ^2.2.0

charset_codec: 0.1.1
  requires hooks >=2.0.2 <2.1.0
```

Pub therefore reports an unsatisfiable graph when both exact direct versions
are added. This cannot be solved by decoder or parser implementation changes.
Possible resolutions require a separate decision:

* change the `sqlite3` version;
* replace the charset dependency; or
* approve another compatibility strategy after evidence review.

No dependency override, lockfile hand-edit or silent version substitution is
allowed.

## Blocker B — GBK PUA compatibility

The mandatory F3.2 vectors remain:

```text
GB18030: 81308130 -> U+0080
GBK PUA: aaa1 -> U+E000
```

The observed `charset_codec 0.1.1` behavior is:

```text
gb18030 81308130 -> U+0080       PASS
gbk      aaa1     -> rejected    FAIL
```

The package's `gb18030` codec maps `aaa1` to U+E000, but GBK must not be
treated as identical to GB18030. Switching all GBK decoding to GB18030 would
violate the F3.4 contract and the frozen fixture semantics. The PUA behavior
must be proven through an explicitly approved compatibility design before
implementation.

## Unresolved decision questions

### Question A — compatibility layer over `charset_codec`

F3.4 may continue with `charset_codec: 0.1.1` plus a narrowly scoped
compatibility layer only if independent tests prove all of the following on
iOS, Android and Windows:

* GBK PUA `aaa1 -> U+E000`;
* GB18030 `81308130 -> U+0080`;
* strict malformed and truncated failures;
* explicit U+FFFD replacement behavior;
* deterministic GBK query encoding; and
* identical behavior without equating GBK and GB18030.

The layer must remain source-neutral, finite and documented. It must not become
a general handwritten charset implementation or conceal a package exception.
No such layer is selected by this proposal.

### Question B — replace the charset dependency

The following candidates require a complete evidence matrix before any choice:

| Candidate | License / maintenance evidence | Platform and dependency shape | GBK / GB18030 / PUA / malformed evidence | Current disposition |
| --- | --- | --- | --- | --- |
| `charset_converter: 2.5.1` | BSD-3-Clause; recent verified publisher and current release signal | Flutter plugin for Android, iOS and Windows among other targets; no Dart dependencies, but platform APIs are involved | API exposes async encode/decode and availability checks; deterministic GBK, GB18030, PUA and malformed behavior across all three targets is unproven | Candidate for controlled cross-platform smoke; no selection |
| `fast_gbk: 1.0.0` | BSD-3-Clause metadata; unverified uploader and stale maintenance signal | Dart/Flutter package with broad platform labels and no required native toolchain | GBK encode/decode and `allowMalformed` are documented; no GB18030 or accepted PUA evidence | GBK-only candidate; no selection |
| `gbk_codec: 0.4.0` | MIT metadata; stale maintenance signal | Pure-Dart package; dependency and parser coupling require review | GBK API is documented; no deterministic GB18030, PUA or malformed-vector evidence | Candidate requiring full audit; no selection |
| `charset: 2.0.1` | Apache-2.0 metadata; older release signal | Pure-Dart Flutter package with broad platform labels | Claims GBK and related charsets; GB18030, PUA and malformed behavior are unproven | Candidate requiring full audit; no selection |
| Controlled pure-Dart implementation | License, maintenance and compatibility would be created by the project | No package/native toolchain, but substantial implementation and test burden | All vectors could be specified, but correctness and maintenance evidence do not yet exist | Deferred; no selection |

Evidence links: [`charset_converter`](https://pub.dev/packages/charset_converter/versions),
[`fast_gbk`](https://pub.dev/packages/fast_gbk/versions),
[`gbk_codec`](https://pub.dev/packages/gbk_codec/versions), and
[`charset`](https://pub.dev/packages/charset/versions).

For every candidate, the eventual decision record must include an exact
version, license/archive evidence, maintenance, Dart/Flutter compatibility,
GBK and GB18030 mappings, PUA behavior, malformed-input behavior, native or
toolchain requirements, and the resolved transitive graph.

### Question C — upgrade `sqlite3`

Changing `sqlite3` to a version compatible with `hooks <2.1.0` is a separate
decision. Before considering it, review:

* Drift code-generation and runtime compatibility;
* SQLite database compatibility and native ABI behavior on iOS, Android and
  Windows; and
* migration, rollback and packaged-storage risk.

No `sqlite3` upgrade is selected or performed by this amendment.

## Preserved architecture requirements

The unresolved dependency choice does not change the accepted pipeline:

```text
bounded bytes + trusted evidence
             -> source-neutral decoder
             -> DecodedDocument provenance
             -> source-neutral HTML parser
             -> provider-neutral structures
```

The decoder must retain selected encoding, evidence/reason and safe failure
metadata. It must remain independent from HTML parsing, provider selectors and
domain models. The parser accepts decoded text and must never parse raw bytes,
perform I/O, create UI/Reader/persistence state, or couple to provider runtime
or authentication.

## Rejected shortcuts

* Treating GBK as GB18030 is rejected because it violates the frozen PUA and
  encoding semantics.
* Falling back to UTF-8 is rejected because it silently corrupts legacy bytes.
* Ignoring PUA characters is rejected because `aaa1 -> U+E000` is mandatory.
* Overriding Pub constraints manually is rejected because it breaks reproducible
  builds.
* Forking a package immediately is rejected because its behavior and
  maintenance burden have not been evaluated.

## Required follow-up evidence

Before F3.4 implementation resumes, a Human-approved amendment must identify
one realizable dependency/compatibility path and provide:

1. a satisfiable repository lockfile graph;
2. exact license and transitive dependency evidence;
3. native/toolchain implications for all target platforms;
4. independent proofs for all F3.2 encoding vectors, including GBK PUA;
5. strict/replacement behavior and query-encoding proofs; and
6. a deterministic compatibility test plan without public-provider requests.

Until then, F3.4 remains **BLOCKED — DEPENDENCY COMPATIBILITY REVIEW REQUIRED**.
