import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';
import '../legacy/legacy_chapter_locator.dart';
import '../progress/reading_progress.dart';

enum LegacyResolutionState { resolved, unresolved, conflict }

enum LegacyResolutionReason {
  resolvedByContemporaneousCatalog,
  resolvedByRecordedRemoteId,
  missingVerifiedProof,
  proofMismatch,
  missingCatalogDigest,
  catalogDigestMismatch,
  sourceMismatch,
  bookMismatch,
  noChapterAtLegacyIndex,
  ambiguousChapterAtLegacyIndex,
  invalidChapterEvidence,
  mappingVersionMismatch,
}

enum LegacyChapterProofKind { recordedRemoteId, coCapturedCatalog }

/// An attestation from an independently reviewed capture-verification boundary.
/// No current F2 importer creates one. A matching digest by itself is not one.
final class LegacyChapterResolutionProof {
  LegacyChapterResolutionProof._({
    required this.kind,
    required this.locator,
    required this.chapterRef,
    required this.mappingVersion,
    required this.artifactDigest,
    this.coCaptureMarker,
    this.catalogDigest,
  }) {
    if (mappingVersion < 1 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(artifactDigest) ||
        chapterRef.sourceId != locator.bookRef.sourceId ||
        chapterRef.bookId != locator.bookRef.bookId ||
        (kind == LegacyChapterProofKind.coCapturedCatalog &&
            (coCaptureMarker == null ||
                coCaptureMarker!.isEmpty ||
                catalogDigest == null ||
                catalogDigest!.isEmpty))) {
      throw ArgumentError('Invalid reconciliation proof');
    }
  }

  final LegacyChapterProofKind kind;
  final LegacyChapterLocatorV1 locator;
  final SourceChapterRef chapterRef;
  final int mappingVersion;
  final String artifactDigest;
  final String? coCaptureMarker;
  final String? catalogDigest;
}

final class LegacyVerifiedChapterCapture {
  const LegacyVerifiedChapterCapture._(this.proof, this.candidates);

  final LegacyChapterResolutionProof proof;
  final List<LegacyChapterCandidate> candidates;
}

/// Verifies a bounded, source-neutral capture against a trusted artifact hash.
/// The trusted hash must come from a reviewed import/capture receipt. The
/// current F2 importer produces no such chapter capture, so it cannot resolve
/// imported ordinals through this verifier.
final class LegacyChapterCaptureVerifier {
  const LegacyChapterCaptureVerifier();

