# Migration from Swift/KMP to Cross-Platform Dart

## 1. Direction

Legacy:
`https://github.com/komorebiiluvu/LightNovelReader-For-IOS`

New production architecture:
one Flutter/Dart implementation for iOS, Android, and Windows.

This is not a file-by-file translation.

## 2. Preserve behavior, not platform implementation

Preserve:
- Reader interaction semantics
- regression fixes
- progress behavior
- parser/source behavior
- cache/image lessons
- migration formats
- performance constraints

Do not preserve as production architecture:
- SwiftUI/UIKit Reader
- native page curl
- KMP
- SharedKit
- Hybrid routing
- global AppStore
- Wenku8 leakage
- platform-specific business state

## 3. Reader migration

The old Reader is a behavior oracle.

Order:
1. deterministic content fixtures
2. ReaderSession
3. continuous scroll
4. paginated Reader
5. settings/progress/invalidation
6. cross-platform chapter transitions
7. pure Flutter/Dart realistic curl
8. iOS/Android/Windows regression
9. performance optimization

Do not start by trying to reproduce every pixel of iOS native curl.

## 4. Source migration

Use Swift/Kotlin parsers as references only.

Order:
1. sanitized fixtures
2. neutral Source API
3. Dart transport/session
4. Dart Wenku8 parser
5. normalized output comparison
6. controlled live smoke
7. second source
8. plugin API freeze

KMP is not carried into the Flutter app.

## 5. Data migration

Build explicit import from legacy iOS data if continuity is required.

Inventory:
- library
- source mappings
- reading progress
- settings
- statistics if retained
- offline data
- credentials/cookies, handled securely

Migration must be idempotent and recoverable.

## 6. Cross-platform migration principle

Do not first reproduce iOS and later “port Flutter” to Android/Windows.

Every new core boundary is designed with all target platforms in mind from day one.

A core dependency that blocks Windows is rejected or isolated before it becomes foundational.

## 7. Completion

Migration completes when:
- user data continuity works
- Source flows work
- Reader and regressions work on all targets
- offline works
- performance is measured per platform
- KMP/SharedKit/native Reader code are not production dependencies
