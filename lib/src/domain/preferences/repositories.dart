import 'preferences.dart';

abstract interface class PreferencesRepository {
  Future<ReaderPreferencesV1?> getReaderPreferences();
  Future<void> saveReaderPreferences(ReaderPreferencesV1 value);
  Future<AppPreferencesV1?> getAppPreferences();
  Future<void> saveAppPreferences(AppPreferencesV1 value);
}
