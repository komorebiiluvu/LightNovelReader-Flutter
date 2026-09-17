import '../identity/identity_failure.dart';
import '../identity/identity_json.dart';
import '../identity/opaque_ids.dart';
import '../library/library_models.dart';

enum ReaderBackground { paperWhite, parchment, darkGray, black, eyeCare }

enum ReaderMode { pageCurl, scroll }

enum ReaderFontFamily { system, songti, kaiti, yuanti }

final class ReaderPreferencesV1 {
  ReaderPreferencesV1({
    required this.fontSize,
    required this.lineSpacing,
    required this.background,
    required this.mode,
    required this.fontFamily,
    required this.bold,
    required this.marginLeft,
    required this.marginRight,
    required this.marginTop,
    required this.marginBottom,
  }) {
    _positive(fontSize);
    _nonNegative(lineSpacing);
    _nonNegative(marginLeft);
    _nonNegative(marginRight);
    _nonNegative(marginTop);
    _nonNegative(marginBottom);
  }

  factory ReaderPreferencesV1.defaults() => ReaderPreferencesV1(
    fontSize: 22,
    lineSpacing: 8,
    background: ReaderBackground.paperWhite,
    mode: ReaderMode.pageCurl,
    fontFamily: ReaderFontFamily.kaiti,
    bold: false,
    marginLeft: 35,
    marginRight: 35,
    marginTop: 72,
    marginBottom: 24,
  );

  factory ReaderPreferencesV1.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'readerPreferences',
      requiredFields: {
        'fontSize',
        'lineSpacing',
        'background',
        'mode',
        'fontFamily',
        'bold',
        'marginLeft',
        'marginRight',
        'marginTop',
        'marginBottom',
      },
    );
    final bold = fields['bold'];
    if (bold is! bool) {
      throw IdentityFailure(IdentityFailureReason.wrongType);
    }
    return ReaderPreferencesV1(
      fontSize: _number(fields['fontSize']),
      lineSpacing: _number(fields['lineSpacing']),
      background: _background(fields['background']),
      mode: _mode(fields['mode']),
      fontFamily: _fontFamily(fields['fontFamily']),
      bold: bold,
      marginLeft: _number(fields['marginLeft']),
      marginRight: _number(fields['marginRight']),
      marginTop: _number(fields['marginTop']),
      marginBottom: _number(fields['marginBottom']),
    );
  }

  final double fontSize;
  final double lineSpacing;
  final ReaderBackground background;
  final ReaderMode mode;
  final ReaderFontFamily fontFamily;
  final bool bold;
  final double marginLeft;
  final double marginRight;
  final double marginTop;
  final double marginBottom;

  Map<String, Object?> toJson() => {
    'kind': 'readerPreferences',
    'version': 1,
    'fontSize': fontSize,
    'lineSpacing': lineSpacing,
    'background': _backgroundToken(background),
    'mode': _modeToken(mode),
    'fontFamily': _fontFamilyToken(fontFamily),
    'bold': bold,
    'marginLeft': marginLeft,
    'marginRight': marginRight,
    'marginTop': marginTop,
    'marginBottom': marginBottom,
  };

  @override
  bool operator ==(Object other) =>
      other is ReaderPreferencesV1 &&
      other.fontSize == fontSize &&
      other.lineSpacing == lineSpacing &&
      other.background == background &&
      other.mode == mode &&
      other.fontFamily == fontFamily &&
      other.bold == bold &&
      other.marginLeft == marginLeft &&
      other.marginRight == marginRight &&
      other.marginTop == marginTop &&
      other.marginBottom == marginBottom;

  @override
  int get hashCode => Object.hash(
    fontSize,
    lineSpacing,
    background,
    mode,
    fontFamily,
    bold,
    marginLeft,
    marginRight,
    marginTop,
    marginBottom,
  );
}

enum AppTheme { system, light, dark }

enum AppAccent { purple, blue, teal, pink, orange, red }

final class AppPreferencesV1 {
  const AppPreferencesV1({
    required this.theme,
    this.preferredSourceId,
    this.selectedShelfId,
    this.accent,
  });

