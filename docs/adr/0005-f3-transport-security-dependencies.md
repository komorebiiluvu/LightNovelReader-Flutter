# ADR 0005 — F3.3 Transport and Security Dependencies

Status: **ACCEPTED**. Human approval: **APPROVED**.
Proposal date: **2026-09-18**. Approval date: **2026-09-18**.
Approved by: **Human project owner**. Accepted baseline:
`13408a83ca58158a8e7d74d911a71c183eaff590`.

This ADR records the human-approved dependency decision for F3.3. It authorizes
adding and using only the exact dependencies listed below for F3.3; it does not
authorize any dependency or implementation outside that slice. The approval
does not itself modify `pubspec.yaml` or `pubspec.lock`.

## Accepted decision

The accepted F3.3 implementation decision is:

| Concern | Package and version | Status in this ADR |
| --- | --- | --- |
| Cross-platform HTTP transport | `dio: 5.11.1` | Accepted |
| Secure storage | `flutter_secure_storage: 11.2.0` | Accepted |
| Cookie management | No package | Accepted |

The versions are deliberately exact. A later implementation change must not
silently substitute a version. Any version change requires a new dependency
review or an amended ADR and human approval.

## Context and constraints

The accepted [F3 Entry Contract](../F3_ENTRY_CONTRACT.md) requires one Dart
transport/session/security foundation shared by iOS, Android and Windows. The
transport boundary must provide bounded deadlines, cancellation, redirect and
status policy, response-byte limits, raw bytes/streams, safe headers and
diagnostics. The session boundary must be source-scoped and generation-aware;
it must prevent stale responses from resurrecting a logged-out session. Secure
storage is an infrastructure capability behind a neutral Dart abstraction.

F3.3 is authorized as a slice, and implementation may add and use only the two
accepted dependencies above. F3.4–F3.7 remain unauthorized and F3 Exit remains
not approved. No live provider request, parser, decoder, cookie runtime or
secure-storage runtime is authorized outside the F3.3 slice.

At the accepted baseline the repository has no Dio, `http`, cookie-manager or
`flutter_secure_storage` dependency. This governance commit leaves
`pubspec.yaml` and `pubspec.lock` unchanged; a later F3.3 implementation may
add only the accepted exact versions.

## Evidence checked on 2026-09-18

Candidate metadata and platform declarations were checked against the package
registries and upstream documentation:

