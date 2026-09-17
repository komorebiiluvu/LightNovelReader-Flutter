/// Source operations that can be bound to a request or operation context.
enum SourceOperation {
  search('search'),
  explore('explore'),
  bookDetail('bookDetail'),
  catalog('catalog'),
  chapterContent('chapterContent'),
  authentication('authentication');

  const SourceOperation(this.wireName);

  final String wireName;
}