  factory AppPreferencesV1.fromJson(Object? input) {
    final fields = readIdentityV1(
      input,
      kind: 'appPreferences',
      requiredFields: {'theme'},
      optionalFields: {'preferredSourceId', 'selectedShelfId', 'accent'},
    );
    return AppPreferencesV1(
      theme: _theme(fields['theme']),
      preferredSourceId: fields.containsKey('preferredSourceId')
          ? SourceId.fromJson(fields['preferredSourceId'])
          : null,
      selectedShelfId: fields.containsKey('selectedShelfId')
          ? ShelfId(identityString(fields['selectedShelfId']))
          : null,
      accent: fields.containsKey('accent') ? _accent(fields['accent']) : null,
    );
  }

  final AppTheme theme;
  final SourceId? preferredSourceId;
  final ShelfId? selectedShelfId;
  final AppAccent? accent;

  Map<String, Object?> toJson() => {
    'kind': 'appPreferences',
    'version': 1,
    'theme': _themeToken(theme),
    if (preferredSourceId != null)
      'preferredSourceId': preferredSourceId!.toJson(),
    if (selectedShelfId != null) 'selectedShelfId': selectedShelfId!.toJson(),
    if (accent != null) 'accent': _accentToken(accent!),
  };

  @override
  bool operator ==(Object other) =>
      other is AppPreferencesV1 &&
      other.theme == theme &&
      other.preferredSourceId == preferredSourceId &&
      other.selectedShelfId == selectedShelfId &&
      other.accent == accent;

  @override
  int get hashCode =>
      Object.hash(theme, preferredSourceId, selectedShelfId, accent);
}

double _number(Object? value) {
  if (value is! num || !value.isFinite) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
  return value.toDouble();
}

void _positive(double value) {
  if (!value.isFinite || value <= 0) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
}

void _nonNegative(double value) {
  if (!value.isFinite || value < 0) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
}

T _token<T>(Object? value, Map<String, T> tokens) {
  if (value is! String || !tokens.containsKey(value)) {
    throw IdentityFailure(IdentityFailureReason.invalidValue);
  }
  return tokens[value] as T;
}

ReaderBackground _background(Object? value) => _token(value, {
  'paperWhite': ReaderBackground.paperWhite,
  'parchment': ReaderBackground.parchment,
  'darkGray': ReaderBackground.darkGray,
  'black': ReaderBackground.black,
  'eyeCare': ReaderBackground.eyeCare,
});

String _backgroundToken(ReaderBackground value) => switch (value) {
  ReaderBackground.paperWhite => 'paperWhite',
  ReaderBackground.parchment => 'parchment',
  ReaderBackground.darkGray => 'darkGray',
  ReaderBackground.black => 'black',
  ReaderBackground.eyeCare => 'eyeCare',
};

ReaderMode _mode(Object? value) => _token(value, {
  'pageCurl': ReaderMode.pageCurl,
  'scroll': ReaderMode.scroll,
});

String _modeToken(ReaderMode value) => switch (value) {
  ReaderMode.pageCurl => 'pageCurl',
  ReaderMode.scroll => 'scroll',
};

ReaderFontFamily _fontFamily(Object? value) => _token(value, {
  'system': ReaderFontFamily.system,
  'songti': ReaderFontFamily.songti,
  'kaiti': ReaderFontFamily.kaiti,
  'yuanti': ReaderFontFamily.yuanti,
});

String _fontFamilyToken(ReaderFontFamily value) => switch (value) {
  ReaderFontFamily.system => 'system',
  ReaderFontFamily.songti => 'songti',
  ReaderFontFamily.kaiti => 'kaiti',
  ReaderFontFamily.yuanti => 'yuanti',
};

AppTheme _theme(Object? value) => _token(value, {
  'system': AppTheme.system,
  'light': AppTheme.light,
  'dark': AppTheme.dark,
});

String _themeToken(AppTheme value) => switch (value) {
  AppTheme.system => 'system',
  AppTheme.light => 'light',
  AppTheme.dark => 'dark',
};

AppAccent _accent(Object? value) => _token(value, {
  'purple': AppAccent.purple,
  'blue': AppAccent.blue,
  'teal': AppAccent.teal,
  'pink': AppAccent.pink,
  'orange': AppAccent.orange,
  'red': AppAccent.red,
});

String _accentToken(AppAccent value) => switch (value) {
  AppAccent.purple => 'purple',
  AppAccent.blue => 'blue',
  AppAccent.teal => 'teal',
  AppAccent.pink => 'pink',
  AppAccent.orange => 'orange',
  AppAccent.red => 'red',
};
