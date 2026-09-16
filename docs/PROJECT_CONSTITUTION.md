# Project Constitution — Cross-Platform Dart/Flutter LightNovelReader

Governance Specification: **v0.2**

Status: **Active for Foundation Development**

Normative governance and precedence rules are defined in `docs/GOVERNANCE.md`.

Legacy behavior is frozen at the commit defined in `docs/LEGACY_BASELINE.md`.

## 0. Mission

Build LightNovelReader into a long-lived, reader-first, source-extensible, AI-maintainable application with one canonical Flutter/Dart implementation.

Primary deployment targets:

- iOS
- Android
- Windows

The implementation stack changes from Swift/KMP to Flutter/Dart.

The product behavior does not reset to zero.

The legacy iOS project remains:
1. reference implementation
2. regression baseline
3. Reader behavior specification
4. troubleshooting knowledge base
5. parser/source reference
6. performance lessons database

## 1. Most important rule

**Preserve proven behavior; rebuild the implementation once in cross-platform Dart.**

Before reimplementing a feature, answer:
- What does the current app actually do?
- Which edge cases were fixed?
- Which behavior is intentional?
- What test/fixture proves parity?
- Does the new implementation work consistently on iOS, Android, and Windows?

## 2. 100% Dart project-owned product layer

All project-owned:
- domain logic
- application logic
- Reader engine
- rendering behavior
- Source system
- plugin host
- persistence orchestration
- feature UI

must be Dart/Flutter.

Do not add hand-written native implementations for core product behavior.

Flutter itself and some third-party packages may contain native code internally. That does not violate this rule as long as the project consumes them through cross-platform Dart APIs and the dependency supports the target platform matrix.

## 3. Cross-platform parity rule

The canonical behavior is platform-neutral.

Do not define “iOS behavior” as the real product and Android/Windows as reduced ports.

If exact platform-native visual behavior cannot be reproduced everywhere, choose a high-quality common behavior.

Platform-specific OS integration may differ only where the operating systems genuinely differ.

## 4. Reader policy

Reader is cross-platform Dart.

Supported architecture includes:
- continuous scroll
- paginated reading
- cross-platform realistic page-turn effect
- tap/swipe gestures
- chapter transitions
- progress restore
- settings
- ordered text/image content

The realistic page-turn effect must be implemented with Flutter/Dart rendering primitives.

Allowed techniques:
- Canvas/CustomPainter
- transforms
- clipping
- gradients/shadows
- animation controllers
- Dart-side gesture/state machines
- Flutter-supported shaders only when they behave across all target platforms

No native UIPageViewController fallback.

If the Flutter curl cannot perfectly match the legacy iOS native curl, behavioral correctness and cross-platform consistency take priority over exact visual imitation.

## 5. Product identity

A reader-first, extensible light novel reader with a consistent high-quality experience across supported platforms.

Flow:

`Search -> Open -> Read -> Continue when updated`

## 6. Architecture qualities

Prefer:
- simple
- explicit
- testable
- replaceable
- cancellable
- source-neutral
- platform-neutral

Avoid:
- giant Clean Architecture ceremony
- global mutable stores
- mega services
- platform conditionals in feature code
- duplicated per-platform product implementations
- premature design systems

## 7. UI strategy

During Core migration:
- preserve information architecture and behavior
- change UI only as needed for Flutter implementation
- no broad visual redesign
- design responsive/adaptive layouts from the start for phone/tablet/desktop
- do not fork separate iOS/Android/Windows feature trees

UI redesign starts after Core Feature Freeze.

## 8. Source-neutral core

Core does not know Wenku8.

Opaque IDs:
- `SourceId`
- `BookId`
- `ChapterId`
- `VolumeId`

Capabilities drive UI.

No source-name branching.

## 9. Ordered content

Canonical chapter model:

```text
Text
Image
```

in one ordered node list.

Legacy unordered data uses an explicit conversion policy; do not fabricate historical image positions.

