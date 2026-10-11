# F3.7 deterministic platform evidence

Status: **IN PROGRESS — F3 EXIT NOT APPROVED**

The existing `integration_test/storage_smoke_test.dart` runner now exercises
the F3 runtime in a packaged Flutter process without contacting Wenku8 or any
public provider. It uses independent inline vectors and synthetic responses.
The test covers schema v2 open/reopen/rollback, a real v1-to-v2 packaged
upgrade retaining progress, secure-storage read/write/delete and new-adapter
read, typed/redacted injected failure, charset vectors, scripted
search/explore/detail/catalog/ordered content, Dio adapter execution, Source
session isolation, caller cancellation, and rejection of late response/cookies
after logout. The
`integration_test/secure_store_restart_test.dart` test runs in two separate
Flutter processes: the first writes a synthetic value, the second reads and
deletes it. The existing CI device runners execute both stages on the same
target with a run-scoped key. Mobile restart checks use `flutter drive` with
`--keep-app-running` for the write stage, explicitly stop that application
process, then launch the read stage. An uninstall/reinstall is not a
process-restart test.

| Platform | Runtime evidence | Result |
| --- | --- | --- |
| Windows | Windows NT 10.0.26200.0, Flutter 3.47.4, Dart 3.13.3, desktop target; `flutter test integration_test/storage_smoke_test.dart -d windows --no-pub` passed 10 tests; separate `secure_store_restart_test.dart` write and read launches each passed 1 test | **PASS for listed scripted packaged and process-restart smoke** |
| Android | Run [38125926148](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/38125926148) passed all 10 packaged Source/runtime checks, then its separate `flutter test` read launch found no stored value. The retained-installation restart workflow has not yet run on Android. | **PASS for 10 listed packaged checks; restart UNPROVEN** |
| iOS | Existing manual CI simulator job runs this same integration test; current revision has not yet completed there | **UNPROVEN** |

The Windows result is execution evidence only for the listed assertions. It
does not establish Android/iOS PASS. The new secure-storage adapter instance
alone is not restart evidence; the separate write/read process launches provide
that Windows evidence. The injected failure proves the Source-neutral wrapper's
typed/redacted error path; it does not simulate every native plugin failure
mode. Flutter 3.47.4's `flutter test` integration runner defaults to uninstalling
the app after a test, so the old Android read failure did not test ordinary
process restart. Android and iOS
process-restart results remain **UNPROVEN** until
the updated workflow completes at the exact tested revision.

The broader F3.7 gate also requires locked builds, the full deterministic
suite, generated-schema verification, relevant session/cancellation/security
regressions and final-revision runtime results on all three targets. Public
Wenku8 live smoke remains supplemental and is not a CI or F3 exit dependency.
