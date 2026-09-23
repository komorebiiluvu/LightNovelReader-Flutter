# F3.4.4 Wenku8 Pure Parser Foundation

Status: **IMPLEMENTED / ACCEPTED**. The Human project owner accepted the
complete F3.4 implementation at baseline
`c72842e7c3151b6ba5693fdcf2e255ef2e3b689f` on **2026-09-23**, after accepting
the F3.4.1–F3.4.3 foundations.

## Boundary

The parser consumes only the generic `ParsedHtmlDocument` produced from an
explicitly decoded `DecodedDocument`. It handles search, Explore, pagination,
detail, catalog and ordered chapter content. It performs no I/O, request
execution, login/session work, persistence or Reader/UI work. The approved
`html: 0.15.7` dependency stays inside `lib/src/source/html/`; Wenku8 code
does not import package DOM types.

Outputs use immutable `SourceParsed*` structures under `lib/src/source/parser/`,
not Wenku8 model types or F2 domain entities. Provider book,
chapter and volume keys remain opaque strings. An ordinal is recorded only as
order. A label-only group keeps its label and has no volume key. Image locators
are retained as raw evidence without an AssetId, resolved URL, image request,
download or cache object. F3.5 must explicitly map verified provider evidence
to source-aware F2 refs.

The generic HTML layer supplies immutable element attributes and subtree node
ranges. Its fragment mode preserves HTML5 context, including `td` fragments.
All parser failures use fixed typed categories and allowlisted field/reason
codes; diagnostics omit HTML, titles, locators, cookies and server text.

## Deterministic fixture evidence

`test/source/wenku8/wenku8_parser_test.dart` decodes committed raw fixture
bytes with the controlled charset layer, builds a generic HTML document, then
compares parsed values against independently authored F3.2 expected sidecars.
It covers all HTML/bin search, Explore, pagination, detail, catalog and content
fixtures, excluding only transport/status metadata and F3.6 reconciliation
records. It checks the exact six-node
`Text / Text / Image / Text / Image / Text` case, repeated images, valid empty
content, malformed/missing containers, page chrome exclusion, deduplication,
stable IDs across reordering, flat catalog, stable volumes and label-only
grouping.

The focused F3.2 fixture, charset, HTML and Wenku8 foundation selection passed
**69 tests** at the F3.4 acceptance checkpoint; the full suite passed
**514 tests**. Dart format, Flutter analysis and `git diff --check` passed.
These are deterministic local checks on Windows; they do not claim Android or
iOS runtime proof.

Some F3.2 sidecars include pagination or Explore descriptor values absent from
their raw HTML. Tests pass that separately authored request/descriptor context
explicitly where needed and assert that HTML lacking pagination evidence yields
no parser-derived cursor or exhausted state. A separately supplied pagination
object is tested only as context passthrough, not as independently parsed
evidence. The parser does not infer a stable block ID from absent bytes. A
title-less table fragment proves cell
boundaries independently from complete detail parsing, which still requires a
title. This division prevents the fixture corpus from silently promoting
missing evidence into identity or pagination state.

Authentication cookie fixtures, transport timeout/status fixtures, host policy
metadata and reconciliation records are owned by F3.3, F3.5 or F3.6 and are
not claimed as pure HTML parser tests. No public-provider request is required.

## Remaining gates

F3.4 is accepted. Windows charset runtime evidence is PASS; Android and iOS
charset runtime evidence remain **UNPROVEN**, not waived. Fresh deterministic
Android and iOS evidence remains an F3.7/F3 Exit requirement. F3.5 is
authorized and remains **IMPLEMENTED / HUMAN REVIEW REQUIRED** until its own
human review. F3.6–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains
**NOT APPROVED**.

## Post-acceptance frozen-Legacy structure correction — 2026-09-23

F3.5 preparation compared the accepted parser to frozen Legacy commit
`d90d4d090c85a0a9c374684696c34befe12636d1`, specifically
`Wenku8DataSource.kt` `getBookVolumes`. The original F3.2 catalog fragments
used simplified `/novel/<book>/<chapter>` links. Frozen Legacy also consumes
table rows with `td.vcss[vid]` volume markers and relative `<chapter>.htm`
links. A separate, explicitly reconstructed fixture and independently authored
expected sidecar now prove that structure, including stable volume IDs, labels
and three distinct chapter IDs. The test pins both LF-normalized UTF-8 text
hashes (these supplemental examples are structural, not byte-encoding vectors).
It is not
presented as a live capture. The pure parser now supports both shapes without
using an ordinal as identity. This corrective regression was included in the
accepted F3.4 baseline; it does not authorize F3.6, image retrieval beyond the
F3.5 ephemeral locator boundary, or F3 Exit.
