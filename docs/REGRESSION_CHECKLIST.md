# Regression Checklist

This checklist converts high-value legacy failures into explicit Flutter migration checks.

## Reader

- [ ] Opening a chapter does not crash
- [ ] Left tap does not crash
- [ ] Right tap works
- [ ] Swipe works
- [ ] Tap + swipe cannot double-advance state
- [ ] Animation lock cannot remain stuck
- [ ] Late animation completion cannot mutate a new chapter/session
- [ ] Rapid repeated interaction remains recoverable
- [ ] Chapter switch clears stale renderer state
- [ ] Page back color matches current theme
- [ ] Dark mode front/back colors are coherent
- [ ] Curl surface does not look abnormally glossy/plastic
- [ ] Theme/settings changes invalidate rendered page cache
- [ ] Scroll end can enter next chapter
- [ ] Scroll transition triggers only once
- [ ] Old chapter progress is not written into the new chapter
- [ ] Hiding/showing controls does not shift body layout unexpectedly
- [ ] Rapid settings changes do not accumulate obsolete pagination tasks
- [ ] Rotation/viewport change repaginates safely
- [ ] Background/foreground does not corrupt progress/session

## Explore

- [ ] “View all” can load later pages
- [ ] Duplicate page results are deduplicated
- [ ] Empty/error page does not incorrectly advance state
- [ ] Total-page metadata cannot roll state backward incorrectly
- [ ] Network failures produce visible/retryable state where appropriate
- [ ] Restored cache resumes pagination correctly
- [ ] Appending pages does not jump scroll offset
- [ ] No implicit append animation causes hitch
- [ ] Stable item identity is preserved
- [ ] Covers are downsampled/cached
- [ ] Cold-cache image loading does not break scroll physics
- [ ] Card clipping/corner radius remains correct
- [ ] Source change cannot leak old Explore results into new source

## Search

- [ ] Older search result cannot overwrite a newer query
- [ ] Cancellation/obsolescence is respected
- [ ] Source identity is part of result ownership

## Source / Wenku8

- [ ] GBK/GB18030 fixture decoding matches expected output
- [ ] Detail fields use robust DOM semantics
- [ ] Description does not consume “recent chapter”/page chrome
- [ ] `<br>` boundaries create paragraphs
- [ ] Text/image sequence is preserved for new fetches
- [ ] Authentication state is source-scoped
- [ ] Cancellation does not become retry
- [ ] malformed/login/error HTML is not silently treated as valid empty content

## Images

- [ ] Stable cache key
- [ ] memory hit
- [ ] disk hit
- [ ] inflight dedup
- [ ] subscriber cancellation
- [ ] retry policy
- [ ] downsample
- [ ] source-specific headers
- [ ] offline reuse
- [ ] old cache migration where supported
- [ ] foreground request is not starved by prefetch queue

## Persistence / migration

- [ ] Bookshelf survives upgrade/import
- [ ] Reading progress survives
- [ ] Reader settings survive
- [ ] Downloads/offline chapters survive where promised
- [ ] Source identity mapping does not collide
- [ ] Legacy IDs map deterministically
- [ ] interrupted migration is recoverable
- [ ] corrupted legacy data does not wipe valid new data
- [ ] secrets are not moved into plain preferences/database
- [ ] migration is idempotent

## Downloads / offline

- [ ] Chapter metadata and ordered nodes persist
- [ ] Required images are included in completeness state
- [ ] Existing chapter body does not incorrectly skip missing images
- [ ] Cancel + clear cannot be followed by late writes recreating cache
- [ ] Restart can recover completed offline content
- [ ] same remote ID from different sources cannot collide

## Plugin

- [ ] invalid manifest isolated
- [ ] syntax error isolated
- [ ] timeout isolated
- [ ] cancellation isolated
- [ ] undeclared domain denied
- [ ] incompatible API version rejected
- [ ] malformed output rejected
- [ ] plugin storage isolated
- [ ] plugin failure cannot crash Reader/App

## Release validation

Detailed release evidence is tracked in `docs/RELEASE_CHECKLIST.md`.

Minimum shared checks:

- [ ] `dart format --set-exit-if-changed .`
- [ ] `flutter analyze`
- [ ] `flutter test`

First-class platform readiness must explicitly include:

| Validation | iOS | Android | Windows |
| --- | --- | --- | --- |
| Build | [ ] | [ ] | [ ] |
| Install / launch | [ ] | [ ] | [ ] |
| Critical smoke flow | [ ] | [ ] | [ ] |
| Reader flow | [ ] | [ ] | [ ] |
| Upgrade / migration | [ ] | [ ] | [ ] |

An iOS-only success is not cross-platform release readiness.
