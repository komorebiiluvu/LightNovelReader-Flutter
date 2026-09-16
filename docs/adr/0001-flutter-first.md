# ADR 0001 — Single cross-platform Flutter/Dart product implementation

Status: Accepted

## Context

The previous application used Swift/SwiftUI/UIKit plus KMP.

The new product must deploy to iOS, Android, and Windows without maintaining three product implementations.

## Decision

Use Flutter/Dart as the single canonical first-party product implementation.

Project-owned business logic, Reader behavior, Source system, plugin host, persistence orchestration, and UI are Dart/Flutter.

Do not use custom native Reader/page-curl implementations.

Flutter-generated platform runners and cross-platform third-party packages may contain native internals.

## Consequences

Benefits:
- one product behavior
- one Reader state machine
- one Source/plugin architecture
- one feature codebase
- lower long-term platform drift

Costs:
- native iOS page-curl cannot simply be reused
- realistic page curl must be rebuilt in Flutter/Dart
- visual parity may be approximate rather than identical
- every foundational package must be screened for Windows support
- platform performance must be measured independently

## Rejected

### Native iOS curl adapter
Rejected because it creates a different Reader implementation and long-term feature parity risk.

### Parallel per-platform implementations
Rejected because it defeats the cross-platform maintenance goal.

### Carry KMP into Flutter
Rejected because it retains an unnecessary parallel toolchain/runtime layer.
