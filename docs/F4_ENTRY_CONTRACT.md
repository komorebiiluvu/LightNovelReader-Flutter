# F4 — Reader Foundation entry proposal

Status: **PROPOSED — F4 NOT AUTHORIZED**. F3 Exit is **NOT APPROVED** at this
proposal checkpoint. Agent entry review under ADR 0008 follows F3 Exit; this
document does not itself authorize Reader implementation or a schema change.

## Purpose and evidence

F4 supplies one Dart/Flutter Reader foundation for iOS, Android and Windows:
`ReaderSession`, continuous scroll, a basic paginated renderer, position
restore, preferences and layout invalidation. The realistic page curl belongs
to F5. Image retrieval/cache and offline reading belong to F6. Feature-level
bookshelf/search/detail UI belongs to F7.

The frozen Legacy reference is
`d90d4d090c85a0a9c374684696c34befe12636d1`. Its `ReaderView.swift` and
`ReaderPagination.swift` demonstrate chapter transitions, saved scroll
fractions, reflow after settings changes and asynchronous pagination. The
Legacy scroll restore estimates a paragraph from a fraction, and paginated
reflow estimates a new page from the old page ratio. These are historical
behavioral evidence, not exact anchors or an algorithm to copy. The frozen
`ReaderPagingStabilityUITests.swift` and `ReaderBarToggleLayoutUITests.swift`
identify regressions to prove with assertions: toggling controls must not
reset the reading position or shift the body. F2's source-aware refs, ordered
`ChapterContent.nodes`, progress metadata and ten reader preference fields
remain unchanged.

## Proposed logical position contract

The durable Reader position is scoped to a `SourceChapterRef` and a digest of
the exact ordered chapter nodes used when it was recorded. Within that content
snapshot, an anchor identifies a node index and, for a text node, a UTF-16
offset at a grapheme boundary. For an image node it identifies the node, not a
fabricated `AssetId` or image URL. A chapter-start anchor is always valid for
successfully obtained empty content. The digest uses a deterministic canonical
encoding of the ordered nodes and their F2 opaque refs; page number, pixel
offset, viewport size and display title are not durable identity.

The node index is a location inside one verified content snapshot, not modern
chapter or node identity. If the content digest differs, the old anchor is
retained as historical evidence but is not silently applied to the changed
content. The safe default visible position is that chapter's start. F4 may
propose a separately reviewed, deterministic remapping rule later; guessing
from equal counts, titles or current catalog ordinals is not permitted.

Both renderers translate this logical anchor into their layout coordinates and
report the current leading-content anchor back to `ReaderSession`. Changing
renderer, font, margins, text scale, viewport or theme never persists a page
index as the position. The session keeps the last valid anchor while layout is
recomputed; an obsolete renderer report cannot overwrite a newer chapter or
anchor. A renderer may expose transient page numbers and scroll fractions for
UI, but they are not F2 chapter identity or a durable F4 anchor.

F2 legacy fractions remain untouched until F3 has proved a modern chapter ref
for the same book. Once proven, a fraction may provide a clearly approximate
first restore within that chapter if no modern anchor exists; it must not
fabricate a ChapterId, replace the original locator, or claim exact paragraph
position. Unresolved legacy locators remain unresolved. A newly observed
modern anchor is stored separately from the preserved legacy record.

Persisting a modern anchor requires a versioned repository/schema decision
before implementation. The accepted F2 `ReadingProgressV1` serialization is
not retroactively redefined. A proposed F4 persistence change must include a
safe v2-to-next-version migration, upgrade/reopen/rollback tests and a
current-state guard against late progress writes; an ADR is required if it
changes the accepted persistence architecture.

## Proposed ReaderSession and renderer event contract

`ReaderSession` owns the active source/book/chapter, load generation,
cancellation, normalized content, logical anchor, transition state, pending
pagination and progress commits. It obtains content through the Source-neutral
`BookSource` boundary. Renderers receive immutable content/layout inputs and
emit intents or position observations; they do not call Wenku8, write the
database or choose a chapter by numeric ID.

