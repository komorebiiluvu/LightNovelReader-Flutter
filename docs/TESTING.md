# Testing Strategy

## 1. Pyramid

### Unit tests
For:
- identity
- ContentNode serialization
- Reader settings/invalidation key
- ReaderSession state transitions
- cache key
- migration transforms
- manifest/version compatibility
- Source request construction

### Fixture tests
For every Source:
- search
- explore
- detail
- volume/chapter list
- chapter content
- authentication response shapes where safely reproducible
- malformed/error pages

Fixture tests are the primary parser regression layer.

### Repository/data tests
Use temporary SQLite/file roots.

Never run migration/data-loss tests against real user storage.

### Widget tests
Use deterministic fake repositories/sources.

Focus on:
- state-to-UI contract
- Reader controls
- Explore pagination triggers
- error/loading states

### Integration tests
Cover:
- search -> detail -> reader
- bookshelf -> continue
- download -> offline read
- settings -> repagination
- source switch/isolation
- plugin -> normalized Source models

### Platform integration validation
Use Flutter integration tests and platform build/run checks on iOS, Android, and Windows for behavior that unit/widget tests cannot exercise, including generated runners and approved third-party package integrations.

Third-party native internals do not authorize first-party native product implementations. This validation category remains subject to the Constitution and the change-authority rules in `docs/GOVERNANCE.md`.

### Real-device regression
Required for:
- realistic page curl
- rapid gestures
- large/image-heavy chapters
- orientation
- background/foreground
- profile/release performance

## 2. Commands

Normal checks:

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Integration:

```bash
flutter test integration_test
```

Use exact device selection in CI/local scripts when multiple devices exist.

## 3. Fixture rules

Fixtures:
- must be sanitized
- must not contain credentials/cookies
- should preserve relevant encoding/DOM structure
- should have expected normalized output
- should include malformed cases

A website change should produce:
- old fixture
- new fixture
- parser diff
- updated/added expectation

## 4. Characterization tests

When migrating legacy behavior, a characterization test may intentionally record current behavior before deciding whether it is a bug.

Do not accidentally promote a known defect into a permanent desired contract.

Mark:
- desired behavior
- legacy behavior
- known defect
explicitly.

## 5. Test quality rule

A test file existing does not mean a behavior is covered.

A test must prove the behavior through meaningful assertions.

Screenshots alone do not prove Reader page state.

## 6. Data migration tests

Must cover:
- clean install
- legacy import
- interrupted import
- corrupted legacy state
- duplicate identity
- missing optional fields
- old offline cache
- repeat migration idempotency

## 7. Performance testing

Use profile/release mode on real hardware.

Record:
- device
- OS
- Flutter version
- commit
- scenario
- cold/hot cache
- frame timings
- memory

Do not compare debug-mode smoothness to release targets.
