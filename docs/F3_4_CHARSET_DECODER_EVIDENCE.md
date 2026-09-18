# F3.4 Charset Decoder Foundation Evidence

Status: **IMPLEMENTED — HUMAN REVIEW REQUIRED**. This document records the
charset-only implementation authorized by ADR 0007. It does not authorize the
HTML parser, Wenku8 parser, request builder, Source runtime, or F3.5.

## Boundary and modes

The runtime boundary is:

```text
RawBytes -> CharsetDecoder -> DecodedDocument
```

`RawBytes` validates and owns an immutable byte sequence. `DecodedDocument`
contains Unicode text, the selected `SourceEncoding`, the caller's bounded
selection evidence, and replacement count/offset metadata. Strict failures are
typed `CharsetDecodeException` values containing only the encoding, failure
kind, and byte offset. No raw bytes, response text, cookies, credentials or
tokens are copied into diagnostics.

The only core modes are `utf8`, `legacyCp936Compatible`, and `gb18030`.
External labels are normalized at one boundary; the decoder and encoder accept
the enum rather than arbitrary charset strings. The legacy mode is deliberately
separate from GB18030. It uses the WHATWG two-byte index and keeps the frozen
CP936-compatible private-use mapping.

Encoding is intentionally narrow. UTF-8 is complete. LegacyCP936Compatible
uses the indexed two-byte mappings plus ASCII. GB18030 uses those two-byte
mappings and the pinned four-byte range algorithm. Unsupported characters fail
with a typed encoding error; no replacement, dropping, or UTF-8 fallback is
performed.

## Generated data provenance

`tool/charset/source/index-gb18030.txt` and
`tool/charset/source/index-gb18030-ranges.txt` are pinned WHATWG Encoding
Standard inputs dated 2024-09-18. Their source identifiers are recorded in the
files and in `gb18030_data.g.dart`:

| Input | SHA-256 | Rows |
| --- | --- | ---: |
| `index-gb18030.txt` | `746b3c55f1a8ec4b90b451f384437a17fd37cd51cd668456a28071a758d10784` | 23,940 |
| `index-gb18030-ranges.txt` | `874c6b6f6f74cf7d427ad228d5b41ddd9354fffd92a2259bf429f86e6baa7a1e` | 207 |

`tool/charset/generate_tables.dart` reads only those pinned files and emits
the dense two-byte index, a sorted first-pointer reverse map, and the
four-byte range arrays. It verifies contiguous source pointers. The generated
file records the source revision/date, hashes, license and fixed generation
parameters. The source is covered by the WHATWG CC BY 4.0 notice; incorporated
data follows the standard's BSD-3-Clause notice. Generated project code follows
the repository's project-source terms. No table is fetched at runtime.

## Independent vectors

The expected values in `test/source/charset/charset_codec_test.dart` are
authored independently from the generated arrays:

| Mode | Bytes | Expected text | Encode result |
| --- | --- | --- | --- |
| LegacyCP936Compatible | `d6d0cec4d0a1cbb5` | `中文小说` | same bytes |
| LegacyCP936Compatible | `aaa1` | `U+E000` | same bytes |
| GB18030 | `81308130` | `U+0080` | same bytes |

The same tests prove strict failure for malformed `8130ff` and truncated
`813081`, and replacement mode produces visible `U+FFFD` characters with
deterministic byte offsets. UTF-8 malformed handling and unpaired UTF-16
encoder input are also covered.

## Platform gate

The codec has no platform imports, native channel, or platform conditional.
The deterministic codec suite therefore executes the same Dart implementation
on every target. Windows evidence is available in this checkout: the focused
suite runs on the Windows Dart VM and passes. Android evidence is a debug APK
compile PASS with the configured API 36 SDK; the first attempt exposed a
pre-existing `jni 1.0.3` CMake path issue caused by the non-ASCII user cache
path, and the same unchanged repository built successfully with an ASCII
temporary Pub cache. There is no Android emulator/device on this host, so
Android runtime vector execution remains an evidence gap. iOS runtime evidence
is also an evidence gap because this Windows host has no iOS simulator or
macOS build runner. These gaps are explicit and must be resolved by the F3.4
platform gate; no parser work may start while either required target evidence is
missing.

## Scope exclusions

This change contains no HTML/DOM parser, Wenku8 parser or request builder, no
Source runtime, no network or authentication path, no persistence, no Reader
work, no new dependency, and no F3.5 implementation.
