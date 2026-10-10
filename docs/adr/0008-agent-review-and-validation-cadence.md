# ADR 0008 — Agent review and milestone validation cadence

Status: **ACCEPTED**

Decision date: **2026-10-10**

Authority: **Human project owner instruction**, delegating future code review, architecture review, slice acceptance, and phase approval to the Agent.

## Context

The previous process required a separate human approval after each small slice
and ran the full GitHub Actions platform matrix on every push. That cadence
slowed implementation even when the change was local and reversible. The owner
explicitly requested Agent review and approval, with CI and packaged smoke at
major milestones or when a substantial change warrants them.

## Decision

- The Agent performs and records a separate review before accepting a slice or
  phase. The record names the baseline, scope, relevant checks, unresolved
  risks, and its approval or blockers. The Agent may authorize the next slice
  after the review. Implementation alone never implies acceptance.
- ADRs remain required for normative architecture, dependency, or contract
  changes. The Agent may approve them after recording compatibility, security,
  migration, and cross-platform evidence appropriate to the risk. This
  delegation changes approval authority, not the architectural constraints.
- Routine code changes receive diff review, formatting, analysis, and focused
  tests. Full local tests run for broad changes, shared boundaries, and phase
  exits. The complete CI/platform smoke matrix runs at phase exits and for
  material platform, dependency, persistence, or security changes; it is not
  triggered on every push or pull request. The Agent dispatches it manually.
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
