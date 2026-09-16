# Legacy Behavioral Baseline

## 1. Canonical legacy repository

Repository:

`https://github.com/komorebiiluvu/LightNovelReader-For-IOS`

## 2. Frozen baseline

Behavioral baseline commit:

`d90d4d090c85a0a9c374684696c34befe12636d1`

Short SHA:

`d90d4d09`

This is the legacy commit that was used for the Phase 0 architecture audit and hotspot analysis.

Future changes in the legacy repository do **not** automatically redefine the expected behavior of the Flutter project.

If a later legacy commit contains a fix or behavior worth adopting, that change must be reviewed explicitly and referenced by commit.

## 3. What the baseline is used for

The baseline is authoritative evidence for:

- existing Reader behavior
- historical Reader bug fixes
- Explore behavior and performance lessons
- Source/Wenku8 behavior
- cache and offline formats
- persistence fields and migration inputs
- historical troubleshooting
- feature inventory

It is **not**:

- a runtime dependency
- a build dependency
- the architecture template for the Flutter app
- proof that every legacy behavior is desirable

## 4. Behavior classification

Every migrated legacy behavior should be classified as one of:

### PRESERVE
Known product behavior that should remain equivalent.

### FIX
Known defect that must not be reproduced as desired behavior.

### REGRESSION TEST
A historical failure that must be prevented even if internal implementation changes.

### DEFER
Existing capability intentionally postponed to a later phase/release.

### DROP
Legacy capability intentionally removed, with explicit product approval.

Do not infer a category silently.

## 5. Current high-value preserved behavior

At minimum, preserve the intent of:

- reader session stability
- left/right tap semantics
- swipe interaction
- continuous scrolling
- chapter transitions
- reading progress persistence
- setting-driven repagination/cache invalidation
- toolbar overlay behavior
- stable Explore item identity
- safe pagination advancement/deduplication
- cover image downsampling/caching/dedup/cancellation concepts
- source parsing fixes documented in legacy troubleshooting

## 6. Known legacy defects that are not desired behavior

The legacy audit identified risks/defects such as:

- incomplete backup import path
- stale async Reader result overwriting a newer chapter
- older search result overwriting a newer query
- source-unaware keys in parts of the old state
- download completeness not guaranteeing image completeness
- legacy chapter content unable to preserve true text/image ordering

These are not requirements to reproduce.

## 7. Evidence mapping

Historical behavior should gradually be converted into:

`legacy behavior -> fixture / reproduction -> new automated test -> acceptance evidence`

The central checklist is:

`docs/REGRESSION_CHECKLIST.md`

More detailed mappings may be added under:

`docs/legacy/swift/`

## 8. Legacy source consultation rule

When an Agent needs to know “how the old app behaved,” use:

1. this frozen commit;
2. the saved Phase 0 audit/hotspots;
3. relevant legacy Git history/commit;
4. troubleshooting documents.

Do not use the latest legacy `main` implicitly.
