import '../../core/app_error.dart';

enum IdentityFailureReason {
  emptyId('identity_empty_id'),
  invalidUnicode('identity_invalid_unicode'),
  nulCharacter('identity_nul_character'),
  missingField('identity_missing_field'),
  wrongType('identity_wrong_type'),
  wrongKind('identity_unsupported_kind'),
  unsupportedVersion('identity_unsupported_version'),
  unknownField('identity_unsupported_field'),
  invalidValue('identity_invalid_value'),
  invalidKey('identity_invalid_key');

  const IdentityFailureReason(this.code);
  final String code;
}

/// A safe boundary failure: never carries the rejected input into diagnostics.
final class IdentityFailure extends AppFailure {
  IdentityFailure(this.reason)
    : super(code: reason.code, message: 'Identity data could not be read.');

  final IdentityFailureReason reason;

  bool get isUnsupported => switch (reason) {
    IdentityFailureReason.wrongKind ||
    IdentityFailureReason.unsupportedVersion ||
    IdentityFailureReason.unknownField => true,
    _ => false,
  };
}
