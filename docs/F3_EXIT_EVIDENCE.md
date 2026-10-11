# F3 Source Foundation exit evidence

Status: **IN PROGRESS — F3 EXIT NOT APPROVED**

Reviewed code candidate: `9f6f7a46ef0f2cdf70b02e7fe1a718ac598f2fea`.
The final Agent exit review under ADR 0008 has not occurred. This record is an
evidence ledger, not an approval or automatic F4 authorization.

## Deliverables and acceptance criteria

- F3.1 Source contracts, capability semantics, registry and typed diagnostics:
  Human accepted at `36bb595f4e26591f07593c962f0a26ff1f587fbf`.
- F3.2 characterized Legacy corpus: 80 raw fixtures, 80 independent expected
  sidecars, byte/provenance/sanitization harness; Human accepted at
  `37360101487db7904f9ef6c915724719ec90db25`.
- F3.3 transport, single Source-scoped session authority and secure-storage
  boundary: Human accepted; dependencies fixed by accepted ADR 0005.
- F3.4 project-owned charset modes, generic HTML foundation, pure Wenku8
  parser/request builder: accepted ADRs 0006 and 0007 govern the implementation.
- F3.5 one built-in Wenku8 runtime adapter with fixture-backed Source behavior;
  no second real Source or plugin runtime.
- F3.6 proof-bound legacy reconciliation, typed schema v2 receipt and
  source-neutral conformance: Agent accepted at
  `9bfd153b9b87d4b0686b2306b3ab1e2f41ddc808` after remediation.
- F3.7 deterministic packaged runtime checks on all three target platforms
  are underway. [The platform ledger](F3_7_PLATFORM_EVIDENCE.md) records exact
  assertions and limitations.

F2 source-aware opaque identities and ordered `ChapterContent.nodes` remain
unchanged. The F2 importer has no trustworthy historical chapter identity
proof; such progress remains unresolved. Core and the source-neutral runtime
contain no Wenku8-specific branch; the pre-existing isolated Legacy import
mapping still recognizes its historical Wenku8 alias. No Reader,
image-download/offline, second real Source or plugin runtime is included in
this phase.

## Automated checks

At code candidate `9f6f7a4`, local format and analysis passed. The full local
unit/fixture/repository suite passed **555 tests** at parent code revision
`f1883c3`; the only later code change adds integration tests and workflow
steps. Windows packaged `storage_smoke_test.dart` passed **10 tests** at the
candidate. The separate secure-store process-restart test passed both write
and read launches on Windows. The candidate's Quality CI job passed formatting,
generated Drift schema/code verification, analysis, and the full test suite.
The candidate's Windows and Android debug jobs also passed. Android passed
all 10 packaged Source/runtime tests; its separate secure-store read failed
after a second `flutter test` launch found no value. Flutter 3.47.4's
integration test runner uninstalls the app by default, so Android
process-restart behavior remains UNPROVEN.
The mobile workflow now uses `flutter drive --keep-app-running` for the write
launch, followed by a new read launch. This revised gate must run before F3
Exit. The iOS result from the old run is recorded separately when terminal.

The manually dispatched final-candidate CI run is
[38125926148](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/38125926148).
Its platform results must be recorded after completion. The earlier
[38125621200](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/38125621200)
tested `f1883c3` and cannot certify the later process-restart change.

## Platform validation

| Required gate | iOS | Android | Windows |
| --- | --- | --- | --- |
| Locked unsigned/debug build | PENDING | PASS at candidate | PASS at candidate |
| Packaged Source search/explore/detail/catalog/ordered content | UNPROVEN | PASS, 10-test scripted smoke at prior candidate | PASS, local scripted smoke |
| Transport, secure store, charset and schema v2 runtime | UNPROVEN | PASS for listed Android packaged assertions; restart pending | PASS for local assertions |
| Separate-process secure-store persistence | UNPROVEN | UNPROVEN | PASS, local and candidate CI write/read launches |
| Session isolation, caller cancellation, late-response rejection | UNPROVEN | PASS, 10-test Android scripted smoke | PASS, local scripted smoke |

These results do not claim real Wenku8 availability. Optional controlled live
smoke is supplemental and not a required F3 exit gate.

## Known exceptions and decision

| Contract risk | Current disposition |
| --- | --- |
| R1 provider drift | 80 frozen fixture vectors and scripted Source tests are deterministic; optional live smoke has not been run and is not required for F3 Exit. |
| R2 charset | Independent CP936/GB18030/malformed/replacement vectors passed on Windows; Android/iOS runtime proof pending. |
| R3 cookie/session | Source-scoped session and generation checks pass local tests; final platform matrix pending. |
| R4 secure storage | Approved package and Windows packaged/restart checks pass; Android/iOS packaged/restart proof pending. |
| R5 identity | F2 opaque refs unchanged; unproven legacy ordinals remain unresolved. |
| R6 fixture integrity | F3.2 accepted whole-corpus byte/hash/provenance/secret audit; full fixture suite passes locally. |
| R7 retry/cancel/bounds | Focused transport tests and packaged caller-cancellation/late-result checks pass locally; final platform matrix pending. |
| R8 scope leak | No Reader, image/offline or plugin runtime implementation in F3.7 diff. |
| R9 platform gap | iOS/Android final-candidate run is pending; no inferred PASS. |
| R10 reconciliation overwrite | Proof-bound atomic receipt, v1 upgrade/rollback and later-user-edit conflict tests pass locally; final packaged platform matrix pending. |

Android and iOS packaged runtime evidence remain **UNPROVEN**. Windows local
PASS is scoped to the listed scripted assertions and is not transferable to
another platform. The injected secure-store failure covers the neutral adapter
error boundary; arbitrary native failure modes are not claimed. Actual F2
ordinal-only progress stays unresolved until independent historical proof
exists; this prevents identity guesswork and does not block F3 runtime safety.

Exit decision: **PENDING**. F4 is **NOT AUTHORIZED** by this ledger. Resolve the
required deterministic platform matrix, synchronize final contract/evidence
records and perform a separate Agent F3 exit review before any F4 entry.
