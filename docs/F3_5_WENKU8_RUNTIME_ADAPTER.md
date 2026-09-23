# F3.5 Wenku8 Runtime Adapter

Status: **IMPLEMENTED / ACCEPTED**.

F3.5 was accepted by the Human project owner on **2026-09-23** at implementation
baseline `adf995b7ee3073ded4ee0b91843d3a429ad23146`. This acceptance authorizes
F3.6 only; F3.7 and F3 Exit remain pending.

## Boundary

The runtime adapter composes the accepted Source contract, Wenku8 request
builder, pure parser, controlled charset decoder, HTML boundary, F3.3
transport and the application-owned single Source session authority. The
composition registers one built-in Wenku8 Source and one matching
authenticator. Provider details stay inside the adapter and do not enter Core
contracts.

The adapter supports deterministic search, Explore, book detail, catalog and
ordered chapter-content flows. It maps verified provider keys to source-aware
F2 references, keeps chapter ordinals as ordering only, preserves label-only
catalog grouping without inventing a volume reference, and retains image
locators only in an in-memory ephemeral index. It does not download, cache or
persist images.

Authentication is explicit and memory-only. The login request carries no old
session cookies, accepts only the approved Wenku8 host and HTTPS policy, and
establishes a session only when the expected `jieqiUserInfo` cookie is present.
Passwords, cookies and server bodies are never placed in diagnostics or
persistent storage. Logout, expiry and late results are guarded by the F3.3
session generation and cancellation contracts.

Pagination requires deterministic provider evidence for non-empty result
pages. Continuations are bound to the source, operation, query/descriptor and
session generation; stale or mismatched continuations fail before transport
I/O. Transport, challenge, status and parse failures remain typed source
failures with redacted diagnostics.

## Evidence

The focused F3.5 selection contains **35 passing tests** across the Wenku8
parser regressions used by the adapter, source orchestration, authenticator and
scripted Dio composition. It covers search and Explore pagination, CP936 query
encoding, Legacy frozen book/detail/home/catalog structures, F2 identity and
ordered content mapping, authentication cookie acceptance and rejection,
logout/cookie isolation, challenge and HTTP failures, caller cancellation,
late logout invalidation and composition registration. The full local suite
passes **539 tests**. Format, analysis and `git diff --check` pass.

These are deterministic scripted tests. No public-provider request is
required, and they do not claim Android or iOS charset-vector runtime proof.
The accepted F3.4 platform evidence gap remains a fresh F3.7 gate. CI run
`35847141315` was not green at approval time: four of five jobs had completed
at the last observed state and the remaining job was not recorded as PASS.
This explicit Human disposition permits F3.6 to start without treating the
incomplete job as a PASS or as a reusable F3.7 waiver.

## Excluded work

F3.5 does not implement reconciliation, a second real Source, plugin runtime,
Reader/UI changes, image download/cache/offline behavior, schema changes or new
dependencies. F3.6 is now **AUTHORIZED**. F3.7 remains **NOT AUTHORIZED** and
F3 Exit remains **NOT APPROVED**.