* [Dio 5.11.1 on pub.dev](https://pub.dev/packages/dio/versions/5.11.1) lists
  Android, iOS and Windows support, MIT licensing, cancellation, timeout
  options, raw byte/stream responses, interceptors and replaceable HTTP
  adapters.
* [http 1.6.0 on pub.dev](https://pub.dev/packages/http/versions/1.6.0) lists
  Android, iOS and Windows support, BSD-3-Clause licensing, and a Dart SDK
  constraint compatible with this repository's Dart 3.13.3 environment.
* [flutter_secure_storage 11.2.0 on pub.dev](https://pub.dev/packages/flutter_secure_storage/versions/11.2.0)
  lists Android, iOS and Windows support and BSD-3-Clause licensing. Its
  [changelog](https://pub.dev/packages/flutter_secure_storage/changelog) records
  the current Android SDK/Java requirements and recent platform fixes.
* The [Windows implementation documentation](https://pub.dev/documentation/flutter_secure_storage_windows/latest/)
  requires the Visual Studio C++ ATL libraries. This is a toolchain prerequisite
  to prove in F3.3; it is not a reason to change the repository toolchain in
  this docs-only governance record.

The current Flutter 3.47.4 SDK resolves `flutter.minSdkVersion` to Android API
24 in its Gradle extension. Some current README/package prose still mentions
Android API 23, but the authoritative v11 release/changelog evidence records
Android `minSdk` **24**. The accepted plugin therefore does not require raising
the current application floor, and no Android minSdk increase is approved. F3.3
must recheck this against the final Flutter SDK and resolved package graph
during implementation.

The project deployment target is iOS 15.0. The existing Windows runner already
builds in CI, but that proves only the current application; it does not prove
that the secure-storage Windows implementation and ATL component are installed
on every future runner.

## Network comparison

Both candidates can be wrapped behind the neutral `SourceTransport` contract.
The comparison below is about how much boundary code is needed to satisfy the
accepted F3 semantics, not about exposing either package in Source contracts.

| Requirement | Dio 5.11.1 | http 1.6.0 | Assessment |
| --- | --- | --- | --- |
| iOS/Android/Windows | Declared by package metadata | Declared by package metadata | Both meet the target matrix; F3.3 must run deterministic package smoke on all three targets. |
| Cancellation | `CancelToken` and adapter cancellation | Modern package:http supports abortable requests through its current request/response APIs | Dio's explicit token and request-scoped option surface map more directly to the operation context required by F3. |
| Deadlines | Connect, send, receive and transform timeout options | Requires wrapper policy around futures and underlying clients | Dio needs less infrastructure for separate bounded phases. |
| Raw bytes and streams | Explicit bytes/stream response modes | `Response`/`BaseResponse` and byte streams | Both can preserve fixture bytes. |
| Repeated response headers | `Headers` retains multi-value header data | `headersSplitValues` exposes multi-value response headers | Both expose the required data; Dio still gives a more directly controlled common adapter surface. F3.3 must add an explicit repeated-header test. |
| Redirect policy | `followRedirects` and `maxRedirects` at the adapter boundary | Depends on the selected client and lower-level `dart:io` behavior | Dio makes the policy visible at the common request boundary. |
| Scripted/fake transport | Replaceable `HttpClientAdapter` and custom Dio instance | Very good `Client` abstraction and fake clients | Both are testable; Dio still requires a neutral wrapper. |
| Failure mapping | `DioException` categories are a useful boundary input | `ClientException`/I/O exceptions are a useful boundary input | Neither type may cross the Source contract; map to typed `SourceFailure`. |
| Cookie behavior | Interceptors exist, but no cookie manager is approved | No cookie manager included | Application-owned session remains the sole cookie authority. |
| License | MIT | BSD-3-Clause | Both are recorded for the accepted dependency decision; verify the resolved dependency inventory during F3.3. |

### Accepted network decision

Choose `dio: 5.11.1`. It directly exposes the cancellation, phase-specific
deadline, redirect, raw-byte/stream and adapter controls that F3.3 must make
deterministic across platforms. The wrapper remains mandatory: no `Dio`,
`DioException`, interceptor or adapter type may appear in Source contracts or
Core.

`http: 1.6.0` remains a viable fallback candidate if human review rejects Dio
or F3.3 proves a platform-specific Dio adapter defect. It is not added as a
second implementation or a hidden fallback. Choosing it later requires an
explicit ADR update and a fresh three-platform validation record.

## Secure-storage evaluation

The accepted secure-storage package is an infrastructure implementation of a
source-neutral secure-store interface. F3.3 must keep the package import out of
Core, Source contracts and provider adapters.

| Area | Evidence and required treatment |
| --- | --- |
| Android | The v11 release/changelog records `minSdk` API 24; the current Flutter floor is API 24. Some README/package prose still says API 23, so the changelog is the authoritative evidence for this decision. No minSdk change is approved or required. F3.3 must build and run read/write/delete and failure-path smoke on the actual runner. |
| iOS | The package uses Keychain and supports iOS. The project target is iOS 15.0. F3.3 must verify Keychain access, protected-data/locked behavior, and any required entitlements on a real deterministic iOS runtime path. |
| Windows | The package supports Windows through its Windows implementation, which requires the Visual Studio C++ ATL libraries. The current Windows CI build is not proof of plugin readiness; F3.3 must run a packaged Windows secure-store smoke and record the toolchain component. |
| Flutter/Dart | The current Flutter 3.47.4/Dart 3.13.3 environment is within the package's documented modern toolchain range. F3.3 must recheck the resolved package metadata during implementation. |
| Mechanism boundary | Android secure cryptographic storage, iOS Keychain and the encrypted file-based Windows implementation remain plugin implementation details. The exact platform crypto/storage mechanics are not frozen here. The application sees only a neutral read/write/delete result and typed `secureStorage` failures. |
| Initialization | Flutter bindings must be initialized before plugin calls. F3.3 owns the initialization and error mapping; this ADR does not add startup code. |
| Unavailability/corruption | Locked, unavailable, corrupt or denied storage is an explicit error. There is no plaintext, Drift, shared-preferences, file or log fallback. Memory-only operation may be used only as an explicit, non-persistent test mode. |
| Uninstall/reinstall | Persistence semantics vary by platform and are not promised here. F3.3 must test and document observed behavior; no migration of Legacy credentials or cookies is authorized. |
| License | BSD-3-Clause; verify the resolved dependency inventory during F3.3. |

The Wenku8-specific policy remains strict: passwords are accepted only for an
explicit sign-in operation, are used transiently, and are not retained after
sign-in. The source-neutral rule permits a future Source to request a different
durable credential model only through an explicitly approved secure design and
the same secure-storage boundary. No such future model is approved by this ADR.

## Cookie and session decision

Do **not** add `cookie_jar`, `dio_cookie_manager` or another cookie-management
dependency. A general cookie jar would make it too easy for transport state to
become an unreviewed durable authority and would obscure source scoping.

F3.3 may define an application-owned, structured session model behind the
accepted contract. That model must own:

* parsing and validating `Set-Cookie` values from raw response headers;
* source, host, domain, path, secure and expiry scoping;
* request-cookie selection without cross-source leakage;
* session generation increments on login, logout, expiry and security reset;
* deterministic redaction of cookie values from errors, logs and diagnostics.

The transport may expose sanitized response metadata and raw repeated headers to
the session boundary, but it does not persist cookies or decide authentication.
No Legacy Swift/KMP dual-session architecture is reproduced.

## Security and dependency rules frozen for F3.3

These rules apply if the ADR is accepted and must be proven by F3.3 tests:

1. No password, bearer token, PHPSESSID, `jieqiUserInfo`, cookie value or other
   credential is stored in Drift, shared preferences, ordinary files, logs,
   fixtures or diagnostics.
2. The secure-store implementation is reached only through a neutral Dart
   abstraction. Source contracts do not import plugin types, and providers do
   not call storage directly.
3. Transport diagnostics contain operation, host policy and typed failure code,
   never bodies, authorization values, cookie values or arbitrary server text.
4. Session state is source-scoped and generation-aware. A late response from a
   previous generation cannot commit authentication state.
5. Redirects, retries, response-size limits and cancellation are bounded by
   explicit operation policy. Credentials are not forwarded to an unapproved
   host or across a source boundary.
6. No certificate-validation bypass, hardcoded credential, Legacy session
   import, network live smoke or parser implementation is authorized by this
   ADR.

## Implementation and validation gate after approval

Only after human acceptance may F3.3 add the exact dependencies and lockfile
entries. The implementation must then provide a neutral transport adapter,
session/security abstractions, scripted tests and deterministic platform smoke.
At minimum the evidence must cover:

* cancellation, phase deadlines, redirect policy, status mapping, response-byte
  limits and repeated-header preservation on iOS, Android and Windows;
* typed mapping of package/network/storage failures to the accepted
  `SourceFailure` codes;
* source-scoped cookie selection, login/logout generation and stale-response
  rejection without durable cookie leakage;
* secure-store read/write/delete, unavailable/locked/corrupt behavior and
  explicit no-plaintext fallback on all three targets;
* Android API 24 compatibility, iOS 15 Keychain behavior and Windows ATL-backed
  packaged behavior;
* `dart format`, `flutter analyze --no-pub`, focused F3.3 tests, full tests,
  `git diff --check`, and a dependency-license/platform inventory.

No public-provider availability is required for this deterministic gate. Any
manual Wenku8 smoke remains supplemental, bounded and separately recorded.

## Risks, rollback and deferred decisions

| Risk | Mitigation / disposition |
| --- | --- |
| Dio adapter or header behavior differs by platform | Use a scripted adapter and three-platform smoke before F3.3 acceptance; amend this ADR if the contract cannot be met. |
| `http` is needed after Dio review | Keep it as the documented alternative; do not add both. Seek an amended human-approved decision. |
| Windows runner lacks ATL | Treat secure-storage smoke as blocked; install the approved Visual Studio component through the platform/toolchain process or amend the dependency decision. Do not add a plaintext fallback. |
| Keychain entitlements or protected-data state differ | Record the deterministic iOS failure semantics and required entitlements in the F3.3 evidence; no silent downgrade. |
| Plugin transitive packages or licenses change | Review the resolved lockfile and license inventory before acceptance; update this ADR for a material change. |
| Package becomes unavailable or a requested version is invalid | Do not silently substitute. Record registry evidence and return for human dependency review. |
| Uninstall/reinstall behavior is platform-specific | Defer a persistence promise until F3.3 tests observe it; no Legacy credential migration. |

Deferred to later approved work: production transport/session implementation,
secure-store initialization, provider request builders, decoder/parser
dependencies, live-provider policy, image retrieval, offline/cache behavior,
and any dependency upgrade after the F3.3 baseline.

## Approval record

ADR 0005: **ACCEPTED**.
Human project-owner approval: **APPROVED** on **2026-09-18**.
Accepted baseline: `13408a83ca58158a8e7d74d911a71c183eaff590`.
The accepted dependencies are `dio: 5.11.1` and
`flutter_secure_storage: 11.2.0`; no cookie-management dependency is approved.
F3.3 remains **AUTHORIZED**, and dependency-using implementation is permitted
within that slice. F3.4–F3.7 remain **NOT AUTHORIZED** and F3 Exit remains **NOT
APPROVED**.
