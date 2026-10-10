# F3.6 Legacy reconciliation evidence

Status: **REMEDIATION IMPLEMENTED / AGENT REVIEW PENDING**

This slice implements source-neutral legacy progress reconciliation. F3.7 and
F3 Exit are not approved by this evidence record.

## Proof and identity

The existing F2 importer stores an ordinal and fraction, without a trusted
remote chapter ID or contemporaneous catalog. Such locators remain unresolved.
The planner requires a verified capture proof before resolving. The capture
verifier checks a bounded, strict source-neutral JSON envelope against a trusted
SHA-256 artifact digest, the exact original locator, dataset, source/book,
mapping version and either an original progress remote ID or an explicit
co-captured catalog mapping. A later catalog, title, count or matching digest
alone cannot create a proof. The persistence boundary also requires a completed
migration run with the same dataset, digest and mapping version before applying.

The original `LegacyChapterLocatorV1` is retained byte-for-byte at the domain
level. Chapter ordinal remains ordering evidence, never a modern ChapterId.
Unresolved/conflict plans retain their safe alternatives for review. No Source
specific branch is present in Core or Domain.

## Atomic receipt and schema v2

Accepted ADR 0009 defines an additive Drift schema v2. A versioned upgrade
preserves v1 data, locators and progress; injected failure rolls back to intact
v1. Applied reconciliation stores an immutable typed receipt, mapping version,
proof kind/digest and ordered candidate alternatives. The receipt pointer and
chapter progress update occur in the same expected-current-state transaction.
Repetition is a no-op; stale plans and later user edits conflict. A normal user
progress save clears the active receipt pointer while retaining the historical
receipt. Close/reopen and cross-book foreign-key tests prove durable ownership.

## Source neutrality

Shared conformance checks run against two test-only Sources with identical
opaque book/chapter IDs across different SourceIds, delimiter and Unicode IDs,
label-only grouping, reversed provider ordinals, unsupported authentication,
paginated search and image-only content. The same catalog/content invariants
run against the fixture-backed Wenku8 adapter, including the six-node ordered
content fixture. No second real Source is added.

## Validation status

Focused reconciliation, persistence migration, and neutrality tests pass on
Windows. Full local suite, generated-schema verification, and the appropriate
manual platform CI are required before a final Agent F3.6 review decision.
Android and iOS charset runtime evidence remain UNPROVEN for F3.7.