## 10. Image architecture

A Source image is a request descriptor, not merely a URL.

Support:
- headers
- Referer
- Cookie/session
- source identity
- stable cache key
- memory cache
- disk cache
- cancellation
- deduplication
- retry
- downsampling
- offline reuse

Image behavior must be supported on iOS, Android, and Windows.

## 11. Persistence

Separate:
- preferences
- structured state
- cache
- downloads/user assets
- secrets

Structured state uses a versioned cross-platform storage layer.

Any dependency selected for persistence must support iOS, Android, and Windows.

No migration by deleting user data.

## 12. Package/dependency policy

Before adding a required package:
- verify iOS
- verify Android
- verify Windows
- verify maintenance/Flutter compatibility
- define fallback if optional

A package lacking Windows support cannot become a required core feature dependency.

Record important package choices in ADRs.

## 13. Plugins

Plugin v1 is content sources only.

External source plugins must not require downloadable Dart application code.

Use:
- manifest
- constrained script runtime or future declarative rules

The runtime choice itself must support iOS, Android, and Windows.

No native-only plugin runtime.

## 14. Performance

Rules:
- parsing off frame-critical work
- disk serialization off frame-critical work
- downsample images
- cancel obsolete tasks
- deduplicate identical work
- visible content > prefetch
- bounded concurrency

Performance is measured separately on each target because renderer/OS/device behavior differs.

No platform is declared performant based on another platform’s measurements.

## 15. Testing matrix

Use:
- unit tests
- fixture tests
- repository tests
- widget tests
- integration tests

Required platform matrix for release-sensitive flows:
- iOS
- Android
- Windows

Historical bugs become cross-platform regression cases unless inherently platform-specific.

## 16. Legacy relationship

Legacy:
`LightNovelReader-For-IOS`

Current:
cross-platform Flutter repository

Keep legacy:
- audits
- regressions
- fixtures
- migration notes
- historical links

Do not import the entire old implementation into active production architecture.

## 17. Migration reuse

Reuse:
- behavior
- data semantics
- tests/fixtures
- parser rules
- algorithmic lessons
- historical bug knowledge
- performance constraints

Reimplement in Dart:
- app shell
- state/application layer
- persistence
- Source
- network abstraction
- Reader
- page-turn rendering
- UI
- plugin host

## 18. Small-safe-change rule

One boundary per patch.

Repository remains:
- buildable
- testable
- understandable
- recoverable

## 19. Phases

### F0 — Governance and legacy freeze
Define cross-platform Dart rules and regression inventory.

### F1 — Flutter foundation
Initialize app, Riverpod, routing, logging/errors, CI, and build baselines for iOS/Android/Windows.

### F2 — Domain + persistence
Source-aware identity, ordered content, library/progress/settings schema, migration interfaces.

### F3 — Source foundation
Source API, registry, transport/session, fixture harness, Wenku8 Dart source.

### F4 — Reader foundation
ReaderSession, continuous scroll, paginated renderer, settings/progress/cache invalidation.

### F5 — Cross-platform realistic page curl
Implement and validate the Flutter/Dart curl renderer on iOS, Android, and Windows.

### F6 — Images + downloads/offline
Cross-platform image pipeline and offline integrity.

### F7 — Feature migration
Bookshelf, Explore, Search, Detail, Settings, Export.

### F8 — Second real Source
Prove Source neutrality.

### F9 — Plugin Runtime MVP
Choose a runtime that is available on all three target platforms.

### F10 — Plugin developer experience
Template, fixtures, schema, tooling.

### F11 — Stabilization
Data migration, slow network, large books, memory, lifecycle, desktop/window resizing, real-device/profile validation.

### F12 — Core Feature Freeze

### F13 — UI/UX redesign
Responsive/adaptive redesign without platform-specific business forks.

## 19.1 Phase Exit Requirements

