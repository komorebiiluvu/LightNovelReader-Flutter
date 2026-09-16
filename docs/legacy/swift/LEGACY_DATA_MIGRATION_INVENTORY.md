# Frozen Swift data migration inventory

Status: Evidence inventory; proposed treatments require approval of
[F2 Entry Contract](../../F2_ENTRY_CONTRACT.md). Date: 2026-09-16.

Inspected repository: `C:\Projects\LightNovelReader-Legacy`, read-only, clean,
detached at **d90d4d090c85a0a9c374684696c34befe12636d1**. Inspection used
`git show`, `git grep` and `git ls-tree` against that exact commit. No user
container, real backup, credentials or later legacy revision was examined.
Locations below are established by code, not a claim that a particular user's
files still exist. No secret values are reproduced.

## 1. Evidence index

All links pin the same frozen commit. Line references below refer to these files.

| Evidence | Frozen source |
| --- | --- |
| L1 | [AppStore.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Store/AppStore.swift): preferences 40–66, snapshot 71–137, restore 224–265, persist 304–337, Explore cache 725–759, groups 977–1083, shelves 1110–1162, progress 1166–1197 and 1501–1535, backup 1260–1327, downloads 1329–1440 |
| L2 | [Book.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Models/Book.swift), [BookShelf.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Models/BookShelf.swift), [ReadingStats.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Models/ReadingStats.swift) |
| L3 | [Chapter.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Models/Chapter.swift) and [ChapterDiskCache.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/ChapterDiskCache.swift) |
| L4 | [KmpBookSourceAdapter.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/KmpBookSourceAdapter.swift): catalog flattening 139–165, content 168–195, cookies 226–252, book IDs 299–328 |
| L5 | [Wenku8Service.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/Wenku8Service.swift): source name 7, cookie persistence 40–46, authentication 75–124, catalog 157, book ID creation 332/427/591 |
| L6 | [CoverImageCache.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/CoverImageCache.swift): root 146–147, keys/compatibility 354–387, URL normalization/hash 404–421 |
| L7 | [ReaderView.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Features/ReaderView.swift): modes 4–6, backgrounds 331–337; [ReaderPagination.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Features/ReaderPagination.swift): font names 12–16; [ColorHex.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Theme/ColorHex.swift): accent key/values |
| L8 | [SettingsView.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Features/SettingsView.swift): backup sharing and JSON file importer; [EpubExporter.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/EpubExporter.swift); [CrashReporter.swift](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Sources/Services/CrashReporter.swift) |
| L9 | [ReadingDataBridge.kt](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/shared/src/commonMain/kotlin/io/nightfish/lightnovelreader/api/ReadingDataBridge.kt), [Volume.kt](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/shared/src/commonMain/kotlin/io/nightfish/lightnovelreader/api/book/Volume.kt), [Wenku8DataSourceApi.kt](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/shared/src/commonMain/kotlin/io/nightfish/lightnovelreader/api/Wenku8DataSourceApi.kt): flat content 255–261 |
| L10 | [project.yml](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/project.yml): 44–51; [project.pbxproj](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/LightNovelReader.xcodeproj/project.pbxproj): 695/720; [Info.plist](https://github.com/komorebiiluvu/LightNovelReader-For-IOS/blob/d90d4d090c85a0a9c374684696c34befe12636d1/Info.plist) |

## 2. Representation and location inventory

`S` below means JSON-encoded `AppStateSnapshot`, stored as **Data**, not a
String, in `UserDefaults.standard["lightnovelreader.app_state.v1"]` (L1).
It belongs to the old app's standard preferences domain. A preferences plist
is a container acquisition concern, not a portable JSON input by itself.
`O` means the old app's Application Support directory plus `LNROffline/`.
Its `safe(x)` replaces every character other than a letter, number, `-`, `_`
with `_`; this is lossy and not invertible. Never derive new domain identity
solely from a directory name. All proposed treatments use the classifications
defined in the entry contract; the phase column identifies the delivery owner.

| Asset / evidence | Exact representation and identity/key | Persistence location | Durable or cache | Risk | Proposed treatment / phase |
| --- | --- | --- | --- | --- | --- |
| Snapshot / L1 | Codable JSON object; no internal schemaVersion; key suffix `.v1`; absent fields default, malformed field can fail whole Swift decode | S; also backup `state` | Mixed envelope | `load()` falls back to empty snapshot on any decode failure | F2 decodes independently by record/field; never interprets failure as empty successful import |
| Library / L1,L2 | `bookLibrary:[Book]`, `savedIDs:Set<String>` encoded as array | S | Durable historical library and default shelf membership | Library includes encountered books, not only saved ones; source-unaware IDs | **MUST MIGRATE**, F2; retain metadata separately from saved membership; no auto-favorite |
| Book metadata / L2 | Required `id,title,author,source,intro:String`, `tags:[String]`, `totalChapters,lastChapter,hits,coverIndex:Int`, `hasUpdate:Bool`; optional `coverURL,publishingHouse,lastUpdate:String`, `isCompleted:Bool`, `wordCountK:Int` | Each `bookLibrary` element; cached `books.json` | Snapshot metadata durable; catalog copy cache | Duplicate IDs, invalid required fields, URL-only cover, date string of unknown zone | **MUST MIGRATE** snapshot fields in F2 as display metadata or typed legacy metadata; no network dependency; cache fallback **BEST-EFFORT IMPORT** when explicitly supplied |
| Source mapping / L1,L4,L5 | `preferredSource:String`; `sourceByID:[bookID:displayName]`; `Book.source`; services keyed by name `文库8(在线)` | S | Durable association/preference | Old aliases `文库8`, `轻小说源A/B` renamed at startup; unsupported mappings could be removed; names do not prove source identity | **MUST MIGRATE**, F2 compatibility mapping with provenance; conflicts/unrecognized names retained, never silently reassigned |
| Book ID / L1,L2,L4,L5 | Swift string `wk8-<aid>` for real Wenku8; old services and AppStore parse its numeric suffix | S and O paths | Durable identity | Stripping prefix or parsing globally loses reversibility/collides; old AppStore parsing must not spread to new Core | **MUST MIGRATE**, F2 preserves exact opaque local ID under a source-aware ref |
| Custom shelves / L1,L2 | `shelves:[{id,name,bookIDs:[String]}]`; generated ID `shelf-` + first 8 UUID characters; shelf array and member array carry order | S | Durable | Missing books, duplicate IDs/members, truncated UUID collision | **MUST MIGRATE**, F2 explicit mapping, order retained; missing books become stubs, conflicts reported |
| Manual merge/split / L1 | `manualGroupByID:[bookID:groupID]`, `groupDisplayName:[groupID:String]`, `splitBookIDs:Set<String>`; `manual:<8 UUID chars>`; automatic group ID `auto:<normalized title>` computed at runtime | S; automatic membership not stored | Manual choices durable; automatic grouping derived | Display names can apply to automatic groups; title matching is not identity | **MUST MIGRATE**, F2 manual membership/names/split flags; preserve automatic-group rename as legacy display metadata; F7 applies grouping presentation |
| Last chapter / L1,L2 | `lastChapterByID:[bookID:Int]` and `Book.lastChapter` are zero-based catalog positions; not cid | S | Durable | Catalog reorder, duplicated fields disagree, missing catalog | **MUST MIGRATE**, F2 unresolved legacy locator; F3 resolves chapter identity, F4 applies reading position |
| Within-chapter progress / L1 | `chapterOffsetByID:[String:Double]`; actual key **`<bookID>#<chapterIndex>`**; stored if fraction >0.02, capped at 1 | S | Durable hint | Comment says per-book but actual keys include chapter; fractions are layout-dependent; prefix ambiguity | **MUST MIGRATE**, F2 preserves raw key/index/fraction, no F4 anchor invented |
| Recent reading / L1 | `readBookIDs:Set<String>`, `lastReadAtByID:[String:Date]` | S | Durable | Chapter 0 alone does not mean unread; Swift Date epoch differs from Unix | **MUST MIGRATE**, F2 read flag/timestamp and raw date provenance |
| Update metadata / L1,L2 | `knownTotalChaptersByID:[String:Int]`, `updateFlagIDs:Set<String>`, `Book.totalChapters/hasUpdate` | S | Durable snapshot hint, refreshable | Historical count must not become a stable chapter key | **MUST MIGRATE**, F2 retain hints; F3 decides refresh semantics |
| Reader preferences / L1,L7 | `fontSize=22,lineSpacing=8,backgroundIndex=0,mode="仿真翻页",fontFamily="楷体",bold=false,marginLeft=35,marginRight=35,marginTop=72,marginBottom=24`; numeric CGFloat encoded as JSON numbers | S.`readerPreferences` | Durable user preference | Enum raw values localized; native fonts/layout not portable | **MUST MIGRATE**, F2 value/intent preservation; F4/F5 rendering/application |
| App preferences / L1,L7 | `theme:"system"/"light"/"dark"`, `selectedShelfID:String?` (`nil`/`default` = default shelf); independent `accentTheme` raw `浅紫/蓝/青绿/粉/橙/红`, default `蓝` | theme/selection in S; accent in separate UserDefaults key `accentTheme` | Small preferences | Accent absent from old backup | theme **MUST MIGRATE** F2; selected shelf **BEST-EFFORT IMPORT** F2; accent **BEST-EFFORT IMPORT**, acquisition/application F7, not present in v1 backup |
| Reading statistics / L1,L2 | `dailyStats:{yyyy-MM-dd:{seconds:Int,chapters:Int}}`, local Gregorian day; `bookReadingSeconds:{bookID:Int}` | S | Durable aggregates, no event log found | No timezone or per-session history; summing repeat imports duplicates totals | **DEFER TO LATER PHASE**, F7 statistics materialization; F2 preserves recognized aggregates in versioned migration staging |
| Search history / L1 | `searchHistory:[String]`, most recent first, maximum 10 in normal writes | S | Durable convenience history | Can contain private text; not search results | **DEFER TO LATER PHASE**, F7; F2 retains recognized field without logging it |
| Catalog / L3,L4,L9 | `[ChapterItem]`: `index:Int,title:String,volume:String?,remoteID:Int?`; computed Swift `id=index`; Kotlin `Volume` has `volumeId,volumeTitle,chapters`, but Swift drops volumeId | `O/<safe(source)>/<safe(bookID)>/catalog.json`; live copy in memory | Download-associated evidence; otherwise rebuildable catalog | Index and volume title mutable; cid optional; KMP fallback `index+1` is not evidence of cid | **DEFER TO LATER PHASE**, F6 file acquisition/import; F2 locator can retain catalog evidence only if explicitly supplied; F3 resolves IDs |
| Offline chapter bodies / L3 | `{index:Int,title:String,paragraphs:[String],images:[String]}`; absent images defaults to `[]`; no body schema version | `O/<safe(source)>/<safe(bookID)>/chapters/<index>.json` | Mixed read-through cache and user-requested download, indistinguishable on disk | Parallel arrays lose inline ordering; positional filenames; not in backup | **DEFER TO LATER PHASE**, F6; protect entire ambiguous offline tree, never auto-delete as disposable cache |
| Offline images / L1,L3 | Raw bytes; filename `<chapterIndex>-<imageOffset>-<first24(SHA256(UTF8(url)))>`; older random Swift hash names found by prefix `<index>-<offset>-` | Same book directory, `images/<safe(name)>` | Download-associated user asset | Multiple prefix matches possible; bodies can exist without images; old code accepts failed image download | **DEFER TO LATER PHASE**, F6; verify files/content associations, no completeness inferred from chapter count |
| Whole-source catalog / L3 | `[Book]`, JSON | `O/<safe(source)>/books.json` | Cache/offline metadata fallback | Filename source spelling is lossy | **CACHE — SAFE TO REBUILD**; F2 **BEST-EFFORT IMPORT** metadata recovery from explicit input, never substitute for unavailable library |
| Covers / L6 | Image bytes; filename SHA-256 of canonical URL; compatibility DJB2 decimal hash and old HTTP variants; Wenku8 HTTP image URL becomes HTTPS | Caches directory `LNRCovers/<hash>` plus memory cache | Cache | No reliable reverse URL/source mapping from filename | **CACHE — SAFE TO REBUILD**, F6; preserve book cover reference, not image-cache files |
| Explore cache / L1 | `explore.homeBlocks.v1`: JSON `[HomeExploreBlock]`; `explore.tagList.v1` string array; `explore.page.v1.<categoryID>#<sort>`: JSON `{books,totalPages}` | UserDefaults separate keys | Cache | Lacks source-aware namespace; stale results | **CACHE — SAFE TO REBUILD**, F3/F7; never normal durable library input |
| Authentication / L1,L4,L5 | `wenku8.cookies`, `wenku8.kmp.cookies`: cookie strings; URLSession cookie store; KMP in-memory cookie; backup optional `wenku8Cookie`; embedded fallback account constants exist | Standard UserDefaults, session storage, backup field, source code | Secret/session material | Plaintext export/preferences and stale sessions; no Keychain calls found in inspected source | **DO NOT MIGRATE**, discard from import input before staging; do not change original; F3 new secure sign-in/storage contract, never copy embedded credentials |
| Backup / L1,L8 | `{format:"lightnovelreader-backup",version:1,exportedAt:ISO8601 string,wenku8Cookie?:String,state:AppStateSnapshot}` | Temporary `LightNovelReader-Backup-yyyyMMdd-HHmm.json`, shared to a user-selected destination | User-owned transfer artifact | Contains optional secret; excludes accent, catalog, bodies, images, covers | F2 required input format for **MUST MIGRATE** state, sanitized on read; import UI/file acquisition F7 |
| EPUB/TXT export / L8 | Derived book export files, not AppStateSnapshot; exporter writes destination supplied by caller | Export/share destination (temporary generation or user's saved file) | User-owned exported document | Does not encode bookshelf/settings/progress | **DO NOT MIGRATE** as app state; leave user files untouched; future document import decision F7 |
| KMP bridge / L9 | `bookshelves:[{id,name,allBookIds}]`; reading `{id,lastReadChapterId,readingProgress}` string JSON | No Swift caller/persistent store found at baseline | Reserved interchange API, not actual iOS snapshot | Cannot assume an upstream Android database exists on iOS | **DO NOT MIGRATE** as an F2 input; additional format requires separate evidence/approval |
| Crash reports / L8 | `crash_<yyyy-MM-dd_HHmmss>.txt`, max 20 reports | Documents/CrashReports | Diagnostic files | May contain private exception text | **DO NOT MIGRATE**; keep legacy originals; diagnostics policy outside F2 |
| Runtime state / L1 | Search results/term/errors, Explore page generations, in-memory chapter cache/tasks, download job progress, shelf sort/filter | Memory only unless a Book was separately retained in S | Ephemeral | Persisting it would reproduce global-state coupling | **DO NOT MIGRATE** |

## 3. Important format findings

The standard JSONEncoder is used without a date override. Snapshot dates are
Swift Date numeric seconds since 2001-01-01T00:00:00Z, whereas `exportedAt` is an
ISO-8601 string. Importers must test the 978307200-second Unix epoch difference;
do not parse snapshot dates as Unix milliseconds. See the
[Swift Foundation Date Codable implementation](https://github.com/swiftlang/swift-foundation/blob/main/Sources/FoundationEssentials/Date.swift).

There is no single database schema marker. Separate markers are the snapshot
key `.v1`, Explore cache keys `.v1`, and backup `version:1`; catalog/body JSON
has no version field. App version 1.1.5/build 6 (L10) is not a data schema.

The old import is not the desired contract: L1:1290–1327 clears `books`, does
not directly restore `snapshot.bookLibrary`, does not restore manual merge,
rename or split fields, restores a cookie, and reloads network data. F2 must
read the exported data directly and restore valid user state without network
access, destructive replacement, or dependence on that old import path.

Legacy paragraphs and images preserve order within each separate array, but
their interleaving is absent. F2 cannot recover true inline image positions.
Unordered legacy bodies remain legacy payloads for F6; they are not silently
converted to a canonical ordered chapter. Even an intact catalog cannot prove
that the catalog and saved progress refer to the same historical revision.

## 4. iOS container feasibility

| Item | Evidence |
| --- | --- |
| Legacy app bundle ID | `com.komorebiiluv.LightNovelReader` in L10, both app build configurations |
| Flutter app bundle ID | `com.komorebiiluvu.lightNovelReader` in `ios/Runner.xcodeproj/project.pbxproj` lines 386, 567, 589 at Flutter commit `53d4723883539ae7acbdd3aabd745c93c2d47d6a` |
| Shared-container entitlement | No App Group/entitlements file or configured app-group entitlement found in either inspected tree |
| Signed application identity | No signed archive/profile inspected; Team/App ID prefix and actual installed identities unverified |

**The configured bundle identities differ. Direct on-device access from the
current Flutter app to the legacy private container is not available.** This
conclusion follows from the repository configuration and Apple's
[iOS sandbox rules](https://support.apple.com/guide/security/security-of-runtime-process-sec15bfe098e/web).
Even the same developer or display name does not grant shared storage access;
[App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
require provisioned participation and deliberate data transfer into the group.

| Mechanism | Feasibility and commitment |
| --- | --- |
| In-place upgrade | Conditional future option only: must become an authorized update of the actual installed legacy app, verify bundle/signing/distribution identity and upgrade retention, and prove a compliant Dart-accessible decoder for legacy UserDefaults **Data**. Changing a string alone is insufficient. No identity change is proposed now. |
| Existing legacy backup | Available producer at baseline. Proposed F2 importer consumes v1 JSON bytes supplied through an explicit input boundary on all three platforms. It cannot recover absent offline files or accent settings. |
| Explicit user export/import | Proposed product delivery route: user exports in old app, transfers file, imports in Flutter. F2 implements conversion/storage after approval; F7 owns picker/UI and platform transfer tests. Original file/app must remain intact. |
| Future transfer | Offline tree/extra settings need a separately approved acquisition route, e.g. legitimate in-place access, user-supplied container export or cooperative exporter. No such consumer-accessible transfer is evidenced today. F6/F7 own feasibility; F11 validates real upgrades. |

F2 can guarantee lossless preservation of valid committed fields in a supplied
baseline backup, including unresolved identities/locators. It cannot claim that
every installed predecessor can already transfer every asset. Offline continuity
remains a product obligation in F6; it must not be erased by calling downloads
cache. A release that replaces the old app cannot claim complete migration
until its acquisition route and recovery are demonstrated. No Constitution
exception or project-owned native migration implementation is proposed.
