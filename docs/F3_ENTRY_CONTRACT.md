# F3 — Source Foundation entry contract

Status: **ACCEPTED**. Revision: **2**.
Prepared: **2026-09-17**. Human approval: **APPROVED**.
Approval date: **2026-09-17**. Approved by: **Human project owner**.
F3 Entry: **APPROVED**.
F3.1: **IMPLEMENTED / ACCEPTED**.
F3.2: **IMPLEMENTED / ACCEPTED**.
F3.3: **IMPLEMENTED / ACCEPTED**.
F3.4: **AUTHORIZED**. F3.5–F3.7: **NOT AUTHORIZED**.
F3 Exit: **NOT APPROVED**.

This accepted contract and [ADR 0004](adr/0004-f3-source-foundation.md) record
the human-approved F3 entry boundary. MUST language below describes the accepted
contract requirements. The entry approval authorized F3.1; its implementation
acceptance and the subsequent F3.2 authorization are recorded below. No network,
secure-storage, decoder/DOM or other dependency is selected or authorized by
this document. Constitution and accepted ADRs retain precedence.

## 1. Reverified baseline and evidence limits

On 2026-09-17, before this revision, the working tree was clean on `main`.
Local HEAD and the last successfully synchronized remote `refs/heads/main` were
`57ff4327f2624a9241ba3ea0cc42ab365b59ac31`.
[F1 baseline](FLUTTER_BASELINE.md) records F1 EXIT APPROVED;
[F2 exit](F2_EXIT_EVIDENCE.md) records F2 EXIT APPROVED by the human owner on
2026-09-17. F2.7 final iOS packaged-storage evidence remains a human-approved
waiver, not PASS; it grants no future iOS waiver. Historical CI results here are
tracked evidence, not freshly rerun or independently reauthenticated CI results.

The read-only checkout `C:/Projects/LightNovelReader-Legacy` was clean and
detached at `d90d4d090c85a0a9c374684696c34befe12636d1`. `git show` against that
exact commit verified the Source adapter, Kotlin parser/client and troubleshooting
evidence below. No Legacy files were modified or credentials copied. No live
Wenku8 requests, Legacy execution, or F3 fixture validation were performed.
There is no `lib/src/source` implementation at this baseline.

The implemented F2 identity/content types and the migration inventory were also
inspected. This revision synchronizes [SOURCE_API](SOURCE_API.md) with the
accepted F3 semantics: source-aware book/catalog inputs, one Catalog capability,
cookie/update meanings, and F8/F9 scope boundaries. It does not change frozen F2
identity or ordered-content semantics.

## 2. Scope and immutable F2 boundary

Deliver one Dart Source contract, registry, fixture harness, transport/session
foundation and Wenku8 adapter shared by iOS, Android and Windows. Source outputs
are normalized metadata/catalog/content, not local library, progress or download
state. Feature/application callers depend on contracts; composition injects
implementations. Domain imports neither HTTP libraries nor Wenku8 code.

Preserve F2 exact opaque ID values, complete reference tuples and v1 codecs.
Wenku8 registration uses `builtin.wenku8`; existing `wk8-<aid>` BookIds remain
unchanged. Only the adapter translates an evidenced provider identifier into a
request parameter. Core MUST NOT parse prefixes, URLs, numeric IDs or source names.
Registry display-name changes do not change identity. Duplicate SourceId
registration fails; missing/disabled/unresolved sources remain durable records
and return typed unavailability, never silently fall back to Wenku8.

Catalog order is explicit metadata. A chapter's ref survives reorder and volume
movement. Modern ChapterId must derive from verified provider identity or an
approved durable surrogate mapping, never index, index+1 or title alone. If no
stable volume key exists, retain grouping/order without claiming stable identity
until a reviewed mapping policy exists; do not manufacture VolumeId from position.

New chapter fetches emit the existing ordered `ChapterContent.nodes` model.
Parser normalization is explicitly fixture-defined; the F2 codec subsequently
preserves that output exactly. Preserve interleaved/repeated images and image-only
chapters. Images carry scoped opaque asset refs; URL resolution metadata stays
inside the adapter, separate from canonical content. No raw URL as AssetId.
The stable asset locator/mapping policy needs review in F3.2 before F3.4 emits
production asset refs. No image retrieval is implied.

Forbidden throughout F3: Reader/session/rendering/anchors, UI migration, second
real Source, plugin runtime or downloadable code, image download/cache/offline
work, bulk scraping, native business implementations, platform-specific Source
engines, hardcoded accounts, Legacy credentials/session migration, plaintext
secret persistence, Source-specific Core branches and Swift/KMP dual sessions.
No schema change is authorized implicitly; any required durable mapping/schema
extension needs a reviewed contract/ADR and migration safety evidence first.

## 3. Accepted Source API v1 semantics

