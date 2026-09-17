# ADR 0004 — F3 Source contracts and single-session architecture

Status: **PROPOSED — NOT ACCEPTED**. Date: **2026-09-17**.
Human approval: **PENDING**. F3: **NOT STARTED / NOT AUTHORIZED**.

## Context

F2 froze opaque source-aware references and ordered ChapterContent v1. The older
Source API sketches predate those types. Frozen Legacy evidence combines Swift
and KMP session state, index-based chapter access and split text/image output.
Preserving that architecture would violate the cross-platform and F2 contracts.
Governance requires an ADR for the proposed Source API boundary, even though no
Constitution exception is requested.

## Proposed decision

Adopt the semantic contracts, gates and F3.1–F3.7 scope in the
[F3 Entry Contract revision 2](../F3_ENTRY_CONTRACT.md), subject to human acceptance.

Use one Dart contract/registry with capability-gated normalized operations,
typed failures and explicit cancellation. Registry keys are immutable F2 SourceIds;
runtime absence never deletes durable source-associated state. Keep provider URL,
encoding, selector and cookie knowledge inside Source infrastructure.

Catalog is one capability covering ordered chapters with optional volume
grouping. `cookies` describes source-scoped transport/session behavior and does
not expose cookie values or imply authentication; `updates` describes explicit
refresh hints and does not authorize a scheduler or push service.

Separate pure request building and byte/DOM parsing from transport and orchestration.
Approve sanitized characterization fixtures and independent expectations before
production Wenku8 parsing. One source-scoped session authority owns authentication,
cookies and generations, shared across approved provider hosts only according to
cookie scope. No global cookie jar, dual session, bundled credentials or native
business layer. Cancellation includes stale-result and stale-cookie suppression.

Treat Catalog as one capability covering ordered chapters with optional volume
grouping. A flat catalog is valid; grouping labels without a stable VolumeId are
presentation metadata and never fabricate a SourceVolumeRef. Preserve F2 BookIds
and ordered content. Catalog order is not identity. Resolve
historical locators only from sufficient source/book-bound evidence, preserving
unresolved/conflicting originals and later user edits. Prove boundaries with
synthetic sources in tests; second real Source and plugin runtime remain F8/F9.

No network/secure-storage package or backend is selected here. Each critical
dependency requires its own ADR with exact-version support/maintenance/compatibility
evidence and explicit human approval before addition/use. Memory-only auth is an
explicit fallback for unavailable secure storage, never plaintext persistence.
Credential retention is source-neutral and must be explicitly reviewed per Source;
Wenku8 specifically does not retain passwords or import Legacy session material.
Resource limits and stable volume/asset mapping specifications must be reviewed
before dependent implementation, as specified in the entry contract.

## Alternatives considered

| Alternative | Reason not proposed |
| --- | --- |
| Port Swift/KMP services and cookie synchronization | Duplicates session authority and native product logic; does not preserve F2 boundaries |
| Put HTTP/parsing directly in feature providers | Couples UI, provider and persistence; prevents fixture isolation and neutral callers |
| Parser first, fixtures afterward | Expectations can merely mirror new defects and lose frozen regression evidence |
| Choose packages while implementing | Bypasses explicit dependency approval and cross-platform runtime evidence |
| Prove neutrality with a second real Source now | Expands scope into F8; fake conformance is sufficient only for F3 boundary proof |

## Consequences

There is one implementation and one session ownership model on all three targets.
Pure parsers are deterministic; network/secure-store behavior needs separate real
platform evidence. Insufficient historical identity evidence remains unresolved.
Dependency review and secure-storage recovery can block runtime work; fixture and
contract approval cannot be treated as approval of a package or phase exit.

SOURCE_API changes in this patch only reconcile frozen F2 facts. New F3 semantics
remain proposed here and in the entry contract. Upon human acceptance, synchronize
the module specification/freeze plan and record authorized slices before dependent
production changes. No F2 schema/codec revision, Reader/image work, plugin runtime
or production Source implementation is part of this ADR patch.

## Acceptance and verification

Human acceptance must identify the contract revision and authorized scope.
Required blocking evidence is the entry contract's deterministic fixture,
conformance, security, reconciliation and three-platform matrix. Optional manual
Wenku8 live smoke is supplemental and never a CI or F3-exit gate; external
provider unavailability is recorded as such. F3 exit is a separate human decision.
Approver/date: **PENDING**. No architectural exception or dependency approval is
implied by committing this proposal.
