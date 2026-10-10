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

## Remediation review — 2026-10-10

Decision: **F3.6 IMPLEMENTED / ACCEPTED**. F3.7 is **AUTHORIZED** under
accepted ADR 0008. F3 Exit remains **NOT APPROVED**.

Reviewed implementation baseline: `9bfd153b9b87d4b0686b2306b3ab1e2f41ddc808`.
Reviewer: Agent. This is a separate review of the remediation, not the
implementation checkpoint above.

The original four blockers are closed:

1. A matching catalog digest alone no longer resolves a locator. A bounded
   capture verifier requires a trusted artifact digest, exact source/book and
   locator, mapping version, and either original recorded remote-ID evidence or
   a co-captured catalog. The F2 importer produces neither proof form, so its
   ordinal-only progress remains unresolved. The repository also requires a
   completed migration run for the same dataset, artifact digest and version.
2. Application requires the plan locator to equal expected progress and
   preserves the exact original locator, including `remoteIdEvidence`.
3. Accepted ADR 0009 defines the versioned Drift schema v2. The repository
   inserts an immutable receipt and ordered alternatives with the progress
   pointer in one transaction. v1 upgrade preservation, rollback, reopen,
   foreign-key, idempotency and user-edit conflict are tested.
4. Shared conformance covers two test-only Sources and fixture-backed Wenku8:
   opaque Unicode/delimiter IDs, same IDs across Sources, label-only grouping,
   differing order/pagination, unsupported auth and ordered/image-only content.
   No second real Source or provider branch was added to Core.

Validation at the reviewed baseline: format and `flutter analyze --no-pub`
passed; 13 focused reconciliation/neutrality tests passed; the full local suite
passed **555 tests**; generated Drift schema/code verification passed; `git
diff --check` passed. The final baseline differs from the 555-test run only by
a comment clarifying that a catalog digest is not contemporaneity proof.

Residual risk: the new receipt path has no production caller and no current F2
capture can resolve progress; this is a safe unresolved state, not an observed
user migration. Schema v2 and the Source runtime still need deterministic
packaged validation on all three target platforms at F3.7. Android and iOS
charset runtime vectors remain **UNPROVEN**. This review records no platform
PASS and grants no F3 Exit waiver. The complete matrix is reserved for F3.7,
consistent with the milestone cadence in ADR 0008.