The following is the accepted semantic surface. F3.1 supplies Dart signatures
and contract tests without changing these semantics; changes require review.

| Operation | Inputs and normalized result | Capability |
| --- | --- | --- |
| Search | Query/filter values plus optional opaque continuation; page of source-aware book summaries | search |
| Explore | Source-declared home/category/filter descriptors and opaque continuation; ordered blocks or book page | explore; filters when supported |
| Book detail | SourceBookRef; metadata including optional cover asset ref | bookDetail |
| Catalog | SourceBookRef; ordered chapters with optional volume/grouping presentation metadata and optional stable SourceVolumeRefs | catalog |
| Chapter content | SourceChapterRef; existing F2 ChapterContent | chapterContent |
| Authentication | Explicit user-supplied credentials, session status and logout through a separate auth contract | authentication |

`catalog` is a single capability, not separate `volumes` and `chapters` flags.
Every catalog result has an ordered chapter sequence. A Source with no volume
structure returns a flat sequence. A grouping label/title or group ordinal with
no stable provider VolumeId is presentation metadata only and must not produce a
fabricated `SourceVolumeRef`; a volume ref requires verified provider identity or
an approved durable surrogate mapping. ChapterId remains opaque and stable when
supported, while index/ordinal/order never becomes identity. The concrete Dart
catalog classes and signatures are an F3.1 deliverable, but this semantic policy
is already fixed for that work.

Every asynchronous operation takes cancellation/operation context. Validate ref
ownership before I/O. Capabilities describe supported operations, not current
login state. Unsupported calls return `unsupportedCapability` before network
access; they never return fake empty success. Cookies are a transport/session
facility, not permission for UI to read secrets. `images` means content can
reference assets; fetching images is F6. Updates may be inferred from refreshed
catalog/metadata in later callers; no background update service is authorized.

Wenku8 F3 minimum includes search, home/category/tag exploration with pagination,
detail, catalog, ordered content, explicit login/status/logout. Filtering and
sort support are descriptor-driven; URLs/selectors do not escape as UI commands.
No new feature pages are required to exercise these services.

Pages return immutable items and an explicit optional next continuation; absent
means exhausted. Continuations are opaque, nonsecret, bound to source, operation,
query/filter identity and session generation. Failed/cancelled requests do not
advance them. Stable-ref dedup preserves first-seen order; no title dedup.
Malformed page metadata cannot roll state backward, loop a cursor or turn an
error into exhaustion. Empty success requires evidence of a valid empty page.

Failures are typed values (or a single typed boundary exception), with stable
codes: `network`, `authentication`, `rateLimit`, `notFound`, `parse`,
`incompatibleResponse`, `cancelled`, `unsupportedCapability`, plus explicit
`sourceUnavailable`, `invalidRequest`, `securityPolicy` and `secureStorage`.
F3.1 chooses one representation consistently. Retryability and bounded retry-after
metadata are explicit. Raw HTTP/library exceptions, response HTML, credential
values and arbitrary server messages never cross diagnostics boundaries.
Distinguish HTTP errors, login/challenge HTML with HTTP 200, missing required DOM,
valid empty content and unsupported response shape.

## 4. Transport, session and security contract

`SourceTransport` owns request execution, deadlines, cancellation, response-byte
limits, redirects, retry/status handling and safe diagnostics. The pure request
builder supplies method, approved target, safe headers/body and operation policy;
the session owner supplies cookies at execution time. Parsing consumes bounded
bytes/decoded input plus safe context; no parser networking or persistence.

One source-scoped session authority owns cookie state, auth status and generation.
Multiple provider hosts share that authority only under explicit host policy;
there is no second Swift/KMP-like session or automatic global jar. Cookie domain,
path, expiry and Secure rules apply per target. Cross-source cookies never mix.
Host-only cookies MUST NOT be copied to sibling/mirror domains. Any historical
cross-domain cookie copying is evidence to inspect, not permission to repeat it.

HTTPS with normal certificate validation is required. Requests and each redirect
hop must satisfy the adapter's explicit host/scheme policy; reject user-info URLs,
unapproved targets and HTTPS downgrade. Never forward credentials, Authorization
or Cookie headers blindly on redirects. Recompute authorized headers/cookies for
each target. No certificate bypass or unrestricted URL fetching.

Use finite injectable policies: connect/overall deadlines, decoded response-byte
limit, redirect cap, retry cap and bounded concurrency/queue. Concrete limits are
reviewed with F3.2 fixtures before F3.3 runtime implementation. Retries are bounded
and limited to replay-safe requests and classified transient failures. Login is
not automatically replayed; parsing/auth/policy failures are not retried. A 429
uses a capped Retry-After within the overall deadline. Cancellation interrupts
queue/backoff/body reads where supported and is never transformed into retry.

