# F3.7 deterministic platform evidence

Status: **IN PROGRESS — F3 EXIT NOT APPROVED**

The existing `integration_test/storage_smoke_test.dart` runner now exercises
the F3 runtime in a packaged Flutter process without contacting Wenku8 or any
public provider. It uses independent inline vectors and synthetic responses.
The test covers schema v2 open/reopen/rollback, a real v1-to-v2 packaged
upgrade retaining progress, secure-storage read/write/delete and new-adapter
read, typed/redacted injected failure, charset vectors, scripted
search/explore/detail/catalog/ordered content, Dio adapter execution, Source
session isolation and rejection of late response/cookies after logout.

| Platform | Runtime evidence | Result |
| --- | --- | --- |
| Windows | Windows NT 10.0.26200.0, Flutter 3.47.4, Dart 3.13.3, desktop target; `flutter test integration_test/storage_smoke_test.dart -d windows --no-pub`; 9 tests executed and passed | **PASS for this scripted packaged smoke** |
| Android | Existing manual CI emulator job runs this same integration test; current revision has not yet completed there | **UNPROVEN** |
| iOS | Existing manual CI simulator job runs this same integration test; current revision has not yet completed there | **UNPROVEN** |

The Windows result is execution evidence only for the listed assertions. It
does not establish Android/iOS PASS. The new secure-storage adapter instance
proves a second instance can read the value, but is **not a process-restart
test**. The injected failure proves the Source-neutral wrapper's typed/redacted
error path; it does not simulate every native plugin failure mode. Current
F3.7 exit review must retain those limits and any missing restart evidence.

The broader F3.7 gate also requires locked builds, the full deterministic
suite, generated-schema verification, relevant session/cancellation/security
regressions and final-revision runtime results on all three targets. Public
Wenku8 live smoke remains supplemental and is not a CI or F3 exit dependency.