  LegacyVerifiedChapterCapture? verify({
    required LegacyChapterLocatorV1 locator,
    required List<int> artifactBytes,
    required String trustedArtifactDigest,
  }) {
    if (artifactBytes.length > 1024 * 1024 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(trustedArtifactDigest) ||
        sha256.convert(artifactBytes).toString() != trustedArtifactDigest) {
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(artifactBytes));
      if (decoded is! Map<String, dynamic> ||
          !_hasOnlyKeys(decoded, {
            'kind',
            'version',
            'datasetId',
            'sourceId',
            'bookId',
            'legacyBookId',
            'chapterIndex',
            'locatorDigest',
            'mappingVersion',
            'captureId',
            'proofKind',
            'remoteId',
            'catalog',
          }) ||
          decoded['kind'] != 'legacyChapterCapture' ||
          decoded['version'] != 1 ||
          decoded['datasetId'] != locator.datasetId.value ||
          decoded['sourceId'] != locator.bookRef.sourceId.value ||
          decoded['bookId'] != locator.bookRef.bookId.value ||
          decoded['legacyBookId'] != locator.legacyBookId.value ||
          decoded['chapterIndex'] != locator.chapterIndex ||
          decoded['locatorDigest'] !=
              sha256
                  .convert(utf8.encode(jsonEncode(locator.toJson())))
                  .toString()) {
        return null;
      }
      final version = decoded['mappingVersion'];
      final captureId = decoded['captureId'];
      if (version is! int ||
          version < 1 ||
          captureId is! String ||
          captureId.isEmpty) {
        return null;
      }
      final kind = switch (decoded['proofKind']) {
        'recordedRemoteId' => LegacyChapterProofKind.recordedRemoteId,
        'coCapturedCatalog' => LegacyChapterProofKind.coCapturedCatalog,
        _ => null,
      };
      if (kind == null) return null;
      if (kind == LegacyChapterProofKind.recordedRemoteId) {
        final remoteId = decoded['remoteId'];
        if (remoteId is! String ||
            remoteId != locator.remoteIdEvidence ||
            decoded.containsKey('catalog')) {
          return null;
        }
        final chapterRef = SourceChapterRef(
          sourceId: locator.bookRef.sourceId,
          bookId: locator.bookRef.bookId,
          chapterId: ChapterId(remoteId),
        );
        return LegacyVerifiedChapterCapture._(
          LegacyChapterResolutionProof._(
            kind: kind,
            locator: locator,
            chapterRef: chapterRef,
            mappingVersion: version,
            artifactDigest: trustedArtifactDigest,
          ),
          const [],
        );
      }
      if (decoded.containsKey('remoteId')) return null;
      final rawCatalog = decoded['catalog'];
      if (rawCatalog is! List ||
          rawCatalog.isEmpty ||
          rawCatalog.length > 10000) {
        return null;
      }
      final normalizedCatalog = <Map<String, Object>>[];
      for (final raw in rawCatalog) {
        if (raw is! Map<String, dynamic> ||
            !_hasOnlyKeys(raw, {'chapterId', 'chapterIndex'}) ||
            raw['chapterId'] is! String ||
            raw['chapterIndex'] is! int) {
          return null;
        }
        normalizedCatalog.add({
          'chapterId': raw['chapterId'] as String,
          'chapterIndex': raw['chapterIndex'] as int,
        });
      }
      final catalogDigest = sha256
          .convert(utf8.encode(jsonEncode(normalizedCatalog)))
          .toString();
      if (locator.catalogDigest != null &&
          locator.catalogDigest != catalogDigest) {
        return null;
      }
      final candidates = <LegacyChapterCandidate>[];
      for (final raw in normalizedCatalog) {
        candidates.add(
          LegacyChapterCandidate(
            chapterRef: SourceChapterRef(
              sourceId: locator.bookRef.sourceId,
              bookId: locator.bookRef.bookId,
              chapterId: ChapterId(raw['chapterId'] as String),
            ),
            chapterIndex: raw['chapterIndex'] as int,
            catalogDigest: catalogDigest,
            mappingVersion: version,
          ),
        );
      }
      final atIndex = candidates
          .where((candidate) => candidate.chapterIndex == locator.chapterIndex)
          .toList(growable: false);
      if (atIndex.length != 1) return null;
      return LegacyVerifiedChapterCapture._(
        LegacyChapterResolutionProof._(
          kind: kind,
          locator: locator,
          chapterRef: atIndex.single.chapterRef,
          mappingVersion: version,
          artifactDigest: trustedArtifactDigest,
          coCaptureMarker: captureId,
          catalogDigest: catalogDigest,
        ),
        List.unmodifiable(candidates),
      );
    } catch (_) {
      // Raw capture content and parser errors never enter diagnostics.
      return null;
    }
  }
}

bool _hasOnlyKeys(Map<String, dynamic> value, Set<String> allowed) =>
    value.keys.every(allowed.contains);

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
  const LegacyChapterResolutionPlan._({
    required this.state,
    required this.reason,
    required this.locator,
    this.chapterRef,
    this.proof,
    this.candidates = const [],
  });

  final LegacyResolutionState state;
  final LegacyResolutionReason reason;
  final LegacyChapterLocatorV1 locator;
  final SourceChapterRef? chapterRef;
  final LegacyChapterResolutionProof? proof;
  final List<LegacyChapterCandidate> candidates;

  bool get canApply => state == LegacyResolutionState.resolved && proof != null;
}

/// Resolves only from source/book-bound, verified capture evidence.
/// Position, title, count and a matching digest without that proof are
/// deliberately insufficient.
final class LegacyChapterReconciliationPlanner {
  const LegacyChapterReconciliationPlanner();