Each caller owns its operation generation. Session/logout/disposal increments
the session generation and invalidates outstanding work. A stale completion
cannot publish output, install Set-Cookie, refresh auth state or write durable
mappings. Session mutation checks the captured generation before commit;
concurrent authentication is serialized/coalesced, with bounded work and no
background bundled-account login. Abort support does not replace stale-result
checks. Tests must deliberately complete obsolete requests late.

Secrets remain in memory or an approved secure-storage adapter only. A
source-neutral credential contract defines whether a source supports ephemeral
credentials, a remembered session, or another explicitly reviewed credential
model. Any durable secret requires an explicit source policy, approved secure
storage, and cross-platform support; it may never use Drift,
shared_preferences, fixtures, logs, URLs, exception strings or whole-response
dumps. Wenku8 specifically MUST NOT retain passwords, MUST NOT import its
Legacy cookies/accounts, and may remember only explicitly approved session
material through the F3 secure-storage contract. Redacted
diagnostics allowlist operation ID, failure code, timing/status and safe counters;
exclude raw query/body/header values and user identifiers. Test synthetic sentinel
leakage through success, failure, redirect and cancellation paths.

Secure-store unavailability returns a typed failure and supports explicit
memory-only sign-in on all targets; never silently use plaintext fallback or
claim that the session is remembered. Logout clears memory, invalidates requests
and deletes the secure record; deletion failure remains visible and blocks silent
restore of that record until recovery. Restart/deletion-failure semantics must be
demonstrated by the chosen secure-storage design before acceptance.

Critical networking and secure-storage dependencies require a separate accepted
dependency ADR and explicit human approval **before addition/use**. Assess exact
versions, maintenance, current Flutter compatibility, licensing, iOS/Android/
Windows runtime support and failure/fallback behavior. SDK-only transport is also
an explicit implementation choice requiring review; it is not an approval bypass.
No package candidate or support claim is adopted by this entry approval.

## 5. Frozen Legacy characterization and fixture gate

All paths below refer to the frozen commit in section 1, not latest Legacy main.
The [existing data inventory](legacy/swift/LEGACY_DATA_MIGRATION_INVENTORY.md)
contains pinned source links and additional migration evidence.

| Frozen evidence inspected | Observed behavior | Proposed classification / proof |
| --- | --- | --- |
| `Sources/Services/KmpBookSourceAdapter.swift`, fetchChapters/fetchContent | Flattens catalog order; missing remoteID falls back to index+1; content becomes paragraphs/images | FIX: no fabricated cid or split canonical arrays; reorder/missing-ID/interleaving fixtures |
| Same adapter, savedCookie/ensureLogin | UserDefaults session persistence; automatic bundled-account login | FIX: explicit login, one session authority, no copied account or plaintext secrets |
| `shared/src/commonMain/kotlin/io/nightfish/lightnovelreader/wenku8/Wenku8Client.kt` | Cookie-bearing HTTP client, timeout/retry, multiple configured hosts | PRESERVE bounded request intent; FIX cookie/redirect isolation; scripted transport tests |
| `shared/src/commonMain/kotlin/io/nightfish/lightnovelreader/wenku8/Wenku8DataSource.kt` | Different hosts per operation, GBK search encoding, DOM detail fields/description, ordered DOM walk with br/image handling | PRESERVE intended fields/paragraphs and operation semantics; characterize host assumptions without declaring them current live facts |
| `docs/KMP-TROUBLESHOOTING.md`, sections 14–15, 20–23, 29 | Encoding gaps/table corruption, concatenated metadata, description swallowing page chrome, missing br boundaries | REGRESSION TEST: byte fixtures, separate field assertions, exact description and node output |
| F2 locator and frozen ChapterItem evidence | Index-based historical progress, optional remote identity evidence | PRESERVE raw locator; evidence-based identity reconciliation only; Reader fraction DEFER F4 |

These classifications are part of the accepted migration boundary, not claims
that every Legacy quirk is desired. F3.2 expands the inventory and labels each fixture
PRESERVE/FIX/REGRESSION TEST/DEFER; DROP requires explicit product approval.

Before any Wenku8 production parser, commit and review a sanitized corpus and
independent expected outputs. Include search (including direct-detail response),
home/category/tag exploration, pagination/duplicates, detail, catalog and content;
authentication success/expiry/rejection, rate-limit/challenge/error/not-found HTML;
malformed/truncated responses and selector changes. Byte fixtures cover GBK
extensions, GB18030 four-byte sequences, mixed ASCII, invalid/truncated sequences
and encoding disagreement. Do not assume a two-byte decoder is full GB18030 or
invent characters for private-use bytes.

