# ADR 0008 — Agent review and milestone validation cadence

Status: **ACCEPTED**

Decision date: **2026-10-10**

Revision 2: **2026-10-11**, accepted on the project owner's explicit cadence
clarification. This revision changes review and test frequency, not technical
exit criteria or the meaning of platform evidence.

Authority: **Human project owner instruction**, delegating future code review, architecture review, slice acceptance, and phase approval to the Agent.

## Context

The previous process required a separate human approval after each small slice
and ran the full GitHub Actions platform matrix on every push. That cadence
slowed implementation even when the change was local and reversible. The owner
explicitly requested Agent review and approval, with CI and packaged smoke at
major milestones or when a substantial change warrants them.

## Decision

- The Agent reviews each code diff for scope, contract fit, data/security risk,
  and meaningful tests. Routine implementation tasks within an authorized
  phase may advance after that review without a separate slice-approval commit.
  A formal, separate review record is required at each phase exit and whenever
  an accepted contract explicitly gates a slice or a normative decision. The
  phase record names the tested baseline, evidence, unresolved risks and PASS
  or precise blockers. Implementation alone never implies phase acceptance.
- ADRs remain required for normative architecture, dependency, or contract
  changes. The Agent may approve them after recording compatibility, security,
  migration, and cross-platform evidence appropriate to the risk. This
  delegation changes approval authority, not the architectural constraints.
- Routine code changes receive diff review, formatting, analysis, and focused
  tests. Full local tests run for broad changes, shared boundaries, and phase
  exits. The complete CI/platform smoke matrix is normally dispatched **once
  for a phase-exit candidate**, not after every fix, commit, or slice. An
  earlier targeted run is justified only when local checks cannot safely
  bound a concrete platform, dependency, persistence, or security risk that
  must be resolved before more work. The Agent records that reason and the
  exact tested revision. Platform work may continue while a dispatched run is
  pending; the phase cannot receive a platform PASS before the result exists.
- Platform results retain their exact meaning. `UNPROVEN`, incomplete, failed,
  and waived evidence are never relabeled `PASS`. F3's deterministic iOS,
  Android, and Windows runtime gate and all other frozen exit criteria remain.
- Past human approvals and their tested revisions remain unchanged. This
  decision applies prospectively from its acceptance date. The project owner
  may override it for a specific task or revoke the delegation.

## Consequences

The Agent can advance work without waiting for another owner message after a
documented review. Milestone records remain auditable. Fewer CI runs reduce
feedback on intermediate commits, so focused local tests and explicit risk
review carry more weight until the next milestone matrix. A relevant CI failure
at a required gate still blocks that gate until resolved or explicitly
dispositioned in a documented decision.

The owner expressly asked to let CI and smoke run asynchronously and to
concentrate formal acceptance at major phase boundaries. The current F3
deterministic three-platform exit matrix remains required; this cadence change
does not convert pending or stalled results into PASS.

## Revision 2 Agent review

Decision: **ACCEPTED** under the owner's 2026-10-11 instruction. The revision
removes repeated slice-level approval paperwork and routine intermediate CI
dispatches. It leaves the Constitution's phase-exit review, F3's mandatory
three-platform deterministic runtime gate, dependency/architecture ADRs, and
data/security invariants intact. `GOVERNANCE.md`, `AGENTS.md`, and `TESTING.md`
are synchronized in this documentation change. Existing F3 CI runs may finish
asynchronously; only a run against the reviewed code candidate can support
F3 Exit.
