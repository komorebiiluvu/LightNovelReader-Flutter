import 'identity_failure.dart';

/// Shared v1 identity-object validation, after JSON syntax decoding.
///
/// A Map cannot reveal duplicate JSON keys. External importers must reject
/// duplicates before calling these codecs (F2.6); jsonDecode alone is insufficient.
Map<String, Object?> readIdentityObject(Object? input) {
  if (input is! Map || input.keys.any((key) => key is! String)) {
    throw IdentityFailure(IdentityFailureReason.wrongType);
  }
  return Map<String, Object?>.from(input);
}

Map<String, Object?> readIdentityV1(
  Object? input, {
  required String kind,
  required Set<String> requiredFields,
  Set<String> optionalFields = const {},
}) {
  final fields = readIdentityObject(input);
  for (final key in {'kind', 'version', ...requiredFields}) {
    if (!fields.containsKey(key)) {
      throw IdentityFailure(IdentityFailureReason.missingField);
    }
  }
  if (identityString(fields['kind']) != kind) {
    throw IdentityFailure(IdentityFailureReason.wrongKind);
  }
  final version = fields['version'];
  if (version is! int) {
    throw IdentityFailure(IdentityFailureReason.wrongType);
  }
  if (version != 1) {
    throw IdentityFailure(IdentityFailureReason.unsupportedVersion);
  }
  final allowed = {'kind', 'version', ...requiredFields, ...optionalFields};
  if (fields.keys.any((key) => !allowed.contains(key))) {
    throw IdentityFailure(IdentityFailureReason.unknownField);
  }
  return fields;
}

String identityString(Object? input) {
  if (input is! String) {
    throw IdentityFailure(IdentityFailureReason.wrongType);
  }
  return input;
}

String? optionalIdentityString(Map<String, Object?> fields, String key) =>
    fields.containsKey(key) ? identityString(fields[key]) : null;