Include Text/Text/Image/Text/Image/Text, image-only, repeated images, br
boundaries, relative/protocol-relative image locators, empty valid content and
missing content containers. Fixture expectations specify normalization and asset
mapping separately from frozen F2 codec behavior. Historical split arrays cannot
prove original inline placement; their conversion remains F6.

Manifest per fixture: ID, operation, frozen evidence permalink/section, synthetic
or sanitized-capture provenance, encoding and safe status/context, content digest,
sanitization method, expected normalized output/failure and behavior classification.
Never commit raw authenticated captures or real cookies/tokens. Synthetic auth
sentinels are explicitly inert, never actual credentials. Scan decoded and raw
fixture forms. Sanitization must retain the byte/DOM condition being tested.
Expected output is reviewed independently, not generated by the production parser.
Code inspection is not an executed Legacy oracle; record that distinction.

## 6. Slices, deliverables and local gates

F3.1, F3.2 and F3.3 are **IMPLEMENTED / ACCEPTED**. F3.4 remains
**AUTHORIZED**. F3.4.1–F3.4.3 are **IMPLEMENTED / ACCEPTED**; F3.4.4 is
**IMPLEMENTED / HUMAN REVIEW REQUIRED**. F3.5–F3.7 remain **NOT AUTHORIZED** and
F3 Exit remains **NOT APPROVED**. ADR 0005 authorizes only its exact F3.3
dependencies; F3.3 acceptance does not approve F3 exit.
Default review sequence is the following, with evidence before advancing.

| Slice | Deliverables / scope | Tests and gate to next slice |
| --- | --- | --- |
| F3.1 Source Contracts + Registry | Neutral operation/result/failure/capability contracts, runtime registry over F2 identities, fake sources, injection boundaries | Unsupported-before-I/O, wrong-ref, duplicate registration, rename/unavailable preservation, cursor ownership and fake conformance; no Wenku8 parser/network |
| F3.2 Legacy Characterization + Fixture Harness | Evidence matrix, sanitized byte/DOM corpus, manifest and independently reviewed expectations; decoder/asset/volume identity and request policy specifications | Fixture integrity/sanitization and expected-value checks; reviewed coverage of section 5 before F3.4; dependency-free test scaffolding must not conceal a production parser |
| F3.3 Transport + Session + Security Foundation | Accepted dependency ADRs first; transport, session authority, secure-store abstraction/approved adapter, scripted server/fakes | Redirect/cookie isolation, deadlines/retries/cancellation, stale Set-Cookie, concurrent login/logout, secure-store failure and secret-exclusion tests; real package smoke on all targets |
| F3.4 Wenku8 Pure Parser + Request Builder | Pure encoding/DOM normalization and request construction using F3.2 evidence | Exact normalized fixtures, safe query encoding/host construction, malformed/error discrimination, ordered node/identity assertions; no runtime orchestration |
| F3.5 Wenku8 Runtime Adapter | Compose contracts, builder/parser, transport/session; explicit auth and paginated service flows | Deterministic end-to-end scripted search/explore/detail/catalog/content/auth; cancellation/late-result and transport-failure coverage; no feature/Reader UI |
| F3.6 Legacy Reconciliation + Source Neutrality Proof | Evidence-based chapter/source resolution plans and safe application through repositories; synthetic alternate-source conformance suite | Exact proof cases, ambiguous/reordered catalog stays unresolved, idempotency/reopen/rollback/user-edit conflict protection; no real second Source |
| F3.7 Cross-platform Validation + Exit Evidence | Final contract synchronization, deterministic platform builds/runtime smoke, optional bounded manual live-smoke record and F3 exit record | Section 9 matrix, final-revision evidence, risk dispositions and explicit human exit approval; no automatic F4 entry |

F3.1 is contract scaffolding, not permission to bypass the fixture-first Source
migration sequence. F3.2 must establish all production parser expectations first.
Each slice remains a separate reviewable change; no F3 mega implementation patch.

## 7. Reconciliation and neutrality acceptance

Resolve a legacy locator only with source/book-bound trustworthy remote ID
evidence, or a demonstrably contemporaneous catalog mapping that uniquely links
the preserved index to that remote ID. A current catalog, matching title, same
count or candidate catalog digest alone is insufficient. F3.2 must specify how
provenance establishes contemporaneity; absent proof means unresolved, not guessed.

Return resolved/unresolved/conflict with safe evidence and mapping version.
Preserve the original locator, fraction, dataset and alternatives. Apply a
verified resolution atomically with its receipt and an expected-current-state
check; repeat is a no-op, later user edits/conflicting mappings remain conflicts.
No source reassignment of unknown aliases by preference/title. Reconciliation
does not fetch offline files, restore a Reader position or overwrite import
baselines. If existing repositories cannot preserve required provenance, propose
the schema/contract extension before implementation, not a hidden side store.

