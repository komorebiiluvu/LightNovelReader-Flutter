# F3.3 — Transport, Session and Security Foundation

Status: **IMPLEMENTED / HUMAN REVIEW REQUIRED**

Slice: **F3.3 — Transport + Session + Security Foundation**

Starting SHA: `961e19e3387c0f66aad0ac519efc7061c383b6b2`

ADR 0005 is **ACCEPTED / APPROVED** by the Human project owner on
2026-09-18. F3.3 is **AUTHORIZED**. F3.4–F3.7 remain **NOT AUTHORIZED** and
F3 Exit remains **NOT APPROVED**. This record does not approve a provider
adapter, parser, live-provider request or the next slice.

## Implementation boundary

The neutral contracts are under `lib/src/source/`:

* `transport/` defines immutable HTTP methods, repeated case-insensitive
  headers, raw byte requests/responses, safe redirect metadata, cancellation
  and finite timeout/retry/redirect/response-size policies.
* `session/` defines the application-owned source-scoped cookie model,
  deterministic Set-Cookie parsing and `SourceSessionManager` generation
  bindings.
* `security/` defines `SecureCredentialStore`, source-scoped opaque storage
  keys and redacted `SecureValue` values.

Concrete implementations are isolated under
`lib/src/data/source_runtime/`:

* `DioSourceTransport` uses Dio 5.11.1 with automatic decoding, redirects,
  cookie persistence and logging disabled. It preserves raw bytes, follows
  only bounded approved redirects, strips credentials on cross-origin hops,
  enforces phase and overall deadlines, bounds retries and response size, and
  maps package failures to the accepted `SourceFailure` boundary.
* `FlutterSecureCredentialStore` is the only production import of
  `flutter_secure_storage`. It provides read/write/delete through the neutral
  store, maps plugin failures to `secureStorage`, and has no plaintext
  fallback.

No provider adapter, request builder, parser, decoder, DOM dependency, Reader,
image/offline path or network startup integration was added. No cookie-manager
or `package:http` dependency is present.

## Session and secret handling

Cookies are owned by one `SourceSessionManager` keyed by `SourceId`. Selection
checks source, host/domain, path, expiry and Secure requirements and sorts
deterministically. Repeated Set-Cookie fields are parsed independently;
Expires commas are preserved, Max-Age deletion and identity replacement are
supported, and an ambiguously combined cookie field is ignored rather than
guessed. Cookie values, authorization values, bodies and raw exception text
are excluded from diagnostics and redacted string representations.

Each request captures a source/session generation. Establish, logout, expiry
and security reset advance the generation and clear the in-memory cookie set.
Set-Cookie commits from a stale binding are rejected, so a late response
cannot restore a logged-out session. Secure values are only accepted through
the source-neutral abstraction; the test backend is explicitly in-memory and
the production adapter uses the approved plugin. No Drift, shared
preferences, ordinary file or Legacy credential/session fallback exists.

Wenku8 passwords remain transient by source policy. A future source may
request another durable credential model only through an explicitly reviewed
secure design and the same abstraction; this slice does not implement one.

## Dependency and platform inventory

Approved direct dependencies, resolved exactly:

| Package | Version | License / role |
| --- | --- | --- |
| `dio` | 5.11.1 | MIT; transport adapter |
| `flutter_secure_storage` | 11.2.0 | BSD-3-Clause; secure-store adapter |

Relevant resolved transitive packages include `dio_web_adapter 2.2.2`,
`flutter_secure_storage_darwin 0.4.3`,
`flutter_secure_storage_linux 3.0.3`,
`flutter_secure_storage_platform_interface 2.1.1`,
`flutter_secure_storage_web 2.1.1`,
`flutter_secure_storage_windows 4.2.2`, `ffi_leak_tracker 0.1.2`, and
`win32 6.4.0`; their package metadata remains in `pubspec.lock` for review.
No additional HTTP, cookie-management or secure-storage package was added.

The resolved license files were reviewed: `dio_web_adapter` is MIT;
`http_parser` is BSD-3-Clause; the five federated
`flutter_secure_storage_*` packages, `ffi_leak_tracker` and `win32` are
BSD-3-Clause. These transitive licenses introduce no additional copyleft or
dependency decision.

The Flutter Android floor remains API 24, matching the authoritative v11
minimum for `flutter_secure_storage`; no minSdk change was made. The iOS
deployment target remains 15.0. Windows uses the plugin's encrypted file-based
implementation and requires ATL; exact plugin crypto/storage mechanics remain
plugin details. The local Windows build and packaged smoke demonstrate that
the current runner has the required ATL/toolchain path.

## Deterministic tests and platform evidence

The focused F3.3 suite uses scripted Dio adapters and in-memory secure-store
backends only. It covers raw GET/POST bytes, repeated headers, status
preservation, cancellation before/during I/O, listener cleanup, timeout and
finite retry mapping, cancellation-aware retry delay, exact response-size
boundaries, redirects and credential stripping, cookie attributes and
selection, source isolation, generation races, secure-store CRUD/failures and
redaction, plus the package-import boundary. Focused and full-suite counts
are recorded below.

Local platform evidence:

* Android debug APK: **PASS** after rerunning with an ASCII `PUB_CACHE` path.
  The first attempt failed in transitive `jni` CMake path handling because the
  Windows username contains non-ASCII characters; this is a local toolchain
  path issue, not a product or platform-floor change.
* Windows debug build: **PASS**.
* Windows packaged storage smoke (SQLite plus secure-storage
  write/read/delete): **PASS**; ATL-backed plugin registration was exercised.
* iOS unsigned build, simulator boot and packaged secure-storage smoke were
  not runnable on this Windows checkout. The repository CI iOS job is the
  required evidence path; its result is reported for the pushed commit and
  any incomplete smoke remains **STALLED / INCOMPLETE**, never PASS or an
  F3 Exit waiver.

No public-provider request or live Wenku8 smoke is part of deterministic F3.3
acceptance. Any later manual live smoke remains bounded, non-CI evidence.

## Validation record

The final implementation run records:

* `dart format --output=none --set-exit-if-changed .`: **PASS**
* `flutter analyze --no-pub`: **PASS**
* focused F3.3 tests: **24 passed**
* `flutter test --no-pub`: **441 passed**
* `git diff --check`: **PASS**

The status is intentionally not F3.3 accepted. Human review must assess the
contract implementation, dependency use, deterministic tests and the iOS CI
runtime evidence before any F3.3 closure or F3.4 authorization.
