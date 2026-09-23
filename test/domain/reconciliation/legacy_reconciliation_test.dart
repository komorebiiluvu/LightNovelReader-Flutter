import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_chapter_locator.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_source_mapping.dart';
import 'package:light_novel_reader/src/domain/progress/reading_progress.dart';
import 'package:light_novel_reader/src/domain/reconciliation/legacy_reconciliation.dart';

void main() {
  final book = SourceBookRef(
    sourceId: SourceId('source.alpha'),
    bookId: BookId('book|同名'),
  );
  final locator = LegacyChapterLocatorV1(
    datasetId: LegacyDatasetId('dataset-a'),
    bookRef: book,
    legacyBookId: BookId('book|同名'),
    chapterIndex: 4,
    fraction: .25,
    chapterTitleEvidence: '旧标题',
    catalogDigest: 'catalog-v1',
  );
  final chapter = SourceChapterRef(
    sourceId: book.sourceId,
    bookId: book.bookId,
    chapterId: ChapterId('第4章|remote'),
  );
  LegacyChapterCandidate candidate({
    SourceBookRef? candidateBook,
    int index = 4,
    String digest = 'catalog-v1',
    String id = '第4章|remote',
    int mappingVersion = 1,
  }) => LegacyChapterCandidate(
    chapterRef: SourceChapterRef(
      sourceId: candidateBook?.sourceId ?? book.sourceId,
      bookId: candidateBook?.bookId ?? book.bookId,
      chapterId: ChapterId(id),
    ),
    chapterIndex: index,
    catalogDigest: digest,
    mappingVersion: mappingVersion,
    title: '新标题',
  );

  test(
    'resolves opaque, reordered, nonnumeric IDs only with matching digest',
    () {
      final plan = const LegacyChapterReconciliationPlanner().plan(
        locator: locator,
        candidates: [candidate(index: 1), candidate(), candidate(index: 9)],
      );
      expect(plan.state, LegacyResolutionState.resolved);
      expect(plan.chapterRef, chapter);
      expect(
        plan.reason,
        LegacyResolutionReason.resolvedByContemporaneousCatalog,
      );
    },
  );

  test(
    'title, position, or a current catalog cannot resolve without digest',
    () {
      final plan = const LegacyChapterReconciliationPlanner().plan(
        locator: LegacyChapterLocatorV1(
          datasetId: locator.datasetId,
          bookRef: locator.bookRef,
          legacyBookId: locator.legacyBookId,
          chapterIndex: locator.chapterIndex,
          fraction: locator.fraction,
          chapterTitleEvidence: locator.chapterTitleEvidence,
        ),
        candidates: [candidate()],
      );
      expect(plan.state, LegacyResolutionState.unresolved);
      expect(plan.reason, LegacyResolutionReason.missingCatalogDigest);
    },
  );

  test('digest mismatch and cross-source candidates never resolve', () {
    final mismatch = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [candidate(digest: 'new-catalog')],
    );
    expect(mismatch.state, LegacyResolutionState.unresolved);
    expect(mismatch.reason, LegacyResolutionReason.catalogDigestMismatch);

    final otherBook = SourceBookRef(
      sourceId: SourceId('source.beta'),
      bookId: book.bookId,
    );
    final crossSource = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [candidate(candidateBook: otherBook)],
    );
    expect(crossSource.state, LegacyResolutionState.conflict);
    expect(crossSource.reason, LegacyResolutionReason.sourceMismatch);
  });

  test('mixed mapping versions remain a conflict', () {
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [
        candidate(mappingVersion: 1),
        candidate(index: 3, mappingVersion: 2),
      ],
    );
    expect(plan.state, LegacyResolutionState.conflict);
    expect(plan.reason, LegacyResolutionReason.mappingVersionMismatch);
    expect(plan.candidates, hasLength(2));
  });

  test('duplicate evidence at one index remains a conflict', () {
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [
        candidate(),
        candidate(id: 'different-remote-id'),
      ],
    );
    expect(plan.state, LegacyResolutionState.conflict);
    expect(plan.reason, LegacyResolutionReason.ambiguousChapterAtLegacyIndex);
  });

  test('atomic apply is idempotent and rejects later user edits', () async {
    final expected = ReadingProgressV1(
      bookRef: book,
      hasRead: true,
      legacyLocator: locator,
    );
    final store = _MemoryStore(expected);
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [candidate()],
    );
    const service = LegacyChapterReconciliationService();

    expect(
      await service.apply(repository: store, expected: expected, plan: plan),
      LegacyReconciliationApplyDisposition.applied,
    );
    final updated = await store.get();
    expect(updated?.chapterRef, chapter);
    expect(
      await service.apply(repository: store, expected: updated!, plan: plan),
      LegacyReconciliationApplyDisposition.unchanged,
    );

    store.current = ReadingProgressV1(bookRef: book, hasRead: false);
    expect(
      await service.apply(repository: store, expected: updated, plan: plan),
      LegacyReconciliationApplyDisposition.conflict,
    );
  });
}

final class _MemoryStore implements LegacyProgressReconciliationRepository {
  _MemoryStore(this.current);

  ReadingProgressV1? current;

  Future<ReadingProgressV1?> get() async => current;

  @override
  Future<LegacyReconciliationApplyDisposition> compareAndApply({
    required SourceBookRef bookRef,
    required ReadingProgressV1 expected,
    required ReadingProgressV1 replacement,
  }) async {
    if (current == null) {
      return LegacyReconciliationApplyDisposition.notFound;
    }
    if (current == replacement) {
      return LegacyReconciliationApplyDisposition.unchanged;
    }
    if (current != expected) {
      return LegacyReconciliationApplyDisposition.conflict;
    }
    current = replacement;
    return LegacyReconciliationApplyDisposition.applied;
  }
}
