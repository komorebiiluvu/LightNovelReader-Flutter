# Performance

## 1. Goals

Reader interaction and Explore scrolling must remain smooth across iOS, Android, and Windows; high-refresh mobile devices remain important targets.

Frame budgets are tight; architecture must prevent avoidable UI-thread work.

## 2. Rules

Do not put on frame-critical paths:
- HTML parsing
- large JSON serialization
- disk scans
- large image decode
- database migrations
- obsolete pagination

## 3. Cancellation and priority

Visible content > near-future prefetch > background maintenance.

Obsolete work should stop or become unable to commit results.

Identical network/image work should be shared where practical.

## 4. Images

Preserve legacy lessons:
- downsample near display size
- memory/disk layers
- inflight dedup
- limited network/decode concurrency
- cancellation
- completion pacing when batches finish together

## 5. Explore

Protect:
- stable item identity
- no offset jump on append
- no implicit append animation
- bounded prefetch
- no full-list rebuild from unrelated global state
- cold cache may reveal covers later, but scroll physics should remain responsive

## 6. Reader

Measure:
- chapter load
- pagination
- frame build/raster
- page-turn interaction
- scroll large chapter
- image-heavy chapter
- settings repagination
- memory after repeated chapter transitions

## 7. Measurement

Use Flutter DevTools/profile mode and native Instruments when needed.

Record:
- hardware
- OS
- Flutter version
- commit
- build mode
- scenario
- cold/hot cache

Static analysis is not performance validation.

## 8. Cross-platform rule

Measure each supported platform independently. Do not use iOS results as proof for Android or Windows, or vice versa.
