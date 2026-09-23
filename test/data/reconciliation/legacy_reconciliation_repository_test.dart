import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:light_novel_reader/src/data/persistence/database.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_library_repository.dart';
import 'package:light_novel_reader/src/data/persistence/repositories/drift_progress_repository.dart';
import 'package:light_novel_reader/src/domain/identity/opaque_ids.dart';
import 'package:light_novel_reader/src/domain/identity/source_refs.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_chapter_locator.dart';
import 'package:light_novel_reader/src/domain/legacy/legacy_source_mapping.dart';
import 'package:light_novel_reader/src/domain/progress/reading_progress.dart';
import 'package:light_novel_reader/src/domain/reconciliation/legacy_reconciliation.dart';

void main() {
  late AppDatabase db;
  late DriftProgressRepository progress;
  late SourceBookRef book;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    progress = DriftProgressRepository(db);
    book = SourceBookRef(
      sourceId: SourceId('fake.alpha'),
      bookId: BookId('same-id'),
    );
    await db.customStatement(
      "INSERT INTO source_registrations(source_id, availability) VALUES ('fake.alpha', 'unresolved')",
    );
    await DriftLibraryRepository(db).ensureStub(book);
    await db.customStatement(
      "INSERT INTO migration_datasets(dataset_id) VALUES ('dataset-a')",
    );
  });

  tearDown(() => db.close());

  test(
    'Drift compare-and-apply updates only the expected current progress',
    () async {
      final locator = LegacyChapterLocatorV1(
        datasetId: LegacyDatasetId('dataset-a'),
        bookRef: book,
        legacyBookId: BookId('same-id'),
        chapterIndex: 2,
        catalogDigest: 'digest-a',
      );
      final expected = ReadingProgressV1(
        bookRef: book,
        hasRead: true,
        legacyLocator: locator,
      );
      await progress.save(expected);
      final chapter = SourceChapterRef(
        sourceId: book.sourceId,
        bookId: book.bookId,
        chapterId: ChapterId('remote|2'),
      );
      final replacement = ReadingProgressV1(
        bookRef: book,
        hasRead: true,
        chapterRef: chapter,
        legacyLocator: LegacyChapterLocatorV1(
          datasetId: locator.datasetId,
          bookRef: book,
          legacyBookId: locator.legacyBookId,
          chapterIndex: locator.chapterIndex,
          remoteIdEvidence: chapter.chapterId.value,
          catalogDigest: locator.catalogDigest,
        ),
      );

      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: replacement,
        ),
        LegacyReconciliationApplyDisposition.applied,
      );
      expect(await progress.get(book), replacement);
      expect(
        await progress.compareAndApply(
          bookRef: book,
          expected: expected,
          replacement: expected,
        ),
        LegacyReconciliationApplyDisposition.conflict,
      );
    },
  );
}
