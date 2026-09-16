# Cross-Platform Policy

## Product targets

- iOS
- Android
- Windows

## Definition of “100% Dart” used by this project

All first-party product code is Dart/Flutter.

Flutter engine/platform runner code and internals of third-party Flutter packages are outside that definition.

The project does not maintain custom Swift/Kotlin/C++ implementations of core features.

## Feature parity

Core features must have one canonical behavior.

Adaptive UI is allowed.

Reduced core functionality on a target platform is not considered parity.

## Package gate

Required dependencies must support the full target matrix or provide an equivalent cross-platform fallback before adoption.
