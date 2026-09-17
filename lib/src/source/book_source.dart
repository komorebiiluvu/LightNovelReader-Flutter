import '../domain/content/chapter_content.dart';
import '../domain/identity/source_refs.dart';
import 'source_capability.dart';
import 'source_continuation.dart';
import 'source_failure.dart';
import 'source_models.dart';
import 'source_operation.dart';

/// Neutral Source operations. Implementations must not perform provider work
/// until the context, capability, ownership and continuation checks pass.
abstract interface class BookSource {
  SourceDescriptor get descriptor;

  Future<SearchResult> search(
    SearchQuery query,
    SourceOperationContext context,
  );

  Future<ExploreResult> explore(
    ExploreRequest request,
    SourceOperationContext context,
  );

  Future<SourceBook> getBook(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<SourceCatalog> getCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<ChapterContent> getChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  );
}

/// Base class that makes the common pre-delegation checks reusable.
abstract class GuardedBookSource implements BookSource {
  @override
  SourceDescriptor get descriptor;

  @override
  Future<SearchResult> search(
    SearchQuery query,
    SourceOperationContext context,
  ) async {
    _before(context, SourceOperation.search, SourceCapability.search);
    if (query.filters.isNotEmpty) {
      SourceContractGuard.requireCapability(
        descriptor,
        SourceCapability.filters,
      );
    }
    _requireSearchContinuation(context, query);
    final result = await onSearch(query, context);
    _after(context);
    _validateSearchResult(result, query, context);
    return result;
  }

  @override
  Future<ExploreResult> explore(
    ExploreRequest request,
    SourceOperationContext context,
  ) async {
    _before(context, SourceOperation.explore, SourceCapability.explore);
    if (request.selections.isNotEmpty) {
      SourceContractGuard.requireCapability(
        descriptor,
        SourceCapability.filters,
      );
    }
    _requireExploreContinuation(context, request);
    final result = await onExplore(request, context);
    _after(context);
    _validateExploreResult(result, request, context);
    return result;
  }

  @override
  Future<SourceBook> getBook(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    _before(context, SourceOperation.bookDetail, SourceCapability.bookDetail);
    SourceContractGuard.requireOwned(descriptor, book);
    final result = await onGetBook(book, context);
    _after(context);
    SourceContractGuard.requireOwned(descriptor, result.bookRef);
    if (result.bookRef != book) throw SourceFailure.invalidRequest();
    if (result.coverAssetRef != null) {
      SourceContractGuard.requireOwned(descriptor, result.coverAssetRef!);
    }
    return result;
  }

  @override
  Future<SourceCatalog> getCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  ) async {
    _before(context, SourceOperation.catalog, SourceCapability.catalog);
    SourceContractGuard.requireOwned(descriptor, book);
    final result = await onGetCatalog(book, context);
    _after(context);
    for (final entry in result.chapters) {
      SourceContractGuard.requireOwned(descriptor, entry.chapterRef);
      final volumeRef = entry.grouping?.volumeRef;
      if (volumeRef != null) {
        SourceContractGuard.requireOwned(descriptor, volumeRef);
      }
      if (entry.chapterRef.sourceId != book.sourceId ||
          entry.chapterRef.bookId != book.bookId) {
        throw SourceFailure.invalidRequest();
      }
    }
    return result;
  }

  @override
  Future<ChapterContent> getChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  ) async {
    _before(
      context,
      SourceOperation.chapterContent,
      SourceCapability.chapterContent,
    );
    SourceContractGuard.requireOwned(descriptor, chapter);
    final result = await onGetChapterContent(chapter, context);
    _after(context);
    SourceContractGuard.requireOwned(descriptor, result.chapterRef);
    if (result.chapterRef != chapter) throw SourceFailure.invalidRequest();
    for (final node in result.nodes) {
      if (node is ImageNode) {
        SourceContractGuard.requireOwned(descriptor, node.assetRef);
        if (node.assetRef.bookId != chapter.bookId) {
          throw SourceFailure.invalidRequest();
        }
      }
    }
    return result;
  }

  Future<SearchResult> onSearch(
    SearchQuery query,
    SourceOperationContext context,
  );

  Future<ExploreResult> onExplore(
    ExploreRequest request,
    SourceOperationContext context,
  );

  Future<SourceBook> onGetBook(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<SourceCatalog> onGetCatalog(
    SourceBookRef book,
    SourceOperationContext context,
  );

  Future<ChapterContent> onGetChapterContent(
    SourceChapterRef chapter,
    SourceOperationContext context,
  );

  void _before(
    SourceOperationContext context,
    SourceOperation operation,
    SourceCapability capability,
  ) {
    context.requireOperation(operation);
    context.requireActive();
    if (context.sourceId != descriptor.sourceId) {
      throw SourceFailure.invalidRequest();
    }
    SourceContractGuard.requireCapability(descriptor, capability);
  }

  void _after(SourceOperationContext context) => context.requireActive();

  void _requireSearchContinuation(
    SourceOperationContext context,
    SearchQuery query,
  ) {
    query.continuation?.validateForSearch(
      sourceId: descriptor.sourceId,
      queryText: query.text,
      filters: query.filters,
      sessionGeneration: context.sessionGeneration,
    );
  }

  void _requireExploreContinuation(
    SourceOperationContext context,
    ExploreRequest request,
  ) {
    request.continuation?.validateForExplore(
      sourceId: descriptor.sourceId,
      descriptorId: request.descriptorId,
      selections: request.selections,
      sessionGeneration: context.sessionGeneration,
    );
  }

  void _validateSearchResult(
    SearchResult result,
    SearchQuery query,
    SourceOperationContext context,
  ) {
    for (final item in result.items) {
      SourceContractGuard.requireOwned(descriptor, item.bookRef);
      if (item.coverAssetRef != null) {
        SourceContractGuard.requireOwned(descriptor, item.coverAssetRef!);
      }
    }
    result.next?.validateForSearch(
      sourceId: descriptor.sourceId,
      queryText: query.text,
      filters: query.filters,
      sessionGeneration: context.sessionGeneration,
    );
  }

  void _validateExploreResult(
    ExploreResult result,
    ExploreRequest request,
    SourceOperationContext context,
  ) {
    for (final block in result.blocks) {
      for (final item in block.books) {
        SourceContractGuard.requireOwned(descriptor, item.bookRef);
        if (item.coverAssetRef != null) {
          SourceContractGuard.requireOwned(descriptor, item.coverAssetRef!);
        }
      }
    }
    result.next?.validateForExplore(
      sourceId: descriptor.sourceId,
      descriptorId: request.descriptorId,
      selections: request.selections,
      sessionGeneration: context.sessionGeneration,
    );
  }
}

final class SourceContractGuard {
  const SourceContractGuard._();

  static void requireCapability(
    SourceDescriptor descriptor,
    SourceCapability capability,
  ) {
    if (!descriptor.capabilities.contains(capability)) {
      throw SourceFailure.unsupportedCapability(capability);
    }
  }

  static void requireOwned(SourceDescriptor descriptor, SourceRef ref) {
    if (ref.sourceId != descriptor.sourceId) {
      throw SourceFailure.invalidRequest();
    }
  }
}