  LegacyChapterResolutionPlan plan({
    required LegacyChapterLocatorV1 locator,
    required Iterable<LegacyChapterCandidate> candidates,
    LegacyChapterResolutionProof? proof,
  }) {
    final all = List<LegacyChapterCandidate>.unmodifiable(candidates);
    if (proof == null) {
      final atIndex = all
          .where((candidate) => candidate.chapterIndex == locator.chapterIndex)
          .toList(growable: false);
      if (atIndex.length > 1) {
        return LegacyChapterResolutionPlan._(
          state: LegacyResolutionState.conflict,
          reason: LegacyResolutionReason.ambiguousChapterAtLegacyIndex,
          locator: locator,
          candidates: all,
        );
      }
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.missingVerifiedProof,
        locator: locator,
        candidates: all,
      );
    }
    if (proof.locator != locator ||
        all.any(
          (candidate) => candidate.mappingVersion != proof.mappingVersion,
        )) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.proofMismatch,
        locator: locator,
        candidates: all,
      );
    }
    if (all.any(
      (candidate) =>
          candidate.chapterRef.sourceId != locator.bookRef.sourceId ||
          candidate.chapterRef.bookId != locator.bookRef.bookId,
    )) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.sourceMismatch,
        locator: locator,
        candidates: all,
      );
    }
    if (proof.kind == LegacyChapterProofKind.recordedRemoteId) {
      if (locator.remoteIdEvidence != proof.chapterRef.chapterId.value ||
          all.isNotEmpty) {
        return LegacyChapterResolutionPlan._(
          state: LegacyResolutionState.conflict,
          reason: LegacyResolutionReason.proofMismatch,
          locator: locator,
          candidates: all,
        );
      }
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.resolved,
        reason: LegacyResolutionReason.resolvedByRecordedRemoteId,
        locator: locator,
        chapterRef: proof.chapterRef,
        proof: proof,
        candidates: all,
      );
    }
    if (_catalogDigestFromCandidates(all) != proof.catalogDigest) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.proofMismatch,
        locator: locator,
        candidates: all,
      );
    }
    if (locator.catalogDigest != null &&
        locator.catalogDigest != proof.catalogDigest) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.catalogDigestMismatch,
        locator: locator,
        candidates: all,
      );
    }
    if (all.any(
      (candidate) => candidate.catalogDigest != proof.catalogDigest,
    )) {
      return LegacyChapterResolutionPlan._(
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
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.mappingVersionMismatch,
        locator: locator,
        candidates: all,
      );
    }
    final atIndex = all
        .where((candidate) => candidate.chapterIndex == locator.chapterIndex)
        .toList(growable: false);
    if (atIndex.isEmpty) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.unresolved,
        reason: LegacyResolutionReason.noChapterAtLegacyIndex,
        locator: locator,
        candidates: all,
      );
    }
    if (atIndex.length != 1 || atIndex.single.chapterRef != proof.chapterRef) {
      return LegacyChapterResolutionPlan._(
        state: LegacyResolutionState.conflict,
        reason: LegacyResolutionReason.ambiguousChapterAtLegacyIndex,
        locator: locator,
        candidates: all,
      );
    }
    return LegacyChapterResolutionPlan._(
      state: LegacyResolutionState.resolved,
      reason: LegacyResolutionReason.resolvedByContemporaneousCatalog,
      locator: locator,
      chapterRef: atIndex.single.chapterRef,
      proof: proof,
      candidates: all,
    );
  }
}

String _catalogDigestFromCandidates(List<LegacyChapterCandidate> candidates) {
  final normalized = [
    for (final candidate in candidates)
      {
        'chapterId': candidate.chapterRef.chapterId.value,
        'chapterIndex': candidate.chapterIndex,
      },
  ];
  return sha256.convert(utf8.encode(jsonEncode(normalized))).toString();
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
    required LegacyChapterResolutionPlan plan,
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
    if (!plan.canApply ||
        plan.chapterRef == null ||
        expected.bookRef != plan.locator.bookRef ||
        expected.legacyLocator != plan.locator ||
        (expected.chapterRef != null &&
            expected.chapterRef != plan.chapterRef)) {
      return Future.value(LegacyReconciliationApplyDisposition.conflict);
    }
    final locator = plan.locator;
    final replacement = ReadingProgressV1(
      bookRef: expected.bookRef,
      hasRead: expected.hasRead,
      chapterRef: plan.chapterRef,
      legacyLocator: locator,
      lastReadAt: expected.lastReadAt,
    );
    return repository.compareAndApply(
      bookRef: expected.bookRef,
      expected: expected,
      replacement: replacement,
      plan: plan,
    );
  }
}
