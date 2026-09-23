# F3.6 Legacy reconciliation evidence

Status: **IMPLEMENTED / HUMAN REVIEW REQUIRED**

This slice implements the source-neutral reconciliation foundation for preserved
legacy reading progress. It does not accept F3.6, start F3.7, or approve F3 Exit.

## Resolution policy

`LegacyChapterReconciliationPlanner` resolves a legacy chapter ordinal only when
all reviewed candidates have:

- the same non-empty catalog digest recorded by the legacy locator;
- the same source-aware `SourceBookRef` as the preserved locator; and
- one unambiguous chapter at the preserved index.

A title, volume label, chapter count, current catalog, or numeric-looking ID is
never sufficient by itself. Missing or mismatched digest evidence is unresolved;
wrong-source/book candidates, duplicate index evidence, and mixed mapping versions
remain conflicts. Candidate evidence is retained in the resolution plan for review.

The plan carries a mapping version on every candidate. This prevents evidence from
different mapping revisions being silently combined. No provider selector,
network call, credential, cookie, or raw secret enters the reconciliation layer.

## Atomic application

`LegacyProgressReconciliationRepository.compareAndApply` applies a resolved
replacement only when the stored progress still equals the expected snapshot. It
returns `notFound`, `unchanged`, `conflict`, or `applied` and performs the read/
compare/write inside one Drift transaction. Repeating an already-applied plan is
idempotent; a later user edit wins and blocks the stale plan. The original dataset,
legacy book key, ordinal, fraction, catalog digest, and safe evidence fields remain
attached to the replacement locator.

## Source neutrality evidence

The focused tests use opaque, nonnumeric, delimiter-bearing and Unicode IDs,
identical book IDs across different sources, reordered chapters, duplicate
candidates, and a fake repository. They exercise the same domain planner and
repository boundary used by any Source adapter; no second real Source is added and
no Wenku8-specific branch exists in Core or Domain reconciliation code.

## Validation

- focused reconciliation tests: recorded with the implementation commit
- full suite: required before Human F3.6 review
- static analysis and formatting: required before Human F3.6 review
- F3.7 platform/exit evidence: still pending
