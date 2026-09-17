import '../identity/source_refs.dart';
import 'reading_progress.dart';

abstract interface class ProgressRepository {
  Future<ReadingProgressV1?> get(SourceBookRef bookRef);

  /// Binary source ID, then book ID order.
  Future<List<ReadingProgressV1>> list();

  /// Replaces the current metadata snapshot for the existing library book.
  Future<void> save(ReadingProgressV1 progress);
}
