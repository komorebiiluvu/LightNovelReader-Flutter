# F2 Exit Evidence

Status: **REVIEW PENDING**

Overall F2 exit: **NOT APPROVED**.

This is an evidence aggregation document, not an approval. Human review is
still required; implementation coverage is not the same as predecessor
replacement or release readiness. F3 is **NOT STARTED / NOT AUTHORIZED**.

## Phase evidence

| Phase | Status | Relevant implementation / closure evidence |
| --- | --- | --- |
| F2.1 | IMPLEMENTED / ACCEPTED | `c2d8a802c1a21aa7cb60e804fb013870aed18bae` |
| F2.2 | IMPLEMENTED / ACCEPTED | `83757cc3571b4f7f63fc80eecdebc504def7c045` |
| F2.3 | EXIT APPROVED | `619658150a803299f70e50c758e0329eb7bcadf1`; [Run #9](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35170388187) |
| F2.4 | EXIT APPROVED | `78b3c36057e4554e76bb98b0eb474ed614f39786`; [Run #11](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35172536438) |
| F2.5 | EXIT APPROVED | `f1dd837942d49527b1a379fcce25e46e7035f027`; [Run #14](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35178792526) |
| F2.6 | EXIT APPROVED | `0ec12e0356ad3fb8428c098d130876407472c168`; [Run #17](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35207590333) |
| F2.7 | IMPLEMENTED — REVIEW PENDING | starting `412c2ae7d48828b3d25b2114e430ca9545b21676`; implementation SHA is the single commit carrying this evidence |

F2.7 uses frozen legacy repository commit
`d90d4d090c85a0a9c374684696c34befe12636d1`. Its implementation commit message
is `feat: add committed legacy state importer`. No F2.7 exit approval is
recorded.

## Aggregate F2.7 evidence

F2.7 uses schema version **1** and the existing Drift/SQLite tables and F2.6
migration tables without schema changes. Dependencies, generated Drift code,
schema snapshots, migration history, workflow and platform files are unchanged.
The local full suite contains **180 passing tests**; the F2.7 focused suite
contains **5 passing tests**. The F2.7 full fixture contains **21 expected /
21 actual** units:

| Entity kind | Expected | Actual |
| --- | ---: | ---: |
| source | 5 | 5 |
| book | 4 | 4 |
| shelf | 2 | 2 |
| group | 2 | 2 |
| split | 1 | 1 |
| progress | 3 | 3 |
| readerPreferences | 1 | 1 |
| appPreferences | 1 | 1 |
| statistics | 1 | 1 |
| searchHistory | 1 | 1 |

Happy-path outcome counts are imported **10**, unchanged **0**,
preserved-unresolved **8**, deferred-preserved **3**,
intentionally-excluded **0**, conflict **0** and failed **0**. Exact repeat,
close/reopen, failure-injection rollback/retry and post-import user-edit
conflict behavior are covered. Safe sentinel search found no secret value in
product or migration storage, and the full input blob is not retained.

Validation observed before push:

- `flutter pub get --enforce-lockfile`: PASS.
- Formatting and no-change format check: PASS.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub`: PASS, 180 tests.
- `./tool/verify_generated.ps1`: PASS; schema and generated outputs unchanged.
- `git diff --check`: PASS.
- Windows packaged storage smoke: PASS; the actual F2.7 service imported an
  inline snapshot, wrote product state, closed/reopened the database and read
  back exact source-aware state.

The new post-push GitHub Actions result is intentionally not predeclared in
this committed evidence. The final report must state only the actually
observed jobs. The previous F2.6 Run #18 Android storage smoke instability is
an existing CI/runtime harness issue; F2.7 does not alter, weaken, skip or
retry that gate. A failed or pending Android smoke in the new run is evidence
against F2.7 exit approval, not a self-fix target here.

## Deferred obligations

The following remain outside F2 and are not hidden by this evidence:

- F3 live Source capabilities, network/session/auth, secure credentials and
  evidence-based chapter/source reconciliation.
- F4 Reader restore, anchor interpretation and navigation behavior.
- F6 offline chapter bodies, images, cache/download transfer and completeness.
- F7 statistics/search/group UI and accent acquisition.
- F11 real installed-app upgrade/recovery, signing/distribution and release
  support validation.

F2.7: **IMPLEMENTED — REVIEW PENDING**

F2 overall: **EXIT REVIEW PENDING / NOT APPROVED**

F3: **NOT STARTED / NOT AUTHORIZED**
