# Governance Specification v0.2

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

Version: **0.2**

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
The phase must not self-advance automatically.
A human owner explicitly approves exit after reviewing evidence.

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
5. obtain human approval before continuing.

Agents must not resolve ambiguity by silently choosing the easier implementation.
