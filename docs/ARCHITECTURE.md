# Architecture — Cross-Platform Flutter/Dart

## 1. Target platforms

First-class:
- iOS
- Android
- Windows

One canonical Dart implementation.

## 2. Layout

```text
lib/
└── src/
    ├── app/
    ├── core/
    ├── domain/
    ├── data/
    ├── source/
    ├── reader/
    │   ├── session/
    │   ├── pagination/
    │   ├── rendering/
    │   │   ├── scroll/
    │   │   ├── paged/
    │   │   └── page_curl/
    │   ├── gestures/
    │   └── progress/
    ├── plugin/
    └── features/
test/
integration_test/
fixtures/
ios/
android/
windows/
docs/
```

`ios/`, `android/`, and `windows/` are Flutter platform runners/build integration, not separate product implementations.

## 3. Dependency direction

```text
Feature UI
  ↓
Feature Controller
  ↓
Domain Contract
  ↓
Data/Source Infrastructure
```

Reader:

```text
Reader Feature
  ↓
ReaderController
  ↓
ReaderSession
  ↓
Dart Pagination / Scroll / Curl Renderers
  ↓
Domain content/repositories
```

## 4. No platform business forks

Feature/domain/reader code must not branch broadly on OS.

Do not create:
- `IOSReaderEngine`
- `AndroidReaderEngine`
- `WindowsReaderEngine`

Create:
- `ReaderEngine`

Adaptive differences such as mouse wheel vs touch gesture input should enter through Flutter's input system and normalize into the same Reader intents.

## 5. State and DI

Riverpod.

Scopes:
- app services
- feature controllers
- reader sessions
- download jobs
- local widget state

No global God Store.

## 6. Domain

Opaque source-aware identity.

Ordered `ContentNode` chapter content.

Models are Dart and framework-neutral where practical.

## 7. Persistence

Select only dependencies supporting the target matrix.

Conceptual split:
- small preferences
- structured database/state
- filesystem content/cache
- secret storage

The implementation package may use native internals, but the project architecture consumes one cross-platform Dart contract.

## 8. Network

One Dart `SourceTransport` abstraction.

Responsibilities:
- cancellation
- headers
- cookies/session
- timeout
- redirects
- retry policy
- status validation
- diagnostics

Parser separate from transport.

## 9. Images

One Dart image pipeline contract.

```text
SourceImageRequest
 -> ImageService
 -> memory/disk/inflight/network/decode
```

No platform-specific image architecture.

## 10. Reader

`ReaderSession` owns:
- active chapter
- request generation
- logical progress
- transitions
- repagination lifecycle

Renderers are pure Flutter/Dart behavior:
- scroll
- paged
- realistic page curl

Desktop input and mobile input normalize to common actions:
- next
- previous
- toggle controls
- scroll

## 11. Cross-platform page curl

Canonical implementation lives in Dart.

Prefer portable Flutter primitives:
- CustomPainter/Canvas
- Matrix4 transforms
- clipping paths
- gradients/shadows
- AnimationController
- GestureDetector/Listener

Shaders may be introduced only after cross-platform support and fallback are demonstrated.

Curl logic is separated into:
- geometry/model
- animation state machine
- renderer
- input mapping

This makes the effect testable without three native implementations.

## 12. Platform integration

Platform folders contain Flutter-generated runner/bootstrap code and required build configuration. OS integrations must use compliant cross-platform Flutter packages through Dart APIs.

Third-party packages may contain native internals only when their Dart API and required functionality support iOS, Android, and Windows. Those internals do not authorize project-owned native product implementations or custom platform-channel core feature implementations.

An ADR cannot override the Constitution. Changing a Constitution-level rule requires explicit human approval and synchronized governance updates as defined in `docs/GOVERNANCE.md`.

## 13. Packages

Every required package gets a support-matrix check.

A package that is iOS/Android-only must not be required for:
- Reader
- Source
- persistence
- image pipeline
- plugin runtime
- core navigation/state

## 14. Plugin runtime

Must have one behavior across all targets.

If a candidate JavaScript engine/package lacks Windows support, reject it for the canonical runtime or supply an equivalent cross-platform runtime behind the exact same semantics before adoption.

## 15. Responsive/adaptive UI

Cross-platform does not mean phone UI stretched onto Windows.

Features share controllers/domain state, while Flutter widgets may adapt layout based on:
- viewport width
- pointer/keyboard availability
- platform conventions where cosmetic

Adaptive presentation must not fork business behavior.

## 16. Architecture changes

Changes to:
- dependencies
- persistent schema
- Source API
- Reader contracts
- plugin runtime
- target platform support

require docs/ADR updates.
