# Governance Specification v0.3

Status: **Active for Foundation Development**

This document defines how architectural rules are interpreted, changed, and accepted while the Flutter foundation is being built.

## 1. Normative precedence

When project documents conflict, the following order applies:

1. `docs/PROJECT_CONSTITUTION.md`
2. Accepted ADRs in `docs/adr/`
3. `docs/ARCHITECTURE.md` and module contracts
4. `AGENTS.md`
5. Task-specific prompts and temporary implementation notes

A lower-priority document may add detail but may not weaken a higher-priority rule.

Examples:
- a task prompt cannot authorize a native Reader implementation if the Constitution forbids it;
- `AGENTS.md` cannot redefine the supported platform matrix;
- an implementation convenience cannot silently alter Source identity semantics.

## 2. Change authority

Architectural exceptions or changes to normative policy require an ADR.

An ADR is required when changing any of the following:

- supported first-class platforms
- the “one canonical Dart implementation” rule
- dependency direction
- state-management strategy
- persistent storage architecture
- Source API contract
- Reader contract
- plugin runtime/security boundary
- target migration guarantees
- use of project-owned native product code

Agents may propose such changes but must not adopt them silently.

An ADR cannot override the Constitution. Changing a Constitution-level rule requires an explicit decision record and synchronized updates to the Constitution, ADR, and all affected governance documents in the same change. An accepted ADR alone does not authorize first-party native product implementations forbidden by the Constitution. Under [ADR 0008](adr/0008-agent-review-and-validation-cadence.md), the project owner has delegated review and approval of future implementation and architecture decisions to the Agent; the Agent must record its reasoning and evidence before accepting a change.

## 3. Required synchronization

When a change modifies a contract or architecture boundary, update all affected normative documents in the same change.

At minimum, check:

- `PROJECT_CONSTITUTION.md`
- `ARCHITECTURE.md`
- relevant module contract
- `AGENTS.md`
- testing/regression docs
- build/release docs
- ADRs

Documentation drift is a defect.

## 4. Governance status

Version: **0.3**

Status: **Active for Foundation Development**

Meaning:

- F1 Flutter Foundation may begin once F1 entry criteria are met.
- Module contracts that are explicitly scheduled for later phases may still evolve.
- No future-phase contract is considered frozen merely because a placeholder exists.
- Before a phase begins, every contract listed as a prerequisite for that phase must be finalized enough to support implementation and acceptance.

## 5. Phase exit model

Every implementation phase must define and satisfy:

### Deliverables
Concrete files, modules, migrations, tooling, or test assets produced.

### Acceptance Criteria
Observable conditions that must be true.

### Required Automated Tests
Tests that must pass before exit.

### Required Platform Validation
Which of iOS, Android, and Windows must be built/run/validated for that phase.

### Evidence / Artifacts
Examples:
- CI link
- command output
- test report
- benchmark record
- migration fixture result
- screenshots/video where interaction is inherently visual

### Known Exceptions
Any accepted unresolved issue, with:
- owner
- scope
- reason
- follow-up phase/task

### Exit Approval
The phase must not self-advance merely because implementation tasks are complete.
The Agent reviews the exit evidence, records a PASS or precise blockers, and may approve the phase and authorize its successor. The reviewer and implementer may be the same Agent, but the review must be a distinct recorded step with the tested revision and unresolved risks. Historical human approvals remain historical facts.

## 5.1 Review and validation cadence

Every code change receives a diff review for scope, contract fit, data/security risk, and meaningful tests. For routine changes, run formatting, analysis, and focused tests covering the affected behavior. Routine implementation tasks within an authorized phase do not each need a separate acceptance record. Keep formal review records for phase exits, expressly gated slices, and normative ADR decisions. Run the full local suite when a change spans boundaries, modifies shared contracts, or closes a phase. Use a failure to guide additional checks; do not repeat passing checks without a new reason.

The cross-platform CI matrix and packaged/device smoke are phase-exit evidence, not a per-commit or per-slice ritual. Normally dispatch one manual matrix for the final phase-exit candidate. Dispatch an earlier targeted check only when local checks cannot safely bound a concrete platform, dependency, persistence/migration, secret/session, or runner risk that blocks further work; record why. Let jobs run asynchronously and continue independent work. Run all three targets for a cross-platform phase exit. Record the exact revision, results, and gaps. A build or another platform's PASS never substitutes for required runtime evidence.

An Agent approval may leave a named, nonblocking evidence gap for a later gate. It may not label that gap PASS, waive a frozen data/security invariant, or claim release readiness without the required platform evidence. CI failure on a relevant gate is a blocker until fixed or dispositioned in a documented ADR.

## 6. Phase entry rule

A future contract does not block F1 merely because it is unfinished.

It becomes blocking only at the phase that depends on it.

Deferred contract schedule is defined in:
`docs/CONTRACT_FREEZE_PLAN.md`

## 7. Release governance

Release readiness is cross-platform.

No iOS-only, Android-only, or Windows-only success is sufficient for a release that claims support for all three first-class targets.

The release matrix lives in:
`docs/RELEASE_CHECKLIST.md`

## 8. Dispute resolution

If two agents disagree:

1. cite the conflicting rules;
2. apply the precedence order;
3. if ambiguity remains, stop implementation;
4. propose the smallest clarifying documentation change or ADR;
5. record the Agent's review and decision before continuing; escalate to the project owner only when a decision requires product intent the repository cannot establish.

Agents must not resolve ambiguity by silently choosing the easier implementation.
