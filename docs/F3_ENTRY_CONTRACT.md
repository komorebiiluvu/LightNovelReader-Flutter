# F3 — Source Foundation entry contract

Status: **PROPOSED — READY FOR HUMAN REVIEW**. Revision: **1**.
Prepared: **2026-09-17**. Human approval: **PENDING**.
F3: **NOT STARTED / NOT AUTHORIZED**.

This proposal and [ADR 0004](adr/0004-f3-source-foundation.md) require explicit
human acceptance before production implementation. MUST language below describes
the proposed contract, not approval. No dependency is selected or authorized by
this document. Constitution and accepted ADRs retain precedence.

## 1. Reverified baseline and evidence limits

On 2026-09-17, before editing, the working tree was clean on `main`.
Local HEAD and remote `refs/heads/main` obtained with `git ls-remote` were both
`373b5498c135936a95343da502a7381692d9b168`.
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
inspected. The only changes to [SOURCE_API](SOURCE_API.md) in this proposal
correct its stale F2 identity/content sketches. Its remaining capability/method
sketches are future-facing; the second real Source remains F8 and plugin adapter
execution remains F9. Those sketches do not expand F3 scope.

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

## 3. Proposed Source API v1 semantics

The following is the reviewable semantic surface. F3.1 supplies Dart signatures
and contract tests without changing these semantics; changes require review.

| Operation | Inputs and normalized result | Capability |
| --- | --- | --- |
| Search | Query/filter values plus optional opaque continuation; page of source-aware book summaries | search |
| Explore | Source-declared home/category/filter descriptors and opaque continuation; ordered blocks or book page | explore; filters when supported |
| Book detail | SourceBookRef; metadata including optional cover asset ref | bookDetail |
| Catalog | SourceBookRef; ordered volume groupings and chapter refs, titles and order metadata | volumes / chapters |
| Chapter content | SourceChapterRef; existing F2 ChapterContent | chapterContent |
| Authentication | Explicit user-supplied credentials, session status and logout through a separate auth contract | authentication |

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

Secrets remain in memory or an approved secure-storage adapter only. Passwords
are not retained after sign-in; any remembered session is separately scoped and
stored only through that adapter. No secrets in Drift, shared_preferences,
fixtures, logs, URLs, exception strings or whole-response dumps. Redacted
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
No package candidate or support claim is adopted in this proposal.

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

These classifications are proposed for human review, not claims that every
Legacy quirk is desired. F3.2 expands the inventory and labels each fixture
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

All slices are **NOT STARTED / NOT AUTHORIZED**. Entry approval must name the
authorized slice(s); accepting this proposal alone does not approve dependencies
or exit. Default review sequence is the following, with evidence before advancing.

| Slice | Deliverables / scope | Tests and gate to next slice |
| --- | --- | --- |
| F3.1 Source Contracts + Registry | Neutral operation/result/failure/capability contracts, runtime registry over F2 identities, fake sources, injection boundaries | Unsupported-before-I/O, wrong-ref, duplicate registration, rename/unavailable preservation, cursor ownership and fake conformance; no Wenku8 parser/network |
| F3.2 Legacy Characterization + Fixture Harness | Evidence matrix, sanitized byte/DOM corpus, manifest and independently reviewed expectations; decoder/asset/volume identity and request policy specifications | Fixture integrity/sanitization and expected-value checks; reviewed coverage of section 5 before F3.4; dependency-free test scaffolding must not conceal a production parser |
| F3.3 Transport + Session + Security Foundation | Accepted dependency ADRs first; transport, session authority, secure-store abstraction/approved adapter, scripted server/fakes | Redirect/cookie isolation, deadlines/retries/cancellation, stale Set-Cookie, concurrent login/logout, secure-store failure and secret-exclusion tests; real package smoke on all targets |
| F3.4 Wenku8 Pure Parser + Request Builder | Pure encoding/DOM normalization and request construction using F3.2 evidence | Exact normalized fixtures, safe query encoding/host construction, malformed/error discrimination, ordered node/identity assertions; no runtime orchestration |
| F3.5 Wenku8 Runtime Adapter | Compose contracts, builder/parser, transport/session; explicit auth and paginated service flows | Deterministic end-to-end scripted search/explore/detail/catalog/content/auth; cancellation/late-result and transport-failure coverage; no feature/Reader UI |
| F3.6 Legacy Reconciliation + Source Neutrality Proof | Evidence-based chapter/source resolution plans and safe application through repositories; synthetic alternate-source conformance suite | Exact proof cases, ambiguous/reordered catalog stays unresolved, idempotency/reopen/rollback/user-edit conflict protection; no real second Source |
| F3.7 Cross-platform Validation + Exit Evidence | Final contract synchronization, platform builds/runtime smoke, bounded controlled live smoke and F3 exit record | Section 9 matrix, final-revision evidence, risk dispositions and explicit human exit approval; no automatic F4 entry |

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
human acceptance of this revision and ADR 0004; an explicit slice authorization;
and capability/failure/transport/session semantics reviewed sufficiently for F3.
No implementation starts merely because this document is committed.

