# Contract Freeze Plan

This document identifies decisions that may remain open during F1 but must be finalized before the phase that depends on them.

| Contract / Decision | Must be finalized before | Minimum content required |
| --- | --- | --- |
| Cross-platform dependency support matrix | F1 implementation dependencies are added | iOS/Android/Windows support, maintenance, fallback |
| Persistent database/package choice | F2 | target support, migration/versioning strategy |
| Legacy iOS import commitment | F2 migration implementation | which assets are imported and failure semantics |
| Source identity/model v1 | before dependent F2 persistence implementation; accepted by F2 exit | opaque IDs, source-aware references, persistence serialization rules |
| Ordered ContentNode / ChapterContent v1 | before dependent F2 model/serialization implementation; accepted by F2 exit | one ordered sequence, text/image nodes, versioning, unknown-content policy, minimal opaque asset reference |
| Source capability and unsupported-operation semantics | F3 | capability declaration, call behavior, structured failure |
| Source transport/session contract | F3 | headers, cookies, redirect, retry, cancellation, diagnostics |
| F3.3 critical dependency selection | before dependency-using F3.3 implementation | exact network and secure-storage packages, platform/toolchain evidence, cookie decision, license and fallback policy |
| Reader logical position/anchor model | F4 | cross-renderer position, restore, content/layout changes |
| Reader renderer event contract | F4 | next/previous/scroll/page/cancel/transition ownership |
| Page-curl visual acceptance reference | F5 | reference samples + behavioral acceptance criteria |
| Image request/cache contract | F6 | identity, headers/session, dedup, cache, cancellation |
| Download/offline completeness contract | F6 | required assets, partial/failure state, restart semantics |
| Export completeness/error policy | F7 | missing chapter/image behavior and user-visible result |
| Second-source neutrality acceptance | F8 | criteria proving no Wenku8-specific core branching |
| Plugin API v1 | before F9 production plugin host implementation | frozen manifest, host API, and output schema |
| Plugin runtime technology | F9 | iOS/Android/Windows support, sandbox feasibility |
| Plugin execution/resource quotas | F9 | timeout/termination, output validation, resource limits |
| Plugin permission-upgrade semantics | F9 | install/update permission behavior |
| Quantified performance thresholds | F11 | representative devices/workloads/statistics/limits |
| Release support matrix and minimum OS versions | before first public release candidate | exact OS versions, install/upgrade support |

Rule:

A contract listed here does not block F1 unless F1 itself depends on that decision.

Before the corresponding phase begins, move the contract from “planned” to a reviewed module specification or accepted ADR.

## F2 proposal checkpoint — 2026-09-16

The [F2 Entry Contract](F2_ENTRY_CONTRACT.md) consolidates the proposed identity,
ordered-content, persistence responsibility, migration commitment and test/exit
contracts. [ADR 0003](adr/0003-f2-persistence-stack.md) proposes the database stack
and migration boundary. The [frozen legacy data inventory](legacy/swift/LEGACY_DATA_MIGRATION_INVENTORY.md)
supplies the observed data formats and iOS container feasibility evidence.

The entry contract and ADR were **ACCEPTED** by the human project owner on
2026-09-16. Current implementation status is **F2.1 IMPLEMENTED / ACCEPTED;
F2.2 IMPLEMENTED / ACCEPTED; F2.3 EXIT APPROVED; F2.4 EXIT APPROVED; F2.5
EXIT APPROVED; F2.6 EXIT APPROVED; F2.7 EXIT APPROVED**. F2.4
human exit approval on
**2026-09-17** is recorded in the
[Library / Groups Baseline](F2_4_LIBRARY_GROUPS_BASELINE.md).
F2.3 human exit approval on **2026-09-17** is recorded in the
[F2.3 Persistence Baseline](F2_3_PERSISTENCE_BASELINE.md).
This checkpoint does not advance the Source, Reader, image/offline, plugin or
performance freeze dates. F1 exit remains approved; F2 EXIT APPROVED on
**2026-09-17**.
F2.6 human exit approval on **2026-09-17** is recorded in the
[Migration Framework Baseline](F2_6_MIGRATION_FRAMEWORK_BASELINE.md).
F2.7 implementation evidence is recorded in the [F2.7 Legacy Import
Baseline](F2_7_LEGACY_IMPORT_BASELINE.md) and [F2 Exit Evidence](F2_EXIT_EVIDENCE.md).
F2 contracts now frozen/accepted within the completed F2 scope include Source
identity/model v1, ordered ContentNode / ChapterContent v1, persistence
stack/schema v1, and the legacy migration commitment/framework. Future
F3/F4/F5/F6/F7/F9/F11 freeze dates and ownership remain unchanged. F3.1 is
**IMPLEMENTED / ACCEPTED**; F3.2 authorization is recorded in the F3 Entry
checkpoint below. F3.3–F3.7 remain **NOT AUTHORIZED**.

## F3 Entry and F3.1 acceptance checkpoint — 2026-09-18

