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

These documents are **PROPOSED, not accepted or frozen**. Explicit human approval
of the entry contract and ADR is required before any F2 production implementation.
This checkpoint does not advance the Source, Reader, image/offline, plugin or
performance freeze dates. F1 exit remains approved; F2 implementation has not begun.
