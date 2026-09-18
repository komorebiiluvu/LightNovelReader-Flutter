# F3.4 Charset Platform Evidence

Evidence scope: the already implemented charset foundation at
`be7462871e656286e740b384350603837dfca0b1`. This gate covers runtime
execution only. It does not authorize or include an HTML parser, Wenku8
parser, request builder, Source runtime, or F3.5.

## Required vectors

The same independently authored assertions are required on each runtime:

| Mode | Bytes | Expected result |
| --- | --- | --- |
| `LegacyCP936Compatible` | `d6d0cec4d0a1cbb5` | `中文小说` |
| `LegacyCP936Compatible` | `aaa1` | `U+E000` |
| `GB18030` | `81308130` | `U+0080` |
| `GB18030`, strict | `8130ff` | typed strict failure |
| `GB18030`, strict | `813081` | typed strict failure |
| `GB18030`, replacement | malformed input | explicit visible `U+FFFD` and replacement metadata |

The runtime boundary remains `RawBytes -> CharsetDecoder ->
DecodedDocument`. Replacement mode is selected explicitly; no runtime charset
guessing or fallback is part of this evidence.

## Results

| Platform | Runtime environment | Result | Evidence and limitation |
| --- | --- | --- | --- |
| Windows | Windows 11 25H2, Flutter 3.47.4, Dart 3.13.3, `windows-x64` target | **PASS** | `flutter test test/source/charset/charset_codec_test.dart -d windows --no-pub`; 12 codec tests executed on the Windows Flutter target and passed. |
| Android | No connected device or emulator; SDK 36 installed, no AVD | **UNPROVEN** | An APK compile exists from the foundation evidence, but it is not runtime evidence. No Android process executed these vectors. A temporary system-image installation was unavailable within this environment; the existing `integration_test` runner was not changed. |
| iOS | Windows host, no macOS runner or iOS simulator/device | **UNPROVEN** | No iOS process executed these vectors. Existing iOS simulator integration infrastructure remains available in the macOS CI job; no iOS PASS is inferred here. |

Android and iOS remain explicit evidence gaps. The Windows result does not
waive either gap, and Android/iOS unavailability is not converted into a
platform PASS. The F3.4 platform gate is therefore incomplete for parser-entry
purposes until real Android runtime execution and iOS simulator/device
execution are recorded.

## Infrastructure and scope audit

The repository's existing `integration_test/` and CI device selection remain
the applicable smoke infrastructure. This documentation-only change does not
create a second CI framework, add a dependency, change a workflow, or alter the
existing storage smoke. The storage smoke is not treated as charset evidence
because it does not execute the charset vectors.

The charset foundation remains **IMPLEMENTED**. No parser work, Wenku8 work,
request-builder work, network work, Source runtime work, schema work, or F3.5
work was started by this gate.