Prove neutrality with test-only sources using nonnumeric/delimiter/Unicode IDs,
same IDs across two sources/books, non-Wenku8 catalog grouping, unsupported auth,
different pagination and mixed/image-only content. Run shared conformance tests
against fake sources and the fixture-backed Wenku8 adapter. Inspect imports and
Core/Domain for URLs/selectors/name branches. Built-in composition/registration
and the existing isolated legacy mapping adapter may name Wenku8; they are not
permission to spread provider logic into Core. A fake proves boundary behavior,
not the F8 second-real-Source milestone.

## 8. Entry gates and deferred decisions

Entry requires verified F1/F2 approvals and unchanged frozen F2 contracts;
recorded human acceptance of this revision and ADR 0004; accepted F3.1 evidence;
the explicit F3.2 slice authorization; accepted ADR 0005 for dependency-using
F3.3 work; and capability/failure/transport/session semantics reviewed
sufficiently for F3. F3.4–F3.7 remain gated. No implementation beyond the
currently authorized slice starts merely because this document is committed.

| Decision / owner | Latest gate / consequence |
| --- | --- |
| HTTP and secure-storage package/backend choices, F3 owner + human reviewer | ADR 0005 accepted for `dio: 5.11.1`, `flutter_secure_storage: 11.2.0` and no cookie manager; future changes require an amended Human-approved dependency decision |
| Decoder/DOM libraries and byte normalization, F3.2 owner | Accepted ADR 0007 governs the project-owned charset foundation; accepted ADR 0006 governs `html: 0.15.7`; independent fixtures and platform evidence remain required before F3.4/F3.7 acceptance |
| Stable volume/asset locator mapping, provenance proof and numeric resource bounds, F3.2 owner | Reviewed specification before F3.3/F3.4 consumers; persistence changes need separate approved migration design |
| Concrete API signatures, F3.1 owner | Reviewed against section 3 before consumers; semantic changes require updated proposal/ADR |
| Reader position/fraction interpretation, F4; curl, F5 | No F3 implementation |
| Image request/cache/offline completeness and historical split content, F6 | No image fetching/cache or offline migration in F3 |
| Feature/import/auth UI and background update presentation, F7 | F3 supplies service interfaces and test harness only |
| Second real Source, F8; plugin ownership/runtime, F9 | Fake neutrality tests do not claim these phases complete |
| Real installed-app migration, performance/release matrix, F11 | F3 runtime validation does not claim release readiness |

## 8.1 F3.4 historical implementation checkpoint — 2026-09-19

ADR 0007 is **ACCEPTED** at baseline
`d4c74a6874779ea2558a97fdcf25ec9da976fa58` and supersedes the decoder portion
of ADR 0006. The F3.4 status at this historical checkpoint was:

- F3.4.1 charset foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.2 HTML parser foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.3 request builder foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.4 Wenku8 parser: **NOT STARTED**
- F3.5–F3.7: **NOT AUTHORIZED**
- F3 Exit: **NOT APPROVED**

The accepted HTML parser dependency remains `html: 0.15.7`; `charset_codec:
0.1.1` is not used by the implementation. Windows charset runtime
evidence is PASS, while Android and iOS runtime evidence remain **UNPROVEN**.
Fresh deterministic Android and iOS evidence is still required by F3.7. The
gap is not a PASS or reusable waiver. Implementing F3.4.2 or F3.4.3 does not
constitute F3.4 acceptance or F3 Exit approval.

## 9. Required tests, platform validation and exit gates

Automated suite includes every assertion in sections 3–7 plus all F2 regression
tests. Use temporary databases/secure-store test namespaces, scripted HTTP and
fake clock/scheduler; deterministic tests must not require live credentials or
public network. Cover status/HTML disagreement, decompressed oversized response,
redirect loop/downgrade/unapproved host, domain/path cookie isolation, auth expiry,
secure-store locked/unavailable/deletion failure, queue/backoff cancellation and
late logout/search/page completion. Assert both returned results and absence of
forbidden state/secret writes; test files alone are not evidence.

| Validation at final tested revision | iOS | Android | Windows |
| --- | --- | --- | --- |
| Build with locked dependencies | macOS unsigned build | Android build | Windows build |
| Packaged Source runtime | Simulator/device | Emulator/device | Desktop |
| Scripted search/explore/detail/catalog/ordered content | Required | Required | Required |
| Approved transport/secure-store set/read/delete/restart and failure behavior | Required | Required | Required |
| Cancellation, session isolation and late-response rejection | Required | Required | Required |

The blocking F3 platform gate is deterministic and reproducible: the scripted
transport/session/parser/adapter tests and the packaged runtime matrix above
must pass on iOS, Android and Windows without public-network access. CI must not
depend on Wenku8 availability.

