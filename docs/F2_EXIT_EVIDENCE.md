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
| F2.7 | EXIT APPROVED | final SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`; [Run #22](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35226294436); Human project owner approval 2026-09-17 |

F2.7 uses frozen legacy repository commit
`d90d4d090c85a0a9c374684696c34befe12636d1`. Its implementation/review-fix
chain is `94ce8ce` → `f0687fe` → `be64ab0` → `286c710`, ending in final
implementation SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`. The Human
project owner approved F2.7 exit on 2026-09-17.

## Aggregate F2.7 evidence

F2.7 uses schema version **1** and the existing Drift/SQLite tables and F2.6
migration tables without schema changes. Dependencies, generated Drift code,
schema snapshots, migration history, workflow and platform files are unchanged.
The final reviewed local full suite contains **370 passing tests**; the F2.7
focused suites contain **195 passing tests** (original 5 plus 190 targeted
review tests, including the Set-provenance regressions). Both corrected frozen-format full fixtures contain **21
expected / 21 actual** verified units:

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

Review fixes enforce all required Book types, retain exact ordered `book.tag`
baseline/candidates, distinguish absent from malformed Set/map/theme/Reader
input, preserve integer aggregate semantics, require valid planned and durable
selected-shelf mappings, verify the complete progress locator and pointer,
and capture immutable dataset/mapping context per import. The concurrent
same-service two-dataset test passes. Malformed Set membership is now explicit
unknown, not false: missing Sets retain the frozen empty-Set false default;
migration-created unresolved stub physical defaults are not accepted semantic
baselines; corrected valid Sets fill those stubs, while genuine preexisting
target state still conflicts. This is covered for saved/update/read/split
state, including shelf/group/progress dependency paths. Fixtures now contain required
`coverIndex` and integer daily/book seconds; counts above are observed, not
preserved by loosening parsing. See `F2_7_LEGACY_IMPORT_BASELINE.md` for the
precise failure/unresolved policies and acceptance coverage.

Validation observed before push:

- `flutter pub get --enforce-lockfile`: PASS.
- Formatting and no-change format check: PASS.
- `flutter analyze --no-pub`: PASS, no issues.
- `flutter test --no-pub`: PASS, 370 tests.
- `./tool/verify_generated.ps1`: PASS; schema and generated outputs unchanged.
- `git diff --check`: PASS.
- Windows packaged storage smoke: PASS; the actual F2.7 service imported an
  inline snapshot, wrote product state, closed/reopened the database and read
  back exact source-aware state.

### Final reviewed platform evidence

[Run #20 / 35217367323](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35217367323)
for `f0687fe015edb0c51d79e33894ffc130310c4d66` executed successfully after
repository visibility/billing recovery: Quality, Android debug, Android
packaged storage smoke, Windows debug, Windows packaged storage smoke, iOS
debug unsigned and iOS simulator packaged storage smoke all PASS.

[Run #21 / 35223587242](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35223587242)
for `be64ab071f714003010e2ea974ecce5823d6c80e` observed the same seven
checks all PASS.

[Run #22 / 35226294436](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35226294436)
for final SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0` observed Quality,
Android debug, Android packaged storage smoke, Windows debug, Windows
packaged storage smoke, iOS debug unsigned build and iOS simulator boot PASS.
The iOS simulator packaged-storage smoke was **NOT PASS, NOT FAIL,
HUMAN-WAIVED / CANCELLED OR ABANDONED AFTER STALL**.

#### F2.7 final iOS packaged-storage smoke evidence waiver

The final reviewed SHA `286c710c39b3fb58a8668b8b5e0f72caa489b7f0`
successfully completed the iOS unsigned build and simulator boot. The
subsequent iOS simulator packaged-storage integration test stalled after
successful Xcode build completion and did not produce a final PASS result
within the accepted review window.

The Human project owner explicitly approved proceeding without a final-SHA iOS
packaged-smoke PASS on 2026-09-17. Supporting evidence includes final-SHA
Quality PASS, Android packaged smoke PASS, Windows packaged smoke PASS, iOS
unsigned build PASS and iOS simulator boot PASS; immediately preceding
reviewed SHA `be64ab0` Run #21 completed the same iOS simulator
packaged-storage smoke successfully; and the final provenance fix changed
only Dart migration logic/tests, not workflow, native iOS code, platform
configuration, schema or dependencies.

Classification: **HUMAN-APPROVED EVIDENCE WAIVER**, not PASS. This waiver
applies only to F2.7 exit evidence and does not permanently waive future iOS
validation requirements.

The historical [Run #19 / 35214416354](https://github.com/komorebiiluvu/LightNovelReader-Flutter/actions/runs/35214416354)
pre-execution failure and the previous F2.6 Run #18 Android smoke instability
remain historical CI evidence. F2.7 did not alter, weaken, skip or retry that
gate.

## Deferred obligations

The following remain outside F2 and are not hidden by this evidence:

- F3 live Source capabilities, network/session/auth, secure credentials and
  evidence-based chapter/source reconciliation.
- F4 Reader restore, anchor interpretation and navigation behavior.
- F6 offline chapter bodies, images, cache/download transfer and completeness.
- F7 statistics/search/group UI and accent acquisition.
- F11 real installed-app upgrade/recovery, signing/distribution and release
  support validation.

F2.7: **EXIT APPROVED**

F2 overall: **EXIT REVIEW PENDING / NOT APPROVED**

F3: **NOT STARTED / NOT AUTHORIZED**
