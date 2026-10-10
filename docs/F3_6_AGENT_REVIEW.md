# F3.6 Agent review — 2026-10-10

Decision: **NOT ACCEPTED — BLOCKERS**

Reviewed implementation baseline: `5e784dc971afcc8b5b1a4499ecaeeb2a47080d4d`

Reviewer: Agent, under accepted ADR 0008. This review does not authorize F3.7
or approve F3 Exit. The reconciliation service currently has no production
caller, so the defects below have not been applied to user progress.

## Blocking findings

1. The planner treats a matching catalog digest as proof of contemporaneity.
   Section 7 of `F3_ENTRY_CONTRACT.md` explicitly says that a candidate digest
   alone is insufficient. The current F2 importer records only an ordinal and
   fraction for imported progress; it does not populate the digest or trusted
   remote ID. Resolution must remain unresolved until a reviewed provenance
   path proves the remote ID or the catalog was captured contemporaneously.
2. `LegacyChapterReconciliationService.apply` does not require the plan's
   locator to equal the expected progress locator. A plan for another snapshot
   can therefore be submitted with an otherwise current expected progress.
   It also replaces `remoteIdEvidence` with the selected chapter ID, losing the
   original field value if it existed. Preserve the exact original locator.
3. The accepted contract requires atomic application with a receipt and
   mapping version. The current transaction updates progress but stores no
   durable reconciliation receipt/version. The existing schema has no chapter
   reconciliation receipt slot. Propose and review a schema/migration design
   before implementing any durable extension; do not use a hidden side store.
4. The seven focused tests do not yet prove the full section 7 neutrality and
   recovery matrix: fake Source conformance, unsupported auth, alternate
   grouping/pagination, image-only content, reopen/rollback, and the
   fixture-backed Wenku8 adapter.

## Existing evidence and next decision

The seven focused tests, 546-test local suite, formatting, and analysis passed
at the implementation checkpoint. Those checks establish that the code builds
and current cases pass; they do not satisfy the missing proof and receipt
contract. Fix the blockers with focused tests and a reviewed schema decision if
needed, then conduct a separate Agent review. F3.7 remains **NOT AUTHORIZED**;
Android and iOS charset runtime evidence remain **UNPROVEN**.