Controlled Wenku8 live smoke is supplemental evidence, not a required F3 exit
gate and never a CI gate. If a human reviewer elects to run it, it is bounded,
manual, opt-in and separate from fixture tests: record host-policy verification,
operation outcomes, platform/toolchain and revision without bodies or secrets;
use a reviewer-provided test account only where needed; never Legacy bundled
credentials; perform no bulk fetch or image downloads. If the provider, WAF,
network or account is externally unavailable, record `NOT RUN / EXTERNALLY
UNAVAILABLE` and continue to assess the deterministic gate. Such unavailability
does not turn a deterministic failure into a pass, and deterministic success does
not claim current provider availability. Record network/provider failures
separately from parser failures. No platform PASS is inferred from another
platform. Any proposal to make live smoke a release-specific condition requires
an explicit human decision and scope; the F2 waiver does not apply.

The F3 exit record must contain the governance fields:

| Field | Required evidence |
| --- | --- |
| Deliverables | Accepted Source API v1 and ADRs, registry, fixtures, transport/session/security, pure parser/builder, runtime adapter, reconciliation and neutrality proof |
| Acceptance Criteria | F2 identity/content unchanged; declared capabilities work; no Core provider branches; no secret/data-loss blocker; no platform divergence |
| Required Automated Tests | Format, analyze, full test suite plus fixture/conformance/security/reconciliation tests with exact counts and commands |
| Required Platform Validation | Deterministic builds and runtime results on all three targets; optional live-smoke evidence is supplemental and must state limitations |
| Evidence / Artifacts | Tested SHA, Flutter/Dart/OS/device, lockfile, CI/run links, fixture hashes and expected/actual assertions; sanitized output only |
| Known Exceptions | Owner, scope, reason, human disposition and follow-up; unavailable/waived is never PASS |
| Exit Approval | Explicit human F3 exit approval after evidence; F4 requires its own entry review |

Before exit, synchronize accepted semantics into SOURCE_API, ARCHITECTURE where
needed, CONTRACT_FREEZE_PLAN, tests/regression docs and ADR statuses through
human review. This draft does not freeze future contracts by itself.

## 10. Risk register

| ID / risk | Mitigation and evidence | Owner / blocking gate |
| --- | --- | --- |
| R1 Provider HTML/host drift | Frozen corpus plus separately labeled optional live evidence; old/new fixture comparison | F3.2/F3.5; deterministic parser gate, live evidence supplemental |
| R2 Partial GBK/GB18030 decoder | Independent byte vectors, malformed/four-byte cases; reviewed dependency | F3.2/F3.4; parser gate |
| R3 Cookie leakage or stale auth resurrection | Per-target cookie policy, generation checks, sentinel tests, logout/restart proof | F3.3; security blocker |
| R4 Secure storage differs across platforms | Approved package matrix plus packaged failure/restart tests; explicit memory-only mode | F3.3/F3.7; dependency and exit blocker |
| R5 False chapter/volume/asset identity | No ordinal identity; reviewed durable mapping and provenance; ambiguous stays unresolved | F3.2/F3.6; identity/data-loss blocker |
| R6 Fixtures reproduce defects or lose byte semantics | Human-reviewed classifications, independent expectations, provenance/sanitization checks | F3.2; parser entry blocker |
| R7 Retry/cancel races or unbounded responses | Bounded policies, fake clock and deliberate late completions | F3.3/F3.5; runtime blocker |
| R8 Scope leaks into Reader/images/plugins | Slice diff/import review; service-only acceptance | Every slice reviewer; scope blocker |
| R9 Platform evidence incomplete | Final-SHA builds and packaged tests; unavailable stays pending | F3.7 + human owner; exit blocker |
| R10 Reconciliation overwrites user changes | Atomic receipt/current-state check, reopen/rollback/idempotency tests; schema review if needed | F3.6; data-loss blocker |

## 11. Entry-contract baseline validation

On 2026-09-17 this documentation-only change passed
`dart format --output=none --set-exit-if-changed .` (56 files, zero changes),
`flutter analyze --no-pub` (no issues), and `flutter test --no-pub`
(370 passing tests). `git diff --check` passed. No dependencies, production code,
tests, schemas, generated files or platform runners were changed. These checks
protect the existing baseline; they are not F3 implementation or platform evidence.
No platform build or live provider smoke was run for this documentation-only
approval record.

Approval record: **APPROVED**. Approver: **Human project owner**. Approval date:
**2026-09-17**. F3 Entry: **APPROVED**. F3.1: **IMPLEMENTED / ACCEPTED**.
F3.2: **IMPLEMENTED / ACCEPTED**. F3.3: **IMPLEMENTED / ACCEPTED**.
F3.4: **AUTHORIZED**. F3.5–F3.7: **NOT AUTHORIZED**. F3 Exit: **NOT APPROVED**.