Every F1–F13 phase must have a phase-specific exit record using the governance template:

- Deliverables
- Acceptance Criteria
- Required Automated Tests
- Required Platform Validation
- Evidence / Artifacts
- Known Exceptions
- Exit Approval

A phase does not auto-advance because implementation tasks are complete.

### F1 — Flutter Foundation exit

Required before F2:

- one canonical Flutter project exists
- iOS, Android, Windows targets are generated/configured
- dependency support matrix exists for required F1 packages
- format/analyze/test baseline passes
- each target has an explicit build status; unavailable local toolchains are backed by CI/another environment before F1 exit
- logging/error/bootstrap/routing/state foundation is documented
- no core feature implementation has introduced platform-specific business forks

### F2 — Domain + Persistence exit

Required before F3:

- source-aware opaque identity contract accepted
- ordered content model accepted
- structured persistence schema/versioning accepted
- migration/import commitment documented
- persistence migration tests exist
- no known data-loss blocker

### F3 — Source Foundation exit

Required before F4:

- Source API v1 accepted
- capability/error semantics accepted
- transport/session/cancellation semantics accepted
- Wenku8 fixture corpus and parser tests pass
- Source core contains no Wenku8-name branching

### F4 — Reader Foundation exit

Required before F5:

- Reader logical position model accepted
- ReaderSession ownership/cancellation semantics accepted
- continuous scroll and paginated modes pass deterministic tests
- progress restore and setting-driven repagination pass
- no unresolved Reader state corruption blocker

### F5 — Page Curl exit

Required before F6:

- pure Flutter/Dart curl implementation exists
- historical curl regression behaviors are covered
- iOS/Android/Windows interaction validation completed
- visual reference review completed
- no platform-specific Reader implementation introduced

### F6 — Images + Downloads/Offline exit

Required before F7:

- image request/cache contract accepted
- offline/download completeness semantics accepted
- cancellation/dedup/retry tests pass
- partial/failure/restart behavior verified
- no cross-source cache collision

### F7 — Feature Migration exit

Required before F8:

- bookshelf/explore/search/detail/settings/export use new contracts
- critical user flow works end-to-end
- no feature bypasses Source/Reader/persistence boundaries

### F8 — Second Source exit

Required before F9:

- second structurally different source works
- no source-name branch is needed in Core/Reader/UI
- any contract change is generalized and documented

### F9 — Plugin Runtime exit

Required before F10:

- runtime supports iOS/Android/Windows
- permissions, termination, validation, and resource limits are specified
- malformed/hostile plugin tests demonstrate isolation
- plugin failure cannot crash the app

### F10 — Plugin DX exit

Required before F11:

- template/schema/docs/test runner agree with actual host
- a source can be developed from the documented workflow without app-core knowledge

### F11 — Stabilization exit

Required before F12:

- quantified performance thresholds are defined and measured
- migration/upgrade recovery is exercised
- critical regression checklist is green or explicitly waived where allowed
- release-support platform/OS matrix is defined
- no known data-loss/security/release blocker

### F12 — Core Feature Freeze exit

Core Feature Freeze means:

- Core domain contracts are stable
- persistence schema and migration policy are stable
- Reader contract is stable
- Source API is stable
- Plugin API/runtime contract is stable if plugin support is in the target release
- cross-platform build matrix is green
- critical regressions are green
- no known data-loss blocker
- no unresolved architecture exception lacks an ADR
- release-critical documentation reflects actual implementation

Only after explicit human approval of F12 may F13 UI/UX Redesign begin.

### F13 — UI/UX Redesign exit

- redesigned UI does not bypass Core boundaries
- critical functionality remains equivalent
- accessibility/adaptive layout reviewed
- platform release matrix remains valid

## 20. Definition of done

At minimum:
- format/analyze
- tests
- regression review
- docs for contract changes
- no known data loss
- no unexplained platform divergence

Release-sensitive functionality must account for all supported target platforms.
