# AGENTS.md — LightNovelReader Cross-Platform Flutter

## 1. Repository role

This repository is the active development repository for the Flutter/Dart generation of LightNovelReader.

Legacy implementation reference:
- `https://github.com/komorebiiluvu/LightNovelReader-For-IOS`
- Role: reference implementation, regression baseline, historical Git record, Reader behavior reference, KMP/Wenku8 troubleshooting knowledge base.

The legacy repository is behavioral evidence, not the architecture template.

## 2. Non-negotiable platform rule

Target platforms:

- iOS
- Android
- Windows

The project uses **one canonical Flutter/Dart product implementation**.

All first-party product logic and UI must be implemented in Dart/Flutter.

Do not add hand-written Swift, Objective-C, Kotlin, Java, C++, Rust, or platform-channel business implementations for product features.

Exceptions are limited to:
- Flutter-generated platform runner/bootstrap files;
- third-party Flutter packages that internally use platform code, if they support the target platform matrix and are wrapped behind a cross-platform Dart API.

A feature is not complete if it only works on one target platform without an explicitly approved cross-platform fallback.

## 3. Read before changing code

Read, in order:

1. `docs/PROJECT_CONSTITUTION.md`
2. `docs/GOVERNANCE.md`
3. `docs/ARCHITECTURE.md`
4. `docs/MIGRATION_FROM_SWIFT.md`
5. task-specific docs:
   - Reader: `docs/READER_ENGINE.md`
   - Source: `docs/SOURCE_API.md`
   - Plugin: `docs/PLUGIN_API.md`
   - Testing: `docs/TESTING.md`, `docs/REGRESSION_CHECKLIST.md`
   - Build: `docs/BUILD.md`

Do not load the whole repository without a concrete reason.

## 4. Technology policy

Primary implementation:
- Dart
- Flutter

State/dependency composition:
- Riverpod

No native iOS page-curl escape hatch exists in the architecture.

The Reader, including realistic page-turning, must use Flutter/Dart rendering primitives shared by iOS, Android, and Windows.

If exact parity with a platform-native effect cannot be achieved cross-platform, prefer a high-quality cross-platform approximation over introducing a platform-specific implementation.

## 5. Dependency acceptance rule

Before adding a package, verify:

- iOS support
- Android support
- Windows support
- active maintenance
- compatibility with current Flutter stable
- behavior when the package is unavailable or unsupported

A package that supports only one target platform must not become a required dependency for a core feature.

Optional platform integrations require a Dart abstraction plus a functional cross-platform fallback.

## 6. Core architecture rules

Allowed direction:

`Feature UI -> Application/Controller -> Domain Contract -> Infrastructure Adapter`

Reader:

`Reader UI -> ReaderSession -> Dart Reader Engine/Renderer -> Domain`

Source:

`Feature/Application -> SourceRegistry -> Source -> Built-in Source or Plugin Adapter`

Forbidden:
- Feature widgets parsing website HTML
- Reader depending on Wenku8/plugin details
- Domain models containing Wenku8 URLs/selectors/aid/cookies
- Plugin code injecting arbitrary Flutter widgets
- platform-specific first-party implementations of core product behavior
- a giant global AppStore
- platform conditionals scattered through feature code

## 7. Platform abstraction rule

Use platform checks only inside narrowly defined infrastructure capabilities.

Feature/domain code must not contain widespread:

```dart
if (Platform.isIOS) ...
if (Platform.isAndroid) ...
if (Platform.isWindows) ...
```

Prefer one cross-platform implementation.

When OS integration truly differs, expose a Dart contract and implement supported behavior through cross-platform Flutter packages or isolated adapters with equivalent user-facing behavior.

## 8. State management

Use Riverpod.

- Prefer feature/session Notifiers.
- Domain models remain Flutter-agnostic.
- Networking, persistence, parsing, and UI state do not belong in one provider.
- Long-running work needs cancellation/obsolescence semantics.
- Only the active generation may commit async results.

Do not add a second global state framework without an ADR.

## 9. Data/model rules

Identity is source-aware and opaque.

Minimum:

```dart
SourceBookRef(sourceId, bookId)
SourceChapterRef(sourceId, bookId, chapterId)
```

Canonical chapter content is ordered:

```dart
ChapterContent(nodes: List<ContentNode>)
```

v1 required:
- text
- image

## 10. Reader safety

Before changing Reader:
1. read `docs/READER_ENGINE.md`;
2. read relevant regressions;
3. identify callers/state owners;
4. define acceptance criteria;
5. add/adjust tests first for historical behavior.

Do not:
- introduce iOS-only curl
- maintain different Reader engines per OS
- change pagination, gestures, progress, and rendering in one patch
- claim 120 Hz from static analysis

## 11. Source/plugin safety

A Source returns normalized models.

Plugin v1 is a content-source plugin, not an app extension.

Plugins must not:
- inject Flutter/native UI
- execute native binaries
- access arbitrary filesystem paths
- call unrestricted system APIs

## 12. Persistence safety

User assets:
- bookshelf
- progress
- downloads/offline chapters
- reader settings
- source mappings

must survive upgrades.

Preferences, structured state, cache, downloads, and secrets are separate concerns.

## 13. Context loading

Start with:
1. target module
2. direct dependencies
3. direct consumers
4. relevant tests
5. relevant docs

Expand only when evidence requires it.

## 14. Small safe changes

Prefer:

`one boundary -> analyze/test -> change -> format/analyze/test -> commit`

Split by responsibility, not line count.

## 15. Required checks

Normal Dart/Flutter task:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Platform-sensitive work must be validated on every affected target.

## 16. Definition of done

Relevant completion requires:
- formatting
- static analysis
- tests
- regression consideration
- documentation updates for contract changes
- no known data loss
- no unexplained platform divergence

Core feature work is not release-ready until iOS, Android, and Windows compatibility is accounted for.

## 17. Migration stance

This is not a blank-slate product redesign.

The old Swift/KMP app is the behavior oracle.

Default preference:

**Preserve proven behavior. Rebuild the implementation once in cross-platform Dart.**


## 18. Governance precedence

When rules conflict:

1. Project Constitution
2. Accepted ADRs
3. Architecture / module contracts
4. AGENTS.md
5. Task prompt

Do not weaken a higher-level rule to make a task easier.

Any exception to a normative architecture rule requires an ADR and human approval.

The frozen legacy behavior reference is defined in `docs/LEGACY_BASELINE.md`.

Deferred contracts and the phase in which they must become final are listed in `docs/CONTRACT_FREEZE_PLAN.md`.
