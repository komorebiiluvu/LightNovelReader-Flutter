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

### Question C — change / potentially downgrade `sqlite3`

Changing `sqlite3` to a version compatible with `hooks <2.1.0` is a separate
decision. The compatibility investigation must consider a change or potential
downgrade from the current `sqlite3: 3.6.0`; it must not assume that an upgrade
is the available direction. Before considering any change, review:

* Drift code-generation and runtime compatibility;
* SQLite database compatibility and native ABI behavior on iOS, Android and
  Windows; and
* migration, rollback and packaged-storage risk.

No `sqlite3` change or downgrade is selected or performed by this amendment.

## Charset compatibility investigation — 2026-09-18

This section records reproducible probes performed outside the repository. No
package was added to this repository and no production decoder was written.
The probes used the frozen F3.2 vectors:

```text
GBK / legacy Windows CP936-compatible: d6d0cec4d0a1cbb5 -> 中文小说
GBK / legacy PUA:                     aaa1             -> U+E000
GB18030:                              81308130         -> U+0080
invalid strict:                       8130ff           -> failure
truncated strict:                     813081           -> failure
query encoding:                       中文小说          -> d6d0cec4d0a1cbb5
```

The `aaa1` vector is retained exactly as frozen. The evidence below calls it
legacy Windows CP936-compatible / legacy GBK-compatible where that is more
precise than claiming that every platform implements the same standards-only
GBK table. GB18030 remains a distinct codec and is never substituted for GBK.

### Candidate A — `charset_converter: 2.5.1`

Archive and package evidence:

* The pub archive contains a BSD-3-Clause `LICENSE`, has no Dart package
  dependencies, requires Dart `^3.12.0` and Flutter `>=3.44.0`, and declares
  Android, iOS, Windows, Linux and macOS plugin implementations.
* The repository's Flutter 3.47.4 toolchain satisfies the package floor. A
  temporary Flutter project containing `charset_converter: 2.5.1` and the
  repository's `sqlite3: 3.6.0` resolved successfully, so the direct graph is
  **PASS**. This is a graph result only; it does not approve the package.
* Android delegates to `java.nio.charset.Charset`; iOS delegates to
  CoreFoundation/NSString; Windows delegates to Win32 code pages. These are
  different native conversion surfaces, not one shared codec implementation.

The controlled Windows desktop smoke used the package's actual plugin. Its
results were:

| Vector / behavior | Windows result |
| --- | --- |
| Chinese legacy bytes | **PASS** through `gb2312` (Win32 code page 936) |
| `aaa1 -> U+E000` | **PASS** through `gb2312`; **PASS** through `GB18030` |
| `81308130 -> U+0080` | **PASS** through `GB18030` |
| Chinese encode/query bytes | **PASS** through `gb2312` and `GB18030` |
| strict invalid/truncated input | **FAIL**: Win32 flags used by the plugin returned replacement/legacy code points instead of a deterministic exception |
| replacement behavior | **UNPROVEN as a contract**: replacement occurred on Windows, but no explicit replacement mode exists |
| `GBK`, `CP936`, `windows-936` labels | **FAIL** on Windows: plugin lookup rejected these labels |
| `gb2312` label | **PASS** as the package's Windows alias for code page 936 |
| `windows-54936` label | **FAIL** on Windows; `GB18030` is the available label |

