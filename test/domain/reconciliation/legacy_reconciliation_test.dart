import 'dart:convert';

import 'package:crypto/crypto.dart';
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
  );
  final chapter = SourceChapterRef(
    sourceId: book.sourceId,
    bookId: book.bookId,
    chapterId: ChapterId('第4章|remote'),
  );
  String catalogDigestFor(int index, String id) => sha256
      .convert(
        utf8.encode(
          jsonEncode([
            {'chapterId': id, 'chapterIndex': index},
          ]),
        ),
      )
      .toString();
  LegacyChapterCandidate candidate({
    SourceBookRef? candidateBook,
    int index = 4,
    String? digest,
    String id = '第4章|remote',
    int mappingVersion = 1,
  }) => LegacyChapterCandidate(
    chapterRef: SourceChapterRef(
      sourceId: candidateBook?.sourceId ?? book.sourceId,
      bookId: candidateBook?.bookId ?? book.bookId,
      chapterId: ChapterId(id),
    ),
    chapterIndex: index,
    catalogDigest: digest ?? catalogDigestFor(4, chapter.chapterId.value),
    mappingVersion: mappingVersion,
    title: '新标题',
  );
  LegacyChapterResolutionProof proof({
    LegacyChapterLocatorV1? forLocator,
    SourceChapterRef? forChapter,
  }) {
    final selectedLocator = forLocator ?? locator;
    final selectedChapter = forChapter ?? chapter;
    final catalog = [
      {
        'chapterId': selectedChapter.chapterId.value,
        'chapterIndex': selectedLocator.chapterIndex,
      },
    ];
    final bytes = utf8.encode(
      jsonEncode({
        'kind': 'legacyChapterCapture',
        'version': 1,
        'datasetId': selectedLocator.datasetId.value,
        'sourceId': selectedLocator.bookRef.sourceId.value,
        'bookId': selectedLocator.bookRef.bookId.value,
        'legacyBookId': selectedLocator.legacyBookId.value,
        'chapterIndex': selectedLocator.chapterIndex,
        'locatorDigest': sha256
            .convert(utf8.encode(jsonEncode(selectedLocator.toJson())))
            .toString(),
        'mappingVersion': 1,
        'captureId': 'same-atomic-capture',
        'proofKind': 'coCapturedCatalog',
        'catalog': catalog,
      }),
    );
    final verified = const LegacyChapterCaptureVerifier().verify(
      locator: selectedLocator,
      artifactBytes: bytes,
      trustedArtifactDigest: sha256.convert(bytes).toString(),
    );
    expect(verified, isNotNull);
    return verified!.proof;
  }

  test('resolves opaque, nonnumeric ID only with verified capture', () {
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [candidate()],
      proof: proof(),
    );
    expect(plan.state, LegacyResolutionState.resolved);
    expect(plan.chapterRef, chapter);
    expect(
      plan.reason,
      LegacyResolutionReason.resolvedByContemporaneousCatalog,
    );
  });

  test(
    'title, position, digest or a current catalog cannot resolve without proof',
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
      expect(plan.reason, LegacyResolutionReason.missingVerifiedProof);
    },
  );

  test('recorded remote ID requires matching preserved evidence and proof', () {
    final recorded = LegacyChapterLocatorV1(
      datasetId: locator.datasetId,
      bookRef: book,
      legacyBookId: locator.legacyBookId,
      chapterIndex: locator.chapterIndex,
      remoteIdEvidence: chapter.chapterId.value,
    );
    final bytes = utf8.encode(
      jsonEncode({
        'kind': 'legacyChapterCapture',
        'version': 1,
        'datasetId': recorded.datasetId.value,
        'sourceId': book.sourceId.value,
        'bookId': book.bookId.value,
        'legacyBookId': recorded.legacyBookId.value,
        'chapterIndex': recorded.chapterIndex,
        'locatorDigest': sha256
            .convert(utf8.encode(jsonEncode(recorded.toJson())))
            .toString(),
        'mappingVersion': 1,
        'captureId': 'recorded-with-progress',
        'proofKind': 'recordedRemoteId',
        'remoteId': chapter.chapterId.value,
      }),
    );
    final attestation = const LegacyChapterCaptureVerifier().verify(
      locator: recorded,
      artifactBytes: bytes,
      trustedArtifactDigest: sha256.convert(bytes).toString(),
    );
    expect(attestation, isNotNull);
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: recorded,
      candidates: const [],
      proof: attestation!.proof,
    );
    expect(plan.state, LegacyResolutionState.resolved);
    expect(plan.reason, LegacyResolutionReason.resolvedByRecordedRemoteId);
    expect(plan.chapterRef, chapter);

    final mismatch = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: const [],
      proof: attestation.proof,
    );
    expect(mismatch.state, LegacyResolutionState.conflict);
    expect(mismatch.reason, LegacyResolutionReason.proofMismatch);
  });

  test('digest mismatch and cross-source candidates never resolve', () {
    final mismatch = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [candidate(digest: 'new-catalog')],
      proof: proof(),
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
      proof: proof(),
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
      proof: proof(),
    );
    expect(plan.state, LegacyResolutionState.conflict);
    expect(plan.reason, LegacyResolutionReason.proofMismatch);
    expect(plan.candidates, hasLength(2));
  });

  test('duplicate evidence at one index remains a conflict', () {
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [
        candidate(),
        candidate(id: 'different-remote-id'),
      ],
      proof: proof(),
    );
    expect(plan.state, LegacyResolutionState.conflict);
    expect(plan.reason, LegacyResolutionReason.proofMismatch);
    final unverified = const LegacyChapterReconciliationPlanner().plan(
      locator: locator,
      candidates: [
        candidate(),
        candidate(id: 'another|id'),
      ],
    );
    expect(unverified.state, LegacyResolutionState.conflict);
    expect(
      unverified.reason,
      LegacyResolutionReason.ambiguousChapterAtLegacyIndex,
    );
  });

  test('capture verifier rejects untrusted hash and secret-bearing fields', () {
    final raw = utf8.encode(
      jsonEncode({
        'kind': 'legacyChapterCapture',
        'version': 1,
        'Authorization': 'Bearer unexpected',
      }),
    );
    final verifier = const LegacyChapterCaptureVerifier();
    expect(
      verifier.verify(
        locator: locator,
        artifactBytes: raw,
        trustedArtifactDigest: sha256.convert(raw).toString(),
      ),
      null,
    );
    expect(
      verifier.verify(
        locator: locator,
        artifactBytes: raw,
        trustedArtifactDigest: '0' * 64,
      ),
      null,
    );
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
      proof: proof(),
    );
    const service = LegacyChapterReconciliationService();

    expect(
      await service.apply(repository: store, expected: expected, plan: plan),
      LegacyReconciliationApplyDisposition.applied,
    );
    final updated = await store.get();
    expect(updated?.chapterRef, chapter);
    expect(updated?.legacyLocator, same(locator));
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

  test('a stale or unrelated plan cannot replace current progress', () async {
    final expected = ReadingProgressV1(
      bookRef: book,
      hasRead: true,
      legacyLocator: locator,
    );
    final store = _MemoryStore(expected);
    final otherLocator = LegacyChapterLocatorV1(
      datasetId: locator.datasetId,
      bookRef: book,
      legacyBookId: locator.legacyBookId,
      chapterIndex: locator.chapterIndex + 1,
      catalogDigest: null,
    );
    final otherPlan = const LegacyChapterReconciliationPlanner().plan(
      locator: otherLocator,
      candidates: [
        candidate(
          index: 5,
          digest: proof(forLocator: otherLocator).catalogDigest,
        ),
      ],
      proof: proof(forLocator: otherLocator),
    );
    expect(
      await const LegacyChapterReconciliationService().apply(
        repository: store,
        expected: expected,
        plan: otherPlan,
      ),
      LegacyReconciliationApplyDisposition.conflict,
    );
    expect(store.current, same(expected));
  });

  test('existing remote ID evidence is preserved, not overwritten', () async {
    final evidencedLocator = LegacyChapterLocatorV1(
      datasetId: locator.datasetId,
      bookRef: book,
      legacyBookId: locator.legacyBookId,
      chapterIndex: locator.chapterIndex,
      remoteIdEvidence: chapter.chapterId.value,
      catalogDigest: null,
    );
    final expected = ReadingProgressV1(
      bookRef: book,
      hasRead: true,
      legacyLocator: evidencedLocator,
    );
    final store = _MemoryStore(expected);
    final plan = const LegacyChapterReconciliationPlanner().plan(
      locator: evidencedLocator,
      candidates: [candidate()],
      proof: proof(forLocator: evidencedLocator),
    );
    expect(
      await const LegacyChapterReconciliationService().apply(
        repository: store,
        expected: expected,
        plan: plan,
      ),
      LegacyReconciliationApplyDisposition.applied,
    );
    expect(store.current?.legacyLocator, same(evidencedLocator));
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
    required LegacyChapterResolutionPlan plan,
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
