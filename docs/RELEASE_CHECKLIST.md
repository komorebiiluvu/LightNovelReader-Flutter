# Cross-Platform Release Checklist

A release claiming iOS, Android, and Windows support is not ready until all required cells are explicitly resolved.

Allowed statuses:

- PASS
- FAIL
- NOT APPLICABLE (must include reason)
- WAIVED (must include owner/reason/follow-up; not allowed for data-loss/security blockers)

## 1. Build and launch matrix

| Validation | iOS | Android | Windows | Evidence |
| --- | --- | --- | --- | --- |
| Clean build |  |  |  |  |
| Release build |  |  |  |  |
| Install/package |  |  |  |  |
| First launch |  |  |  |  |
| Upgrade launch |  |  |  |  |

## 2. Automated verification

| Validation | iOS | Android | Windows | Evidence |
| --- | --- | --- | --- | --- |
| Dart unit tests | shared result | shared result | shared result |  |
| Widget tests | shared result | shared result | shared result |  |
| Source fixture tests | shared result | shared result | shared result |  |
| Integration smoke |  |  |  |  |
| Migration/import tests |  |  |  |  |

Shared Dart tests may have one common result, but platform integration behavior must still be validated where platform packaging/runtime is involved.

## 3. Critical smoke flow

Run at least:

`launch -> search/explore -> book detail -> chapter list -> read -> change chapter -> close -> reopen -> restore`

| Flow | iOS | Android | Windows | Evidence |
| --- | --- | --- | --- | --- |
| Critical smoke |  |  |  |  |

## 4. Reader

| Reader validation | iOS | Android | Windows | Evidence |
| --- | --- | --- | --- | --- |
| Continuous scroll |  |  |  |  |
| Paginated mode |  |  |  |  |
| Realistic page curl (when shipped) |  |  |  |  |
| Previous/next input |  |  |  |  |
| Progress restore |  |  |  |  |
| Settings + repagination |  |  |  |  |
| Theme/background |  |  |  |  |
| Resize/orientation relevant behavior |  |  |  |  |

## 5. Persistence / upgrade

| Validation | iOS | Android | Windows | Evidence |
| --- | --- | --- | --- | --- |
| Existing library retained |  |  |  |  |
| Reading progress retained |  |  |  |  |
| Reader settings retained |  |  |  |  |
| Offline content retained where promised |  |  |  |  |
| Interrupted migration recoverable |  |  |  |  |

Legacy Swift-app import is evaluated separately according to the migration commitment and is primarily relevant to iOS unless a cross-device import mechanism is introduced.

## 6. Performance

Performance-sensitive releases must attach per-platform measurement evidence.

Do not use one platform’s result to approve another platform.

## 7. Blockers

The following cannot be waived for release:

- known data-loss path
- corrupting migration
- critical Reader crash
- credentials/secrets exposed
- required target cannot build/install
- plugin sandbox escape affecting shipped plugin support

## 8. Release approval

Release candidate:

Commit / tag:

Reviewer:

Date:

Known waivers:

Final decision:
- APPROVED
- REJECTED