Android's packaged charset list includes `GBK` and `GB18030` and the source
uses `Charset.forName`, while iOS's list includes `cp936`, `gb2312` and
`gb18030` and the source uses CoreFoundation name conversion. No Android
device/emulator or iOS runtime was available for this investigation, so the
mandatory vectors and malformed-input behavior on those two targets remain
**UNPROVEN**. The platform-specific labels therefore cannot be frozen from
static inspection alone. Evidence: [package versions](https://pub.dev/packages/charset_converter/versions),
[API documentation](https://pub.dev/documentation/charset_converter/latest/charset_converter/),
and the exact 2.5.1 archive source.

Candidate A is therefore **not selected**. It is a possible future path only
if a new decision accepts canonical per-platform labels, defines one explicit
strict/replacement contract above the plugin, and supplies Android and iOS
runtime evidence for every mandatory vector.

### Candidate B — `charset: 2.0.1`

The exact archive is Apache-2.0 and pure Dart with no runtime dependencies.
The probe confirmed Chinese GBK decode, `aaa1 -> U+E000`, Chinese encode, and
strict failure for invalid and truncated sequences. Its `GbkCodec` also exposes
`allowMalformed: true` and emits U+FFFD. However, its label map aliases
`gb18030` to the same GBK codec: `81308130` did not decode to U+0080. This is a
deterministic **FAIL** for the required GB18030 vector, even though its GBK
behavior is otherwise useful. Candidate B is **not sufficient** as the sole
decoder.

### Candidate C — `fast_gbk: 1.0.0`

The exact archive is BSD-3-Clause and pure Dart with no runtime dependencies,
but the package is an old release with an unverified uploader and a package SDK
constraint below Dart 3. The current Dart 3.13.3 probe still resolved it and
confirmed Chinese GBK decode, `aaa1 -> U+E000`, Chinese encode, strict failure,
and U+FFFD replacement through `GbkCodec(allowMalformed: true)`. It provides
GBK only and has no GB18030 four-byte implementation; `81308130` is therefore
a deterministic **FAIL**. Candidate C is **not sufficient** as the sole
decoder.

### Candidate D — `gbk_codec: 0.4.0`

The exact archive is MIT and pure Dart, but it directly depends on `html` and
ships HTML-related conversion artifacts. That couples a decoder candidate to
the parser dependency boundary. The probe decoded Chinese and encoded the
query vector, but returned a non-PUA character for `aaa1`, decoded the
GB18030 vector as ordinary GBK text, and did not fail deterministically for
invalid or truncated input. These are **FAIL** results for PUA, GB18030 and
strict malformed behavior. Candidate D is rejected for both semantic and
architectural reasons.

### Existing `charset_codec: 0.1.1`

The exact accepted candidate remains the strongest pure API match for the
GB18030 vector, strict failures, U+FFFD replacement mode and deterministic
encoding. The probe also reconfirmed its GBK PUA failure (`aaa1` is rejected),
and its native Rust hook requires `hooks >=2.0.2 <2.1.0`. `dart pub outdated`
reported no newer resolvable `charset_codec` release; only its transitive
toolchain packages have newer releases. No compatibility override or fork is
proposed.

### Empirical score matrix

`PASS` means the exact probe or archive evidence establishes the behavior;
`FAIL` means it contradicts a mandatory requirement; `UNPROVEN` means the
required target runtime or contract was not observed; `N/A` means the vector is
outside that candidate's declared scope.

| Requirement | `charset_codec 0.1.1` | `charset_converter 2.5.1` | `charset 2.0.1` | `fast_gbk 1.0.0` | `gbk_codec 0.4.0` |
| --- | --- | --- | --- | --- | --- |
| Chinese legacy decode/encode | PASS | PASS on Windows via `gb2312`; Android/iOS UNPROVEN | PASS | PASS | PASS |
| `aaa1 -> U+E000` | FAIL for GBK; PASS for GB18030 | PASS on Windows via `gb2312`; Android/iOS UNPROVEN | PASS | PASS | FAIL |
| GB18030 `81308130 -> U+0080` | PASS | PASS on Windows; Android/iOS UNPROVEN | FAIL | FAIL | FAIL |
| strict invalid/truncated | PASS | FAIL on Windows; Android/iOS UNPROVEN | PASS | PASS | FAIL |
| explicit replacement mode | PASS | UNPROVEN as a common contract | PASS | PASS | FAIL |
| fixed aliases across targets | UNPROVEN | FAIL on Windows; Android/iOS UNPROVEN | FAIL (`gb18030` aliases GBK) | N/A | N/A |
| deterministic query encoding | PASS | PASS on Windows; Android/iOS UNPROVEN | PASS | PASS | PASS |
| graph with current `sqlite3 3.6.0` | FAIL (`hooks` conflict) | PASS in temporary Flutter graph | PASS | PASS | PASS, with `html` coupling |
| license / shape | MIT; native Rust hooks | BSD-3-Clause; native platform APIs | Apache-2.0; pure Dart | BSD-3-Clause; pure Dart | MIT; pure Dart plus `html` |
| disposition | blocked by PUA and graph | conditional candidate only | GBK-only | GBK-only | rejected |

No candidate currently satisfies every mandatory vector, one explicit error
contract and all three target runtimes with a repository-compatible graph.

### sqlite3 compatibility evidence

The repository currently pins `sqlite3: 3.6.0`, whose resolved graph requires
`hooks ^2.2.0`; this conflicts with `charset_codec 0.1.1`, which requires
`hooks >=2.0.2 <2.1.0`. This remains a real resolution failure.

Temporary exact-version probes showed that `sqlite3` 3.5.2, 3.5.1, 3.5.0,
3.4.0 and 3.3.4 can resolve with `charset_codec 0.1.1` and select `hooks
2.0.2`. That establishes **graph compatibility only**. It does not establish
Drift API compatibility, database migration safety, SQLite ABI equivalence,
packaged-storage behavior or rollback safety. Those are a separate Human
decision before changing or potentially downgrading `sqlite3`; this amendment
does not select any version and does not modify project dependencies.

### Controlled pure-Dart feasibility

The [WHATWG Encoding Standard](https://encoding.spec.whatwg.org/) defines GBK
and GB18030 as separate legacy multi-byte encodings, separate label rules,
stateful decoder/encoder algorithms and explicit `replacement`/`fatal` error
modes. A controlled Dart implementation would need an authoritative GB18030
index/range table, a reviewed CP936/legacy-GBK compatibility overlay for the
frozen PUA vector, reverse maps for encoding, streaming state and the exact
strict/replacement diagnostics. The tables and tests would be a material
binary/data addition and their provenance and license would need review.
This is feasible in principle but remains **UNPROVEN**, unimplemented and
deferred; no table was generated in this investigation.

### Investigation disposition

The amendment remains **PROPOSED — ADDITIONAL PLATFORM EVIDENCE REQUIRED**.
The investigation does not select a dependency, authorize an alias shim,
approve a `sqlite3` change, add a pure-Dart implementation or unblock F3.4.
The next Human decision must choose one complete path and require the missing
Android/iOS or compatibility evidence before implementation.

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
