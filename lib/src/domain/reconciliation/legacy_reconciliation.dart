import '../identity/source_refs.dart';
import '../legacy/legacy_chapter_locator.dart';
import '../progress/reading_progress.dart';

enum LegacyResolutionState { resolved, unresolved, conflict }

enum LegacyResolutionReason {
  resolvedByContemporaneousCatalog,
  missingCatalogDigest,
  catalogDigestMismatch,
  sourceMismatch,
  bookMismatch,
  noChapterAtLegacyIndex,
  ambiguousChapterAtLegacyIndex,
  invalidChapterEvidence,
  mappingVersionMismatch,
}

/// Sanitized chapter evidence produced by a reviewed Source catalog read.
/// The catalog digest is the contemporaneity boundary; titles and volume labels
/// are retained for review but never resolve a chapter by themselves.
final class LegacyChapterCandidate {
  LegacyChapterCandidate({
    required this.chapterRef,
    required this.chapterIndex,
    required this.catalogDigest,
    required this.mappingVersion,
    this.title,
    this.volumeLabel,
  }) {
    if (chapterIndex < 0 || catalogDigest.isEmpty || mappingVersion < 1) {
      throw ArgumentError('Invalid chapter evidence');
    }
    if (chapterRef.chapterId.value.isEmpty) {
      throw ArgumentError('Empty chapter identity');
    }
  }

  final SourceChapterRef chapterRef;
  final int chapterIndex;
  final String catalogDigest;
  final int mappingVersion;
  final String? title;
  final String? volumeLabel;
}

final class LegacyChapterResolutionPlan {
  const LegacyChapterResolutionPlan({
    required this.state,
    required this.reason,
    required this.locator,
    this.chapterRef,
    this.candidates = const [],
  });

  final LegacyResolutionState state;
  final LegacyResolutionReason reason;
  final LegacyChapterLocatorV1 locator;
  final SourceChapterRef? chapterRef;
  final List<LegacyChapterCandidate> candidates;

  bool get canApply => state == LegacyResolutionState.resolved;
}

/// Resolves only from source/book-bound, contemporaneous catalog evidence.
/// Position, title, count and a current catalog without a matching digest are
/// deliberately insufficient.
final class LegacyChapterReconciliationPlanner {
  const LegacyChapterReconciliationPlanner();

  LegacyChapterResolutionPlan plan({
    required LegacyChapterLocatorV1 locator,
    required Iterable<LegacyChapterCandidate> candidates,
  }) {
    final all = List<LegacyChapterCandidate>.unmodifiable(candidates);
    if (locator.catalogDigest == null || locator.catalogDigest!.isEmpty) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.missingCatalogDigest,
        locator: locator,
        candidates: all,
      );
    }
    if (all.any(
      (candidate) => candidate.catalogDigest != locator.catalogDigest,
    )) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.catalogDigestMismatch,
        locator: locator,
        candidates: all,
      );
    }
    final mappingVersions = all
        .map((candidate) => candidate.mappingVersion)
        .toSet();
    if (mappingVersions.length != 1) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.mappingVersionMismatch,
        locator: locator,
        candidates: all,
      );
    }
    final scoped = all
        .where((candidate) {
          return candidate.chapterRef.sourceId == locator.bookRef.sourceId &&
              candidate.chapterRef.bookId == locator.bookRef.bookId;
        })
        .toList(growable: false);
    if (scoped.length != all.length) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.sourceMismatch,
        locator: locator,
        candidates: all,
      );
    }
    final atIndex = scoped
        .where((candidate) => candidate.chapterIndex == locator.chapterIndex)
        .toList(growable: false);
    if (atIndex.isEmpty) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.noChapterAtLegacyIndex,
        locator: locator,
        candidates: all,
      );
    }
    if (atIndex.length != 1 ||
        atIndex.map((candidate) => candidate.chapterRef).toSet().length != 1) {
      return LegacyChapterResolutionPlan(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.ambiguousChapterAtLegacyIndex,
        locator: locator,
        candidates: all,
      );
    }
    return LegacyChapterResolutionPlan(
      state: LegacyResolutionState.resolved,
      reason: LegacyResolutionReason.resolvedByContemporaneousCatalog,
      locator: locator,
      chapterRef: atIndex.single.chapterRef,
      candidates: all,
    );
  }
}

enum LegacyReconciliationApplyDisposition {
  applied,
  unchanged,
  conflict,
  notFound,
}

/// Repository boundary for an atomic expected-current-state reconciliation.
abstract interface class LegacyProgressReconciliationRepository {
  Future<LegacyReconciliationApplyDisposition> compareAndApply({
    required SourceBookRef bookRef,
    required ReadingProgressV1 expected,
    required ReadingProgressV1 replacement,
  });
}

final class LegacyChapterReconciliationService {
  const LegacyChapterReconciliationService({
    this.planner = const LegacyChapterReconciliationPlanner(),
  });

  final LegacyChapterReconciliationPlanner planner;

  Future<LegacyReconciliationApplyDisposition> apply({
    required LegacyProgressReconciliationRepository repository,
    required ReadingProgressV1 expected,
    required LegacyChapterResolutionPlan plan,
  }) {
    if (!plan.canApply || plan.chapterRef == null) {
      return Future.value(LegacyReconciliationApplyDisposition.conflict);
    }
    final locator = plan.locator;
    final replacement = ReadingProgressV1(
      bookRef: expected.bookRef,
      hasRead: expected.hasRead,
      chapterRef: plan.chapterRef,
      legacyLocator: LegacyChapterLocatorV1(
        datasetId: locator.datasetId,
        bookRef: locator.bookRef,
        legacyBookId: locator.legacyBookId,
        chapterIndex: locator.chapterIndex,
        rawOffsetKey: locator.rawOffsetKey,
        fraction: locator.fraction,
        remoteIdEvidence: plan.chapterRef!.chapterId.value,
        chapterTitleEvidence: locator.chapterTitleEvidence,
        volumeTitleEvidence: locator.volumeTitleEvidence,
        catalogDigest: locator.catalogDigest,
      ),
      lastReadAt: expected.lastReadAt,
    );
    return repository.compareAndApply(
      bookRef: expected.bookRef,
      expected: expected,
      replacement: replacement,
    );
  }
}