The [F3 Entry Contract](F3_ENTRY_CONTRACT.md) revision **2** and [ADR 0004](adr/0004-f3-source-foundation.md)
were accepted by the **Human project owner** on **2026-09-17**. They freeze the
Source capability, Catalog, transport/session, cancellation and security
semantics required before F3.1–F3.7. `SOURCE_API.md` is synchronized with the
accepted contract: Catalog is one capability; flat catalogs and grouping without
a stable VolumeId are defined without fabricating identity; cookies and updates
are infrastructure/update-hint semantics; and the second real Source remains an
F8 deliverable.

This checkpoint is **ACCEPTED**. F3 Entry is **APPROVED**. F3.1 is
**IMPLEMENTED / ACCEPTED** at baseline SHA
`36bb595f4e26591f07593c962f0a26ff1f587fbf`, approved by the Human project owner
on **2026-09-18**. Focused F3.1 tests: **31 passed**; full suite: **401 passed**;
CI run [35246451941](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35246451941)
completed successfully. F3.2 is **AUTHORIZED**. F3.3–F3.7 remain **NOT
AUTHORIZED** and F3 Exit remains **NOT APPROVED**. No network, secure-storage,
decoder/DOM or other dependency, production implementation beyond F3.1 or F3
exit is approved by this checkpoint. Deterministic three-platform validation is
the blocking F3 evidence; manual Wenku8 live smoke is supplemental and is not a
CI or F3-exit gate.

## F3.2 acceptance and F3.3 authorization checkpoint — 2026-09-18

The Human project owner approved F3.2 at baseline SHA
`37360101487db7904f9ef6c915724719ec90db25` on **2026-09-18**. F3.2 is
**IMPLEMENTED / ACCEPTED**. The accepted evidence contains 80 deterministic
fixtures and 80 independently authored expected sidecars, with 60 synthetic and
20 reconstructed-from-frozen-evidence entries. Classifications are PRESERVE 15,
FIX 23, REGRESSION_TEST 37, DEFER 5 and DROP 0. Audited byte vectors include
GBK Chinese `d6d0cec4d0a1cbb5`, GB18030 `81308130` → U+0080 and GBK PUA
`aaa1` → U+E000. The ordered-content corpus includes the explicit
Text / Text / Image / Text / Image / Text sequence. Whole-corpus raw,
manifest and expected-sidecar secret scanning passed. F2 opaque identity and
ordered `ChapterContent.nodes` semantics remain unchanged. Focused F3.2 tests:
**17 passed**; full suite: **418 passed**; format, analyze and diff checks passed.

CI run [35258020716](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35258020716)
was inspected for this baseline: Quality PASS, Android debug PASS, Android
packaged storage smoke PASS, Windows debug PASS, Windows packaged storage smoke
PASS, iOS debug build without signing PASS, iOS simulator boot PASS, and iOS
simulator packaged-storage smoke **STALLED / INCOMPLETE — NOT F3.2 BLOCKING**.
The stalled iOS packaged-storage smoke is not an iOS PASS and is not a reusable
F3 platform waiver. Fresh deterministic iOS runtime evidence remains required
at the appropriate later runtime/platform gate and must be resolved no later
than F3.7 before F3 Exit approval. No platform PASS is inferred from Android or
Windows.

F3.3 is **AUTHORIZED**. F3.4–F3.7 remain **NOT AUTHORIZED**. F3 Exit remains
**NOT APPROVED**. This authorization does not approve a networking or
secure-storage dependency; any critical dependency still requires its separate
ADR and explicit Human project owner approval under the accepted F3 contract.

## F3.3 dependency proposal checkpoint — 2026-09-18

[ADR 0005](adr/0005-f3-transport-security-dependencies.md) is **PROPOSED / NOT
ACCEPTED**. It records the exact candidate proposal `dio: 5.11.1` for network
transport, `flutter_secure_storage: 11.2.0` for secure storage, and no
cookie-management dependency. The proposal compares `http: 1.6.0`, records the
current Android API 24 floor, iOS 15.0 deployment target and Windows ATL
toolchain requirement, and defines the source-scoped cookie/security boundary.

F3.3 remains **AUTHORIZED as a slice**, but any implementation that adds or
uses a critical network or secure-storage dependency is blocked until ADR 0005
is accepted by the Human project owner. No package, lockfile entry or F3.3
runtime implementation is approved by this checkpoint. F3.4–F3.7 remain **NOT
AUTHORIZED** and F3 Exit remains **NOT APPROVED**. The accepted F3 Entry and
F3.1/F3.2 semantics are unchanged.

## F3.3 dependency approval checkpoint — 2026-09-18

[ADR 0005](adr/0005-f3-transport-security-dependencies.md) was **ACCEPTED** by
the **Human project owner** on **2026-09-18** at accepted baseline SHA
`13408a83ca58158a8e7d74d911a71c183eaff590`. The approved dependencies are
`dio: 5.11.1` and `flutter_secure_storage: 11.2.0`; no cookie-management
dependency is approved. The Android floor remains API 24, the iOS target
remains 15.0, and Windows ATL-backed packaged/runtime evidence remains required
during F3.3.

F3.3 remains **AUTHORIZED**, and dependency-using implementation is now
permitted within F3.3 only. F3.4–F3.7 remain **NOT AUTHORIZED** and F3 Exit
remains **NOT APPROVED**. No other HTTP, cookie-management or secure-storage
dependency is approved without a new or amended Human-approved dependency
decision.
