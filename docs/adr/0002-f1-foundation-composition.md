# ADR 0002 — Minimal F1 composition

Status: Accepted within the explicitly authorized F1 implementation scope

Date: 2026-09-16

## Context

F1 needs a testable application shell and the already approved Riverpod direction.
It has one placeholder destination and no content, persistence, or plugin work.
This decision does not change the Constitution or approve a native-code exception.

## Decision

- Add only `flutter_riverpod` 3.4.3 as a direct runtime dependency. Use manual
  providers and a root `ProviderScope`; no code generation or second state store.
- Keep provider composition, bootstrap and routing in `lib/src/app/`.
- Use Flutter's built-in `Navigator`/route factory for the single F1 home route.
  Unknown routes return to home without logging route names or arguments. A
  routing package is not needed for the current scope.
- Keep framework-independent failures and structured local logging in
  `lib/src/core/`. Bootstrap owns Flutter and root-isolate error hooks.
- Use `dart:developer` as the local diagnostic sink, with injectable writer/clock
  for tests. Record timestamp, level, event, failure code, runtime type and supplied
  runtime stack. Do not log arbitrary exception messages or external route data.

## Dependency acceptance

The [publisher's package page](https://pub.dev/packages/flutter_riverpod/versions/3.4.3)
declares iOS, Android and Windows support. The published package was current on
2026-09-16; its local manifest requires Dart `^3.12.0` and Flutter `>=3.0.0`, which
the selected Flutter 3.47.4 / Dart 3.13.3 satisfies. It adds no native platform
plugin. Actual local builds and iOS pending status are recorded separately in
`docs/FLUTTER_BASELINE.md`.

## Consequences

One direct runtime dependency is added; its transitive versions are locked in
`pubspec.lock`. Riverpod is required and has no optional runtime fallback: failed
dependency resolution blocks the build. Existing template dependencies remain.
The one-route shell does not promise deep-link semantics. Logging is local and is
not durable crash reporting, analytics, or telemetry. Future phases can extend
these boundaries under the existing governance process.