| Decision / owner | Latest gate / consequence |
| --- | --- |
| HTTP and secure-storage package/backend choices, F3 owner + human reviewer | Separate ADR approval before dependent F3.3 code/dependency changes; unresolved choice blocks that work |
| Decoder/DOM libraries and byte normalization, F3.2 owner | Support/license review and independent fixtures before F3.4; critical dependency choices need ADR approval |
| Stable volume/asset locator mapping, provenance proof and numeric resource bounds, F3.2 owner | Reviewed specification before F3.3/F3.4 consumers; persistence changes need separate approved migration design |
| Concrete API signatures, F3.1 owner | Reviewed against section 3 before consumers; semantic changes require updated proposal/ADR |
| Reader position/fraction interpretation, F4; curl, F5 | No F3 implementation |
| Image request/cache/offline completeness and historical split content, F6 | No image fetching/cache or offline migration in F3 |
| Feature/import/auth UI and background update presentation, F7 | F3 supplies service interfaces and test harness only |
| Second real Source, F8; plugin ownership/runtime, F9 | Fake neutrality tests do not claim these phases complete |
| Real installed-app migration, performance/release matrix, F11 | F3 runtime validation does not claim release readiness |

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

Controlled live smoke is bounded, opt-in and separate from CI fixture tests:
record host-policy verification, operation outcomes, platform/toolchain and
revision without bodies/secrets. Use a reviewer-provided test account only where
needed; never Legacy bundled credentials. No bulk fetch or image downloads.
Required live behavior remains pending if unavailable; fixtures do not prove
current provider access. Record network/provider failures separately from parser
failures. No platform PASS inferred from another platform. Any proposed evidence
exception requires explicit human review with scope/owner/follow-up; the F2 waiver
does not apply.

The F3 exit record must contain the governance fields:

| Field | Required evidence |
| --- | --- |
| Deliverables | Accepted Source API v1 and ADRs, registry, fixtures, transport/session/security, pure parser/builder, runtime adapter, reconciliation and neutrality proof |
| Acceptance Criteria | F2 identity/content unchanged; declared capabilities work; no Core provider branches; no secret/data-loss blocker; no platform divergence |
| Required Automated Tests | Format, analyze, full test suite plus fixture/conformance/security/reconciliation tests with exact counts and commands |
| Required Platform Validation | Above builds and runtime results, plus controlled live evidence with explicit limitations |
| Evidence / Artifacts | Tested SHA, Flutter/Dart/OS/device, lockfile, CI/run links, fixture hashes and expected/actual assertions; sanitized output only |
| Known Exceptions | Owner, scope, reason, human disposition and follow-up; unavailable/waived is never PASS |
| Exit Approval | Explicit human F3 exit approval after evidence; F4 requires its own entry review |

Before exit, synchronize accepted semantics into SOURCE_API, ARCHITECTURE where
needed, CONTRACT_FREEZE_PLAN, tests/regression docs and ADR statuses through
human review. This draft does not freeze future contracts by itself.

## 10. Risk register

| ID / risk | Mitigation and evidence | Owner / blocking gate |
| --- | --- | --- |
| R1 Provider HTML/host drift | Frozen corpus plus separately labeled live evidence; old/new fixture comparison | F3.2/F3.5; parser/live acceptance |
| R2 Partial GBK/GB18030 decoder | Independent byte vectors, malformed/four-byte cases; reviewed dependency | F3.2/F3.4; parser gate |
| R3 Cookie leakage or stale auth resurrection | Per-target cookie policy, generation checks, sentinel tests, logout/restart proof | F3.3; security blocker |
| R4 Secure storage differs across platforms | Approved package matrix plus packaged failure/restart tests; explicit memory-only mode | F3.3/F3.7; dependency and exit blocker |
| R5 False chapter/volume/asset identity | No ordinal identity; reviewed durable mapping and provenance; ambiguous stays unresolved | F3.2/F3.6; identity/data-loss blocker |
| R6 Fixtures reproduce defects or lose byte semantics | Human-reviewed classifications, independent expectations, provenance/sanitization checks | F3.2; parser entry blocker |
| R7 Retry/cancel races or unbounded responses | Bounded policies, fake clock and deliberate late completions | F3.3/F3.5; runtime blocker |
| R8 Scope leaks into Reader/images/plugins | Slice diff/import review; service-only acceptance | Every slice reviewer; scope blocker |
| R9 Platform evidence incomplete | Final-SHA builds and packaged tests; unavailable stays pending | F3.7 + human owner; exit blocker |
| R10 Reconciliation overwrites user changes | Atomic receipt/current-state check, reopen/rollback/idempotency tests; schema review if needed | F3.6; data-loss blocker |

## 11. Proposal-only validation

On 2026-09-17 this documentation-only change passed
`dart format --output=none --set-exit-if-changed .` (56 files, zero changes),
`flutter analyze --no-pub` (no issues), and `flutter test --no-pub`
(370 passing tests). `git diff --check` passed. No dependencies, production code,
tests, schemas, generated files or platform runners were changed. These checks
protect the existing baseline; they are not F3 implementation or platform evidence.
No platform build or live provider smoke was run for this proposal.

Approval record: **PENDING**. Approver/date/authorized slices: **not recorded**.
This preparation ends at **READY FOR HUMAN F3 ENTRY REVIEW**.
