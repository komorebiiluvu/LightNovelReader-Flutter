# LightNovelReader — Cross-Platform Flutter

A reader-first, source-extensible light novel reader implemented as one canonical Flutter/Dart application for:

- iOS
- Android
- Windows

## Core direction

- Reader-first
- Search -> Read
- Source-extensible
- Plugin-first for content sources
- AI-maintainable
- Cross-platform by architecture, not by parallel platform rewrites

## Implementation rule

All first-party product logic and UI are Dart/Flutter.

There is no iOS-specific Reader implementation and no native page-curl fallback in the product architecture.

Flutter-generated platform runners and third-party Flutter packages may internally contain native code; project-owned business/UI behavior remains Dart and must preserve equivalent behavior across targets.

## Legacy reference

Previous implementation:

`https://github.com/komorebiiluvu/LightNovelReader-For-IOS`

The legacy project remains the source for:
- Reader behavior
- regression history
- parser/source knowledge
- migration formats
- performance lessons

This repository does not mechanically translate Swift files into Dart.

## Architecture entry points

Read:
- `AGENTS.md`
- `docs/PROJECT_CONSTITUTION.md`
- `docs/GOVERNANCE.md`
- `docs/LEGACY_BASELINE.md`
- `docs/CONTRACT_FREEZE_PLAN.md`
- `docs/ARCHITECTURE.md`
- `docs/MIGRATION_FROM_SWIFT.md`
- `docs/READER_ENGINE.md`
- `docs/SOURCE_API.md`
- `docs/PLUGIN_API.md`
- `docs/TESTING.md`
- `docs/REGRESSION_CHECKLIST.md`
- `docs/BUILD.md`
