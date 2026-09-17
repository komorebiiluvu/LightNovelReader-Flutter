import '../identity/opaque_ids.dart';
import '../identity/source_refs.dart';
import '../library/library_models.dart';
import '../preferences/preferences.dart';
import 'migration_models.dart';

final class LegacyImportExecutionContext {
  const LegacyImportExecutionContext({
    required this.datasetId,
    required this.mappingVersion,
  });
  final String datasetId;
  final int mappingVersion;
}

/// Sanitized, immutable payloads produced by the concrete legacy planner.
/// None of these types can carry a raw JSON object or an excluded field.
sealed class LegacyImportPayload {
  const LegacyImportPayload();
}

final class SourceImportPayload extends LegacyImportPayload {
  const SourceImportPayload({required this.legacyName, required this.sourceId});
  final String legacyName;
  final SourceId sourceId;
}

final class BookImportPayload extends LegacyImportPayload {
  const BookImportPayload({
    required this.bookId,
    required this.bookRef,
    required this.saved,
    required this.sourceName,
    required this.sourceByIdName,
    required this.bookSourceName,
    required this.title,
    required this.author,
    required this.intro,
    required this.tags,
    required this.totalChapters,
    required this.lastChapter,
    required this.hits,
    required this.coverIndex,
    required this.hasUpdate,
    required this.coverUrl,
    required this.publishingHouse,
    required this.lastUpdate,
    required this.isCompleted,
    required this.wordCountK,
    required this.knownTotal,
    required this.updateFlag,
    required this.sourceConflict,
  });

  final BookId bookId;
  final SourceBookRef bookRef;
  final bool saved;
  final String? sourceName;
  final String? sourceByIdName;
  final String? bookSourceName;
  final String? title;
  final String? author;
  final String? intro;
  final List<String> tags;
  final int? totalChapters;
  final int? lastChapter;
  final int? hits;
  final int? coverIndex;
  final bool? hasUpdate;
  final String? coverUrl;
  final String? publishingHouse;
  final String? lastUpdate;
  final bool? isCompleted;
  final int? wordCountK;
  final int? knownTotal;
  final bool? updateFlag;
  final bool sourceConflict;
}

final class ShelfImportPayload extends LegacyImportPayload {
  const ShelfImportPayload({
    required this.legacyId,
    required this.targetId,
    required this.name,
    required this.ordinal,
    required this.members,
    required this.hasDuplicateMembers,
    required this.hasInvalidMembers,
  });
  final String legacyId;
  final ShelfId targetId;
  final String name;
  final int ordinal;
  final List<BookImportPayload> members;
  final bool hasDuplicateMembers;
  final bool hasInvalidMembers;
}

final class GroupImportPayload extends LegacyImportPayload {
  const GroupImportPayload({
    required this.legacyId,
    required this.targetId,
    required this.displayName,
    required this.members,
  });
  final String legacyId;
  final ManualGroupId targetId;
  final String? displayName;
  final List<BookImportPayload> members;
}

final class AutoGroupRenamePayload extends LegacyImportPayload {
  const AutoGroupRenamePayload({required this.displayName});
  final String? displayName;
}

final class SplitImportPayload extends LegacyImportPayload {
  const SplitImportPayload({required this.book});
  final BookImportPayload book;
}

final class ProgressImportPayload extends LegacyImportPayload {
  const ProgressImportPayload({
    required this.book,
    required this.hasRead,
    required this.selectedChapter,
    required this.selectedFraction,
    required this.selectedOffsetKey,
    required this.appleDateSeconds,
    required this.lastReadAt,
  });
  final BookImportPayload book;
  final bool hasRead;
  final int? selectedChapter;
  final double? selectedFraction;
  final String? selectedOffsetKey;
  final double? appleDateSeconds;
  final DateTime? lastReadAt;
}

final class OrphanProgressPayload extends LegacyImportPayload {
  const OrphanProgressPayload();
}

final class ReaderPreferencesImportPayload extends LegacyImportPayload {
  const ReaderPreferencesImportPayload({
    required this.value,
    required this.invalidFields,
  });
  final ReaderPreferencesV1 value;
  final Set<String> invalidFields;
}

final class AppPreferencesImportPayload extends LegacyImportPayload {
  const AppPreferencesImportPayload({
    required this.theme,
    required this.preferredSourceId,
    required this.selectedShelfId,
    required this.selectedShelfLegacyId,
    required this.invalidFields,
  });
  final AppTheme theme;
  final SourceId preferredSourceId;
  final ShelfId? selectedShelfId;
  final String? selectedShelfLegacyId;
  final Set<String> invalidFields;
}

final class DeferredStatisticsPayload extends LegacyImportPayload {
  const DeferredStatisticsPayload({required this.evidenceCount});
  final int evidenceCount;
}

final class DeferredSearchHistoryPayload extends LegacyImportPayload {
  const DeferredSearchHistoryPayload({required this.termCount});
  final int termCount;
}

/// A typed concrete plan. Payloads are held only in memory and are never
/// persisted wholesale; the migration repository persists scalar evidence.
final class LegacyImportPlan {
  const LegacyImportPlan({required this.plan, required this.payloads});
  final MigrationPlan plan;
  final Map<String, LegacyImportPayload> payloads;

  LegacyImportPayload payloadFor(MigrationUnit unit) =>
      payloads['${unit.entityKind.wireName}\u0000${unit.legacyKey}']!;
}

final class LegacyImportResult {
  const LegacyImportResult({required this.run, required this.report});
  final MigrationRun run;
  final LegacyImportReport report;
}

final class LegacyImportReport {
  const LegacyImportReport({
    required this.run,
    required this.expectedByKind,
    required this.verifiedByKind,
    required this.outcomeCounts,
    required this.unresolvedRecords,
    required this.deferredRecords,
    required this.conflicts,
    required this.failures,
    this.offlineAssetsDeferred = true,
    this.accentUnavailable = true,
  });

  final MigrationRun run;
  final Map<MigrationEntityKind, int> expectedByKind;
  final Map<MigrationEntityKind, int> verifiedByKind;
  final Map<MigrationOutcome, int> outcomeCounts;
  final int unresolvedRecords;
  final int deferredRecords;
  final int conflicts;
  final int failures;
  final bool offlineAssetsDeferred;
  final bool accentUnavailable;
}