The common intents are: open/close, next/previous page, next/previous chapter,
scroll-position update, jump to a verified catalog chapter, settings change,
viewport change and cancellation. A boundary gesture may request a chapter
transition at most once. Chapter transitions carry the destination
`SourceChapterRef` and an initial direction (`start` or `end`), never a guessed
ordinal identity. Newer chapter/load/layout generations invalidate older
completions before they can publish content, page layouts or progress.

The scroll renderer consumes the ordered node sequence and supports short or
empty chapters, image placeholders, wheel/trackpad/touch input, position
restore and one-shot end-of-chapter transitions. The paginated renderer uses
the same sequence and anchor, splits text without losing characters, keeps
image nodes in order and supports basic next/previous page interaction. F4
does not claim a realistic curl effect. Until F6, image nodes use visible,
deterministic placeholders; no image request, download or cache is introduced.

Pagination cache identity includes content digest, resolved font metrics,
font size/weight, line and paragraph spacing, margins, viewport, text scale
and image-placeholder geometry. Background/theme values affect the key only
when they change layout. Cache hits cannot bypass active-generation checks.
Changing layout settings or viewport invalidates only affected layouts,
recomputes from the logical anchor and does not jump to chapter start. Unsupported
fonts get an explicit cross-platform fallback whose layout metrics are part
of the cache key; the F2 preference value is preserved.

## Proposed implementation slices and gates

| Slice | Deliverable | Focused proof |
| --- | --- | --- |
| F4.1 Position and persistence contract | Accepted anchor/event semantics; reviewed storage migration if required | exact/fingerprint-mismatch/legacy-fraction cases; no F2 rewrite |
| F4.2 ReaderSession | source-neutral loading, generation, navigation and progress ownership | late load/layout/progress suppression, one-shot transition, reopen |
| F4.3 Continuous scroll | ordered text/image-placeholder layout and position reporting | restore, short/empty chapter, resize, control-bar stability |
| F4.4 Basic paginated renderer | deterministic page partition and anchor mapping | no lost/duplicated text, previous/next/edge, reflow |
| F4.5 Preferences and integration | F2 settings applied, cache invalidation, cross-renderer switch | font fallback, rapid settings changes, progress restore |
| F4.6 Exit evidence | phase review and cross-platform Reader smoke | iOS/Android/Windows packaged runtime and full relevant suite |

F4 Entry requires an approved F3 Exit, a reviewed version of this contract,
and any necessary persistence/dependency ADR before that change is used. No
new package is selected by this proposal. Ordinary slices use focused checks;
the complete CI/platform matrix belongs at the F4 phase-exit candidate or an
earlier concrete platform-risk gate under ADR 0008.

F4 Exit requires: accepted logical position and renderer event contracts;
working continuous scroll and basic paginated modes on all three platforms;
deterministic progress restore and setting/viewport reflow; preservation of
ordered nodes and F2 identities; no known data-loss or stale-session blocker;
and recorded Agent review with exact tested revision, tests and platform
results. Device-specific performance and realistic curl quality remain F5/F11
work. An unrun platform is `UNPROVEN`, never inferred from another target.

## Risk register

| Risk | Required disposition before F4 Exit |
| --- | --- |
| Stale content anchor points into changed text | Content digest check; retain old evidence; safe fallback and explicit tests |
| Late load/pagination/progress overwrites current chapter | Session generation and repository current-state guard; race tests |
| Legacy fraction becomes fabricated identity | F3-proven chapter ref first; approximate restore only; original locator retained |
| Renderer mode or settings change jumps position | Shared anchor and reflow tests, including rapid changes and control toggles |
| Platform font metrics diverge | Explicit fallback and per-platform runtime/layout evidence |
| Ordered images are lost before F6 | Stable placeholders in the original node positions; image fetching deferred |
| Persistence upgrade loses F2 progress | Versioned migration, rollback/reopen and data-preservation proof |

This proposal does not accept F3 Exit, authorize F4 implementation, or approve
F5 curl, F6 image/offline work or F7 feature migration.