## 12. F3.1 implementation acceptance — 2026-09-18

The Human project owner accepted F3.1 at baseline SHA
`36bb595f4e26591f07593c962f0a26ff1f587fbf` on **2026-09-18**. The accepted
implementation covers the neutral Source contracts, registry, catalog policy,
structural continuation binding, Explore descriptor discovery and typed failure
diagnostics. F2 identity/content semantics remain unchanged.

Focused F3.1 tests passed: **31**. The full suite passed: **401**. CI run
[35246451941](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35246451941)
completed successfully.

F3.2 is **AUTHORIZED**. F3.3–F3.7 remain **NOT AUTHORIZED**, and F3 Exit remains
**NOT APPROVED**. This acceptance authorizes no transport, network, secure
storage, parser, runtime adapter, reconciliation, second Source, plugin, Reader,
image, offline or schema work.

## 13. F3.2 acceptance and F3.3 authorization — 2026-09-18

The Human project owner approved F3.2 at accepted baseline SHA
`37360101487db7904f9ef6c915724719ec90db25` on **2026-09-18**. F3.2 is
**IMPLEMENTED / ACCEPTED** with 80 deterministic fixtures, 80 independent
expected sidecars, 60 synthetic and 20 reconstructed entries, classifications
PRESERVE 15 / FIX 23 / REGRESSION_TEST 37 / DEFER 5 / DROP 0, audited charset
bytes, the six-node ordered-content fixture and whole-corpus secret scanning.
Focused F3.2 tests passed: **17**; full suite: **418**.

CI run [35258020716](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35258020716)
passed Quality, Android debug, Android packaged storage smoke, Windows debug,
Windows packaged storage smoke, iOS unsigned debug build and iOS simulator
boot. iOS simulator packaged-storage smoke is **STALLED / INCOMPLETE — NOT
F3.2 BLOCKING**. It is not an iOS PASS and not a reusable F3 platform waiver;
fresh deterministic iOS runtime evidence remains required by F3.7 before F3
Exit approval. Android or Windows results do not imply iOS PASS.

F3.3 is **AUTHORIZED**. F3.4–F3.7 remain **NOT AUTHORIZED** and F3 Exit
remains **NOT APPROVED**. This authorization does not approve a network or
secure-storage package; a critical dependency still requires a separate ADR and
explicit Human project owner approval.

## 14. F3.3 dependency proposal checkpoint — 2026-09-18

[ADR 0005](adr/0005-f3-transport-security-dependencies.md) is **PROPOSED / NOT
ACCEPTED**. It proposes the exact candidates `dio: 5.11.1` and
`flutter_secure_storage: 11.2.0`, compares `http: 1.6.0`, and selects no
cookie-management dependency. It records Android API 24 compatibility, the
iOS 15.0 target, the Windows ATL prerequisite, license evidence, security
boundaries and deferred platform smoke gates without changing this accepted
contract's semantics.

F3.3 remains **AUTHORIZED as a slice**, but dependency-using implementation is
blocked until ADR 0005 is accepted by the Human project owner. No dependency,
lockfile entry or F3.3 runtime implementation is approved by this checkpoint.
F3.4–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains **NOT APPROVED**.

## 15. F3.3 dependency approval checkpoint — 2026-09-18

[ADR 0005](adr/0005-f3-transport-security-dependencies.md) is **ACCEPTED** and
the Human project owner approved it on **2026-09-18** at accepted baseline SHA
`13408a83ca58158a8e7d74d911a71c183eaff590`. The exact approved dependencies are
`dio: 5.11.1` and `flutter_secure_storage: 11.2.0`; no cookie-management
dependency is approved. Android API 24, iOS 15.0 and the Windows ATL/toolchain
requirements remain as recorded in ADR 0005.

F3.3 remains **AUTHORIZED**, and dependency-using implementation is permitted
within that slice. F3.4–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains **NOT
APPROVED**. No other HTTP, cookie-management or secure-storage dependency is
approved without a new or amended Human-approved dependency decision.

## 16. F3.3 implementation acceptance and F3.4 authorization — 2026-09-18

The Human project owner accepted F3.3 at baseline SHA
`8822cfed27e87ec33d3bf923a1ce6384007cc50d` on **2026-09-18**. The accepted
evidence includes 44 focused F3.3 tests, 462 full-suite tests, and CI run
[35310986634](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35310986634)
with Quality, Android, Windows and iOS packaged/runtime checks passing.

The remembered-session crash-safe revocation limitation remains explicit and
review-gated: the approved three-method secure-store abstraction cannot
guarantee a durable tombstone if the underlying store cannot persist or delete
state during failure. No real Source may enable remembered-session restoration
without later review and explicit provider policy.

