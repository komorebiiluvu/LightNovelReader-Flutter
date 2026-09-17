import '../../../domain/identity/opaque_ids.dart';
import '../../../domain/library/library_models.dart';
import '../../../domain/library/repository_failure.dart';
import '../../../domain/preferences/preferences.dart';
import '../../../domain/preferences/repositories.dart';
import '../database.dart' show AppDatabase;
import 'repository_access.dart';

final class DriftPreferencesRepository implements PreferencesRepository {
  DriftPreferencesRepository(AppDatabase db) : _access = RepositoryAccess(db);
  final RepositoryAccess _access;

  @override
  Future<ReaderPreferencesV1?> getReaderPreferences() => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM reader_preferences WHERE singleton=1',
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    if (row.read<int>('version') != 1) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    return ReaderPreferencesV1(
      fontSize: row.read<double>('font_size'),
      lineSpacing: row.read<double>('line_spacing'),
      background: _background(row.read<String>('background')),
      mode: _mode(row.read<String>('mode')),
      fontFamily: _fontFamily(row.read<String>('font_family')),
      bold: row.read<int>('bold') == 1,
      marginLeft: row.read<double>('margin_left'),
      marginRight: row.read<double>('margin_right'),
      marginTop: row.read<double>('margin_top'),
      marginBottom: row.read<double>('margin_bottom'),
    );
  });

  @override
  Future<void> saveReaderPreferences(ReaderPreferencesV1 value) => _access.run(
    () => _access.write(
      'INSERT INTO reader_preferences('
      'singleton,version,font_size,line_spacing,background,mode,font_family,'
      'bold,margin_left,margin_right,margin_top,margin_bottom) '
      'VALUES (1,1,?,?,?,?,?,?,?,?,?,?) '
      'ON CONFLICT(singleton) DO UPDATE SET version=1,font_size=excluded.font_size,'
      'line_spacing=excluded.line_spacing,background=excluded.background,'
      'mode=excluded.mode,font_family=excluded.font_family,bold=excluded.bold,'
      'margin_left=excluded.margin_left,margin_right=excluded.margin_right,'
      'margin_top=excluded.margin_top,margin_bottom=excluded.margin_bottom',
      [
        value.fontSize,
        value.lineSpacing,
        _backgroundToken(value.background),
        _modeToken(value.mode),
        _fontFamilyToken(value.fontFamily),
        value.bold ? 1 : 0,
        value.marginLeft,
        value.marginRight,
        value.marginTop,
        value.marginBottom,
      ],
    ),
  );

  @override
  Future<AppPreferencesV1?> getAppPreferences() => _access.run(() async {
    final rows = await _access.rows(
      'SELECT * FROM app_preferences WHERE singleton=1',
    );
    if (rows.isEmpty) return null;
    final row = rows.single;
    if (row.read<int>('version') != 1) {
      throw RepositoryFailure(RepositoryFailureReason.storage);
    }
    return AppPreferencesV1(
      theme: _theme(row.read<String>('theme')),
      preferredSourceId: row.readNullable<String>('preferred_source_id') == null
          ? null
          : SourceId(row.read<String>('preferred_source_id')),
      selectedShelfId: row.readNullable<String>('selected_shelf_id') == null
          ? null
          : ShelfId(row.read<String>('selected_shelf_id')),
      accent: _accentNullable(row.readNullable<String>('accent')),
    );
  });

  @override
  Future<void> saveAppPreferences(AppPreferencesV1 value) => _access.run(
    () async {
      if (value.preferredSourceId != null) {
        await _access.requireRow(
          'SELECT 1 FROM source_registrations WHERE source_id=?',
          [value.preferredSourceId!.value],
          RepositoryFailureReason.invalidReference,
        );
      }
      if (value.selectedShelfId != null) {
        await _access.requireRow('SELECT 1 FROM shelves WHERE shelf_id=?', [
          value.selectedShelfId!.value,
        ], RepositoryFailureReason.invalidReference);
      }
      await _access.write(
        'INSERT INTO app_preferences('
        'singleton,version,theme,preferred_source_id,selected_shelf_id,accent) '
        'VALUES (1,1,?,?,?,?) '
        'ON CONFLICT(singleton) DO UPDATE SET version=1,theme=excluded.theme,'
        'preferred_source_id=excluded.preferred_source_id,'
        'selected_shelf_id=excluded.selected_shelf_id,accent=excluded.accent',
        [
          _themeToken(value.theme),
          value.preferredSourceId?.value,
          value.selectedShelfId?.value,
          value.accent == null ? null : _accentToken(value.accent!),
        ],
      );
    },
  );
}

ReaderBackground _background(String value) => switch (value) {
  'paperWhite' => ReaderBackground.paperWhite,
  'parchment' => ReaderBackground.parchment,
  'darkGray' => ReaderBackground.darkGray,
  'black' => ReaderBackground.black,
  'eyeCare' => ReaderBackground.eyeCare,
  _ => throw RepositoryFailure(RepositoryFailureReason.storage),
};

String _backgroundToken(ReaderBackground value) => switch (value) {
  ReaderBackground.paperWhite => 'paperWhite',
  ReaderBackground.parchment => 'parchment',
  ReaderBackground.darkGray => 'darkGray',
  ReaderBackground.black => 'black',
  ReaderBackground.eyeCare => 'eyeCare',
};

ReaderMode _mode(String value) => switch (value) {
  'pageCurl' => ReaderMode.pageCurl,
  'scroll' => ReaderMode.scroll,
  _ => throw RepositoryFailure(RepositoryFailureReason.storage),
};

String _modeToken(ReaderMode value) => switch (value) {
  ReaderMode.pageCurl => 'pageCurl',
  ReaderMode.scroll => 'scroll',
};

ReaderFontFamily _fontFamily(String value) => switch (value) {
  'system' => ReaderFontFamily.system,
  'songti' => ReaderFontFamily.songti,
  'kaiti' => ReaderFontFamily.kaiti,
  'yuanti' => ReaderFontFamily.yuanti,
  _ => throw RepositoryFailure(RepositoryFailureReason.storage),
};

String _fontFamilyToken(ReaderFontFamily value) => switch (value) {
  ReaderFontFamily.system => 'system',
  ReaderFontFamily.songti => 'songti',
  ReaderFontFamily.kaiti => 'kaiti',
  ReaderFontFamily.yuanti => 'yuanti',
};

AppTheme _theme(String value) => switch (value) {
  'system' => AppTheme.system,
  'light' => AppTheme.light,
  'dark' => AppTheme.dark,
  _ => throw RepositoryFailure(RepositoryFailureReason.storage),
};

String _themeToken(AppTheme value) => switch (value) {
  AppTheme.system => 'system',
  AppTheme.light => 'light',
  AppTheme.dark => 'dark',
};

AppAccent? _accentNullable(String? value) => switch (value) {
  null => null,
  'purple' => AppAccent.purple,
  'blue' => AppAccent.blue,
  'teal' => AppAccent.teal,
  'pink' => AppAccent.pink,
  'orange' => AppAccent.orange,
  'red' => AppAccent.red,
  _ => throw RepositoryFailure(RepositoryFailureReason.storage),
};

String _accentToken(AppAccent value) => switch (value) {
  AppAccent.purple => 'purple',
  AppAccent.blue => 'blue',
  AppAccent.teal => 'teal',
  AppAccent.pink => 'pink',
  AppAccent.orange => 'orange',
  AppAccent.red => 'red',
};
