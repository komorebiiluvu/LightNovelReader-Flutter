import '../../core/app_error.dart';

enum RepositoryFailureReason {
  notFound,
  conflict,
  invalidReference,
  invalidInput,
  storage,
}

/// Safe public failure; never includes SQL, paths, or rejected values.
final class RepositoryFailure extends AppFailure {
  RepositoryFailure(this.reason)
    : super(
        code: 'repository_${reason.name}',
        message: 'The repository operation could not be completed.',
      );
  final RepositoryFailureReason reason;
}