F3.4 Wenku8 Pure Parser + Request Builder is **AUTHORIZED**. F3.5–F3.7 remain
**NOT AUTHORIZED** and F3 Exit remains **NOT APPROVED**. This authorization does
not approve a decoder, charset, HTML or DOM dependency; any critical dependency
requires its own dependency review, ADR and Human approval.

## 17. F3.4 parser dependency acceptance checkpoint — 2026-09-18

[ADR 0006](adr/0006-f3-parser-dependencies.md) is **ACCEPTED** at baseline
`c0ad8a3b64166c0a95a52aaa9caa9c9d9d04dd51`, approved by the **Human project
owner** on **2026-09-18**. Its active parser dependency is `html: 0.15.7` for
HTML5 DOM parsing. The `html` license evidence is pub metadata
unavailable/unknown with upstream `dart-lang/tools` BSD-3-Clause evidence
accepted for this dependency decision. The former `charset_codec: 0.1.1`
decoder selection is superseded by accepted ADR 0007 and is not used by the
current implementation.

F3.4 is **AUTHORIZED** for decoder, HTML parser, request builder and
provider-neutral parsed-structure foundations only. No arbitrary or additional
dependency is approved. F3.5–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains
**NOT APPROVED**.

## 18. F3.4 charset compatibility amendment checkpoint — 2026-09-18

[ADR 0006 amendment](adr/0006-amendment-charset-compatibility.md) is
**SUPERSEDED by accepted ADR 0007**. It remains a historical record of the
dependency graph conflict and mandatory-vector failure: `sqlite3: 3.6.0`
requires `hooks ^2.2.0`, while `charset_codec: 0.1.1` requires
`hooks >=2.0.2 <2.1.0`, and the external probe rejected `aaa1 -> U+E000`.
It is no longer the current decoder path and does not alter the accepted HTML
parser decision.

## 19. F3.4 historical implementation checkpoint — 2026-09-19

ADR 0007 is **ACCEPTED** at baseline
`d4c74a6874779ea2558a97fdcf25ec9da976fa58`, approved by the Human project
owner on **2026-09-18**. The F3.4 status at this historical checkpoint was:

- F3.4.1 charset foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.2 HTML parser foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.3 request builder foundation: **IMPLEMENTED / HUMAN REVIEW REQUIRED**
- F3.4.4 Wenku8 parser: **NOT STARTED**
- F3.5–F3.7: **NOT AUTHORIZED**
- F3 Exit: **NOT APPROVED**

ADR 0007 supersedes the decoder portion of ADR 0006 and adds no dependency.
Windows charset runtime evidence is PASS, while Android and iOS charset
runtime evidence remain **UNPROVEN**. Fresh deterministic evidence on both
platforms is required at the F3.7 gate; the gap is not a PASS or reusable
waiver. Implementing F3.4.2 or F3.4.3 does not constitute F3.4 acceptance or
F3 Exit approval.

## 20. F3.4 foundation review and F3.4.4 authorization — 2026-09-23

The Human project owner approved F3.4.1 charset, F3.4.2 HTML parser, and
F3.4.3 request builder foundations on **2026-09-23** at baseline
`1251235750b13606b77a4a4a509da9e3f3aef948`. Their status is
**IMPLEMENTED / ACCEPTED**. **F3.4.4 Wenku8 Pure Parser is AUTHORIZED** within
the accepted F3.4 architecture and independently authored F3.2 fixture corpus.
This checkpoint does not accept F3.4 as a whole.

F3.4.4 may implement only pure deterministic parsing, source-neutral parsed
structures, isolated Wenku8 selector/normalization logic, typed redacted
failures, ordered content, fixture tests, and evidence. It does not authorize
network execution, a Source runtime, authentication/session orchestration,
persistence/schema changes, Reader/UI, or new dependencies. F3.5–F3.7 remain
**NOT AUTHORIZED** and F3 Exit remains **NOT APPROVED**.

Windows charset runtime evidence remains PASS. Android and iOS charset runtime
evidence remain **UNPROVEN** and are not waived; fresh deterministic evidence
is required at F3.7 before F3 Exit.

## 21. F3.4.4 implementation checkpoint — 2026-09-23

F3.4.4 Wenku8 Pure Parser is **IMPLEMENTED / HUMAN REVIEW REQUIRED**. It uses
the generic decoded/HTML boundary, keeps provider selectors in the Wenku8
adapter and checks independently authored F3.2 expected sidecars. F3.4.1,
F3.4.2 and F3.4.3 remain **IMPLEMENTED / ACCEPTED**. F3.4 as a whole remains
unaccepted. F3.5–F3.7 are **NOT AUTHORIZED** and F3 Exit is **NOT APPROVED**.
Android and iOS charset runtime evidence are **UNPROVEN** and remain a fresh
deterministic F3.7/F3 Exit gate.
