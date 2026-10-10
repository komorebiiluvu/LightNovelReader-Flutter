# ADR 0009 — F3 legacy chapter reconciliation proof and receipts

Status: **ACCEPTED**

Revision: **2** — Agent-reviewed hardening of co-capture marker persistence.

Decision date: **2026-10-10**

Review authority: Agent under ADR 0008. This decision addresses the blockers in
[the F3.6 review](../F3_6_AGENT_REVIEW.md); it does not approve F3.6 or F3 Exit.

## Context

F2 preserves an opaque legacy chapter ordinal and optional evidence. The actual
F2 importer currently writes only the ordinal and fraction to its locator. A
later catalog, matching title/count, or matching digest cannot establish which
remote chapter ID belonged to that ordinal when progress was recorded. The
existing F3.6 planner incorrectly treated matching digests as contemporaneity.
Its progress update also lacks a durable mapping receipt and version.

## Decision: proof before resolution

The resolver must default to `unresolved`. It may resolve only with a reviewed,
source/book/dataset-bound proof of one of these forms:

1. **Recorded remote ID:** the original progress artifact itself records the
   remote chapter ID. The verifier checks that value against the unchanged
   `LegacyChapterLocatorV1.remoteIdEvidence`, the target `SourceChapterRef`,
   and the artifact's verified digest. A remote ID copied from a later catalog
   does not qualify.
2. **Contemporaneous catalog:** a single verified capture artifact contains the
   progress ordinal and the catalog mapping together, with an explicit
   co-capture marker and matching source/book/dataset. The verifier checks the
   artifact digest, catalog digest, mapping version, and that exactly one
   chapter ID occupies the recorded ordinal. Merely importing a catalog in
   the same run, or comparing two independently captured digests, does not
   qualify.

The current F2 backup/snapshot importer has neither proof form. Its imported
locators therefore remain unresolved. No current Wenku8 fetch upgrades them.
The proof verifier is Source-neutral and accepts only independently reviewed
capture evidence; the Source catalog adapter cannot assert contemporaneity.
Conflicting remote ID evidence, changed source/book, mixed mapping versions, or
ambiguous ordinal mapping remains a conflict. The original locator is immutable.

## Decision: schema v2 receipt

Add an explicit, additive Drift schema v2 migration from accepted v1. It must
preserve all v1 rows and reject newer unknown versions. The new typed tables
are:

- `chapter_reconciliation_receipts`: immutable receipt ID, dataset/source/book,
  original locator ID, resolved chapter ID, mapping version, proof kind,
  verified artifact digest, optional catalog digest, and a SHA-256 digest of
  the co-capture marker. The raw marker is never persisted. A unique key prevents
  remapping one locator. A composite foreign key binds the receipt to the exact
  original locator.
- `chapter_reconciliation_candidates`: ordered, source-aware candidate chapter
  refs, legacy ordinal, catalog digest and mapping version for each applied
  receipt. This retains alternatives without arbitrary HTML, credentials or
  server messages.

`reading_progress` gains a nullable receipt pointer bound to the same
source/book. Verified application inserts receipt/candidates and updates the
progress chapter and receipt pointer in one transaction after an
expected-current-state comparison. Ordinary user progress writes clear a stale
receipt pointer. Repeating the same accepted mapping is a no-op; different
mapping/proof or a later user edit is a conflict. Receipt creation and progress
update roll back together on failure. No generic JSON side store is allowed.

The current `ReadingProgressV1` identity/content wire semantics remain
unchanged. The new pointer is repository provenance, not a Reader position.
The migration must have v1-to-v2 preservation, failed-upgrade rollback,
close/reopen, foreign-key, collision and idempotency tests. Generated Drift
code and schema snapshots are committed and verified. Because this changes
persistence, run the relevant full local suite and platform smoke at the F3.7
gate; a platform is not marked PASS before runtime execution.

## Alternatives rejected

- Treating a digest or current catalog as historical proof risks a wrong
  chapter identity.
- Reusing `remoteIdEvidence` as the resolved ID destroys raw evidence.
- Storing a receipt only in memory, logs, or an arbitrary side file cannot
  survive restart or be atomically checked with progress.
- Reusing F2 import receipts for chapter mappings changes their meaning and
  does not store a chapter-specific proof/version.

## Agent review

The design keeps every current imported locator unresolved until independently
verified evidence exists, preserves F2 wire models, and uses a versioned
additive migration with typed source-aware keys. It adds no dependency or
platform-specific business code. Accepted for F3.6 implementation; acceptance
of the implementation still requires separate code review and evidence.
