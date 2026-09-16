# Reader Engine — Pure Flutter/Dart

## 1. Goal

Provide one high-quality Reader implementation across iOS, Android, and Windows.

No native Reader implementation is allowed in the canonical architecture.

## 2. Structure

```text
ReaderFeature
  ↓
ReaderController
  ↓
ReaderSession
  ├── ChapterLoader
  ├── ProgressRepository
  ├── PaginationEngine
  └── Renderer
       ├── ScrollRenderer
       ├── PagedRenderer
       └── PageCurlRenderer
```

All are Dart/Flutter.

## 3. ReaderSession owns

- source/book/chapter identity
- load generation/epoch
- cancellation/obsolescence
- logical position
- chapter transitions
- progress commits
- repagination lifecycle
- renderer-independent state

Old async results cannot commit after the session moves on.

## 4. Content

Input is ordered `ChapterContent(nodes)`.

Images remain in source order.

## 5. Scroll renderer

Must support:
- position restore
- next-chapter transition
- duplicate-transition prevention
- short chapters
- image-heavy content
- lifecycle/window resize
- touch, wheel, trackpad behavior

## 6. Paged renderer

Pagination is Dart.

Cache key accounts for:
- content/version
- font
- size
- line/paragraph spacing
- margins
- viewport
- text scale
- layout-affecting theme values

Obsolete pagination cannot commit.

## 7. Realistic page curl

The curl is implemented in Flutter/Dart.

Architecture:

```text
CurlGeometry
CurlStateMachine
CurlGestureInterpreter
CurlPainter/Renderer
```

Suggested portable primitives:
- `CustomPainter`
- `Canvas`
- `Path`
- `Matrix4`
- clipping
- gradients
- shadows
- `AnimationController`
- pointer/touch gestures

Do not bind the canonical behavior to `UIPageViewController` or any OS-native curl component.

## 8. Curl acceptance criteria

Historical legacy behaviors become cross-platform tests:

- opening reader never crashes
- previous/left action never crashes
- next/right action works
- swipe and tap cannot double-commit
- animation lock cannot remain stuck
- timeout/recovery path exists
- late completion cannot mutate a new session
- chapter switch resets stale curl state
- page back appearance matches theme
- dark mode front/back coherent
- no abnormal glossy/plastic appearance
- setting/theme changes invalidate rendered pages
- rapid interactions remain recoverable

In addition:
- mouse click/drag on Windows maps to equivalent intents
- window resize during/after animation cannot corrupt state
- touch, mouse, and trackpad paths converge on the same state machine

## 9. Cross-platform compromise rule

The legacy native iOS curl is a visual/behavior reference only.

If an exact replica would require platform-specific code, do not add native code.

Prefer:
1. behavior correctness
2. stable progress/state
3. cross-platform interaction consistency
4. high-quality visual approximation
5. exact legacy visual parity

in that order.

## 10. Testing

Pure Dart:
- Curl geometry math
- state transitions
- lock/recovery
- obsolete-event rejection
- chapter boundary behavior

Widget:
- paged/curl controls
- resizing
- pointer/touch mappings

Integration:
- open/read/next/restore
- setting changes
- image-heavy chapters

Platform matrix:
- iOS device/simulator
- Android device/emulator
- Windows desktop

## 11. Performance

Measure independently:
- iOS
- Android
- Windows

Use profile/release mode.

No 120 Hz or smoothness claim based on another platform.
