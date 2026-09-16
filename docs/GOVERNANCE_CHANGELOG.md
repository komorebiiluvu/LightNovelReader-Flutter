# Governance Changelog

## v0.2 — Active for Foundation Development

Changes from v0.1 draft:

- defined normative document precedence
- required ADRs for architecture-policy exceptions
- froze legacy behavior reference to commit `d90d4d09`
- added explicit behavior classification (preserve/fix/regression/defer/drop)
- added common phase exit model
- added concrete F1–F13 exit expectations
- defined Core Feature Freeze
- added deferred-contract freeze schedule
- added explicit iOS/Android/Windows release matrix
- clarified that future-phase contract details do not block F1
- clarified that release support requires evidence per first-class platform

This version is sufficient to govern F1 Foundation Development.
Module contracts remain subject to phase-specific review before implementation.

### F1 implementation clarifications — 2026-09-16

Governance version and status remain v0.2 / Active for Foundation Development.

- clarified that ADRs cannot override the Constitution; Constitution-level changes require explicit human approval and synchronized governance updates
- restricted native internals to compliant third-party packages and generated runners without authorizing first-party native product implementations; generalized platform integration validation
- synchronized the F1 checklist and exit criteria with the CI baseline
- required successful iOS/Android/Windows build evidence for F1 exit; iOS remains Validation Pending on Windows until an actual macOS build passes
- required persistence-dependent Source identity/serialization rules before dependent F2 implementation and acceptance by F2 exit
- required Plugin API v1 manifest/host API/output schema freeze before F9 production host implementation
- limited release approval to PASS, justified NOT APPLICABLE, and permitted WAIVED cells while preserving all non-waivable blockers
