// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class SourceRegistrations extends Table
    with TableInfo<SourceRegistrations, SourceRegistration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SourceRegistrations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(source_id) > 0 AND instr(source_id, char(0)) = 0)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _availabilityMeta = const VerificationMeta(
    'availability',
  );
  late final GeneratedColumn<String> availability = GeneratedColumn<String>(
    'availability',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (availability IN (\'available\', \'unavailable\', \'unresolved\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, displayName, availability];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'source_registrations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SourceRegistration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    if (data.containsKey('availability')) {
      context.handle(
        _availabilityMeta,
        availability.isAcceptableOrUnknown(
          data['availability']!,
          _availabilityMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_availabilityMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId};
  @override
  SourceRegistration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SourceRegistration(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
      availability: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}availability'],
      )!,
    );
  }

  @override
  SourceRegistrations createAlias(String alias) {
    return SourceRegistrations(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SourceRegistration extends DataClass
    implements Insertable<SourceRegistration> {
  final String sourceId;
  final String? displayName;
  final String availability;
  const SourceRegistration({
    required this.sourceId,
    this.displayName,
    required this.availability,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    map['availability'] = Variable<String>(availability);
    return map;
  }

  SourceRegistrationsCompanion toCompanion(bool nullToAbsent) {
    return SourceRegistrationsCompanion(
      sourceId: Value(sourceId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
      availability: Value(availability),
    );
  }

  factory SourceRegistration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SourceRegistration(
      sourceId: serializer.fromJson<String>(json['source_id']),
      displayName: serializer.fromJson<String?>(json['display_name']),
      availability: serializer.fromJson<String>(json['availability']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'display_name': serializer.toJson<String?>(displayName),
      'availability': serializer.toJson<String>(availability),
    };
  }

  SourceRegistration copyWith({
    String? sourceId,
    Value<String?> displayName = const Value.absent(),
    String? availability,
  }) => SourceRegistration(
    sourceId: sourceId ?? this.sourceId,
    displayName: displayName.present ? displayName.value : this.displayName,
    availability: availability ?? this.availability,
  );
  SourceRegistration copyWithCompanion(SourceRegistrationsCompanion data) {
    return SourceRegistration(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      availability: data.availability.present
          ? data.availability.value
          : this.availability,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SourceRegistration(')
          ..write('sourceId: $sourceId, ')
          ..write('displayName: $displayName, ')
          ..write('availability: $availability')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, displayName, availability);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SourceRegistration &&
          other.sourceId == this.sourceId &&
          other.displayName == this.displayName &&
          other.availability == this.availability);
}

class SourceRegistrationsCompanion extends UpdateCompanion<SourceRegistration> {
  final Value<String> sourceId;
  final Value<String?> displayName;
  final Value<String> availability;
  final Value<int> rowid;
  const SourceRegistrationsCompanion({
    this.sourceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.availability = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SourceRegistrationsCompanion.insert({
    required String sourceId,
    this.displayName = const Value.absent(),
    required String availability,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       availability = Value(availability);
  static Insertable<SourceRegistration> custom({
    Expression<String>? sourceId,
    Expression<String>? displayName,
    Expression<String>? availability,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (displayName != null) 'display_name': displayName,
      if (availability != null) 'availability': availability,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SourceRegistrationsCompanion copyWith({
    Value<String>? sourceId,
    Value<String?>? displayName,
    Value<String>? availability,
    Value<int>? rowid,
  }) {
    return SourceRegistrationsCompanion(
      sourceId: sourceId ?? this.sourceId,
      displayName: displayName ?? this.displayName,
      availability: availability ?? this.availability,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (availability.present) {
      map['availability'] = Variable<String>(availability.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SourceRegistrationsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('displayName: $displayName, ')
          ..write('availability: $availability, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LibraryEntries extends Table
    with TableInfo<LibraryEntries, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LibraryEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES source_registrations(source_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY CHECK (length(book_id) > 0 AND instr(book_id, char(0)) = 0)',
  );
  static const VerificationMeta _savedMeta = const VerificationMeta('saved');
  late final GeneratedColumn<int> saved = GeneratedColumn<int>(
    'saved',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (saved IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _metadataStateMeta = const VerificationMeta(
    'metadataState',
  );
  late final GeneratedColumn<String> metadataState = GeneratedColumn<String>(
    'metadata_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (metadata_state IN (\'known\', \'stub\'))',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _authorMeta = const VerificationMeta('author');
  late final GeneratedColumn<String> author = GeneratedColumn<String>(
    'author',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _coverAssetIdMeta = const VerificationMeta(
    'coverAssetId',
  );
  late final GeneratedColumn<String> coverAssetId = GeneratedColumn<String>(
    'cover_asset_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY CHECK (cover_asset_id IS NULL OR(length(cover_asset_id) > 0 AND instr(cover_asset_id, char(0)) = 0))',
  );
  static const VerificationMeta _knownTotalChaptersMeta =
      const VerificationMeta('knownTotalChapters');
  late final GeneratedColumn<int> knownTotalChapters = GeneratedColumn<int>(
    'known_total_chapters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updateFlagMeta = const VerificationMeta(
    'updateFlag',
  );
  late final GeneratedColumn<int> updateFlag = GeneratedColumn<int>(
    'update_flag',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (update_flag IS NULL OR update_flag IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    bookId,
    saved,
    metadataState,
    title,
    author,
    description,
    coverAssetId,
    knownTotalChapters,
    updateFlag,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'library_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LibraryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('saved')) {
      context.handle(
        _savedMeta,
        saved.isAcceptableOrUnknown(data['saved']!, _savedMeta),
      );
    }
    if (data.containsKey('metadata_state')) {
      context.handle(
        _metadataStateMeta,
        metadataState.isAcceptableOrUnknown(
          data['metadata_state']!,
          _metadataStateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataStateMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('author')) {
      context.handle(
        _authorMeta,
        author.isAcceptableOrUnknown(data['author']!, _authorMeta),
      );
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cover_asset_id')) {
      context.handle(
        _coverAssetIdMeta,
        coverAssetId.isAcceptableOrUnknown(
          data['cover_asset_id']!,
          _coverAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('known_total_chapters')) {
      context.handle(
        _knownTotalChaptersMeta,
        knownTotalChapters.isAcceptableOrUnknown(
          data['known_total_chapters']!,
          _knownTotalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('update_flag')) {
      context.handle(
        _updateFlagMeta,
        updateFlag.isAcceptableOrUnknown(data['update_flag']!, _updateFlagMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, bookId};
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      saved: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved'],
      )!,
      metadataState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_state'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      author: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}author'],
      ),
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      coverAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_asset_id'],
      ),
      knownTotalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}known_total_chapters'],
      ),
      updateFlag: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}update_flag'],
      ),
    );
  }

  @override
  LibraryEntries createAlias(String alias) {
    return LibraryEntries(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_id, book_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final String sourceId;
  final String bookId;
  final int saved;
  final String metadataState;
  final String? title;
  final String? author;
  final String? description;
  final String? coverAssetId;
  final int? knownTotalChapters;
  final int? updateFlag;
  const LibraryEntry({
    required this.sourceId,
    required this.bookId,
    required this.saved,
    required this.metadataState,
    this.title,
    this.author,
    this.description,
    this.coverAssetId,
    this.knownTotalChapters,
    this.updateFlag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['saved'] = Variable<int>(saved);
    map['metadata_state'] = Variable<String>(metadataState);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || author != null) {
      map['author'] = Variable<String>(author);
    }
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || coverAssetId != null) {
      map['cover_asset_id'] = Variable<String>(coverAssetId);
    }
    if (!nullToAbsent || knownTotalChapters != null) {
      map['known_total_chapters'] = Variable<int>(knownTotalChapters);
    }
    if (!nullToAbsent || updateFlag != null) {
      map['update_flag'] = Variable<int>(updateFlag);
    }
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      saved: Value(saved),
      metadataState: Value(metadataState),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      author: author == null && nullToAbsent
          ? const Value.absent()
          : Value(author),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      coverAssetId: coverAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(coverAssetId),
      knownTotalChapters: knownTotalChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(knownTotalChapters),
      updateFlag: updateFlag == null && nullToAbsent
          ? const Value.absent()
          : Value(updateFlag),
    );
  }

  factory LibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      saved: serializer.fromJson<int>(json['saved']),
      metadataState: serializer.fromJson<String>(json['metadata_state']),
      title: serializer.fromJson<String?>(json['title']),
      author: serializer.fromJson<String?>(json['author']),
      description: serializer.fromJson<String?>(json['description']),
      coverAssetId: serializer.fromJson<String?>(json['cover_asset_id']),
      knownTotalChapters: serializer.fromJson<int?>(
        json['known_total_chapters'],
      ),
      updateFlag: serializer.fromJson<int?>(json['update_flag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'saved': serializer.toJson<int>(saved),
      'metadata_state': serializer.toJson<String>(metadataState),
      'title': serializer.toJson<String?>(title),
      'author': serializer.toJson<String?>(author),
      'description': serializer.toJson<String?>(description),
      'cover_asset_id': serializer.toJson<String?>(coverAssetId),
      'known_total_chapters': serializer.toJson<int?>(knownTotalChapters),
      'update_flag': serializer.toJson<int?>(updateFlag),
    };
  }

  LibraryEntry copyWith({
    String? sourceId,
    String? bookId,
    int? saved,
    String? metadataState,
    Value<String?> title = const Value.absent(),
    Value<String?> author = const Value.absent(),
    Value<String?> description = const Value.absent(),
    Value<String?> coverAssetId = const Value.absent(),
    Value<int?> knownTotalChapters = const Value.absent(),
    Value<int?> updateFlag = const Value.absent(),
  }) => LibraryEntry(
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    saved: saved ?? this.saved,
    metadataState: metadataState ?? this.metadataState,
    title: title.present ? title.value : this.title,
    author: author.present ? author.value : this.author,
    description: description.present ? description.value : this.description,
    coverAssetId: coverAssetId.present ? coverAssetId.value : this.coverAssetId,
    knownTotalChapters: knownTotalChapters.present
        ? knownTotalChapters.value
        : this.knownTotalChapters,
    updateFlag: updateFlag.present ? updateFlag.value : this.updateFlag,
  );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      saved: data.saved.present ? data.saved.value : this.saved,
      metadataState: data.metadataState.present
          ? data.metadataState.value
          : this.metadataState,
      title: data.title.present ? data.title.value : this.title,
      author: data.author.present ? data.author.value : this.author,
      description: data.description.present
          ? data.description.value
          : this.description,
      coverAssetId: data.coverAssetId.present
          ? data.coverAssetId.value
          : this.coverAssetId,
      knownTotalChapters: data.knownTotalChapters.present
          ? data.knownTotalChapters.value
          : this.knownTotalChapters,
      updateFlag: data.updateFlag.present
          ? data.updateFlag.value
          : this.updateFlag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('saved: $saved, ')
          ..write('metadataState: $metadataState, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('coverAssetId: $coverAssetId, ')
          ..write('knownTotalChapters: $knownTotalChapters, ')
          ..write('updateFlag: $updateFlag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    bookId,
    saved,
    metadataState,
    title,
    author,
    description,
    coverAssetId,
    knownTotalChapters,
    updateFlag,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.saved == this.saved &&
          other.metadataState == this.metadataState &&
          other.title == this.title &&
          other.author == this.author &&
          other.description == this.description &&
          other.coverAssetId == this.coverAssetId &&
          other.knownTotalChapters == this.knownTotalChapters &&
          other.updateFlag == this.updateFlag);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> saved;
  final Value<String> metadataState;
  final Value<String?> title;
  final Value<String?> author;
  final Value<String?> description;
  final Value<String?> coverAssetId;
  final Value<int?> knownTotalChapters;
  final Value<int?> updateFlag;
  final Value<int> rowid;
  const LibraryEntriesCompanion({
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.saved = const Value.absent(),
    this.metadataState = const Value.absent(),
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.coverAssetId = const Value.absent(),
    this.knownTotalChapters = const Value.absent(),
    this.updateFlag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    required String sourceId,
    required String bookId,
    this.saved = const Value.absent(),
    required String metadataState,
    this.title = const Value.absent(),
    this.author = const Value.absent(),
    this.description = const Value.absent(),
    this.coverAssetId = const Value.absent(),
    this.knownTotalChapters = const Value.absent(),
    this.updateFlag = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       bookId = Value(bookId),
       metadataState = Value(metadataState);
  static Insertable<LibraryEntry> custom({
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? saved,
    Expression<String>? metadataState,
    Expression<String>? title,
    Expression<String>? author,
    Expression<String>? description,
    Expression<String>? coverAssetId,
    Expression<int>? knownTotalChapters,
    Expression<int>? updateFlag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (saved != null) 'saved': saved,
      if (metadataState != null) 'metadata_state': metadataState,
      if (title != null) 'title': title,
      if (author != null) 'author': author,
      if (description != null) 'description': description,
      if (coverAssetId != null) 'cover_asset_id': coverAssetId,
      if (knownTotalChapters != null)
        'known_total_chapters': knownTotalChapters,
      if (updateFlag != null) 'update_flag': updateFlag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LibraryEntriesCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? saved,
    Value<String>? metadataState,
    Value<String?>? title,
    Value<String?>? author,
    Value<String?>? description,
    Value<String?>? coverAssetId,
    Value<int?>? knownTotalChapters,
    Value<int?>? updateFlag,
    Value<int>? rowid,
  }) {
    return LibraryEntriesCompanion(
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      saved: saved ?? this.saved,
      metadataState: metadataState ?? this.metadataState,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      coverAssetId: coverAssetId ?? this.coverAssetId,
      knownTotalChapters: knownTotalChapters ?? this.knownTotalChapters,
      updateFlag: updateFlag ?? this.updateFlag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (saved.present) {
      map['saved'] = Variable<int>(saved.value);
    }
    if (metadataState.present) {
      map['metadata_state'] = Variable<String>(metadataState.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (author.present) {
      map['author'] = Variable<String>(author.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (coverAssetId.present) {
      map['cover_asset_id'] = Variable<String>(coverAssetId.value);
    }
    if (knownTotalChapters.present) {
      map['known_total_chapters'] = Variable<int>(knownTotalChapters.value);
    }
    if (updateFlag.present) {
      map['update_flag'] = Variable<int>(updateFlag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('saved: $saved, ')
          ..write('metadataState: $metadataState, ')
          ..write('title: $title, ')
          ..write('author: $author, ')
          ..write('description: $description, ')
          ..write('coverAssetId: $coverAssetId, ')
          ..write('knownTotalChapters: $knownTotalChapters, ')
          ..write('updateFlag: $updateFlag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class BookTags extends Table with TableInfo<BookTags, BookTag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  BookTags(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (ordinal >= 0)',
  );
  static const VerificationMeta _tagMeta = const VerificationMeta('tag');
  late final GeneratedColumn<String> tag = GeneratedColumn<String>(
    'tag',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, bookId, ordinal, tag];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'book_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<BookTag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('tag')) {
      context.handle(
        _tagMeta,
        tag.isAcceptableOrUnknown(data['tag']!, _tagMeta),
      );
    } else if (isInserting) {
      context.missing(_tagMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, bookId, ordinal};
  @override
  BookTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BookTag(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      tag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag'],
      )!,
    );
  }

  @override
  BookTags createAlias(String alias) {
    return BookTags(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_id, book_id, ordinal)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class BookTag extends DataClass implements Insertable<BookTag> {
  final String sourceId;
  final String bookId;
  final int ordinal;
  final String tag;
  const BookTag({
    required this.sourceId,
    required this.bookId,
    required this.ordinal,
    required this.tag,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['ordinal'] = Variable<int>(ordinal);
    map['tag'] = Variable<String>(tag);
    return map;
  }

  BookTagsCompanion toCompanion(bool nullToAbsent) {
    return BookTagsCompanion(
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      ordinal: Value(ordinal),
      tag: Value(tag),
    );
  }

  factory BookTag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BookTag(
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      tag: serializer.fromJson<String>(json['tag']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'ordinal': serializer.toJson<int>(ordinal),
      'tag': serializer.toJson<String>(tag),
    };
  }

  BookTag copyWith({
    String? sourceId,
    String? bookId,
    int? ordinal,
    String? tag,
  }) => BookTag(
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    ordinal: ordinal ?? this.ordinal,
    tag: tag ?? this.tag,
  );
  BookTag copyWithCompanion(BookTagsCompanion data) {
    return BookTag(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      tag: data.tag.present ? data.tag.value : this.tag,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BookTag(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('ordinal: $ordinal, ')
          ..write('tag: $tag')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, bookId, ordinal, tag);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BookTag &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.ordinal == this.ordinal &&
          other.tag == this.tag);
}

class BookTagsCompanion extends UpdateCompanion<BookTag> {
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> ordinal;
  final Value<String> tag;
  final Value<int> rowid;
  const BookTagsCompanion({
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.tag = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BookTagsCompanion.insert({
    required String sourceId,
    required String bookId,
    required int ordinal,
    required String tag,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       bookId = Value(bookId),
       ordinal = Value(ordinal),
       tag = Value(tag);
  static Insertable<BookTag> custom({
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? ordinal,
    Expression<String>? tag,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (ordinal != null) 'ordinal': ordinal,
      if (tag != null) 'tag': tag,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BookTagsCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? ordinal,
    Value<String>? tag,
    Value<int>? rowid,
  }) {
    return BookTagsCompanion(
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      ordinal: ordinal ?? this.ordinal,
      tag: tag ?? this.tag,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (tag.present) {
      map['tag'] = Variable<String>(tag.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BookTagsCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('ordinal: $ordinal, ')
          ..write('tag: $tag, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LegacyBookMetadata extends Table
    with TableInfo<LegacyBookMetadata, LegacyBookMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LegacyBookMetadata(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _legacySourceNameMeta = const VerificationMeta(
    'legacySourceName',
  );
  late final GeneratedColumn<String> legacySourceName = GeneratedColumn<String>(
    'legacy_source_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _totalChaptersMeta = const VerificationMeta(
    'totalChapters',
  );
  late final GeneratedColumn<int> totalChapters = GeneratedColumn<int>(
    'total_chapters',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastChapterMeta = const VerificationMeta(
    'lastChapter',
  );
  late final GeneratedColumn<int> lastChapter = GeneratedColumn<int>(
    'last_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hitsMeta = const VerificationMeta('hits');
  late final GeneratedColumn<int> hits = GeneratedColumn<int>(
    'hits',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _coverIndexMeta = const VerificationMeta(
    'coverIndex',
  );
  late final GeneratedColumn<int> coverIndex = GeneratedColumn<int>(
    'cover_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _hasUpdateMeta = const VerificationMeta(
    'hasUpdate',
  );
  late final GeneratedColumn<int> hasUpdate = GeneratedColumn<int>(
    'has_update',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (has_update IS NULL OR has_update IN (0, 1))',
  );
  static const VerificationMeta _coverReferenceMeta = const VerificationMeta(
    'coverReference',
  );
  late final GeneratedColumn<String> coverReference = GeneratedColumn<String>(
    'cover_reference',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _publishingHouseMeta = const VerificationMeta(
    'publishingHouse',
  );
  late final GeneratedColumn<String> publishingHouse = GeneratedColumn<String>(
    'publishing_house',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastUpdateMeta = const VerificationMeta(
    'lastUpdate',
  );
  late final GeneratedColumn<String> lastUpdate = GeneratedColumn<String>(
    'last_update',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  late final GeneratedColumn<int> isCompleted = GeneratedColumn<int>(
    'is_completed',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (is_completed IS NULL OR is_completed IN (0, 1))',
  );
  static const VerificationMeta _wordCountKMeta = const VerificationMeta(
    'wordCountK',
  );
  late final GeneratedColumn<int> wordCountK = GeneratedColumn<int>(
    'word_count_k',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    bookId,
    legacySourceName,
    totalChapters,
    lastChapter,
    hits,
    coverIndex,
    hasUpdate,
    coverReference,
    publishingHouse,
    lastUpdate,
    isCompleted,
    wordCountK,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_book_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyBookMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('legacy_source_name')) {
      context.handle(
        _legacySourceNameMeta,
        legacySourceName.isAcceptableOrUnknown(
          data['legacy_source_name']!,
          _legacySourceNameMeta,
        ),
      );
    }
    if (data.containsKey('total_chapters')) {
      context.handle(
        _totalChaptersMeta,
        totalChapters.isAcceptableOrUnknown(
          data['total_chapters']!,
          _totalChaptersMeta,
        ),
      );
    }
    if (data.containsKey('last_chapter')) {
      context.handle(
        _lastChapterMeta,
        lastChapter.isAcceptableOrUnknown(
          data['last_chapter']!,
          _lastChapterMeta,
        ),
      );
    }
    if (data.containsKey('hits')) {
      context.handle(
        _hitsMeta,
        hits.isAcceptableOrUnknown(data['hits']!, _hitsMeta),
      );
    }
    if (data.containsKey('cover_index')) {
      context.handle(
        _coverIndexMeta,
        coverIndex.isAcceptableOrUnknown(data['cover_index']!, _coverIndexMeta),
      );
    }
    if (data.containsKey('has_update')) {
      context.handle(
        _hasUpdateMeta,
        hasUpdate.isAcceptableOrUnknown(data['has_update']!, _hasUpdateMeta),
      );
    }
    if (data.containsKey('cover_reference')) {
      context.handle(
        _coverReferenceMeta,
        coverReference.isAcceptableOrUnknown(
          data['cover_reference']!,
          _coverReferenceMeta,
        ),
      );
    }
    if (data.containsKey('publishing_house')) {
      context.handle(
        _publishingHouseMeta,
        publishingHouse.isAcceptableOrUnknown(
          data['publishing_house']!,
          _publishingHouseMeta,
        ),
      );
    }
    if (data.containsKey('last_update')) {
      context.handle(
        _lastUpdateMeta,
        lastUpdate.isAcceptableOrUnknown(data['last_update']!, _lastUpdateMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('word_count_k')) {
      context.handle(
        _wordCountKMeta,
        wordCountK.isAcceptableOrUnknown(
          data['word_count_k']!,
          _wordCountKMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, bookId};
  @override
  LegacyBookMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyBookMetadataData(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      legacySourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_source_name'],
      ),
      totalChapters: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters'],
      ),
      lastChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_chapter'],
      ),
      hits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hits'],
      ),
      coverIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cover_index'],
      ),
      hasUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}has_update'],
      ),
      coverReference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_reference'],
      ),
      publishingHouse: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}publishing_house'],
      ),
      lastUpdate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_update'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_completed'],
      ),
      wordCountK: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}word_count_k'],
      ),
    );
  }

  @override
  LegacyBookMetadata createAlias(String alias) {
    return LegacyBookMetadata(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_id, book_id)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LegacyBookMetadataData extends DataClass
    implements Insertable<LegacyBookMetadataData> {
  final String sourceId;
  final String bookId;
  final String? legacySourceName;
  final int? totalChapters;
  final int? lastChapter;
  final int? hits;
  final int? coverIndex;
  final int? hasUpdate;
  final String? coverReference;
  final String? publishingHouse;
  final String? lastUpdate;
  final int? isCompleted;
  final int? wordCountK;
  const LegacyBookMetadataData({
    required this.sourceId,
    required this.bookId,
    this.legacySourceName,
    this.totalChapters,
    this.lastChapter,
    this.hits,
    this.coverIndex,
    this.hasUpdate,
    this.coverReference,
    this.publishingHouse,
    this.lastUpdate,
    this.isCompleted,
    this.wordCountK,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    if (!nullToAbsent || legacySourceName != null) {
      map['legacy_source_name'] = Variable<String>(legacySourceName);
    }
    if (!nullToAbsent || totalChapters != null) {
      map['total_chapters'] = Variable<int>(totalChapters);
    }
    if (!nullToAbsent || lastChapter != null) {
      map['last_chapter'] = Variable<int>(lastChapter);
    }
    if (!nullToAbsent || hits != null) {
      map['hits'] = Variable<int>(hits);
    }
    if (!nullToAbsent || coverIndex != null) {
      map['cover_index'] = Variable<int>(coverIndex);
    }
    if (!nullToAbsent || hasUpdate != null) {
      map['has_update'] = Variable<int>(hasUpdate);
    }
    if (!nullToAbsent || coverReference != null) {
      map['cover_reference'] = Variable<String>(coverReference);
    }
    if (!nullToAbsent || publishingHouse != null) {
      map['publishing_house'] = Variable<String>(publishingHouse);
    }
    if (!nullToAbsent || lastUpdate != null) {
      map['last_update'] = Variable<String>(lastUpdate);
    }
    if (!nullToAbsent || isCompleted != null) {
      map['is_completed'] = Variable<int>(isCompleted);
    }
    if (!nullToAbsent || wordCountK != null) {
      map['word_count_k'] = Variable<int>(wordCountK);
    }
    return map;
  }

  LegacyBookMetadataCompanion toCompanion(bool nullToAbsent) {
    return LegacyBookMetadataCompanion(
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      legacySourceName: legacySourceName == null && nullToAbsent
          ? const Value.absent()
          : Value(legacySourceName),
      totalChapters: totalChapters == null && nullToAbsent
          ? const Value.absent()
          : Value(totalChapters),
      lastChapter: lastChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(lastChapter),
      hits: hits == null && nullToAbsent ? const Value.absent() : Value(hits),
      coverIndex: coverIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(coverIndex),
      hasUpdate: hasUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(hasUpdate),
      coverReference: coverReference == null && nullToAbsent
          ? const Value.absent()
          : Value(coverReference),
      publishingHouse: publishingHouse == null && nullToAbsent
          ? const Value.absent()
          : Value(publishingHouse),
      lastUpdate: lastUpdate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastUpdate),
      isCompleted: isCompleted == null && nullToAbsent
          ? const Value.absent()
          : Value(isCompleted),
      wordCountK: wordCountK == null && nullToAbsent
          ? const Value.absent()
          : Value(wordCountK),
    );
  }

  factory LegacyBookMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyBookMetadataData(
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      legacySourceName: serializer.fromJson<String?>(
        json['legacy_source_name'],
      ),
      totalChapters: serializer.fromJson<int?>(json['total_chapters']),
      lastChapter: serializer.fromJson<int?>(json['last_chapter']),
      hits: serializer.fromJson<int?>(json['hits']),
      coverIndex: serializer.fromJson<int?>(json['cover_index']),
      hasUpdate: serializer.fromJson<int?>(json['has_update']),
      coverReference: serializer.fromJson<String?>(json['cover_reference']),
      publishingHouse: serializer.fromJson<String?>(json['publishing_house']),
      lastUpdate: serializer.fromJson<String?>(json['last_update']),
      isCompleted: serializer.fromJson<int?>(json['is_completed']),
      wordCountK: serializer.fromJson<int?>(json['word_count_k']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'legacy_source_name': serializer.toJson<String?>(legacySourceName),
      'total_chapters': serializer.toJson<int?>(totalChapters),
      'last_chapter': serializer.toJson<int?>(lastChapter),
      'hits': serializer.toJson<int?>(hits),
      'cover_index': serializer.toJson<int?>(coverIndex),
      'has_update': serializer.toJson<int?>(hasUpdate),
      'cover_reference': serializer.toJson<String?>(coverReference),
      'publishing_house': serializer.toJson<String?>(publishingHouse),
      'last_update': serializer.toJson<String?>(lastUpdate),
      'is_completed': serializer.toJson<int?>(isCompleted),
      'word_count_k': serializer.toJson<int?>(wordCountK),
    };
  }

  LegacyBookMetadataData copyWith({
    String? sourceId,
    String? bookId,
    Value<String?> legacySourceName = const Value.absent(),
    Value<int?> totalChapters = const Value.absent(),
    Value<int?> lastChapter = const Value.absent(),
    Value<int?> hits = const Value.absent(),
    Value<int?> coverIndex = const Value.absent(),
    Value<int?> hasUpdate = const Value.absent(),
    Value<String?> coverReference = const Value.absent(),
    Value<String?> publishingHouse = const Value.absent(),
    Value<String?> lastUpdate = const Value.absent(),
    Value<int?> isCompleted = const Value.absent(),
    Value<int?> wordCountK = const Value.absent(),
  }) => LegacyBookMetadataData(
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    legacySourceName: legacySourceName.present
        ? legacySourceName.value
        : this.legacySourceName,
    totalChapters: totalChapters.present
        ? totalChapters.value
        : this.totalChapters,
    lastChapter: lastChapter.present ? lastChapter.value : this.lastChapter,
    hits: hits.present ? hits.value : this.hits,
    coverIndex: coverIndex.present ? coverIndex.value : this.coverIndex,
    hasUpdate: hasUpdate.present ? hasUpdate.value : this.hasUpdate,
    coverReference: coverReference.present
        ? coverReference.value
        : this.coverReference,
    publishingHouse: publishingHouse.present
        ? publishingHouse.value
        : this.publishingHouse,
    lastUpdate: lastUpdate.present ? lastUpdate.value : this.lastUpdate,
    isCompleted: isCompleted.present ? isCompleted.value : this.isCompleted,
    wordCountK: wordCountK.present ? wordCountK.value : this.wordCountK,
  );
  LegacyBookMetadataData copyWithCompanion(LegacyBookMetadataCompanion data) {
    return LegacyBookMetadataData(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      legacySourceName: data.legacySourceName.present
          ? data.legacySourceName.value
          : this.legacySourceName,
      totalChapters: data.totalChapters.present
          ? data.totalChapters.value
          : this.totalChapters,
      lastChapter: data.lastChapter.present
          ? data.lastChapter.value
          : this.lastChapter,
      hits: data.hits.present ? data.hits.value : this.hits,
      coverIndex: data.coverIndex.present
          ? data.coverIndex.value
          : this.coverIndex,
      hasUpdate: data.hasUpdate.present ? data.hasUpdate.value : this.hasUpdate,
      coverReference: data.coverReference.present
          ? data.coverReference.value
          : this.coverReference,
      publishingHouse: data.publishingHouse.present
          ? data.publishingHouse.value
          : this.publishingHouse,
      lastUpdate: data.lastUpdate.present
          ? data.lastUpdate.value
          : this.lastUpdate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      wordCountK: data.wordCountK.present
          ? data.wordCountK.value
          : this.wordCountK,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyBookMetadataData(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('legacySourceName: $legacySourceName, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('lastChapter: $lastChapter, ')
          ..write('hits: $hits, ')
          ..write('coverIndex: $coverIndex, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('coverReference: $coverReference, ')
          ..write('publishingHouse: $publishingHouse, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('wordCountK: $wordCountK')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    bookId,
    legacySourceName,
    totalChapters,
    lastChapter,
    hits,
    coverIndex,
    hasUpdate,
    coverReference,
    publishingHouse,
    lastUpdate,
    isCompleted,
    wordCountK,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyBookMetadataData &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.legacySourceName == this.legacySourceName &&
          other.totalChapters == this.totalChapters &&
          other.lastChapter == this.lastChapter &&
          other.hits == this.hits &&
          other.coverIndex == this.coverIndex &&
          other.hasUpdate == this.hasUpdate &&
          other.coverReference == this.coverReference &&
          other.publishingHouse == this.publishingHouse &&
          other.lastUpdate == this.lastUpdate &&
          other.isCompleted == this.isCompleted &&
          other.wordCountK == this.wordCountK);
}

class LegacyBookMetadataCompanion
    extends UpdateCompanion<LegacyBookMetadataData> {
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<String?> legacySourceName;
  final Value<int?> totalChapters;
  final Value<int?> lastChapter;
  final Value<int?> hits;
  final Value<int?> coverIndex;
  final Value<int?> hasUpdate;
  final Value<String?> coverReference;
  final Value<String?> publishingHouse;
  final Value<String?> lastUpdate;
  final Value<int?> isCompleted;
  final Value<int?> wordCountK;
  final Value<int> rowid;
  const LegacyBookMetadataCompanion({
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.legacySourceName = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.lastChapter = const Value.absent(),
    this.hits = const Value.absent(),
    this.coverIndex = const Value.absent(),
    this.hasUpdate = const Value.absent(),
    this.coverReference = const Value.absent(),
    this.publishingHouse = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.wordCountK = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyBookMetadataCompanion.insert({
    required String sourceId,
    required String bookId,
    this.legacySourceName = const Value.absent(),
    this.totalChapters = const Value.absent(),
    this.lastChapter = const Value.absent(),
    this.hits = const Value.absent(),
    this.coverIndex = const Value.absent(),
    this.hasUpdate = const Value.absent(),
    this.coverReference = const Value.absent(),
    this.publishingHouse = const Value.absent(),
    this.lastUpdate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.wordCountK = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       bookId = Value(bookId);
  static Insertable<LegacyBookMetadataData> custom({
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<String>? legacySourceName,
    Expression<int>? totalChapters,
    Expression<int>? lastChapter,
    Expression<int>? hits,
    Expression<int>? coverIndex,
    Expression<int>? hasUpdate,
    Expression<String>? coverReference,
    Expression<String>? publishingHouse,
    Expression<String>? lastUpdate,
    Expression<int>? isCompleted,
    Expression<int>? wordCountK,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (legacySourceName != null) 'legacy_source_name': legacySourceName,
      if (totalChapters != null) 'total_chapters': totalChapters,
      if (lastChapter != null) 'last_chapter': lastChapter,
      if (hits != null) 'hits': hits,
      if (coverIndex != null) 'cover_index': coverIndex,
      if (hasUpdate != null) 'has_update': hasUpdate,
      if (coverReference != null) 'cover_reference': coverReference,
      if (publishingHouse != null) 'publishing_house': publishingHouse,
      if (lastUpdate != null) 'last_update': lastUpdate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (wordCountK != null) 'word_count_k': wordCountK,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyBookMetadataCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<String?>? legacySourceName,
    Value<int?>? totalChapters,
    Value<int?>? lastChapter,
    Value<int?>? hits,
    Value<int?>? coverIndex,
    Value<int?>? hasUpdate,
    Value<String?>? coverReference,
    Value<String?>? publishingHouse,
    Value<String?>? lastUpdate,
    Value<int?>? isCompleted,
    Value<int?>? wordCountK,
    Value<int>? rowid,
  }) {
    return LegacyBookMetadataCompanion(
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      legacySourceName: legacySourceName ?? this.legacySourceName,
      totalChapters: totalChapters ?? this.totalChapters,
      lastChapter: lastChapter ?? this.lastChapter,
      hits: hits ?? this.hits,
      coverIndex: coverIndex ?? this.coverIndex,
      hasUpdate: hasUpdate ?? this.hasUpdate,
      coverReference: coverReference ?? this.coverReference,
      publishingHouse: publishingHouse ?? this.publishingHouse,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      isCompleted: isCompleted ?? this.isCompleted,
      wordCountK: wordCountK ?? this.wordCountK,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (legacySourceName.present) {
      map['legacy_source_name'] = Variable<String>(legacySourceName.value);
    }
    if (totalChapters.present) {
      map['total_chapters'] = Variable<int>(totalChapters.value);
    }
    if (lastChapter.present) {
      map['last_chapter'] = Variable<int>(lastChapter.value);
    }
    if (hits.present) {
      map['hits'] = Variable<int>(hits.value);
    }
    if (coverIndex.present) {
      map['cover_index'] = Variable<int>(coverIndex.value);
    }
    if (hasUpdate.present) {
      map['has_update'] = Variable<int>(hasUpdate.value);
    }
    if (coverReference.present) {
      map['cover_reference'] = Variable<String>(coverReference.value);
    }
    if (publishingHouse.present) {
      map['publishing_house'] = Variable<String>(publishingHouse.value);
    }
    if (lastUpdate.present) {
      map['last_update'] = Variable<String>(lastUpdate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<int>(isCompleted.value);
    }
    if (wordCountK.present) {
      map['word_count_k'] = Variable<int>(wordCountK.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyBookMetadataCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('legacySourceName: $legacySourceName, ')
          ..write('totalChapters: $totalChapters, ')
          ..write('lastChapter: $lastChapter, ')
          ..write('hits: $hits, ')
          ..write('coverIndex: $coverIndex, ')
          ..write('hasUpdate: $hasUpdate, ')
          ..write('coverReference: $coverReference, ')
          ..write('publishingHouse: $publishingHouse, ')
          ..write('lastUpdate: $lastUpdate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('wordCountK: $wordCountK, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Shelves extends Table with TableInfo<Shelves, Shelve> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Shelves(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shelfIdMeta = const VerificationMeta(
    'shelfId',
  );
  late final GeneratedColumn<String> shelfId = GeneratedColumn<String>(
    'shelf_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(shelf_id) > 0 AND instr(shelf_id, char(0)) = 0)',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (ordinal >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [shelfId, name, ordinal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelves';
  @override
  VerificationContext validateIntegrity(
    Insertable<Shelve> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shelf_id')) {
      context.handle(
        _shelfIdMeta,
        shelfId.isAcceptableOrUnknown(data['shelf_id']!, _shelfIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shelfIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shelfId};
  @override
  Shelve map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Shelve(
      shelfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
    );
  }

  @override
  Shelves createAlias(String alias) {
    return Shelves(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Shelve extends DataClass implements Insertable<Shelve> {
  final String shelfId;
  final String name;
  final int ordinal;
  const Shelve({
    required this.shelfId,
    required this.name,
    required this.ordinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shelf_id'] = Variable<String>(shelfId);
    map['name'] = Variable<String>(name);
    map['ordinal'] = Variable<int>(ordinal);
    return map;
  }

  ShelvesCompanion toCompanion(bool nullToAbsent) {
    return ShelvesCompanion(
      shelfId: Value(shelfId),
      name: Value(name),
      ordinal: Value(ordinal),
    );
  }

  factory Shelve.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Shelve(
      shelfId: serializer.fromJson<String>(json['shelf_id']),
      name: serializer.fromJson<String>(json['name']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shelf_id': serializer.toJson<String>(shelfId),
      'name': serializer.toJson<String>(name),
      'ordinal': serializer.toJson<int>(ordinal),
    };
  }

  Shelve copyWith({String? shelfId, String? name, int? ordinal}) => Shelve(
    shelfId: shelfId ?? this.shelfId,
    name: name ?? this.name,
    ordinal: ordinal ?? this.ordinal,
  );
  Shelve copyWithCompanion(ShelvesCompanion data) {
    return Shelve(
      shelfId: data.shelfId.present ? data.shelfId.value : this.shelfId,
      name: data.name.present ? data.name.value : this.name,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Shelve(')
          ..write('shelfId: $shelfId, ')
          ..write('name: $name, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shelfId, name, ordinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Shelve &&
          other.shelfId == this.shelfId &&
          other.name == this.name &&
          other.ordinal == this.ordinal);
}

class ShelvesCompanion extends UpdateCompanion<Shelve> {
  final Value<String> shelfId;
  final Value<String> name;
  final Value<int> ordinal;
  final Value<int> rowid;
  const ShelvesCompanion({
    this.shelfId = const Value.absent(),
    this.name = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShelvesCompanion.insert({
    required String shelfId,
    required String name,
    required int ordinal,
    this.rowid = const Value.absent(),
  }) : shelfId = Value(shelfId),
       name = Value(name),
       ordinal = Value(ordinal);
  static Insertable<Shelve> custom({
    Expression<String>? shelfId,
    Expression<String>? name,
    Expression<int>? ordinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shelfId != null) 'shelf_id': shelfId,
      if (name != null) 'name': name,
      if (ordinal != null) 'ordinal': ordinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShelvesCompanion copyWith({
    Value<String>? shelfId,
    Value<String>? name,
    Value<int>? ordinal,
    Value<int>? rowid,
  }) {
    return ShelvesCompanion(
      shelfId: shelfId ?? this.shelfId,
      name: name ?? this.name,
      ordinal: ordinal ?? this.ordinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shelfId.present) {
      map['shelf_id'] = Variable<String>(shelfId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelvesCompanion(')
          ..write('shelfId: $shelfId, ')
          ..write('name: $name, ')
          ..write('ordinal: $ordinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ShelfMembers extends Table with TableInfo<ShelfMembers, ShelfMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ShelfMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _shelfIdMeta = const VerificationMeta(
    'shelfId',
  );
  late final GeneratedColumn<String> shelfId = GeneratedColumn<String>(
    'shelf_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES shelves(shelf_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (ordinal >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [shelfId, sourceId, bookId, ordinal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'shelf_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<ShelfMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('shelf_id')) {
      context.handle(
        _shelfIdMeta,
        shelfId.isAcceptableOrUnknown(data['shelf_id']!, _shelfIdMeta),
      );
    } else if (isInserting) {
      context.missing(_shelfIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {shelfId, sourceId, bookId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {shelfId, ordinal},
  ];
  @override
  ShelfMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ShelfMember(
      shelfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}shelf_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
    );
  }

  @override
  ShelfMembers createAlias(String alias) {
    return ShelfMembers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(shelf_id, source_id, book_id)',
    'UNIQUE(shelf_id, ordinal)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ShelfMember extends DataClass implements Insertable<ShelfMember> {
  final String shelfId;
  final String sourceId;
  final String bookId;
  final int ordinal;
  const ShelfMember({
    required this.shelfId,
    required this.sourceId,
    required this.bookId,
    required this.ordinal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['shelf_id'] = Variable<String>(shelfId);
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['ordinal'] = Variable<int>(ordinal);
    return map;
  }

  ShelfMembersCompanion toCompanion(bool nullToAbsent) {
    return ShelfMembersCompanion(
      shelfId: Value(shelfId),
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      ordinal: Value(ordinal),
    );
  }

  factory ShelfMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ShelfMember(
      shelfId: serializer.fromJson<String>(json['shelf_id']),
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'shelf_id': serializer.toJson<String>(shelfId),
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'ordinal': serializer.toJson<int>(ordinal),
    };
  }

  ShelfMember copyWith({
    String? shelfId,
    String? sourceId,
    String? bookId,
    int? ordinal,
  }) => ShelfMember(
    shelfId: shelfId ?? this.shelfId,
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    ordinal: ordinal ?? this.ordinal,
  );
  ShelfMember copyWithCompanion(ShelfMembersCompanion data) {
    return ShelfMember(
      shelfId: data.shelfId.present ? data.shelfId.value : this.shelfId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ShelfMember(')
          ..write('shelfId: $shelfId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('ordinal: $ordinal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(shelfId, sourceId, bookId, ordinal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ShelfMember &&
          other.shelfId == this.shelfId &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.ordinal == this.ordinal);
}

class ShelfMembersCompanion extends UpdateCompanion<ShelfMember> {
  final Value<String> shelfId;
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> ordinal;
  final Value<int> rowid;
  const ShelfMembersCompanion({
    this.shelfId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ShelfMembersCompanion.insert({
    required String shelfId,
    required String sourceId,
    required String bookId,
    required int ordinal,
    this.rowid = const Value.absent(),
  }) : shelfId = Value(shelfId),
       sourceId = Value(sourceId),
       bookId = Value(bookId),
       ordinal = Value(ordinal);
  static Insertable<ShelfMember> custom({
    Expression<String>? shelfId,
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? ordinal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (shelfId != null) 'shelf_id': shelfId,
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (ordinal != null) 'ordinal': ordinal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ShelfMembersCompanion copyWith({
    Value<String>? shelfId,
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? ordinal,
    Value<int>? rowid,
  }) {
    return ShelfMembersCompanion(
      shelfId: shelfId ?? this.shelfId,
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      ordinal: ordinal ?? this.ordinal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (shelfId.present) {
      map['shelf_id'] = Variable<String>(shelfId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ShelfMembersCompanion(')
          ..write('shelfId: $shelfId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('ordinal: $ordinal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ManualGroups extends Table with TableInfo<ManualGroups, ManualGroup> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ManualGroups(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(group_id) > 0 AND instr(group_id, char(0)) = 0)',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'manual_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ManualGroup> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId};
  @override
  ManualGroup map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ManualGroup(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
    );
  }

  @override
  ManualGroups createAlias(String alias) {
    return ManualGroups(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ManualGroup extends DataClass implements Insertable<ManualGroup> {
  final String groupId;
  final String? displayName;
  const ManualGroup({required this.groupId, this.displayName});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    if (!nullToAbsent || displayName != null) {
      map['display_name'] = Variable<String>(displayName);
    }
    return map;
  }

  ManualGroupsCompanion toCompanion(bool nullToAbsent) {
    return ManualGroupsCompanion(
      groupId: Value(groupId),
      displayName: displayName == null && nullToAbsent
          ? const Value.absent()
          : Value(displayName),
    );
  }

  factory ManualGroup.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ManualGroup(
      groupId: serializer.fromJson<String>(json['group_id']),
      displayName: serializer.fromJson<String?>(json['display_name']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'display_name': serializer.toJson<String?>(displayName),
    };
  }

  ManualGroup copyWith({
    String? groupId,
    Value<String?> displayName = const Value.absent(),
  }) => ManualGroup(
    groupId: groupId ?? this.groupId,
    displayName: displayName.present ? displayName.value : this.displayName,
  );
  ManualGroup copyWithCompanion(ManualGroupsCompanion data) {
    return ManualGroup(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ManualGroup(')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ManualGroup &&
          other.groupId == this.groupId &&
          other.displayName == this.displayName);
}

class ManualGroupsCompanion extends UpdateCompanion<ManualGroup> {
  final Value<String> groupId;
  final Value<String?> displayName;
  final Value<int> rowid;
  const ManualGroupsCompanion({
    this.groupId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ManualGroupsCompanion.insert({
    required String groupId,
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId);
  static Insertable<ManualGroup> custom({
    Expression<String>? groupId,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ManualGroupsCompanion copyWith({
    Value<String>? groupId,
    Value<String?>? displayName,
    Value<int>? rowid,
  }) {
    return ManualGroupsCompanion(
      groupId: groupId ?? this.groupId,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ManualGroupsCompanion(')
          ..write('groupId: $groupId, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class GroupMembers extends Table with TableInfo<GroupMembers, GroupMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  GroupMembers(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES manual_groups(group_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  @override
  List<GeneratedColumn> get $columns => [groupId, sourceId, bookId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'group_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<GroupMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    } else if (isInserting) {
      context.missing(_groupIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {groupId, sourceId, bookId};
  @override
  GroupMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GroupMember(
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
    );
  }

  @override
  GroupMembers createAlias(String alias) {
    return GroupMembers(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(group_id, source_id, book_id)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class GroupMember extends DataClass implements Insertable<GroupMember> {
  final String groupId;
  final String sourceId;
  final String bookId;
  const GroupMember({
    required this.groupId,
    required this.sourceId,
    required this.bookId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['group_id'] = Variable<String>(groupId);
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    return map;
  }

  GroupMembersCompanion toCompanion(bool nullToAbsent) {
    return GroupMembersCompanion(
      groupId: Value(groupId),
      sourceId: Value(sourceId),
      bookId: Value(bookId),
    );
  }

  factory GroupMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GroupMember(
      groupId: serializer.fromJson<String>(json['group_id']),
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'group_id': serializer.toJson<String>(groupId),
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
    };
  }

  GroupMember copyWith({String? groupId, String? sourceId, String? bookId}) =>
      GroupMember(
        groupId: groupId ?? this.groupId,
        sourceId: sourceId ?? this.sourceId,
        bookId: bookId ?? this.bookId,
      );
  GroupMember copyWithCompanion(GroupMembersCompanion data) {
    return GroupMember(
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GroupMember(')
          ..write('groupId: $groupId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(groupId, sourceId, bookId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GroupMember &&
          other.groupId == this.groupId &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId);
}

class GroupMembersCompanion extends UpdateCompanion<GroupMember> {
  final Value<String> groupId;
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> rowid;
  const GroupMembersCompanion({
    this.groupId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GroupMembersCompanion.insert({
    required String groupId,
    required String sourceId,
    required String bookId,
    this.rowid = const Value.absent(),
  }) : groupId = Value(groupId),
       sourceId = Value(sourceId),
       bookId = Value(bookId);
  static Insertable<GroupMember> custom({
    Expression<String>? groupId,
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (groupId != null) 'group_id': groupId,
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GroupMembersCompanion copyWith({
    Value<String>? groupId,
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? rowid,
  }) {
    return GroupMembersCompanion(
      groupId: groupId ?? this.groupId,
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GroupMembersCompanion(')
          ..write('groupId: $groupId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SplitOverrides extends Table
    with TableInfo<SplitOverrides, SplitOverride> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SplitOverrides(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _isSplitMeta = const VerificationMeta(
    'isSplit',
  );
  late final GeneratedColumn<int> isSplit = GeneratedColumn<int>(
    'is_split',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (is_split IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [sourceId, bookId, isSplit];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'split_overrides';
  @override
  VerificationContext validateIntegrity(
    Insertable<SplitOverride> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('is_split')) {
      context.handle(
        _isSplitMeta,
        isSplit.isAcceptableOrUnknown(data['is_split']!, _isSplitMeta),
      );
    } else if (isInserting) {
      context.missing(_isSplitMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, bookId};
  @override
  SplitOverride map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SplitOverride(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      isSplit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_split'],
      )!,
    );
  }

  @override
  SplitOverrides createAlias(String alias) {
    return SplitOverrides(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_id, book_id)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SplitOverride extends DataClass implements Insertable<SplitOverride> {
  final String sourceId;
  final String bookId;
  final int isSplit;
  const SplitOverride({
    required this.sourceId,
    required this.bookId,
    required this.isSplit,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['is_split'] = Variable<int>(isSplit);
    return map;
  }

  SplitOverridesCompanion toCompanion(bool nullToAbsent) {
    return SplitOverridesCompanion(
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      isSplit: Value(isSplit),
    );
  }

  factory SplitOverride.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SplitOverride(
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      isSplit: serializer.fromJson<int>(json['is_split']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'is_split': serializer.toJson<int>(isSplit),
    };
  }

  SplitOverride copyWith({String? sourceId, String? bookId, int? isSplit}) =>
      SplitOverride(
        sourceId: sourceId ?? this.sourceId,
        bookId: bookId ?? this.bookId,
        isSplit: isSplit ?? this.isSplit,
      );
  SplitOverride copyWithCompanion(SplitOverridesCompanion data) {
    return SplitOverride(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      isSplit: data.isSplit.present ? data.isSplit.value : this.isSplit,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SplitOverride(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('isSplit: $isSplit')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sourceId, bookId, isSplit);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SplitOverride &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.isSplit == this.isSplit);
}

class SplitOverridesCompanion extends UpdateCompanion<SplitOverride> {
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> isSplit;
  final Value<int> rowid;
  const SplitOverridesCompanion({
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.isSplit = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SplitOverridesCompanion.insert({
    required String sourceId,
    required String bookId,
    required int isSplit,
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       bookId = Value(bookId),
       isSplit = Value(isSplit);
  static Insertable<SplitOverride> custom({
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? isSplit,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (isSplit != null) 'is_split': isSplit,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SplitOverridesCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? isSplit,
    Value<int>? rowid,
  }) {
    return SplitOverridesCompanion(
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      isSplit: isSplit ?? this.isSplit,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (isSplit.present) {
      map['is_split'] = Variable<int>(isSplit.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SplitOverridesCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('isSplit: $isSplit, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MigrationDatasets extends Table
    with TableInfo<MigrationDatasets, MigrationDataset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MigrationDatasets(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(dataset_id) > 0 AND instr(dataset_id, char(0)) = 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [datasetId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_datasets';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationDataset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {datasetId};
  @override
  MigrationDataset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationDataset(
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
    );
  }

  @override
  MigrationDatasets createAlias(String alias) {
    return MigrationDatasets(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class MigrationDataset extends DataClass
    implements Insertable<MigrationDataset> {
  final String datasetId;
  const MigrationDataset({required this.datasetId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_id'] = Variable<String>(datasetId);
    return map;
  }

  MigrationDatasetsCompanion toCompanion(bool nullToAbsent) {
    return MigrationDatasetsCompanion(datasetId: Value(datasetId));
  }

  factory MigrationDataset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationDataset(
      datasetId: serializer.fromJson<String>(json['dataset_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataset_id': serializer.toJson<String>(datasetId),
    };
  }

  MigrationDataset copyWith({String? datasetId}) =>
      MigrationDataset(datasetId: datasetId ?? this.datasetId);
  MigrationDataset copyWithCompanion(MigrationDatasetsCompanion data) {
    return MigrationDataset(
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationDataset(')
          ..write('datasetId: $datasetId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => datasetId.hashCode;
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationDataset && other.datasetId == this.datasetId);
}

class MigrationDatasetsCompanion extends UpdateCompanion<MigrationDataset> {
  final Value<String> datasetId;
  final Value<int> rowid;
  const MigrationDatasetsCompanion({
    this.datasetId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationDatasetsCompanion.insert({
    required String datasetId,
    this.rowid = const Value.absent(),
  }) : datasetId = Value(datasetId);
  static Insertable<MigrationDataset> custom({
    Expression<String>? datasetId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetId != null) 'dataset_id': datasetId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationDatasetsCompanion copyWith({
    Value<String>? datasetId,
    Value<int>? rowid,
  }) {
    return MigrationDatasetsCompanion(
      datasetId: datasetId ?? this.datasetId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationDatasetsCompanion(')
          ..write('datasetId: $datasetId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class MigrationRuns extends Table with TableInfo<MigrationRuns, MigrationRun> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  MigrationRuns(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES migration_datasets(dataset_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _importerVersionMeta = const VerificationMeta(
    'importerVersion',
  );
  late final GeneratedColumn<int> importerVersion = GeneratedColumn<int>(
    'importer_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (importer_version > 0)',
  );
  static const VerificationMeta _inputDigestMeta = const VerificationMeta(
    'inputDigest',
  );
  late final GeneratedColumn<String> inputDigest = GeneratedColumn<String>(
    'input_digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(input_digest) = 64 AND input_digest NOT GLOB \'*[^0-9a-f]*\')',
  );
  static const VerificationMeta _mappingVersionMeta = const VerificationMeta(
    'mappingVersion',
  );
  late final GeneratedColumn<int> mappingVersion = GeneratedColumn<int>(
    'mapping_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mapping_version > 0)',
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (state IN (\'pending\', \'applying\', \'verifying\', \'complete\', \'partial\', \'failed\'))',
  );
  static const VerificationMeta _expectedUnitsMeta = const VerificationMeta(
    'expectedUnits',
  );
  late final GeneratedColumn<int> expectedUnits = GeneratedColumn<int>(
    'expected_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (expected_units >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _verifiedUnitsMeta = const VerificationMeta(
    'verifiedUnits',
  );
  late final GeneratedColumn<int> verifiedUnits = GeneratedColumn<int>(
    'verified_units',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (verified_units >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    datasetId,
    importerVersion,
    inputDigest,
    mappingVersion,
    state,
    expectedUnits,
    verifiedUnits,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'migration_runs';
  @override
  VerificationContext validateIntegrity(
    Insertable<MigrationRun> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('importer_version')) {
      context.handle(
        _importerVersionMeta,
        importerVersion.isAcceptableOrUnknown(
          data['importer_version']!,
          _importerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importerVersionMeta);
    }
    if (data.containsKey('input_digest')) {
      context.handle(
        _inputDigestMeta,
        inputDigest.isAcceptableOrUnknown(
          data['input_digest']!,
          _inputDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputDigestMeta);
    }
    if (data.containsKey('mapping_version')) {
      context.handle(
        _mappingVersionMeta,
        mappingVersion.isAcceptableOrUnknown(
          data['mapping_version']!,
          _mappingVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mappingVersionMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('expected_units')) {
      context.handle(
        _expectedUnitsMeta,
        expectedUnits.isAcceptableOrUnknown(
          data['expected_units']!,
          _expectedUnitsMeta,
        ),
      );
    }
    if (data.containsKey('verified_units')) {
      context.handle(
        _verifiedUnitsMeta,
        verifiedUnits.isAcceptableOrUnknown(
          data['verified_units']!,
          _verifiedUnitsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    datasetId,
    importerVersion,
    inputDigest,
  };
  @override
  MigrationRun map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MigrationRun(
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      importerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importer_version'],
      )!,
      inputDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_digest'],
      )!,
      mappingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mapping_version'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      expectedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}expected_units'],
      )!,
      verifiedUnits: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}verified_units'],
      )!,
    );
  }

  @override
  MigrationRuns createAlias(String alias) {
    return MigrationRuns(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(dataset_id, importer_version, input_digest)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class MigrationRun extends DataClass implements Insertable<MigrationRun> {
  final String datasetId;
  final int importerVersion;
  final String inputDigest;
  final int mappingVersion;
  final String state;
  final int expectedUnits;
  final int verifiedUnits;
  const MigrationRun({
    required this.datasetId,
    required this.importerVersion,
    required this.inputDigest,
    required this.mappingVersion,
    required this.state,
    required this.expectedUnits,
    required this.verifiedUnits,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_id'] = Variable<String>(datasetId);
    map['importer_version'] = Variable<int>(importerVersion);
    map['input_digest'] = Variable<String>(inputDigest);
    map['mapping_version'] = Variable<int>(mappingVersion);
    map['state'] = Variable<String>(state);
    map['expected_units'] = Variable<int>(expectedUnits);
    map['verified_units'] = Variable<int>(verifiedUnits);
    return map;
  }

  MigrationRunsCompanion toCompanion(bool nullToAbsent) {
    return MigrationRunsCompanion(
      datasetId: Value(datasetId),
      importerVersion: Value(importerVersion),
      inputDigest: Value(inputDigest),
      mappingVersion: Value(mappingVersion),
      state: Value(state),
      expectedUnits: Value(expectedUnits),
      verifiedUnits: Value(verifiedUnits),
    );
  }

  factory MigrationRun.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MigrationRun(
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      importerVersion: serializer.fromJson<int>(json['importer_version']),
      inputDigest: serializer.fromJson<String>(json['input_digest']),
      mappingVersion: serializer.fromJson<int>(json['mapping_version']),
      state: serializer.fromJson<String>(json['state']),
      expectedUnits: serializer.fromJson<int>(json['expected_units']),
      verifiedUnits: serializer.fromJson<int>(json['verified_units']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataset_id': serializer.toJson<String>(datasetId),
      'importer_version': serializer.toJson<int>(importerVersion),
      'input_digest': serializer.toJson<String>(inputDigest),
      'mapping_version': serializer.toJson<int>(mappingVersion),
      'state': serializer.toJson<String>(state),
      'expected_units': serializer.toJson<int>(expectedUnits),
      'verified_units': serializer.toJson<int>(verifiedUnits),
    };
  }

  MigrationRun copyWith({
    String? datasetId,
    int? importerVersion,
    String? inputDigest,
    int? mappingVersion,
    String? state,
    int? expectedUnits,
    int? verifiedUnits,
  }) => MigrationRun(
    datasetId: datasetId ?? this.datasetId,
    importerVersion: importerVersion ?? this.importerVersion,
    inputDigest: inputDigest ?? this.inputDigest,
    mappingVersion: mappingVersion ?? this.mappingVersion,
    state: state ?? this.state,
    expectedUnits: expectedUnits ?? this.expectedUnits,
    verifiedUnits: verifiedUnits ?? this.verifiedUnits,
  );
  MigrationRun copyWithCompanion(MigrationRunsCompanion data) {
    return MigrationRun(
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      importerVersion: data.importerVersion.present
          ? data.importerVersion.value
          : this.importerVersion,
      inputDigest: data.inputDigest.present
          ? data.inputDigest.value
          : this.inputDigest,
      mappingVersion: data.mappingVersion.present
          ? data.mappingVersion.value
          : this.mappingVersion,
      state: data.state.present ? data.state.value : this.state,
      expectedUnits: data.expectedUnits.present
          ? data.expectedUnits.value
          : this.expectedUnits,
      verifiedUnits: data.verifiedUnits.present
          ? data.verifiedUnits.value
          : this.verifiedUnits,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRun(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('inputDigest: $inputDigest, ')
          ..write('mappingVersion: $mappingVersion, ')
          ..write('state: $state, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('verifiedUnits: $verifiedUnits')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    datasetId,
    importerVersion,
    inputDigest,
    mappingVersion,
    state,
    expectedUnits,
    verifiedUnits,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MigrationRun &&
          other.datasetId == this.datasetId &&
          other.importerVersion == this.importerVersion &&
          other.inputDigest == this.inputDigest &&
          other.mappingVersion == this.mappingVersion &&
          other.state == this.state &&
          other.expectedUnits == this.expectedUnits &&
          other.verifiedUnits == this.verifiedUnits);
}

class MigrationRunsCompanion extends UpdateCompanion<MigrationRun> {
  final Value<String> datasetId;
  final Value<int> importerVersion;
  final Value<String> inputDigest;
  final Value<int> mappingVersion;
  final Value<String> state;
  final Value<int> expectedUnits;
  final Value<int> verifiedUnits;
  final Value<int> rowid;
  const MigrationRunsCompanion({
    this.datasetId = const Value.absent(),
    this.importerVersion = const Value.absent(),
    this.inputDigest = const Value.absent(),
    this.mappingVersion = const Value.absent(),
    this.state = const Value.absent(),
    this.expectedUnits = const Value.absent(),
    this.verifiedUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MigrationRunsCompanion.insert({
    required String datasetId,
    required int importerVersion,
    required String inputDigest,
    required int mappingVersion,
    required String state,
    this.expectedUnits = const Value.absent(),
    this.verifiedUnits = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : datasetId = Value(datasetId),
       importerVersion = Value(importerVersion),
       inputDigest = Value(inputDigest),
       mappingVersion = Value(mappingVersion),
       state = Value(state);
  static Insertable<MigrationRun> custom({
    Expression<String>? datasetId,
    Expression<int>? importerVersion,
    Expression<String>? inputDigest,
    Expression<int>? mappingVersion,
    Expression<String>? state,
    Expression<int>? expectedUnits,
    Expression<int>? verifiedUnits,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetId != null) 'dataset_id': datasetId,
      if (importerVersion != null) 'importer_version': importerVersion,
      if (inputDigest != null) 'input_digest': inputDigest,
      if (mappingVersion != null) 'mapping_version': mappingVersion,
      if (state != null) 'state': state,
      if (expectedUnits != null) 'expected_units': expectedUnits,
      if (verifiedUnits != null) 'verified_units': verifiedUnits,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MigrationRunsCompanion copyWith({
    Value<String>? datasetId,
    Value<int>? importerVersion,
    Value<String>? inputDigest,
    Value<int>? mappingVersion,
    Value<String>? state,
    Value<int>? expectedUnits,
    Value<int>? verifiedUnits,
    Value<int>? rowid,
  }) {
    return MigrationRunsCompanion(
      datasetId: datasetId ?? this.datasetId,
      importerVersion: importerVersion ?? this.importerVersion,
      inputDigest: inputDigest ?? this.inputDigest,
      mappingVersion: mappingVersion ?? this.mappingVersion,
      state: state ?? this.state,
      expectedUnits: expectedUnits ?? this.expectedUnits,
      verifiedUnits: verifiedUnits ?? this.verifiedUnits,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (importerVersion.present) {
      map['importer_version'] = Variable<int>(importerVersion.value);
    }
    if (inputDigest.present) {
      map['input_digest'] = Variable<String>(inputDigest.value);
    }
    if (mappingVersion.present) {
      map['mapping_version'] = Variable<int>(mappingVersion.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (expectedUnits.present) {
      map['expected_units'] = Variable<int>(expectedUnits.value);
    }
    if (verifiedUnits.present) {
      map['verified_units'] = Variable<int>(verifiedUnits.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MigrationRunsCompanion(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('inputDigest: $inputDigest, ')
          ..write('mappingVersion: $mappingVersion, ')
          ..write('state: $state, ')
          ..write('expectedUnits: $expectedUnits, ')
          ..write('verifiedUnits: $verifiedUnits, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecordReceipts extends Table
    with TableInfo<RecordReceipts, RecordReceipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecordReceipts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES migration_datasets(dataset_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _importerVersionMeta = const VerificationMeta(
    'importerVersion',
  );
  late final GeneratedColumn<int> importerVersion = GeneratedColumn<int>(
    'importer_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (importer_version > 0)',
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (entity_kind IN (\'source\', \'book\', \'shelf\', \'group\', \'split\', \'progress\', \'readerPreferences\', \'appPreferences\', \'statistics\', \'searchHistory\', \'catalog\'))',
  );
  static const VerificationMeta _legacyKeyMeta = const VerificationMeta(
    'legacyKey',
  );
  late final GeneratedColumn<String> legacyKey = GeneratedColumn<String>(
    'legacy_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  @override
  List<GeneratedColumn> get $columns => [
    datasetId,
    importerVersion,
    entityKind,
    legacyKey,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordReceipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('importer_version')) {
      context.handle(
        _importerVersionMeta,
        importerVersion.isAcceptableOrUnknown(
          data['importer_version']!,
          _importerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importerVersionMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('legacy_key')) {
      context.handle(
        _legacyKeyMeta,
        legacyKey.isAcceptableOrUnknown(data['legacy_key']!, _legacyKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyKeyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    datasetId,
    importerVersion,
    entityKind,
    legacyKey,
  };
  @override
  RecordReceipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordReceipt(
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      importerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importer_version'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      legacyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_key'],
      )!,
    );
  }

  @override
  RecordReceipts createAlias(String alias) {
    return RecordReceipts(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(dataset_id, importer_version, entity_kind, legacy_key)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RecordReceipt extends DataClass implements Insertable<RecordReceipt> {
  final String datasetId;
  final int importerVersion;
  final String entityKind;
  final String legacyKey;
  const RecordReceipt({
    required this.datasetId,
    required this.importerVersion,
    required this.entityKind,
    required this.legacyKey,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_id'] = Variable<String>(datasetId);
    map['importer_version'] = Variable<int>(importerVersion);
    map['entity_kind'] = Variable<String>(entityKind);
    map['legacy_key'] = Variable<String>(legacyKey);
    return map;
  }

  RecordReceiptsCompanion toCompanion(bool nullToAbsent) {
    return RecordReceiptsCompanion(
      datasetId: Value(datasetId),
      importerVersion: Value(importerVersion),
      entityKind: Value(entityKind),
      legacyKey: Value(legacyKey),
    );
  }

  factory RecordReceipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordReceipt(
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      importerVersion: serializer.fromJson<int>(json['importer_version']),
      entityKind: serializer.fromJson<String>(json['entity_kind']),
      legacyKey: serializer.fromJson<String>(json['legacy_key']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataset_id': serializer.toJson<String>(datasetId),
      'importer_version': serializer.toJson<int>(importerVersion),
      'entity_kind': serializer.toJson<String>(entityKind),
      'legacy_key': serializer.toJson<String>(legacyKey),
    };
  }

  RecordReceipt copyWith({
    String? datasetId,
    int? importerVersion,
    String? entityKind,
    String? legacyKey,
  }) => RecordReceipt(
    datasetId: datasetId ?? this.datasetId,
    importerVersion: importerVersion ?? this.importerVersion,
    entityKind: entityKind ?? this.entityKind,
    legacyKey: legacyKey ?? this.legacyKey,
  );
  RecordReceipt copyWithCompanion(RecordReceiptsCompanion data) {
    return RecordReceipt(
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      importerVersion: data.importerVersion.present
          ? data.importerVersion.value
          : this.importerVersion,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      legacyKey: data.legacyKey.present ? data.legacyKey.value : this.legacyKey,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordReceipt(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(datasetId, importerVersion, entityKind, legacyKey);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordReceipt &&
          other.datasetId == this.datasetId &&
          other.importerVersion == this.importerVersion &&
          other.entityKind == this.entityKind &&
          other.legacyKey == this.legacyKey);
}

class RecordReceiptsCompanion extends UpdateCompanion<RecordReceipt> {
  final Value<String> datasetId;
  final Value<int> importerVersion;
  final Value<String> entityKind;
  final Value<String> legacyKey;
  final Value<int> rowid;
  const RecordReceiptsCompanion({
    this.datasetId = const Value.absent(),
    this.importerVersion = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.legacyKey = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordReceiptsCompanion.insert({
    required String datasetId,
    required int importerVersion,
    required String entityKind,
    required String legacyKey,
    this.rowid = const Value.absent(),
  }) : datasetId = Value(datasetId),
       importerVersion = Value(importerVersion),
       entityKind = Value(entityKind),
       legacyKey = Value(legacyKey);
  static Insertable<RecordReceipt> custom({
    Expression<String>? datasetId,
    Expression<int>? importerVersion,
    Expression<String>? entityKind,
    Expression<String>? legacyKey,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetId != null) 'dataset_id': datasetId,
      if (importerVersion != null) 'importer_version': importerVersion,
      if (entityKind != null) 'entity_kind': entityKind,
      if (legacyKey != null) 'legacy_key': legacyKey,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordReceiptsCompanion copyWith({
    Value<String>? datasetId,
    Value<int>? importerVersion,
    Value<String>? entityKind,
    Value<String>? legacyKey,
    Value<int>? rowid,
  }) {
    return RecordReceiptsCompanion(
      datasetId: datasetId ?? this.datasetId,
      importerVersion: importerVersion ?? this.importerVersion,
      entityKind: entityKind ?? this.entityKind,
      legacyKey: legacyKey ?? this.legacyKey,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (importerVersion.present) {
      map['importer_version'] = Variable<int>(importerVersion.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (legacyKey.present) {
      map['legacy_key'] = Variable<String>(legacyKey.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordReceiptsCompanion(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RecordOutcomes extends Table
    with TableInfo<RecordOutcomes, RecordOutcome> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecordOutcomes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _importerVersionMeta = const VerificationMeta(
    'importerVersion',
  );
  late final GeneratedColumn<int> importerVersion = GeneratedColumn<int>(
    'importer_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _inputDigestMeta = const VerificationMeta(
    'inputDigest',
  );
  late final GeneratedColumn<String> inputDigest = GeneratedColumn<String>(
    'input_digest',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _legacyKeyMeta = const VerificationMeta(
    'legacyKey',
  );
  late final GeneratedColumn<String> legacyKey = GeneratedColumn<String>(
    'legacy_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _outcomeMeta = const VerificationMeta(
    'outcome',
  );
  late final GeneratedColumn<String> outcome = GeneratedColumn<String>(
    'outcome',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (outcome IN (\'imported\', \'unchanged\', \'preserved-unresolved\', \'deferred-preserved\', \'intentionally-excluded\', \'failed\', \'conflict\'))',
  );
  static const VerificationMeta _diagnosticCodeMeta = const VerificationMeta(
    'diagnosticCode',
  );
  late final GeneratedColumn<String> diagnosticCode = GeneratedColumn<String>(
    'diagnostic_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (diagnostic_code IS NULL OR diagnostic_code IN (\'invalid-field\', \'unknown-field\', \'unsupported\', \'missing-evidence\', \'conflicting-evidence\', \'verification-failed\', \'secret-excluded\'))',
  );
  static const VerificationMeta _omittedFieldCountMeta = const VerificationMeta(
    'omittedFieldCount',
  );
  late final GeneratedColumn<int> omittedFieldCount = GeneratedColumn<int>(
    'omitted_field_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (omitted_field_count >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    datasetId,
    importerVersion,
    inputDigest,
    entityKind,
    legacyKey,
    outcome,
    diagnosticCode,
    omittedFieldCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'record_outcomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecordOutcome> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('importer_version')) {
      context.handle(
        _importerVersionMeta,
        importerVersion.isAcceptableOrUnknown(
          data['importer_version']!,
          _importerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importerVersionMeta);
    }
    if (data.containsKey('input_digest')) {
      context.handle(
        _inputDigestMeta,
        inputDigest.isAcceptableOrUnknown(
          data['input_digest']!,
          _inputDigestMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_inputDigestMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('legacy_key')) {
      context.handle(
        _legacyKeyMeta,
        legacyKey.isAcceptableOrUnknown(data['legacy_key']!, _legacyKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyKeyMeta);
    }
    if (data.containsKey('outcome')) {
      context.handle(
        _outcomeMeta,
        outcome.isAcceptableOrUnknown(data['outcome']!, _outcomeMeta),
      );
    } else if (isInserting) {
      context.missing(_outcomeMeta);
    }
    if (data.containsKey('diagnostic_code')) {
      context.handle(
        _diagnosticCodeMeta,
        diagnosticCode.isAcceptableOrUnknown(
          data['diagnostic_code']!,
          _diagnosticCodeMeta,
        ),
      );
    }
    if (data.containsKey('omitted_field_count')) {
      context.handle(
        _omittedFieldCountMeta,
        omittedFieldCount.isAcceptableOrUnknown(
          data['omitted_field_count']!,
          _omittedFieldCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    datasetId,
    importerVersion,
    inputDigest,
    entityKind,
    legacyKey,
  };
  @override
  RecordOutcome map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecordOutcome(
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      importerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importer_version'],
      )!,
      inputDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}input_digest'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      legacyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_key'],
      )!,
      outcome: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}outcome'],
      )!,
      diagnosticCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}diagnostic_code'],
      ),
      omittedFieldCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}omitted_field_count'],
      )!,
    );
  }

  @override
  RecordOutcomes createAlias(String alias) {
    return RecordOutcomes(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(dataset_id, importer_version, input_digest, entity_kind, legacy_key)',
    'FOREIGN KEY(dataset_id, importer_version, input_digest)REFERENCES migration_runs(dataset_id, importer_version, input_digest)ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY(dataset_id, importer_version, entity_kind, legacy_key)REFERENCES record_receipts(dataset_id, importer_version, entity_kind, legacy_key)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RecordOutcome extends DataClass implements Insertable<RecordOutcome> {
  final String datasetId;
  final int importerVersion;
  final String inputDigest;
  final String entityKind;
  final String legacyKey;
  final String outcome;
  final String? diagnosticCode;
  final int omittedFieldCount;
  const RecordOutcome({
    required this.datasetId,
    required this.importerVersion,
    required this.inputDigest,
    required this.entityKind,
    required this.legacyKey,
    required this.outcome,
    this.diagnosticCode,
    required this.omittedFieldCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_id'] = Variable<String>(datasetId);
    map['importer_version'] = Variable<int>(importerVersion);
    map['input_digest'] = Variable<String>(inputDigest);
    map['entity_kind'] = Variable<String>(entityKind);
    map['legacy_key'] = Variable<String>(legacyKey);
    map['outcome'] = Variable<String>(outcome);
    if (!nullToAbsent || diagnosticCode != null) {
      map['diagnostic_code'] = Variable<String>(diagnosticCode);
    }
    map['omitted_field_count'] = Variable<int>(omittedFieldCount);
    return map;
  }

  RecordOutcomesCompanion toCompanion(bool nullToAbsent) {
    return RecordOutcomesCompanion(
      datasetId: Value(datasetId),
      importerVersion: Value(importerVersion),
      inputDigest: Value(inputDigest),
      entityKind: Value(entityKind),
      legacyKey: Value(legacyKey),
      outcome: Value(outcome),
      diagnosticCode: diagnosticCode == null && nullToAbsent
          ? const Value.absent()
          : Value(diagnosticCode),
      omittedFieldCount: Value(omittedFieldCount),
    );
  }

  factory RecordOutcome.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecordOutcome(
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      importerVersion: serializer.fromJson<int>(json['importer_version']),
      inputDigest: serializer.fromJson<String>(json['input_digest']),
      entityKind: serializer.fromJson<String>(json['entity_kind']),
      legacyKey: serializer.fromJson<String>(json['legacy_key']),
      outcome: serializer.fromJson<String>(json['outcome']),
      diagnosticCode: serializer.fromJson<String?>(json['diagnostic_code']),
      omittedFieldCount: serializer.fromJson<int>(json['omitted_field_count']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataset_id': serializer.toJson<String>(datasetId),
      'importer_version': serializer.toJson<int>(importerVersion),
      'input_digest': serializer.toJson<String>(inputDigest),
      'entity_kind': serializer.toJson<String>(entityKind),
      'legacy_key': serializer.toJson<String>(legacyKey),
      'outcome': serializer.toJson<String>(outcome),
      'diagnostic_code': serializer.toJson<String?>(diagnosticCode),
      'omitted_field_count': serializer.toJson<int>(omittedFieldCount),
    };
  }

  RecordOutcome copyWith({
    String? datasetId,
    int? importerVersion,
    String? inputDigest,
    String? entityKind,
    String? legacyKey,
    String? outcome,
    Value<String?> diagnosticCode = const Value.absent(),
    int? omittedFieldCount,
  }) => RecordOutcome(
    datasetId: datasetId ?? this.datasetId,
    importerVersion: importerVersion ?? this.importerVersion,
    inputDigest: inputDigest ?? this.inputDigest,
    entityKind: entityKind ?? this.entityKind,
    legacyKey: legacyKey ?? this.legacyKey,
    outcome: outcome ?? this.outcome,
    diagnosticCode: diagnosticCode.present
        ? diagnosticCode.value
        : this.diagnosticCode,
    omittedFieldCount: omittedFieldCount ?? this.omittedFieldCount,
  );
  RecordOutcome copyWithCompanion(RecordOutcomesCompanion data) {
    return RecordOutcome(
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      importerVersion: data.importerVersion.present
          ? data.importerVersion.value
          : this.importerVersion,
      inputDigest: data.inputDigest.present
          ? data.inputDigest.value
          : this.inputDigest,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      legacyKey: data.legacyKey.present ? data.legacyKey.value : this.legacyKey,
      outcome: data.outcome.present ? data.outcome.value : this.outcome,
      diagnosticCode: data.diagnosticCode.present
          ? data.diagnosticCode.value
          : this.diagnosticCode,
      omittedFieldCount: data.omittedFieldCount.present
          ? data.omittedFieldCount.value
          : this.omittedFieldCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecordOutcome(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('inputDigest: $inputDigest, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('outcome: $outcome, ')
          ..write('diagnosticCode: $diagnosticCode, ')
          ..write('omittedFieldCount: $omittedFieldCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    datasetId,
    importerVersion,
    inputDigest,
    entityKind,
    legacyKey,
    outcome,
    diagnosticCode,
    omittedFieldCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecordOutcome &&
          other.datasetId == this.datasetId &&
          other.importerVersion == this.importerVersion &&
          other.inputDigest == this.inputDigest &&
          other.entityKind == this.entityKind &&
          other.legacyKey == this.legacyKey &&
          other.outcome == this.outcome &&
          other.diagnosticCode == this.diagnosticCode &&
          other.omittedFieldCount == this.omittedFieldCount);
}

class RecordOutcomesCompanion extends UpdateCompanion<RecordOutcome> {
  final Value<String> datasetId;
  final Value<int> importerVersion;
  final Value<String> inputDigest;
  final Value<String> entityKind;
  final Value<String> legacyKey;
  final Value<String> outcome;
  final Value<String?> diagnosticCode;
  final Value<int> omittedFieldCount;
  final Value<int> rowid;
  const RecordOutcomesCompanion({
    this.datasetId = const Value.absent(),
    this.importerVersion = const Value.absent(),
    this.inputDigest = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.legacyKey = const Value.absent(),
    this.outcome = const Value.absent(),
    this.diagnosticCode = const Value.absent(),
    this.omittedFieldCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RecordOutcomesCompanion.insert({
    required String datasetId,
    required int importerVersion,
    required String inputDigest,
    required String entityKind,
    required String legacyKey,
    required String outcome,
    this.diagnosticCode = const Value.absent(),
    this.omittedFieldCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : datasetId = Value(datasetId),
       importerVersion = Value(importerVersion),
       inputDigest = Value(inputDigest),
       entityKind = Value(entityKind),
       legacyKey = Value(legacyKey),
       outcome = Value(outcome);
  static Insertable<RecordOutcome> custom({
    Expression<String>? datasetId,
    Expression<int>? importerVersion,
    Expression<String>? inputDigest,
    Expression<String>? entityKind,
    Expression<String>? legacyKey,
    Expression<String>? outcome,
    Expression<String>? diagnosticCode,
    Expression<int>? omittedFieldCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetId != null) 'dataset_id': datasetId,
      if (importerVersion != null) 'importer_version': importerVersion,
      if (inputDigest != null) 'input_digest': inputDigest,
      if (entityKind != null) 'entity_kind': entityKind,
      if (legacyKey != null) 'legacy_key': legacyKey,
      if (outcome != null) 'outcome': outcome,
      if (diagnosticCode != null) 'diagnostic_code': diagnosticCode,
      if (omittedFieldCount != null) 'omitted_field_count': omittedFieldCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RecordOutcomesCompanion copyWith({
    Value<String>? datasetId,
    Value<int>? importerVersion,
    Value<String>? inputDigest,
    Value<String>? entityKind,
    Value<String>? legacyKey,
    Value<String>? outcome,
    Value<String?>? diagnosticCode,
    Value<int>? omittedFieldCount,
    Value<int>? rowid,
  }) {
    return RecordOutcomesCompanion(
      datasetId: datasetId ?? this.datasetId,
      importerVersion: importerVersion ?? this.importerVersion,
      inputDigest: inputDigest ?? this.inputDigest,
      entityKind: entityKind ?? this.entityKind,
      legacyKey: legacyKey ?? this.legacyKey,
      outcome: outcome ?? this.outcome,
      diagnosticCode: diagnosticCode ?? this.diagnosticCode,
      omittedFieldCount: omittedFieldCount ?? this.omittedFieldCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (importerVersion.present) {
      map['importer_version'] = Variable<int>(importerVersion.value);
    }
    if (inputDigest.present) {
      map['input_digest'] = Variable<String>(inputDigest.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (legacyKey.present) {
      map['legacy_key'] = Variable<String>(legacyKey.value);
    }
    if (outcome.present) {
      map['outcome'] = Variable<String>(outcome.value);
    }
    if (diagnosticCode.present) {
      map['diagnostic_code'] = Variable<String>(diagnosticCode.value);
    }
    if (omittedFieldCount.present) {
      map['omitted_field_count'] = Variable<int>(omittedFieldCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecordOutcomesCompanion(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('inputDigest: $inputDigest, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('outcome: $outcome, ')
          ..write('diagnosticCode: $diagnosticCode, ')
          ..write('omittedFieldCount: $omittedFieldCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SafeLegacyValues extends Table
    with TableInfo<SafeLegacyValues, SafeLegacyValue> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SafeLegacyValues(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _importerVersionMeta = const VerificationMeta(
    'importerVersion',
  );
  late final GeneratedColumn<int> importerVersion = GeneratedColumn<int>(
    'importer_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _legacyKeyMeta = const VerificationMeta(
    'legacyKey',
  );
  late final GeneratedColumn<String> legacyKey = GeneratedColumn<String>(
    'legacy_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _candidateIdMeta = const VerificationMeta(
    'candidateId',
  );
  late final GeneratedColumn<String> candidateId = GeneratedColumn<String>(
    'candidate_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL COLLATE BINARY CHECK (length(candidate_id) > 0)',
  );
  static const VerificationMeta _fieldMeta = const VerificationMeta('field');
  late final GeneratedColumn<String> field = GeneratedColumn<String>(
    'field',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (field IN (\'book.id\', \'book.title\', \'book.author\', \'book.source\', \'book.intro\', \'book.tag\', \'book.totalChapters\', \'book.lastChapter\', \'book.hits\', \'book.coverIndex\', \'book.hasUpdate\', \'book.coverReference\', \'book.publishingHouse\', \'book.lastUpdate\', \'book.isCompleted\', \'book.wordCountK\', \'book.saved\', \'source.name\', \'source.byIdName\', \'source.preferred\', \'shelf.id\', \'shelf.name\', \'shelf.ordinal\', \'shelf.member\', \'group.id\', \'group.name\', \'group.member\', \'group.autoRename\', \'split.bookId\', \'progress.lastChapter\', \'progress.bookLastChapter\', \'progress.offset\', \'progress.hasRead\', \'progress.appleDate\', \'progress.knownTotal\', \'progress.updateFlag\', \'reader.fontSize\', \'reader.lineSpacing\', \'reader.backgroundIndex\', \'reader.mode\', \'reader.fontFamily\', \'reader.bold\', \'reader.marginLeft\', \'reader.marginRight\', \'reader.marginTop\', \'reader.marginBottom\', \'app.theme\', \'app.selectedShelf\', \'app.accent\', \'stats.dailySeconds\', \'stats.dailyChapters\', \'stats.bookSeconds\', \'search.term\', \'catalog.index\', \'catalog.title\', \'catalog.volume\', \'catalog.remoteId\'))',
  );
  static const VerificationMeta _mapKeyMeta = const VerificationMeta('mapKey');
  late final GeneratedColumn<String> mapKey = GeneratedColumn<String>(
    'map_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\' COLLATE BINARY',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (ordinal >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _valueTypeMeta = const VerificationMeta(
    'valueType',
  );
  late final GeneratedColumn<String> valueType = GeneratedColumn<String>(
    'value_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (value_type IN (\'string\', \'integer\', \'number\', \'boolean\', \'null\'))',
  );
  static const VerificationMeta _textValueMeta = const VerificationMeta(
    'textValue',
  );
  late final GeneratedColumn<String> textValue = GeneratedColumn<String>(
    'text_value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _integerValueMeta = const VerificationMeta(
    'integerValue',
  );
  late final GeneratedColumn<int> integerValue = GeneratedColumn<int>(
    'integer_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _numberValueMeta = const VerificationMeta(
    'numberValue',
  );
  late final GeneratedColumn<double> numberValue = GeneratedColumn<double>(
    'number_value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (number_value IS NULL OR(number_value - number_value)IS NOT NULL)',
  );
  static const VerificationMeta _booleanValueMeta = const VerificationMeta(
    'booleanValue',
  );
  late final GeneratedColumn<int> booleanValue = GeneratedColumn<int>(
    'boolean_value',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (boolean_value IS NULL OR boolean_value IN (0, 1))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    datasetId,
    importerVersion,
    entityKind,
    legacyKey,
    candidateId,
    field,
    mapKey,
    ordinal,
    valueType,
    textValue,
    integerValue,
    numberValue,
    booleanValue,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'safe_legacy_values';
  @override
  VerificationContext validateIntegrity(
    Insertable<SafeLegacyValue> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('importer_version')) {
      context.handle(
        _importerVersionMeta,
        importerVersion.isAcceptableOrUnknown(
          data['importer_version']!,
          _importerVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_importerVersionMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('legacy_key')) {
      context.handle(
        _legacyKeyMeta,
        legacyKey.isAcceptableOrUnknown(data['legacy_key']!, _legacyKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyKeyMeta);
    }
    if (data.containsKey('candidate_id')) {
      context.handle(
        _candidateIdMeta,
        candidateId.isAcceptableOrUnknown(
          data['candidate_id']!,
          _candidateIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_candidateIdMeta);
    }
    if (data.containsKey('field')) {
      context.handle(
        _fieldMeta,
        field.isAcceptableOrUnknown(data['field']!, _fieldMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldMeta);
    }
    if (data.containsKey('map_key')) {
      context.handle(
        _mapKeyMeta,
        mapKey.isAcceptableOrUnknown(data['map_key']!, _mapKeyMeta),
      );
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    }
    if (data.containsKey('value_type')) {
      context.handle(
        _valueTypeMeta,
        valueType.isAcceptableOrUnknown(data['value_type']!, _valueTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_valueTypeMeta);
    }
    if (data.containsKey('text_value')) {
      context.handle(
        _textValueMeta,
        textValue.isAcceptableOrUnknown(data['text_value']!, _textValueMeta),
      );
    }
    if (data.containsKey('integer_value')) {
      context.handle(
        _integerValueMeta,
        integerValue.isAcceptableOrUnknown(
          data['integer_value']!,
          _integerValueMeta,
        ),
      );
    }
    if (data.containsKey('number_value')) {
      context.handle(
        _numberValueMeta,
        numberValue.isAcceptableOrUnknown(
          data['number_value']!,
          _numberValueMeta,
        ),
      );
    }
    if (data.containsKey('boolean_value')) {
      context.handle(
        _booleanValueMeta,
        booleanValue.isAcceptableOrUnknown(
          data['boolean_value']!,
          _booleanValueMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {
    datasetId,
    importerVersion,
    entityKind,
    legacyKey,
    candidateId,
    field,
    mapKey,
    ordinal,
  };
  @override
  SafeLegacyValue map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SafeLegacyValue(
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      importerVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}importer_version'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      legacyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_key'],
      )!,
      candidateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}candidate_id'],
      )!,
      field: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field'],
      )!,
      mapKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_key'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      valueType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_type'],
      )!,
      textValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text_value'],
      ),
      integerValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}integer_value'],
      ),
      numberValue: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}number_value'],
      ),
      booleanValue: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}boolean_value'],
      ),
    );
  }

  @override
  SafeLegacyValues createAlias(String alias) {
    return SafeLegacyValues(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(dataset_id, importer_version, entity_kind, legacy_key, candidate_id, field, map_key, ordinal)',
    'FOREIGN KEY(dataset_id, importer_version, entity_kind, legacy_key)REFERENCES record_receipts(dataset_id, importer_version, entity_kind, legacy_key)ON UPDATE RESTRICT ON DELETE RESTRICT',
    'CHECK((value_type = \'string\' AND text_value IS NOT NULL AND integer_value IS NULL AND number_value IS NULL AND boolean_value IS NULL)OR(value_type = \'integer\' AND text_value IS NULL AND integer_value IS NOT NULL AND number_value IS NULL AND boolean_value IS NULL)OR(value_type = \'number\' AND text_value IS NULL AND integer_value IS NULL AND number_value IS NOT NULL AND boolean_value IS NULL)OR(value_type = \'boolean\' AND text_value IS NULL AND integer_value IS NULL AND number_value IS NULL AND boolean_value IS NOT NULL)OR(value_type = \'null\' AND text_value IS NULL AND integer_value IS NULL AND number_value IS NULL AND boolean_value IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class SafeLegacyValue extends DataClass implements Insertable<SafeLegacyValue> {
  final String datasetId;
  final int importerVersion;
  final String entityKind;
  final String legacyKey;
  final String candidateId;
  final String field;
  final String mapKey;
  final int ordinal;
  final String valueType;
  final String? textValue;
  final int? integerValue;
  final double? numberValue;
  final int? booleanValue;
  const SafeLegacyValue({
    required this.datasetId,
    required this.importerVersion,
    required this.entityKind,
    required this.legacyKey,
    required this.candidateId,
    required this.field,
    required this.mapKey,
    required this.ordinal,
    required this.valueType,
    this.textValue,
    this.integerValue,
    this.numberValue,
    this.booleanValue,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['dataset_id'] = Variable<String>(datasetId);
    map['importer_version'] = Variable<int>(importerVersion);
    map['entity_kind'] = Variable<String>(entityKind);
    map['legacy_key'] = Variable<String>(legacyKey);
    map['candidate_id'] = Variable<String>(candidateId);
    map['field'] = Variable<String>(field);
    map['map_key'] = Variable<String>(mapKey);
    map['ordinal'] = Variable<int>(ordinal);
    map['value_type'] = Variable<String>(valueType);
    if (!nullToAbsent || textValue != null) {
      map['text_value'] = Variable<String>(textValue);
    }
    if (!nullToAbsent || integerValue != null) {
      map['integer_value'] = Variable<int>(integerValue);
    }
    if (!nullToAbsent || numberValue != null) {
      map['number_value'] = Variable<double>(numberValue);
    }
    if (!nullToAbsent || booleanValue != null) {
      map['boolean_value'] = Variable<int>(booleanValue);
    }
    return map;
  }

  SafeLegacyValuesCompanion toCompanion(bool nullToAbsent) {
    return SafeLegacyValuesCompanion(
      datasetId: Value(datasetId),
      importerVersion: Value(importerVersion),
      entityKind: Value(entityKind),
      legacyKey: Value(legacyKey),
      candidateId: Value(candidateId),
      field: Value(field),
      mapKey: Value(mapKey),
      ordinal: Value(ordinal),
      valueType: Value(valueType),
      textValue: textValue == null && nullToAbsent
          ? const Value.absent()
          : Value(textValue),
      integerValue: integerValue == null && nullToAbsent
          ? const Value.absent()
          : Value(integerValue),
      numberValue: numberValue == null && nullToAbsent
          ? const Value.absent()
          : Value(numberValue),
      booleanValue: booleanValue == null && nullToAbsent
          ? const Value.absent()
          : Value(booleanValue),
    );
  }

  factory SafeLegacyValue.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SafeLegacyValue(
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      importerVersion: serializer.fromJson<int>(json['importer_version']),
      entityKind: serializer.fromJson<String>(json['entity_kind']),
      legacyKey: serializer.fromJson<String>(json['legacy_key']),
      candidateId: serializer.fromJson<String>(json['candidate_id']),
      field: serializer.fromJson<String>(json['field']),
      mapKey: serializer.fromJson<String>(json['map_key']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      valueType: serializer.fromJson<String>(json['value_type']),
      textValue: serializer.fromJson<String?>(json['text_value']),
      integerValue: serializer.fromJson<int?>(json['integer_value']),
      numberValue: serializer.fromJson<double?>(json['number_value']),
      booleanValue: serializer.fromJson<int?>(json['boolean_value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'dataset_id': serializer.toJson<String>(datasetId),
      'importer_version': serializer.toJson<int>(importerVersion),
      'entity_kind': serializer.toJson<String>(entityKind),
      'legacy_key': serializer.toJson<String>(legacyKey),
      'candidate_id': serializer.toJson<String>(candidateId),
      'field': serializer.toJson<String>(field),
      'map_key': serializer.toJson<String>(mapKey),
      'ordinal': serializer.toJson<int>(ordinal),
      'value_type': serializer.toJson<String>(valueType),
      'text_value': serializer.toJson<String?>(textValue),
      'integer_value': serializer.toJson<int?>(integerValue),
      'number_value': serializer.toJson<double?>(numberValue),
      'boolean_value': serializer.toJson<int?>(booleanValue),
    };
  }

  SafeLegacyValue copyWith({
    String? datasetId,
    int? importerVersion,
    String? entityKind,
    String? legacyKey,
    String? candidateId,
    String? field,
    String? mapKey,
    int? ordinal,
    String? valueType,
    Value<String?> textValue = const Value.absent(),
    Value<int?> integerValue = const Value.absent(),
    Value<double?> numberValue = const Value.absent(),
    Value<int?> booleanValue = const Value.absent(),
  }) => SafeLegacyValue(
    datasetId: datasetId ?? this.datasetId,
    importerVersion: importerVersion ?? this.importerVersion,
    entityKind: entityKind ?? this.entityKind,
    legacyKey: legacyKey ?? this.legacyKey,
    candidateId: candidateId ?? this.candidateId,
    field: field ?? this.field,
    mapKey: mapKey ?? this.mapKey,
    ordinal: ordinal ?? this.ordinal,
    valueType: valueType ?? this.valueType,
    textValue: textValue.present ? textValue.value : this.textValue,
    integerValue: integerValue.present ? integerValue.value : this.integerValue,
    numberValue: numberValue.present ? numberValue.value : this.numberValue,
    booleanValue: booleanValue.present ? booleanValue.value : this.booleanValue,
  );
  SafeLegacyValue copyWithCompanion(SafeLegacyValuesCompanion data) {
    return SafeLegacyValue(
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      importerVersion: data.importerVersion.present
          ? data.importerVersion.value
          : this.importerVersion,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      legacyKey: data.legacyKey.present ? data.legacyKey.value : this.legacyKey,
      candidateId: data.candidateId.present
          ? data.candidateId.value
          : this.candidateId,
      field: data.field.present ? data.field.value : this.field,
      mapKey: data.mapKey.present ? data.mapKey.value : this.mapKey,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      valueType: data.valueType.present ? data.valueType.value : this.valueType,
      textValue: data.textValue.present ? data.textValue.value : this.textValue,
      integerValue: data.integerValue.present
          ? data.integerValue.value
          : this.integerValue,
      numberValue: data.numberValue.present
          ? data.numberValue.value
          : this.numberValue,
      booleanValue: data.booleanValue.present
          ? data.booleanValue.value
          : this.booleanValue,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SafeLegacyValue(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('candidateId: $candidateId, ')
          ..write('field: $field, ')
          ..write('mapKey: $mapKey, ')
          ..write('ordinal: $ordinal, ')
          ..write('valueType: $valueType, ')
          ..write('textValue: $textValue, ')
          ..write('integerValue: $integerValue, ')
          ..write('numberValue: $numberValue, ')
          ..write('booleanValue: $booleanValue')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    datasetId,
    importerVersion,
    entityKind,
    legacyKey,
    candidateId,
    field,
    mapKey,
    ordinal,
    valueType,
    textValue,
    integerValue,
    numberValue,
    booleanValue,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SafeLegacyValue &&
          other.datasetId == this.datasetId &&
          other.importerVersion == this.importerVersion &&
          other.entityKind == this.entityKind &&
          other.legacyKey == this.legacyKey &&
          other.candidateId == this.candidateId &&
          other.field == this.field &&
          other.mapKey == this.mapKey &&
          other.ordinal == this.ordinal &&
          other.valueType == this.valueType &&
          other.textValue == this.textValue &&
          other.integerValue == this.integerValue &&
          other.numberValue == this.numberValue &&
          other.booleanValue == this.booleanValue);
}

class SafeLegacyValuesCompanion extends UpdateCompanion<SafeLegacyValue> {
  final Value<String> datasetId;
  final Value<int> importerVersion;
  final Value<String> entityKind;
  final Value<String> legacyKey;
  final Value<String> candidateId;
  final Value<String> field;
  final Value<String> mapKey;
  final Value<int> ordinal;
  final Value<String> valueType;
  final Value<String?> textValue;
  final Value<int?> integerValue;
  final Value<double?> numberValue;
  final Value<int?> booleanValue;
  final Value<int> rowid;
  const SafeLegacyValuesCompanion({
    this.datasetId = const Value.absent(),
    this.importerVersion = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.legacyKey = const Value.absent(),
    this.candidateId = const Value.absent(),
    this.field = const Value.absent(),
    this.mapKey = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.valueType = const Value.absent(),
    this.textValue = const Value.absent(),
    this.integerValue = const Value.absent(),
    this.numberValue = const Value.absent(),
    this.booleanValue = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SafeLegacyValuesCompanion.insert({
    required String datasetId,
    required int importerVersion,
    required String entityKind,
    required String legacyKey,
    required String candidateId,
    required String field,
    this.mapKey = const Value.absent(),
    this.ordinal = const Value.absent(),
    required String valueType,
    this.textValue = const Value.absent(),
    this.integerValue = const Value.absent(),
    this.numberValue = const Value.absent(),
    this.booleanValue = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : datasetId = Value(datasetId),
       importerVersion = Value(importerVersion),
       entityKind = Value(entityKind),
       legacyKey = Value(legacyKey),
       candidateId = Value(candidateId),
       field = Value(field),
       valueType = Value(valueType);
  static Insertable<SafeLegacyValue> custom({
    Expression<String>? datasetId,
    Expression<int>? importerVersion,
    Expression<String>? entityKind,
    Expression<String>? legacyKey,
    Expression<String>? candidateId,
    Expression<String>? field,
    Expression<String>? mapKey,
    Expression<int>? ordinal,
    Expression<String>? valueType,
    Expression<String>? textValue,
    Expression<int>? integerValue,
    Expression<double>? numberValue,
    Expression<int>? booleanValue,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (datasetId != null) 'dataset_id': datasetId,
      if (importerVersion != null) 'importer_version': importerVersion,
      if (entityKind != null) 'entity_kind': entityKind,
      if (legacyKey != null) 'legacy_key': legacyKey,
      if (candidateId != null) 'candidate_id': candidateId,
      if (field != null) 'field': field,
      if (mapKey != null) 'map_key': mapKey,
      if (ordinal != null) 'ordinal': ordinal,
      if (valueType != null) 'value_type': valueType,
      if (textValue != null) 'text_value': textValue,
      if (integerValue != null) 'integer_value': integerValue,
      if (numberValue != null) 'number_value': numberValue,
      if (booleanValue != null) 'boolean_value': booleanValue,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SafeLegacyValuesCompanion copyWith({
    Value<String>? datasetId,
    Value<int>? importerVersion,
    Value<String>? entityKind,
    Value<String>? legacyKey,
    Value<String>? candidateId,
    Value<String>? field,
    Value<String>? mapKey,
    Value<int>? ordinal,
    Value<String>? valueType,
    Value<String?>? textValue,
    Value<int?>? integerValue,
    Value<double?>? numberValue,
    Value<int?>? booleanValue,
    Value<int>? rowid,
  }) {
    return SafeLegacyValuesCompanion(
      datasetId: datasetId ?? this.datasetId,
      importerVersion: importerVersion ?? this.importerVersion,
      entityKind: entityKind ?? this.entityKind,
      legacyKey: legacyKey ?? this.legacyKey,
      candidateId: candidateId ?? this.candidateId,
      field: field ?? this.field,
      mapKey: mapKey ?? this.mapKey,
      ordinal: ordinal ?? this.ordinal,
      valueType: valueType ?? this.valueType,
      textValue: textValue ?? this.textValue,
      integerValue: integerValue ?? this.integerValue,
      numberValue: numberValue ?? this.numberValue,
      booleanValue: booleanValue ?? this.booleanValue,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (importerVersion.present) {
      map['importer_version'] = Variable<int>(importerVersion.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (legacyKey.present) {
      map['legacy_key'] = Variable<String>(legacyKey.value);
    }
    if (candidateId.present) {
      map['candidate_id'] = Variable<String>(candidateId.value);
    }
    if (field.present) {
      map['field'] = Variable<String>(field.value);
    }
    if (mapKey.present) {
      map['map_key'] = Variable<String>(mapKey.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (valueType.present) {
      map['value_type'] = Variable<String>(valueType.value);
    }
    if (textValue.present) {
      map['text_value'] = Variable<String>(textValue.value);
    }
    if (integerValue.present) {
      map['integer_value'] = Variable<int>(integerValue.value);
    }
    if (numberValue.present) {
      map['number_value'] = Variable<double>(numberValue.value);
    }
    if (booleanValue.present) {
      map['boolean_value'] = Variable<int>(booleanValue.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SafeLegacyValuesCompanion(')
          ..write('datasetId: $datasetId, ')
          ..write('importerVersion: $importerVersion, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('candidateId: $candidateId, ')
          ..write('field: $field, ')
          ..write('mapKey: $mapKey, ')
          ..write('ordinal: $ordinal, ')
          ..write('valueType: $valueType, ')
          ..write('textValue: $textValue, ')
          ..write('integerValue: $integerValue, ')
          ..write('numberValue: $numberValue, ')
          ..write('booleanValue: $booleanValue, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LegacyIdentityMappings extends Table
    with TableInfo<LegacyIdentityMappings, LegacyIdentityMapping> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LegacyIdentityMappings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _mappingIdMeta = const VerificationMeta(
    'mappingId',
  );
  late final GeneratedColumn<String> mappingId = GeneratedColumn<String>(
    'mapping_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(mapping_id) > 0)',
  );
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES migration_datasets(dataset_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _entityKindMeta = const VerificationMeta(
    'entityKind',
  );
  late final GeneratedColumn<String> entityKind = GeneratedColumn<String>(
    'entity_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (entity_kind IN (\'source\', \'book\', \'shelf\', \'group\'))',
  );
  static const VerificationMeta _legacyKeyMeta = const VerificationMeta(
    'legacyKey',
  );
  late final GeneratedColumn<String> legacyKey = GeneratedColumn<String>(
    'legacy_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _mappingVersionMeta = const VerificationMeta(
    'mappingVersion',
  );
  late final GeneratedColumn<int> mappingVersion = GeneratedColumn<int>(
    'mapping_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (mapping_version > 0)',
  );
  static const VerificationMeta _resolutionMeta = const VerificationMeta(
    'resolution',
  );
  late final GeneratedColumn<String> resolution = GeneratedColumn<String>(
    'resolution',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (resolution IN (\'unresolved\', \'resolved\', \'conflict\'))',
  );
  static const VerificationMeta _sourceByIdNameMeta = const VerificationMeta(
    'sourceByIdName',
  );
  late final GeneratedColumn<String> sourceByIdName = GeneratedColumn<String>(
    'source_by_id_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _bookSourceNameMeta = const VerificationMeta(
    'bookSourceName',
  );
  late final GeneratedColumn<String> bookSourceName = GeneratedColumn<String>(
    'book_source_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _targetSourceIdMeta = const VerificationMeta(
    'targetSourceId',
  );
  late final GeneratedColumn<String> targetSourceId = GeneratedColumn<String>(
    'target_source_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY REFERENCES source_registrations(source_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _targetBookIdMeta = const VerificationMeta(
    'targetBookId',
  );
  late final GeneratedColumn<String> targetBookId = GeneratedColumn<String>(
    'target_book_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY',
  );
  static const VerificationMeta _targetShelfIdMeta = const VerificationMeta(
    'targetShelfId',
  );
  late final GeneratedColumn<String> targetShelfId = GeneratedColumn<String>(
    'target_shelf_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY REFERENCES shelves(shelf_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _targetGroupIdMeta = const VerificationMeta(
    'targetGroupId',
  );
  late final GeneratedColumn<String> targetGroupId = GeneratedColumn<String>(
    'target_group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY REFERENCES manual_groups(group_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  @override
  List<GeneratedColumn> get $columns => [
    mappingId,
    datasetId,
    entityKind,
    legacyKey,
    mappingVersion,
    resolution,
    sourceByIdName,
    bookSourceName,
    targetSourceId,
    targetBookId,
    targetShelfId,
    targetGroupId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_identity_mappings';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyIdentityMapping> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('mapping_id')) {
      context.handle(
        _mappingIdMeta,
        mappingId.isAcceptableOrUnknown(data['mapping_id']!, _mappingIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mappingIdMeta);
    }
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('entity_kind')) {
      context.handle(
        _entityKindMeta,
        entityKind.isAcceptableOrUnknown(data['entity_kind']!, _entityKindMeta),
      );
    } else if (isInserting) {
      context.missing(_entityKindMeta);
    }
    if (data.containsKey('legacy_key')) {
      context.handle(
        _legacyKeyMeta,
        legacyKey.isAcceptableOrUnknown(data['legacy_key']!, _legacyKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_legacyKeyMeta);
    }
    if (data.containsKey('mapping_version')) {
      context.handle(
        _mappingVersionMeta,
        mappingVersion.isAcceptableOrUnknown(
          data['mapping_version']!,
          _mappingVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_mappingVersionMeta);
    }
    if (data.containsKey('resolution')) {
      context.handle(
        _resolutionMeta,
        resolution.isAcceptableOrUnknown(data['resolution']!, _resolutionMeta),
      );
    } else if (isInserting) {
      context.missing(_resolutionMeta);
    }
    if (data.containsKey('source_by_id_name')) {
      context.handle(
        _sourceByIdNameMeta,
        sourceByIdName.isAcceptableOrUnknown(
          data['source_by_id_name']!,
          _sourceByIdNameMeta,
        ),
      );
    }
    if (data.containsKey('book_source_name')) {
      context.handle(
        _bookSourceNameMeta,
        bookSourceName.isAcceptableOrUnknown(
          data['book_source_name']!,
          _bookSourceNameMeta,
        ),
      );
    }
    if (data.containsKey('target_source_id')) {
      context.handle(
        _targetSourceIdMeta,
        targetSourceId.isAcceptableOrUnknown(
          data['target_source_id']!,
          _targetSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('target_book_id')) {
      context.handle(
        _targetBookIdMeta,
        targetBookId.isAcceptableOrUnknown(
          data['target_book_id']!,
          _targetBookIdMeta,
        ),
      );
    }
    if (data.containsKey('target_shelf_id')) {
      context.handle(
        _targetShelfIdMeta,
        targetShelfId.isAcceptableOrUnknown(
          data['target_shelf_id']!,
          _targetShelfIdMeta,
        ),
      );
    }
    if (data.containsKey('target_group_id')) {
      context.handle(
        _targetGroupIdMeta,
        targetGroupId.isAcceptableOrUnknown(
          data['target_group_id']!,
          _targetGroupIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {mappingId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {datasetId, entityKind, legacyKey, mappingVersion},
  ];
  @override
  LegacyIdentityMapping map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyIdentityMapping(
      mappingId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mapping_id'],
      )!,
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      entityKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_kind'],
      )!,
      legacyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_key'],
      )!,
      mappingVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mapping_version'],
      )!,
      resolution: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resolution'],
      )!,
      sourceByIdName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_by_id_name'],
      ),
      bookSourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_source_name'],
      ),
      targetSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_source_id'],
      ),
      targetBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_book_id'],
      ),
      targetShelfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_shelf_id'],
      ),
      targetGroupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_group_id'],
      ),
    );
  }

  @override
  LegacyIdentityMappings createAlias(String alias) {
    return LegacyIdentityMappings(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(dataset_id, entity_kind, legacy_key, mapping_version)',
    'FOREIGN KEY(target_source_id, target_book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
    'CHECK(target_book_id IS NULL OR target_source_id IS NOT NULL)',
    'CHECK(resolution != \'resolved\' OR(entity_kind = \'source\' AND target_source_id IS NOT NULL)OR(entity_kind = \'book\' AND target_source_id IS NOT NULL AND target_book_id IS NOT NULL)OR(entity_kind = \'shelf\' AND target_shelf_id IS NOT NULL)OR(entity_kind = \'group\' AND target_group_id IS NOT NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LegacyIdentityMapping extends DataClass
    implements Insertable<LegacyIdentityMapping> {
  final String mappingId;
  final String datasetId;
  final String entityKind;
  final String legacyKey;
  final int mappingVersion;
  final String resolution;
  final String? sourceByIdName;
  final String? bookSourceName;
  final String? targetSourceId;
  final String? targetBookId;
  final String? targetShelfId;
  final String? targetGroupId;
  const LegacyIdentityMapping({
    required this.mappingId,
    required this.datasetId,
    required this.entityKind,
    required this.legacyKey,
    required this.mappingVersion,
    required this.resolution,
    this.sourceByIdName,
    this.bookSourceName,
    this.targetSourceId,
    this.targetBookId,
    this.targetShelfId,
    this.targetGroupId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['mapping_id'] = Variable<String>(mappingId);
    map['dataset_id'] = Variable<String>(datasetId);
    map['entity_kind'] = Variable<String>(entityKind);
    map['legacy_key'] = Variable<String>(legacyKey);
    map['mapping_version'] = Variable<int>(mappingVersion);
    map['resolution'] = Variable<String>(resolution);
    if (!nullToAbsent || sourceByIdName != null) {
      map['source_by_id_name'] = Variable<String>(sourceByIdName);
    }
    if (!nullToAbsent || bookSourceName != null) {
      map['book_source_name'] = Variable<String>(bookSourceName);
    }
    if (!nullToAbsent || targetSourceId != null) {
      map['target_source_id'] = Variable<String>(targetSourceId);
    }
    if (!nullToAbsent || targetBookId != null) {
      map['target_book_id'] = Variable<String>(targetBookId);
    }
    if (!nullToAbsent || targetShelfId != null) {
      map['target_shelf_id'] = Variable<String>(targetShelfId);
    }
    if (!nullToAbsent || targetGroupId != null) {
      map['target_group_id'] = Variable<String>(targetGroupId);
    }
    return map;
  }

  LegacyIdentityMappingsCompanion toCompanion(bool nullToAbsent) {
    return LegacyIdentityMappingsCompanion(
      mappingId: Value(mappingId),
      datasetId: Value(datasetId),
      entityKind: Value(entityKind),
      legacyKey: Value(legacyKey),
      mappingVersion: Value(mappingVersion),
      resolution: Value(resolution),
      sourceByIdName: sourceByIdName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceByIdName),
      bookSourceName: bookSourceName == null && nullToAbsent
          ? const Value.absent()
          : Value(bookSourceName),
      targetSourceId: targetSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSourceId),
      targetBookId: targetBookId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetBookId),
      targetShelfId: targetShelfId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetShelfId),
      targetGroupId: targetGroupId == null && nullToAbsent
          ? const Value.absent()
          : Value(targetGroupId),
    );
  }

  factory LegacyIdentityMapping.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyIdentityMapping(
      mappingId: serializer.fromJson<String>(json['mapping_id']),
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      entityKind: serializer.fromJson<String>(json['entity_kind']),
      legacyKey: serializer.fromJson<String>(json['legacy_key']),
      mappingVersion: serializer.fromJson<int>(json['mapping_version']),
      resolution: serializer.fromJson<String>(json['resolution']),
      sourceByIdName: serializer.fromJson<String?>(json['source_by_id_name']),
      bookSourceName: serializer.fromJson<String?>(json['book_source_name']),
      targetSourceId: serializer.fromJson<String?>(json['target_source_id']),
      targetBookId: serializer.fromJson<String?>(json['target_book_id']),
      targetShelfId: serializer.fromJson<String?>(json['target_shelf_id']),
      targetGroupId: serializer.fromJson<String?>(json['target_group_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'mapping_id': serializer.toJson<String>(mappingId),
      'dataset_id': serializer.toJson<String>(datasetId),
      'entity_kind': serializer.toJson<String>(entityKind),
      'legacy_key': serializer.toJson<String>(legacyKey),
      'mapping_version': serializer.toJson<int>(mappingVersion),
      'resolution': serializer.toJson<String>(resolution),
      'source_by_id_name': serializer.toJson<String?>(sourceByIdName),
      'book_source_name': serializer.toJson<String?>(bookSourceName),
      'target_source_id': serializer.toJson<String?>(targetSourceId),
      'target_book_id': serializer.toJson<String?>(targetBookId),
      'target_shelf_id': serializer.toJson<String?>(targetShelfId),
      'target_group_id': serializer.toJson<String?>(targetGroupId),
    };
  }

  LegacyIdentityMapping copyWith({
    String? mappingId,
    String? datasetId,
    String? entityKind,
    String? legacyKey,
    int? mappingVersion,
    String? resolution,
    Value<String?> sourceByIdName = const Value.absent(),
    Value<String?> bookSourceName = const Value.absent(),
    Value<String?> targetSourceId = const Value.absent(),
    Value<String?> targetBookId = const Value.absent(),
    Value<String?> targetShelfId = const Value.absent(),
    Value<String?> targetGroupId = const Value.absent(),
  }) => LegacyIdentityMapping(
    mappingId: mappingId ?? this.mappingId,
    datasetId: datasetId ?? this.datasetId,
    entityKind: entityKind ?? this.entityKind,
    legacyKey: legacyKey ?? this.legacyKey,
    mappingVersion: mappingVersion ?? this.mappingVersion,
    resolution: resolution ?? this.resolution,
    sourceByIdName: sourceByIdName.present
        ? sourceByIdName.value
        : this.sourceByIdName,
    bookSourceName: bookSourceName.present
        ? bookSourceName.value
        : this.bookSourceName,
    targetSourceId: targetSourceId.present
        ? targetSourceId.value
        : this.targetSourceId,
    targetBookId: targetBookId.present ? targetBookId.value : this.targetBookId,
    targetShelfId: targetShelfId.present
        ? targetShelfId.value
        : this.targetShelfId,
    targetGroupId: targetGroupId.present
        ? targetGroupId.value
        : this.targetGroupId,
  );
  LegacyIdentityMapping copyWithCompanion(
    LegacyIdentityMappingsCompanion data,
  ) {
    return LegacyIdentityMapping(
      mappingId: data.mappingId.present ? data.mappingId.value : this.mappingId,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      entityKind: data.entityKind.present
          ? data.entityKind.value
          : this.entityKind,
      legacyKey: data.legacyKey.present ? data.legacyKey.value : this.legacyKey,
      mappingVersion: data.mappingVersion.present
          ? data.mappingVersion.value
          : this.mappingVersion,
      resolution: data.resolution.present
          ? data.resolution.value
          : this.resolution,
      sourceByIdName: data.sourceByIdName.present
          ? data.sourceByIdName.value
          : this.sourceByIdName,
      bookSourceName: data.bookSourceName.present
          ? data.bookSourceName.value
          : this.bookSourceName,
      targetSourceId: data.targetSourceId.present
          ? data.targetSourceId.value
          : this.targetSourceId,
      targetBookId: data.targetBookId.present
          ? data.targetBookId.value
          : this.targetBookId,
      targetShelfId: data.targetShelfId.present
          ? data.targetShelfId.value
          : this.targetShelfId,
      targetGroupId: data.targetGroupId.present
          ? data.targetGroupId.value
          : this.targetGroupId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyIdentityMapping(')
          ..write('mappingId: $mappingId, ')
          ..write('datasetId: $datasetId, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('mappingVersion: $mappingVersion, ')
          ..write('resolution: $resolution, ')
          ..write('sourceByIdName: $sourceByIdName, ')
          ..write('bookSourceName: $bookSourceName, ')
          ..write('targetSourceId: $targetSourceId, ')
          ..write('targetBookId: $targetBookId, ')
          ..write('targetShelfId: $targetShelfId, ')
          ..write('targetGroupId: $targetGroupId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    mappingId,
    datasetId,
    entityKind,
    legacyKey,
    mappingVersion,
    resolution,
    sourceByIdName,
    bookSourceName,
    targetSourceId,
    targetBookId,
    targetShelfId,
    targetGroupId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyIdentityMapping &&
          other.mappingId == this.mappingId &&
          other.datasetId == this.datasetId &&
          other.entityKind == this.entityKind &&
          other.legacyKey == this.legacyKey &&
          other.mappingVersion == this.mappingVersion &&
          other.resolution == this.resolution &&
          other.sourceByIdName == this.sourceByIdName &&
          other.bookSourceName == this.bookSourceName &&
          other.targetSourceId == this.targetSourceId &&
          other.targetBookId == this.targetBookId &&
          other.targetShelfId == this.targetShelfId &&
          other.targetGroupId == this.targetGroupId);
}

class LegacyIdentityMappingsCompanion
    extends UpdateCompanion<LegacyIdentityMapping> {
  final Value<String> mappingId;
  final Value<String> datasetId;
  final Value<String> entityKind;
  final Value<String> legacyKey;
  final Value<int> mappingVersion;
  final Value<String> resolution;
  final Value<String?> sourceByIdName;
  final Value<String?> bookSourceName;
  final Value<String?> targetSourceId;
  final Value<String?> targetBookId;
  final Value<String?> targetShelfId;
  final Value<String?> targetGroupId;
  final Value<int> rowid;
  const LegacyIdentityMappingsCompanion({
    this.mappingId = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.entityKind = const Value.absent(),
    this.legacyKey = const Value.absent(),
    this.mappingVersion = const Value.absent(),
    this.resolution = const Value.absent(),
    this.sourceByIdName = const Value.absent(),
    this.bookSourceName = const Value.absent(),
    this.targetSourceId = const Value.absent(),
    this.targetBookId = const Value.absent(),
    this.targetShelfId = const Value.absent(),
    this.targetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyIdentityMappingsCompanion.insert({
    required String mappingId,
    required String datasetId,
    required String entityKind,
    required String legacyKey,
    required int mappingVersion,
    required String resolution,
    this.sourceByIdName = const Value.absent(),
    this.bookSourceName = const Value.absent(),
    this.targetSourceId = const Value.absent(),
    this.targetBookId = const Value.absent(),
    this.targetShelfId = const Value.absent(),
    this.targetGroupId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : mappingId = Value(mappingId),
       datasetId = Value(datasetId),
       entityKind = Value(entityKind),
       legacyKey = Value(legacyKey),
       mappingVersion = Value(mappingVersion),
       resolution = Value(resolution);
  static Insertable<LegacyIdentityMapping> custom({
    Expression<String>? mappingId,
    Expression<String>? datasetId,
    Expression<String>? entityKind,
    Expression<String>? legacyKey,
    Expression<int>? mappingVersion,
    Expression<String>? resolution,
    Expression<String>? sourceByIdName,
    Expression<String>? bookSourceName,
    Expression<String>? targetSourceId,
    Expression<String>? targetBookId,
    Expression<String>? targetShelfId,
    Expression<String>? targetGroupId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (mappingId != null) 'mapping_id': mappingId,
      if (datasetId != null) 'dataset_id': datasetId,
      if (entityKind != null) 'entity_kind': entityKind,
      if (legacyKey != null) 'legacy_key': legacyKey,
      if (mappingVersion != null) 'mapping_version': mappingVersion,
      if (resolution != null) 'resolution': resolution,
      if (sourceByIdName != null) 'source_by_id_name': sourceByIdName,
      if (bookSourceName != null) 'book_source_name': bookSourceName,
      if (targetSourceId != null) 'target_source_id': targetSourceId,
      if (targetBookId != null) 'target_book_id': targetBookId,
      if (targetShelfId != null) 'target_shelf_id': targetShelfId,
      if (targetGroupId != null) 'target_group_id': targetGroupId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyIdentityMappingsCompanion copyWith({
    Value<String>? mappingId,
    Value<String>? datasetId,
    Value<String>? entityKind,
    Value<String>? legacyKey,
    Value<int>? mappingVersion,
    Value<String>? resolution,
    Value<String?>? sourceByIdName,
    Value<String?>? bookSourceName,
    Value<String?>? targetSourceId,
    Value<String?>? targetBookId,
    Value<String?>? targetShelfId,
    Value<String?>? targetGroupId,
    Value<int>? rowid,
  }) {
    return LegacyIdentityMappingsCompanion(
      mappingId: mappingId ?? this.mappingId,
      datasetId: datasetId ?? this.datasetId,
      entityKind: entityKind ?? this.entityKind,
      legacyKey: legacyKey ?? this.legacyKey,
      mappingVersion: mappingVersion ?? this.mappingVersion,
      resolution: resolution ?? this.resolution,
      sourceByIdName: sourceByIdName ?? this.sourceByIdName,
      bookSourceName: bookSourceName ?? this.bookSourceName,
      targetSourceId: targetSourceId ?? this.targetSourceId,
      targetBookId: targetBookId ?? this.targetBookId,
      targetShelfId: targetShelfId ?? this.targetShelfId,
      targetGroupId: targetGroupId ?? this.targetGroupId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (mappingId.present) {
      map['mapping_id'] = Variable<String>(mappingId.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (entityKind.present) {
      map['entity_kind'] = Variable<String>(entityKind.value);
    }
    if (legacyKey.present) {
      map['legacy_key'] = Variable<String>(legacyKey.value);
    }
    if (mappingVersion.present) {
      map['mapping_version'] = Variable<int>(mappingVersion.value);
    }
    if (resolution.present) {
      map['resolution'] = Variable<String>(resolution.value);
    }
    if (sourceByIdName.present) {
      map['source_by_id_name'] = Variable<String>(sourceByIdName.value);
    }
    if (bookSourceName.present) {
      map['book_source_name'] = Variable<String>(bookSourceName.value);
    }
    if (targetSourceId.present) {
      map['target_source_id'] = Variable<String>(targetSourceId.value);
    }
    if (targetBookId.present) {
      map['target_book_id'] = Variable<String>(targetBookId.value);
    }
    if (targetShelfId.present) {
      map['target_shelf_id'] = Variable<String>(targetShelfId.value);
    }
    if (targetGroupId.present) {
      map['target_group_id'] = Variable<String>(targetGroupId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyIdentityMappingsCompanion(')
          ..write('mappingId: $mappingId, ')
          ..write('datasetId: $datasetId, ')
          ..write('entityKind: $entityKind, ')
          ..write('legacyKey: $legacyKey, ')
          ..write('mappingVersion: $mappingVersion, ')
          ..write('resolution: $resolution, ')
          ..write('sourceByIdName: $sourceByIdName, ')
          ..write('bookSourceName: $bookSourceName, ')
          ..write('targetSourceId: $targetSourceId, ')
          ..write('targetBookId: $targetBookId, ')
          ..write('targetShelfId: $targetShelfId, ')
          ..write('targetGroupId: $targetGroupId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class LegacyChapterLocators extends Table
    with TableInfo<LegacyChapterLocators, LegacyChapterLocator> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LegacyChapterLocators(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _locatorIdMeta = const VerificationMeta(
    'locatorId',
  );
  late final GeneratedColumn<String> locatorId = GeneratedColumn<String>(
    'locator_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL PRIMARY KEY COLLATE BINARY CHECK (length(locator_id) > 0)',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _datasetIdMeta = const VerificationMeta(
    'datasetId',
  );
  late final GeneratedColumn<String> datasetId = GeneratedColumn<String>(
    'dataset_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY REFERENCES migration_datasets(dataset_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _legacyBookIdMeta = const VerificationMeta(
    'legacyBookId',
  );
  late final GeneratedColumn<String> legacyBookId = GeneratedColumn<String>(
    'legacy_book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL COLLATE BINARY CHECK (length(legacy_book_id) > 0)',
  );
  static const VerificationMeta _chapterIndexMeta = const VerificationMeta(
    'chapterIndex',
  );
  late final GeneratedColumn<int> chapterIndex = GeneratedColumn<int>(
    'chapter_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (chapter_index >= 0)',
  );
  static const VerificationMeta _rawOffsetKeyMeta = const VerificationMeta(
    'rawOffsetKey',
  );
  late final GeneratedColumn<String> rawOffsetKey = GeneratedColumn<String>(
    'raw_offset_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fractionMeta = const VerificationMeta(
    'fraction',
  );
  late final GeneratedColumn<double> fraction = GeneratedColumn<double>(
    'fraction',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (fraction IS NULL OR fraction BETWEEN 0 AND 1)',
  );
  static const VerificationMeta _remoteIdEvidenceMeta = const VerificationMeta(
    'remoteIdEvidence',
  );
  late final GeneratedColumn<String> remoteIdEvidence = GeneratedColumn<String>(
    'remote_id_evidence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _chapterTitleEvidenceMeta =
      const VerificationMeta('chapterTitleEvidence');
  late final GeneratedColumn<String> chapterTitleEvidence =
      GeneratedColumn<String>(
        'chapter_title_evidence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _volumeTitleEvidenceMeta =
      const VerificationMeta('volumeTitleEvidence');
  late final GeneratedColumn<String> volumeTitleEvidence =
      GeneratedColumn<String>(
        'volume_title_evidence',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _catalogDigestMeta = const VerificationMeta(
    'catalogDigest',
  );
  late final GeneratedColumn<String> catalogDigest = GeneratedColumn<String>(
    'catalog_digest',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    locatorId,
    version,
    datasetId,
    sourceId,
    bookId,
    legacyBookId,
    chapterIndex,
    rawOffsetKey,
    fraction,
    remoteIdEvidence,
    chapterTitleEvidence,
    volumeTitleEvidence,
    catalogDigest,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'legacy_chapter_locators';
  @override
  VerificationContext validateIntegrity(
    Insertable<LegacyChapterLocator> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('locator_id')) {
      context.handle(
        _locatorIdMeta,
        locatorId.isAcceptableOrUnknown(data['locator_id']!, _locatorIdMeta),
      );
    } else if (isInserting) {
      context.missing(_locatorIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('dataset_id')) {
      context.handle(
        _datasetIdMeta,
        datasetId.isAcceptableOrUnknown(data['dataset_id']!, _datasetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_datasetIdMeta);
    }
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('legacy_book_id')) {
      context.handle(
        _legacyBookIdMeta,
        legacyBookId.isAcceptableOrUnknown(
          data['legacy_book_id']!,
          _legacyBookIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_legacyBookIdMeta);
    }
    if (data.containsKey('chapter_index')) {
      context.handle(
        _chapterIndexMeta,
        chapterIndex.isAcceptableOrUnknown(
          data['chapter_index']!,
          _chapterIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_chapterIndexMeta);
    }
    if (data.containsKey('raw_offset_key')) {
      context.handle(
        _rawOffsetKeyMeta,
        rawOffsetKey.isAcceptableOrUnknown(
          data['raw_offset_key']!,
          _rawOffsetKeyMeta,
        ),
      );
    }
    if (data.containsKey('fraction')) {
      context.handle(
        _fractionMeta,
        fraction.isAcceptableOrUnknown(data['fraction']!, _fractionMeta),
      );
    }
    if (data.containsKey('remote_id_evidence')) {
      context.handle(
        _remoteIdEvidenceMeta,
        remoteIdEvidence.isAcceptableOrUnknown(
          data['remote_id_evidence']!,
          _remoteIdEvidenceMeta,
        ),
      );
    }
    if (data.containsKey('chapter_title_evidence')) {
      context.handle(
        _chapterTitleEvidenceMeta,
        chapterTitleEvidence.isAcceptableOrUnknown(
          data['chapter_title_evidence']!,
          _chapterTitleEvidenceMeta,
        ),
      );
    }
    if (data.containsKey('volume_title_evidence')) {
      context.handle(
        _volumeTitleEvidenceMeta,
        volumeTitleEvidence.isAcceptableOrUnknown(
          data['volume_title_evidence']!,
          _volumeTitleEvidenceMeta,
        ),
      );
    }
    if (data.containsKey('catalog_digest')) {
      context.handle(
        _catalogDigestMeta,
        catalogDigest.isAcceptableOrUnknown(
          data['catalog_digest']!,
          _catalogDigestMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {locatorId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {sourceId, bookId, locatorId},
  ];
  @override
  LegacyChapterLocator map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LegacyChapterLocator(
      locatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}locator_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      datasetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dataset_id'],
      )!,
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      legacyBookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_book_id'],
      )!,
      chapterIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter_index'],
      )!,
      rawOffsetKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_offset_key'],
      ),
      fraction: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fraction'],
      ),
      remoteIdEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_id_evidence'],
      ),
      chapterTitleEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_title_evidence'],
      ),
      volumeTitleEvidence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}volume_title_evidence'],
      ),
      catalogDigest: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_digest'],
      ),
    );
  }

  @override
  LegacyChapterLocators createAlias(String alias) {
    return LegacyChapterLocators(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(source_id, book_id, locator_id)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LegacyChapterLocator extends DataClass
    implements Insertable<LegacyChapterLocator> {
  final String locatorId;
  final int version;
  final String datasetId;
  final String sourceId;
  final String bookId;
  final String legacyBookId;
  final int chapterIndex;
  final String? rawOffsetKey;
  final double? fraction;
  final String? remoteIdEvidence;
  final String? chapterTitleEvidence;
  final String? volumeTitleEvidence;
  final String? catalogDigest;
  const LegacyChapterLocator({
    required this.locatorId,
    required this.version,
    required this.datasetId,
    required this.sourceId,
    required this.bookId,
    required this.legacyBookId,
    required this.chapterIndex,
    this.rawOffsetKey,
    this.fraction,
    this.remoteIdEvidence,
    this.chapterTitleEvidence,
    this.volumeTitleEvidence,
    this.catalogDigest,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['locator_id'] = Variable<String>(locatorId);
    map['version'] = Variable<int>(version);
    map['dataset_id'] = Variable<String>(datasetId);
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['legacy_book_id'] = Variable<String>(legacyBookId);
    map['chapter_index'] = Variable<int>(chapterIndex);
    if (!nullToAbsent || rawOffsetKey != null) {
      map['raw_offset_key'] = Variable<String>(rawOffsetKey);
    }
    if (!nullToAbsent || fraction != null) {
      map['fraction'] = Variable<double>(fraction);
    }
    if (!nullToAbsent || remoteIdEvidence != null) {
      map['remote_id_evidence'] = Variable<String>(remoteIdEvidence);
    }
    if (!nullToAbsent || chapterTitleEvidence != null) {
      map['chapter_title_evidence'] = Variable<String>(chapterTitleEvidence);
    }
    if (!nullToAbsent || volumeTitleEvidence != null) {
      map['volume_title_evidence'] = Variable<String>(volumeTitleEvidence);
    }
    if (!nullToAbsent || catalogDigest != null) {
      map['catalog_digest'] = Variable<String>(catalogDigest);
    }
    return map;
  }

  LegacyChapterLocatorsCompanion toCompanion(bool nullToAbsent) {
    return LegacyChapterLocatorsCompanion(
      locatorId: Value(locatorId),
      version: Value(version),
      datasetId: Value(datasetId),
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      legacyBookId: Value(legacyBookId),
      chapterIndex: Value(chapterIndex),
      rawOffsetKey: rawOffsetKey == null && nullToAbsent
          ? const Value.absent()
          : Value(rawOffsetKey),
      fraction: fraction == null && nullToAbsent
          ? const Value.absent()
          : Value(fraction),
      remoteIdEvidence: remoteIdEvidence == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteIdEvidence),
      chapterTitleEvidence: chapterTitleEvidence == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterTitleEvidence),
      volumeTitleEvidence: volumeTitleEvidence == null && nullToAbsent
          ? const Value.absent()
          : Value(volumeTitleEvidence),
      catalogDigest: catalogDigest == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogDigest),
    );
  }

  factory LegacyChapterLocator.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LegacyChapterLocator(
      locatorId: serializer.fromJson<String>(json['locator_id']),
      version: serializer.fromJson<int>(json['version']),
      datasetId: serializer.fromJson<String>(json['dataset_id']),
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      legacyBookId: serializer.fromJson<String>(json['legacy_book_id']),
      chapterIndex: serializer.fromJson<int>(json['chapter_index']),
      rawOffsetKey: serializer.fromJson<String?>(json['raw_offset_key']),
      fraction: serializer.fromJson<double?>(json['fraction']),
      remoteIdEvidence: serializer.fromJson<String?>(
        json['remote_id_evidence'],
      ),
      chapterTitleEvidence: serializer.fromJson<String?>(
        json['chapter_title_evidence'],
      ),
      volumeTitleEvidence: serializer.fromJson<String?>(
        json['volume_title_evidence'],
      ),
      catalogDigest: serializer.fromJson<String?>(json['catalog_digest']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'locator_id': serializer.toJson<String>(locatorId),
      'version': serializer.toJson<int>(version),
      'dataset_id': serializer.toJson<String>(datasetId),
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'legacy_book_id': serializer.toJson<String>(legacyBookId),
      'chapter_index': serializer.toJson<int>(chapterIndex),
      'raw_offset_key': serializer.toJson<String?>(rawOffsetKey),
      'fraction': serializer.toJson<double?>(fraction),
      'remote_id_evidence': serializer.toJson<String?>(remoteIdEvidence),
      'chapter_title_evidence': serializer.toJson<String?>(
        chapterTitleEvidence,
      ),
      'volume_title_evidence': serializer.toJson<String?>(volumeTitleEvidence),
      'catalog_digest': serializer.toJson<String?>(catalogDigest),
    };
  }

  LegacyChapterLocator copyWith({
    String? locatorId,
    int? version,
    String? datasetId,
    String? sourceId,
    String? bookId,
    String? legacyBookId,
    int? chapterIndex,
    Value<String?> rawOffsetKey = const Value.absent(),
    Value<double?> fraction = const Value.absent(),
    Value<String?> remoteIdEvidence = const Value.absent(),
    Value<String?> chapterTitleEvidence = const Value.absent(),
    Value<String?> volumeTitleEvidence = const Value.absent(),
    Value<String?> catalogDigest = const Value.absent(),
  }) => LegacyChapterLocator(
    locatorId: locatorId ?? this.locatorId,
    version: version ?? this.version,
    datasetId: datasetId ?? this.datasetId,
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    legacyBookId: legacyBookId ?? this.legacyBookId,
    chapterIndex: chapterIndex ?? this.chapterIndex,
    rawOffsetKey: rawOffsetKey.present ? rawOffsetKey.value : this.rawOffsetKey,
    fraction: fraction.present ? fraction.value : this.fraction,
    remoteIdEvidence: remoteIdEvidence.present
        ? remoteIdEvidence.value
        : this.remoteIdEvidence,
    chapterTitleEvidence: chapterTitleEvidence.present
        ? chapterTitleEvidence.value
        : this.chapterTitleEvidence,
    volumeTitleEvidence: volumeTitleEvidence.present
        ? volumeTitleEvidence.value
        : this.volumeTitleEvidence,
    catalogDigest: catalogDigest.present
        ? catalogDigest.value
        : this.catalogDigest,
  );
  LegacyChapterLocator copyWithCompanion(LegacyChapterLocatorsCompanion data) {
    return LegacyChapterLocator(
      locatorId: data.locatorId.present ? data.locatorId.value : this.locatorId,
      version: data.version.present ? data.version.value : this.version,
      datasetId: data.datasetId.present ? data.datasetId.value : this.datasetId,
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      legacyBookId: data.legacyBookId.present
          ? data.legacyBookId.value
          : this.legacyBookId,
      chapterIndex: data.chapterIndex.present
          ? data.chapterIndex.value
          : this.chapterIndex,
      rawOffsetKey: data.rawOffsetKey.present
          ? data.rawOffsetKey.value
          : this.rawOffsetKey,
      fraction: data.fraction.present ? data.fraction.value : this.fraction,
      remoteIdEvidence: data.remoteIdEvidence.present
          ? data.remoteIdEvidence.value
          : this.remoteIdEvidence,
      chapterTitleEvidence: data.chapterTitleEvidence.present
          ? data.chapterTitleEvidence.value
          : this.chapterTitleEvidence,
      volumeTitleEvidence: data.volumeTitleEvidence.present
          ? data.volumeTitleEvidence.value
          : this.volumeTitleEvidence,
      catalogDigest: data.catalogDigest.present
          ? data.catalogDigest.value
          : this.catalogDigest,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LegacyChapterLocator(')
          ..write('locatorId: $locatorId, ')
          ..write('version: $version, ')
          ..write('datasetId: $datasetId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('legacyBookId: $legacyBookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('rawOffsetKey: $rawOffsetKey, ')
          ..write('fraction: $fraction, ')
          ..write('remoteIdEvidence: $remoteIdEvidence, ')
          ..write('chapterTitleEvidence: $chapterTitleEvidence, ')
          ..write('volumeTitleEvidence: $volumeTitleEvidence, ')
          ..write('catalogDigest: $catalogDigest')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    locatorId,
    version,
    datasetId,
    sourceId,
    bookId,
    legacyBookId,
    chapterIndex,
    rawOffsetKey,
    fraction,
    remoteIdEvidence,
    chapterTitleEvidence,
    volumeTitleEvidence,
    catalogDigest,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LegacyChapterLocator &&
          other.locatorId == this.locatorId &&
          other.version == this.version &&
          other.datasetId == this.datasetId &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.legacyBookId == this.legacyBookId &&
          other.chapterIndex == this.chapterIndex &&
          other.rawOffsetKey == this.rawOffsetKey &&
          other.fraction == this.fraction &&
          other.remoteIdEvidence == this.remoteIdEvidence &&
          other.chapterTitleEvidence == this.chapterTitleEvidence &&
          other.volumeTitleEvidence == this.volumeTitleEvidence &&
          other.catalogDigest == this.catalogDigest);
}

class LegacyChapterLocatorsCompanion
    extends UpdateCompanion<LegacyChapterLocator> {
  final Value<String> locatorId;
  final Value<int> version;
  final Value<String> datasetId;
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<String> legacyBookId;
  final Value<int> chapterIndex;
  final Value<String?> rawOffsetKey;
  final Value<double?> fraction;
  final Value<String?> remoteIdEvidence;
  final Value<String?> chapterTitleEvidence;
  final Value<String?> volumeTitleEvidence;
  final Value<String?> catalogDigest;
  final Value<int> rowid;
  const LegacyChapterLocatorsCompanion({
    this.locatorId = const Value.absent(),
    this.version = const Value.absent(),
    this.datasetId = const Value.absent(),
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.legacyBookId = const Value.absent(),
    this.chapterIndex = const Value.absent(),
    this.rawOffsetKey = const Value.absent(),
    this.fraction = const Value.absent(),
    this.remoteIdEvidence = const Value.absent(),
    this.chapterTitleEvidence = const Value.absent(),
    this.volumeTitleEvidence = const Value.absent(),
    this.catalogDigest = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LegacyChapterLocatorsCompanion.insert({
    required String locatorId,
    this.version = const Value.absent(),
    required String datasetId,
    required String sourceId,
    required String bookId,
    required String legacyBookId,
    required int chapterIndex,
    this.rawOffsetKey = const Value.absent(),
    this.fraction = const Value.absent(),
    this.remoteIdEvidence = const Value.absent(),
    this.chapterTitleEvidence = const Value.absent(),
    this.volumeTitleEvidence = const Value.absent(),
    this.catalogDigest = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : locatorId = Value(locatorId),
       datasetId = Value(datasetId),
       sourceId = Value(sourceId),
       bookId = Value(bookId),
       legacyBookId = Value(legacyBookId),
       chapterIndex = Value(chapterIndex);
  static Insertable<LegacyChapterLocator> custom({
    Expression<String>? locatorId,
    Expression<int>? version,
    Expression<String>? datasetId,
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<String>? legacyBookId,
    Expression<int>? chapterIndex,
    Expression<String>? rawOffsetKey,
    Expression<double>? fraction,
    Expression<String>? remoteIdEvidence,
    Expression<String>? chapterTitleEvidence,
    Expression<String>? volumeTitleEvidence,
    Expression<String>? catalogDigest,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (locatorId != null) 'locator_id': locatorId,
      if (version != null) 'version': version,
      if (datasetId != null) 'dataset_id': datasetId,
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (legacyBookId != null) 'legacy_book_id': legacyBookId,
      if (chapterIndex != null) 'chapter_index': chapterIndex,
      if (rawOffsetKey != null) 'raw_offset_key': rawOffsetKey,
      if (fraction != null) 'fraction': fraction,
      if (remoteIdEvidence != null) 'remote_id_evidence': remoteIdEvidence,
      if (chapterTitleEvidence != null)
        'chapter_title_evidence': chapterTitleEvidence,
      if (volumeTitleEvidence != null)
        'volume_title_evidence': volumeTitleEvidence,
      if (catalogDigest != null) 'catalog_digest': catalogDigest,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LegacyChapterLocatorsCompanion copyWith({
    Value<String>? locatorId,
    Value<int>? version,
    Value<String>? datasetId,
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<String>? legacyBookId,
    Value<int>? chapterIndex,
    Value<String?>? rawOffsetKey,
    Value<double?>? fraction,
    Value<String?>? remoteIdEvidence,
    Value<String?>? chapterTitleEvidence,
    Value<String?>? volumeTitleEvidence,
    Value<String?>? catalogDigest,
    Value<int>? rowid,
  }) {
    return LegacyChapterLocatorsCompanion(
      locatorId: locatorId ?? this.locatorId,
      version: version ?? this.version,
      datasetId: datasetId ?? this.datasetId,
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      legacyBookId: legacyBookId ?? this.legacyBookId,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      rawOffsetKey: rawOffsetKey ?? this.rawOffsetKey,
      fraction: fraction ?? this.fraction,
      remoteIdEvidence: remoteIdEvidence ?? this.remoteIdEvidence,
      chapterTitleEvidence: chapterTitleEvidence ?? this.chapterTitleEvidence,
      volumeTitleEvidence: volumeTitleEvidence ?? this.volumeTitleEvidence,
      catalogDigest: catalogDigest ?? this.catalogDigest,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (locatorId.present) {
      map['locator_id'] = Variable<String>(locatorId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (datasetId.present) {
      map['dataset_id'] = Variable<String>(datasetId.value);
    }
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (legacyBookId.present) {
      map['legacy_book_id'] = Variable<String>(legacyBookId.value);
    }
    if (chapterIndex.present) {
      map['chapter_index'] = Variable<int>(chapterIndex.value);
    }
    if (rawOffsetKey.present) {
      map['raw_offset_key'] = Variable<String>(rawOffsetKey.value);
    }
    if (fraction.present) {
      map['fraction'] = Variable<double>(fraction.value);
    }
    if (remoteIdEvidence.present) {
      map['remote_id_evidence'] = Variable<String>(remoteIdEvidence.value);
    }
    if (chapterTitleEvidence.present) {
      map['chapter_title_evidence'] = Variable<String>(
        chapterTitleEvidence.value,
      );
    }
    if (volumeTitleEvidence.present) {
      map['volume_title_evidence'] = Variable<String>(
        volumeTitleEvidence.value,
      );
    }
    if (catalogDigest.present) {
      map['catalog_digest'] = Variable<String>(catalogDigest.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LegacyChapterLocatorsCompanion(')
          ..write('locatorId: $locatorId, ')
          ..write('version: $version, ')
          ..write('datasetId: $datasetId, ')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('legacyBookId: $legacyBookId, ')
          ..write('chapterIndex: $chapterIndex, ')
          ..write('rawOffsetKey: $rawOffsetKey, ')
          ..write('fraction: $fraction, ')
          ..write('remoteIdEvidence: $remoteIdEvidence, ')
          ..write('chapterTitleEvidence: $chapterTitleEvidence, ')
          ..write('volumeTitleEvidence: $volumeTitleEvidence, ')
          ..write('catalogDigest: $catalogDigest, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReadingProgress extends Table
    with TableInfo<ReadingProgress, ReadingProgressData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReadingProgress(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sourceIdMeta = const VerificationMeta(
    'sourceId',
  );
  late final GeneratedColumn<String> sourceId = GeneratedColumn<String>(
    'source_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _bookIdMeta = const VerificationMeta('bookId');
  late final GeneratedColumn<String> bookId = GeneratedColumn<String>(
    'book_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL COLLATE BINARY',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _hasReadMeta = const VerificationMeta(
    'hasRead',
  );
  late final GeneratedColumn<int> hasRead = GeneratedColumn<int>(
    'has_read',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (has_read IN (0, 1))',
  );
  static const VerificationMeta _chapterIdMeta = const VerificationMeta(
    'chapterId',
  );
  late final GeneratedColumn<String> chapterId = GeneratedColumn<String>(
    'chapter_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY CHECK (chapter_id IS NULL OR(length(chapter_id) > 0 AND instr(chapter_id, char(0)) = 0))',
  );
  static const VerificationMeta _legacyLocatorIdMeta = const VerificationMeta(
    'legacyLocatorId',
  );
  late final GeneratedColumn<String> legacyLocatorId = GeneratedColumn<String>(
    'legacy_locator_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY',
  );
  static const VerificationMeta _lastReadAtMeta = const VerificationMeta(
    'lastReadAt',
  );
  late final GeneratedColumn<String> lastReadAt = GeneratedColumn<String>(
    'last_read_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (last_read_at IS NULL OR(last_read_at GLOB \'????-??-??T??:??:??.*Z\' AND julianday(last_read_at) IS NOT NULL))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    sourceId,
    bookId,
    version,
    hasRead,
    chapterId,
    legacyLocatorId,
    lastReadAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reading_progress';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReadingProgressData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('source_id')) {
      context.handle(
        _sourceIdMeta,
        sourceId.isAcceptableOrUnknown(data['source_id']!, _sourceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceIdMeta);
    }
    if (data.containsKey('book_id')) {
      context.handle(
        _bookIdMeta,
        bookId.isAcceptableOrUnknown(data['book_id']!, _bookIdMeta),
      );
    } else if (isInserting) {
      context.missing(_bookIdMeta);
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('has_read')) {
      context.handle(
        _hasReadMeta,
        hasRead.isAcceptableOrUnknown(data['has_read']!, _hasReadMeta),
      );
    } else if (isInserting) {
      context.missing(_hasReadMeta);
    }
    if (data.containsKey('chapter_id')) {
      context.handle(
        _chapterIdMeta,
        chapterId.isAcceptableOrUnknown(data['chapter_id']!, _chapterIdMeta),
      );
    }
    if (data.containsKey('legacy_locator_id')) {
      context.handle(
        _legacyLocatorIdMeta,
        legacyLocatorId.isAcceptableOrUnknown(
          data['legacy_locator_id']!,
          _legacyLocatorIdMeta,
        ),
      );
    }
    if (data.containsKey('last_read_at')) {
      context.handle(
        _lastReadAtMeta,
        lastReadAt.isAcceptableOrUnknown(
          data['last_read_at']!,
          _lastReadAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sourceId, bookId};
  @override
  ReadingProgressData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReadingProgressData(
      sourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_id'],
      )!,
      bookId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_id'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      hasRead: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}has_read'],
      )!,
      chapterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}chapter_id'],
      ),
      legacyLocatorId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_locator_id'],
      ),
      lastReadAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_read_at'],
      ),
    );
  }

  @override
  ReadingProgress createAlias(String alias) {
    return ReadingProgress(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(source_id, book_id)',
    'FOREIGN KEY(source_id, book_id)REFERENCES library_entries(source_id, book_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
    'FOREIGN KEY(source_id, book_id, legacy_locator_id)REFERENCES legacy_chapter_locators(source_id, book_id, locator_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ReadingProgressData extends DataClass
    implements Insertable<ReadingProgressData> {
  final String sourceId;
  final String bookId;
  final int version;
  final int hasRead;
  final String? chapterId;
  final String? legacyLocatorId;
  final String? lastReadAt;
  const ReadingProgressData({
    required this.sourceId,
    required this.bookId,
    required this.version,
    required this.hasRead,
    this.chapterId,
    this.legacyLocatorId,
    this.lastReadAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source_id'] = Variable<String>(sourceId);
    map['book_id'] = Variable<String>(bookId);
    map['version'] = Variable<int>(version);
    map['has_read'] = Variable<int>(hasRead);
    if (!nullToAbsent || chapterId != null) {
      map['chapter_id'] = Variable<String>(chapterId);
    }
    if (!nullToAbsent || legacyLocatorId != null) {
      map['legacy_locator_id'] = Variable<String>(legacyLocatorId);
    }
    if (!nullToAbsent || lastReadAt != null) {
      map['last_read_at'] = Variable<String>(lastReadAt);
    }
    return map;
  }

  ReadingProgressCompanion toCompanion(bool nullToAbsent) {
    return ReadingProgressCompanion(
      sourceId: Value(sourceId),
      bookId: Value(bookId),
      version: Value(version),
      hasRead: Value(hasRead),
      chapterId: chapterId == null && nullToAbsent
          ? const Value.absent()
          : Value(chapterId),
      legacyLocatorId: legacyLocatorId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyLocatorId),
      lastReadAt: lastReadAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReadAt),
    );
  }

  factory ReadingProgressData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReadingProgressData(
      sourceId: serializer.fromJson<String>(json['source_id']),
      bookId: serializer.fromJson<String>(json['book_id']),
      version: serializer.fromJson<int>(json['version']),
      hasRead: serializer.fromJson<int>(json['has_read']),
      chapterId: serializer.fromJson<String?>(json['chapter_id']),
      legacyLocatorId: serializer.fromJson<String?>(json['legacy_locator_id']),
      lastReadAt: serializer.fromJson<String?>(json['last_read_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source_id': serializer.toJson<String>(sourceId),
      'book_id': serializer.toJson<String>(bookId),
      'version': serializer.toJson<int>(version),
      'has_read': serializer.toJson<int>(hasRead),
      'chapter_id': serializer.toJson<String?>(chapterId),
      'legacy_locator_id': serializer.toJson<String?>(legacyLocatorId),
      'last_read_at': serializer.toJson<String?>(lastReadAt),
    };
  }

  ReadingProgressData copyWith({
    String? sourceId,
    String? bookId,
    int? version,
    int? hasRead,
    Value<String?> chapterId = const Value.absent(),
    Value<String?> legacyLocatorId = const Value.absent(),
    Value<String?> lastReadAt = const Value.absent(),
  }) => ReadingProgressData(
    sourceId: sourceId ?? this.sourceId,
    bookId: bookId ?? this.bookId,
    version: version ?? this.version,
    hasRead: hasRead ?? this.hasRead,
    chapterId: chapterId.present ? chapterId.value : this.chapterId,
    legacyLocatorId: legacyLocatorId.present
        ? legacyLocatorId.value
        : this.legacyLocatorId,
    lastReadAt: lastReadAt.present ? lastReadAt.value : this.lastReadAt,
  );
  ReadingProgressData copyWithCompanion(ReadingProgressCompanion data) {
    return ReadingProgressData(
      sourceId: data.sourceId.present ? data.sourceId.value : this.sourceId,
      bookId: data.bookId.present ? data.bookId.value : this.bookId,
      version: data.version.present ? data.version.value : this.version,
      hasRead: data.hasRead.present ? data.hasRead.value : this.hasRead,
      chapterId: data.chapterId.present ? data.chapterId.value : this.chapterId,
      legacyLocatorId: data.legacyLocatorId.present
          ? data.legacyLocatorId.value
          : this.legacyLocatorId,
      lastReadAt: data.lastReadAt.present
          ? data.lastReadAt.value
          : this.lastReadAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressData(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('version: $version, ')
          ..write('hasRead: $hasRead, ')
          ..write('chapterId: $chapterId, ')
          ..write('legacyLocatorId: $legacyLocatorId, ')
          ..write('lastReadAt: $lastReadAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sourceId,
    bookId,
    version,
    hasRead,
    chapterId,
    legacyLocatorId,
    lastReadAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReadingProgressData &&
          other.sourceId == this.sourceId &&
          other.bookId == this.bookId &&
          other.version == this.version &&
          other.hasRead == this.hasRead &&
          other.chapterId == this.chapterId &&
          other.legacyLocatorId == this.legacyLocatorId &&
          other.lastReadAt == this.lastReadAt);
}

class ReadingProgressCompanion extends UpdateCompanion<ReadingProgressData> {
  final Value<String> sourceId;
  final Value<String> bookId;
  final Value<int> version;
  final Value<int> hasRead;
  final Value<String?> chapterId;
  final Value<String?> legacyLocatorId;
  final Value<String?> lastReadAt;
  final Value<int> rowid;
  const ReadingProgressCompanion({
    this.sourceId = const Value.absent(),
    this.bookId = const Value.absent(),
    this.version = const Value.absent(),
    this.hasRead = const Value.absent(),
    this.chapterId = const Value.absent(),
    this.legacyLocatorId = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReadingProgressCompanion.insert({
    required String sourceId,
    required String bookId,
    this.version = const Value.absent(),
    required int hasRead,
    this.chapterId = const Value.absent(),
    this.legacyLocatorId = const Value.absent(),
    this.lastReadAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : sourceId = Value(sourceId),
       bookId = Value(bookId),
       hasRead = Value(hasRead);
  static Insertable<ReadingProgressData> custom({
    Expression<String>? sourceId,
    Expression<String>? bookId,
    Expression<int>? version,
    Expression<int>? hasRead,
    Expression<String>? chapterId,
    Expression<String>? legacyLocatorId,
    Expression<String>? lastReadAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sourceId != null) 'source_id': sourceId,
      if (bookId != null) 'book_id': bookId,
      if (version != null) 'version': version,
      if (hasRead != null) 'has_read': hasRead,
      if (chapterId != null) 'chapter_id': chapterId,
      if (legacyLocatorId != null) 'legacy_locator_id': legacyLocatorId,
      if (lastReadAt != null) 'last_read_at': lastReadAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReadingProgressCompanion copyWith({
    Value<String>? sourceId,
    Value<String>? bookId,
    Value<int>? version,
    Value<int>? hasRead,
    Value<String?>? chapterId,
    Value<String?>? legacyLocatorId,
    Value<String?>? lastReadAt,
    Value<int>? rowid,
  }) {
    return ReadingProgressCompanion(
      sourceId: sourceId ?? this.sourceId,
      bookId: bookId ?? this.bookId,
      version: version ?? this.version,
      hasRead: hasRead ?? this.hasRead,
      chapterId: chapterId ?? this.chapterId,
      legacyLocatorId: legacyLocatorId ?? this.legacyLocatorId,
      lastReadAt: lastReadAt ?? this.lastReadAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sourceId.present) {
      map['source_id'] = Variable<String>(sourceId.value);
    }
    if (bookId.present) {
      map['book_id'] = Variable<String>(bookId.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (hasRead.present) {
      map['has_read'] = Variable<int>(hasRead.value);
    }
    if (chapterId.present) {
      map['chapter_id'] = Variable<String>(chapterId.value);
    }
    if (legacyLocatorId.present) {
      map['legacy_locator_id'] = Variable<String>(legacyLocatorId.value);
    }
    if (lastReadAt.present) {
      map['last_read_at'] = Variable<String>(lastReadAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReadingProgressCompanion(')
          ..write('sourceId: $sourceId, ')
          ..write('bookId: $bookId, ')
          ..write('version: $version, ')
          ..write('hasRead: $hasRead, ')
          ..write('chapterId: $chapterId, ')
          ..write('legacyLocatorId: $legacyLocatorId, ')
          ..write('lastReadAt: $lastReadAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ReaderPreferences extends Table
    with TableInfo<ReaderPreferences, ReaderPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ReaderPreferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (singleton = 1)',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _fontSizeMeta = const VerificationMeta(
    'fontSize',
  );
  late final GeneratedColumn<double> fontSize = GeneratedColumn<double>(
    'font_size',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 22 CHECK (font_size > 0 AND(font_size - font_size)IS NOT NULL)',
    defaultValue: const CustomExpression('22'),
  );
  static const VerificationMeta _lineSpacingMeta = const VerificationMeta(
    'lineSpacing',
  );
  late final GeneratedColumn<double> lineSpacing = GeneratedColumn<double>(
    'line_spacing',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 8 CHECK (line_spacing >= 0 AND(line_spacing - line_spacing)IS NOT NULL)',
    defaultValue: const CustomExpression('8'),
  );
  static const VerificationMeta _backgroundMeta = const VerificationMeta(
    'background',
  );
  late final GeneratedColumn<String> background = GeneratedColumn<String>(
    'background',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'paperWhite\' CHECK (background IN (\'paperWhite\', \'parchment\', \'darkGray\', \'black\', \'eyeCare\'))',
    defaultValue: const CustomExpression('\'paperWhite\''),
  );
  static const VerificationMeta _modeMeta = const VerificationMeta('mode');
  late final GeneratedColumn<String> mode = GeneratedColumn<String>(
    'mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'pageCurl\' CHECK (mode IN (\'pageCurl\', \'scroll\'))',
    defaultValue: const CustomExpression('\'pageCurl\''),
  );
  static const VerificationMeta _fontFamilyMeta = const VerificationMeta(
    'fontFamily',
  );
  late final GeneratedColumn<String> fontFamily = GeneratedColumn<String>(
    'font_family',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'kaiti\' CHECK (font_family IN (\'system\', \'songti\', \'kaiti\', \'yuanti\'))',
    defaultValue: const CustomExpression('\'kaiti\''),
  );
  static const VerificationMeta _boldMeta = const VerificationMeta('bold');
  late final GeneratedColumn<int> bold = GeneratedColumn<int>(
    'bold',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (bold IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _marginLeftMeta = const VerificationMeta(
    'marginLeft',
  );
  late final GeneratedColumn<double> marginLeft = GeneratedColumn<double>(
    'margin_left',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 35 CHECK (margin_left >= 0 AND(margin_left - margin_left)IS NOT NULL)',
    defaultValue: const CustomExpression('35'),
  );
  static const VerificationMeta _marginRightMeta = const VerificationMeta(
    'marginRight',
  );
  late final GeneratedColumn<double> marginRight = GeneratedColumn<double>(
    'margin_right',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 35 CHECK (margin_right >= 0 AND(margin_right - margin_right)IS NOT NULL)',
    defaultValue: const CustomExpression('35'),
  );
  static const VerificationMeta _marginTopMeta = const VerificationMeta(
    'marginTop',
  );
  late final GeneratedColumn<double> marginTop = GeneratedColumn<double>(
    'margin_top',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 72 CHECK (margin_top >= 0 AND(margin_top - margin_top)IS NOT NULL)',
    defaultValue: const CustomExpression('72'),
  );
  static const VerificationMeta _marginBottomMeta = const VerificationMeta(
    'marginBottom',
  );
  late final GeneratedColumn<double> marginBottom = GeneratedColumn<double>(
    'margin_bottom',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 24 CHECK (margin_bottom >= 0 AND(margin_bottom - margin_bottom)IS NOT NULL)',
    defaultValue: const CustomExpression('24'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    singleton,
    version,
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
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reader_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReaderPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('font_size')) {
      context.handle(
        _fontSizeMeta,
        fontSize.isAcceptableOrUnknown(data['font_size']!, _fontSizeMeta),
      );
    }
    if (data.containsKey('line_spacing')) {
      context.handle(
        _lineSpacingMeta,
        lineSpacing.isAcceptableOrUnknown(
          data['line_spacing']!,
          _lineSpacingMeta,
        ),
      );
    }
    if (data.containsKey('background')) {
      context.handle(
        _backgroundMeta,
        background.isAcceptableOrUnknown(data['background']!, _backgroundMeta),
      );
    }
    if (data.containsKey('mode')) {
      context.handle(
        _modeMeta,
        mode.isAcceptableOrUnknown(data['mode']!, _modeMeta),
      );
    }
    if (data.containsKey('font_family')) {
      context.handle(
        _fontFamilyMeta,
        fontFamily.isAcceptableOrUnknown(data['font_family']!, _fontFamilyMeta),
      );
    }
    if (data.containsKey('bold')) {
      context.handle(
        _boldMeta,
        bold.isAcceptableOrUnknown(data['bold']!, _boldMeta),
      );
    }
    if (data.containsKey('margin_left')) {
      context.handle(
        _marginLeftMeta,
        marginLeft.isAcceptableOrUnknown(data['margin_left']!, _marginLeftMeta),
      );
    }
    if (data.containsKey('margin_right')) {
      context.handle(
        _marginRightMeta,
        marginRight.isAcceptableOrUnknown(
          data['margin_right']!,
          _marginRightMeta,
        ),
      );
    }
    if (data.containsKey('margin_top')) {
      context.handle(
        _marginTopMeta,
        marginTop.isAcceptableOrUnknown(data['margin_top']!, _marginTopMeta),
      );
    }
    if (data.containsKey('margin_bottom')) {
      context.handle(
        _marginBottomMeta,
        marginBottom.isAcceptableOrUnknown(
          data['margin_bottom']!,
          _marginBottomMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  ReaderPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReaderPreference(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      fontSize: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}font_size'],
      )!,
      lineSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}line_spacing'],
      )!,
      background: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}background'],
      )!,
      mode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode'],
      )!,
      fontFamily: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}font_family'],
      )!,
      bold: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bold'],
      )!,
      marginLeft: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}margin_left'],
      )!,
      marginRight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}margin_right'],
      )!,
      marginTop: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}margin_top'],
      )!,
      marginBottom: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}margin_bottom'],
      )!,
    );
  }

  @override
  ReaderPreferences createAlias(String alias) {
    return ReaderPreferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class ReaderPreference extends DataClass
    implements Insertable<ReaderPreference> {
  final int singleton;
  final int version;
  final double fontSize;
  final double lineSpacing;
  final String background;
  final String mode;
  final String fontFamily;
  final int bold;
  final double marginLeft;
  final double marginRight;
  final double marginTop;
  final double marginBottom;
  const ReaderPreference({
    required this.singleton,
    required this.version,
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
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    map['version'] = Variable<int>(version);
    map['font_size'] = Variable<double>(fontSize);
    map['line_spacing'] = Variable<double>(lineSpacing);
    map['background'] = Variable<String>(background);
    map['mode'] = Variable<String>(mode);
    map['font_family'] = Variable<String>(fontFamily);
    map['bold'] = Variable<int>(bold);
    map['margin_left'] = Variable<double>(marginLeft);
    map['margin_right'] = Variable<double>(marginRight);
    map['margin_top'] = Variable<double>(marginTop);
    map['margin_bottom'] = Variable<double>(marginBottom);
    return map;
  }

  ReaderPreferencesCompanion toCompanion(bool nullToAbsent) {
    return ReaderPreferencesCompanion(
      singleton: Value(singleton),
      version: Value(version),
      fontSize: Value(fontSize),
      lineSpacing: Value(lineSpacing),
      background: Value(background),
      mode: Value(mode),
      fontFamily: Value(fontFamily),
      bold: Value(bold),
      marginLeft: Value(marginLeft),
      marginRight: Value(marginRight),
      marginTop: Value(marginTop),
      marginBottom: Value(marginBottom),
    );
  }

  factory ReaderPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReaderPreference(
      singleton: serializer.fromJson<int>(json['singleton']),
      version: serializer.fromJson<int>(json['version']),
      fontSize: serializer.fromJson<double>(json['font_size']),
      lineSpacing: serializer.fromJson<double>(json['line_spacing']),
      background: serializer.fromJson<String>(json['background']),
      mode: serializer.fromJson<String>(json['mode']),
      fontFamily: serializer.fromJson<String>(json['font_family']),
      bold: serializer.fromJson<int>(json['bold']),
      marginLeft: serializer.fromJson<double>(json['margin_left']),
      marginRight: serializer.fromJson<double>(json['margin_right']),
      marginTop: serializer.fromJson<double>(json['margin_top']),
      marginBottom: serializer.fromJson<double>(json['margin_bottom']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'version': serializer.toJson<int>(version),
      'font_size': serializer.toJson<double>(fontSize),
      'line_spacing': serializer.toJson<double>(lineSpacing),
      'background': serializer.toJson<String>(background),
      'mode': serializer.toJson<String>(mode),
      'font_family': serializer.toJson<String>(fontFamily),
      'bold': serializer.toJson<int>(bold),
      'margin_left': serializer.toJson<double>(marginLeft),
      'margin_right': serializer.toJson<double>(marginRight),
      'margin_top': serializer.toJson<double>(marginTop),
      'margin_bottom': serializer.toJson<double>(marginBottom),
    };
  }

  ReaderPreference copyWith({
    int? singleton,
    int? version,
    double? fontSize,
    double? lineSpacing,
    String? background,
    String? mode,
    String? fontFamily,
    int? bold,
    double? marginLeft,
    double? marginRight,
    double? marginTop,
    double? marginBottom,
  }) => ReaderPreference(
    singleton: singleton ?? this.singleton,
    version: version ?? this.version,
    fontSize: fontSize ?? this.fontSize,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    background: background ?? this.background,
    mode: mode ?? this.mode,
    fontFamily: fontFamily ?? this.fontFamily,
    bold: bold ?? this.bold,
    marginLeft: marginLeft ?? this.marginLeft,
    marginRight: marginRight ?? this.marginRight,
    marginTop: marginTop ?? this.marginTop,
    marginBottom: marginBottom ?? this.marginBottom,
  );
  ReaderPreference copyWithCompanion(ReaderPreferencesCompanion data) {
    return ReaderPreference(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      version: data.version.present ? data.version.value : this.version,
      fontSize: data.fontSize.present ? data.fontSize.value : this.fontSize,
      lineSpacing: data.lineSpacing.present
          ? data.lineSpacing.value
          : this.lineSpacing,
      background: data.background.present
          ? data.background.value
          : this.background,
      mode: data.mode.present ? data.mode.value : this.mode,
      fontFamily: data.fontFamily.present
          ? data.fontFamily.value
          : this.fontFamily,
      bold: data.bold.present ? data.bold.value : this.bold,
      marginLeft: data.marginLeft.present
          ? data.marginLeft.value
          : this.marginLeft,
      marginRight: data.marginRight.present
          ? data.marginRight.value
          : this.marginRight,
      marginTop: data.marginTop.present ? data.marginTop.value : this.marginTop,
      marginBottom: data.marginBottom.present
          ? data.marginBottom.value
          : this.marginBottom,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPreference(')
          ..write('singleton: $singleton, ')
          ..write('version: $version, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('background: $background, ')
          ..write('mode: $mode, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('bold: $bold, ')
          ..write('marginLeft: $marginLeft, ')
          ..write('marginRight: $marginRight, ')
          ..write('marginTop: $marginTop, ')
          ..write('marginBottom: $marginBottom')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singleton,
    version,
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
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReaderPreference &&
          other.singleton == this.singleton &&
          other.version == this.version &&
          other.fontSize == this.fontSize &&
          other.lineSpacing == this.lineSpacing &&
          other.background == this.background &&
          other.mode == this.mode &&
          other.fontFamily == this.fontFamily &&
          other.bold == this.bold &&
          other.marginLeft == this.marginLeft &&
          other.marginRight == this.marginRight &&
          other.marginTop == this.marginTop &&
          other.marginBottom == this.marginBottom);
}

class ReaderPreferencesCompanion extends UpdateCompanion<ReaderPreference> {
  final Value<int> singleton;
  final Value<int> version;
  final Value<double> fontSize;
  final Value<double> lineSpacing;
  final Value<String> background;
  final Value<String> mode;
  final Value<String> fontFamily;
  final Value<int> bold;
  final Value<double> marginLeft;
  final Value<double> marginRight;
  final Value<double> marginTop;
  final Value<double> marginBottom;
  const ReaderPreferencesCompanion({
    this.singleton = const Value.absent(),
    this.version = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.background = const Value.absent(),
    this.mode = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.bold = const Value.absent(),
    this.marginLeft = const Value.absent(),
    this.marginRight = const Value.absent(),
    this.marginTop = const Value.absent(),
    this.marginBottom = const Value.absent(),
  });
  ReaderPreferencesCompanion.insert({
    this.singleton = const Value.absent(),
    this.version = const Value.absent(),
    this.fontSize = const Value.absent(),
    this.lineSpacing = const Value.absent(),
    this.background = const Value.absent(),
    this.mode = const Value.absent(),
    this.fontFamily = const Value.absent(),
    this.bold = const Value.absent(),
    this.marginLeft = const Value.absent(),
    this.marginRight = const Value.absent(),
    this.marginTop = const Value.absent(),
    this.marginBottom = const Value.absent(),
  });
  static Insertable<ReaderPreference> custom({
    Expression<int>? singleton,
    Expression<int>? version,
    Expression<double>? fontSize,
    Expression<double>? lineSpacing,
    Expression<String>? background,
    Expression<String>? mode,
    Expression<String>? fontFamily,
    Expression<int>? bold,
    Expression<double>? marginLeft,
    Expression<double>? marginRight,
    Expression<double>? marginTop,
    Expression<double>? marginBottom,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (version != null) 'version': version,
      if (fontSize != null) 'font_size': fontSize,
      if (lineSpacing != null) 'line_spacing': lineSpacing,
      if (background != null) 'background': background,
      if (mode != null) 'mode': mode,
      if (fontFamily != null) 'font_family': fontFamily,
      if (bold != null) 'bold': bold,
      if (marginLeft != null) 'margin_left': marginLeft,
      if (marginRight != null) 'margin_right': marginRight,
      if (marginTop != null) 'margin_top': marginTop,
      if (marginBottom != null) 'margin_bottom': marginBottom,
    });
  }

  ReaderPreferencesCompanion copyWith({
    Value<int>? singleton,
    Value<int>? version,
    Value<double>? fontSize,
    Value<double>? lineSpacing,
    Value<String>? background,
    Value<String>? mode,
    Value<String>? fontFamily,
    Value<int>? bold,
    Value<double>? marginLeft,
    Value<double>? marginRight,
    Value<double>? marginTop,
    Value<double>? marginBottom,
  }) {
    return ReaderPreferencesCompanion(
      singleton: singleton ?? this.singleton,
      version: version ?? this.version,
      fontSize: fontSize ?? this.fontSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      background: background ?? this.background,
      mode: mode ?? this.mode,
      fontFamily: fontFamily ?? this.fontFamily,
      bold: bold ?? this.bold,
      marginLeft: marginLeft ?? this.marginLeft,
      marginRight: marginRight ?? this.marginRight,
      marginTop: marginTop ?? this.marginTop,
      marginBottom: marginBottom ?? this.marginBottom,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (fontSize.present) {
      map['font_size'] = Variable<double>(fontSize.value);
    }
    if (lineSpacing.present) {
      map['line_spacing'] = Variable<double>(lineSpacing.value);
    }
    if (background.present) {
      map['background'] = Variable<String>(background.value);
    }
    if (mode.present) {
      map['mode'] = Variable<String>(mode.value);
    }
    if (fontFamily.present) {
      map['font_family'] = Variable<String>(fontFamily.value);
    }
    if (bold.present) {
      map['bold'] = Variable<int>(bold.value);
    }
    if (marginLeft.present) {
      map['margin_left'] = Variable<double>(marginLeft.value);
    }
    if (marginRight.present) {
      map['margin_right'] = Variable<double>(marginRight.value);
    }
    if (marginTop.present) {
      map['margin_top'] = Variable<double>(marginTop.value);
    }
    if (marginBottom.present) {
      map['margin_bottom'] = Variable<double>(marginBottom.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReaderPreferencesCompanion(')
          ..write('singleton: $singleton, ')
          ..write('version: $version, ')
          ..write('fontSize: $fontSize, ')
          ..write('lineSpacing: $lineSpacing, ')
          ..write('background: $background, ')
          ..write('mode: $mode, ')
          ..write('fontFamily: $fontFamily, ')
          ..write('bold: $bold, ')
          ..write('marginLeft: $marginLeft, ')
          ..write('marginRight: $marginRight, ')
          ..write('marginTop: $marginTop, ')
          ..write('marginBottom: $marginBottom')
          ..write(')'))
        .toString();
  }
}

class AppPreferences extends Table
    with TableInfo<AppPreferences, AppPreference> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  AppPreferences(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonMeta = const VerificationMeta(
    'singleton',
  );
  late final GeneratedColumn<int> singleton = GeneratedColumn<int>(
    'singleton',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL PRIMARY KEY CHECK (singleton = 1)',
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (version = 1)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _themeMeta = const VerificationMeta('theme');
  late final GeneratedColumn<String> theme = GeneratedColumn<String>(
    'theme',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (theme IN (\'system\', \'light\', \'dark\'))',
  );
  static const VerificationMeta _preferredSourceIdMeta = const VerificationMeta(
    'preferredSourceId',
  );
  late final GeneratedColumn<String> preferredSourceId =
      GeneratedColumn<String>(
        'preferred_source_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: 'COLLATE BINARY REFERENCES source_registrations(source_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
      );
  static const VerificationMeta _selectedShelfIdMeta = const VerificationMeta(
    'selectedShelfId',
  );
  late final GeneratedColumn<String> selectedShelfId = GeneratedColumn<String>(
    'selected_shelf_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'COLLATE BINARY REFERENCES shelves(shelf_id)ON UPDATE RESTRICT ON DELETE RESTRICT',
  );
  static const VerificationMeta _accentMeta = const VerificationMeta('accent');
  late final GeneratedColumn<String> accent = GeneratedColumn<String>(
    'accent',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (accent IS NULL OR accent IN (\'purple\', \'blue\', \'teal\', \'pink\', \'orange\', \'red\'))',
  );
  @override
  List<GeneratedColumn> get $columns => [
    singleton,
    version,
    theme,
    preferredSourceId,
    selectedShelfId,
    accent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppPreference> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton')) {
      context.handle(
        _singletonMeta,
        singleton.isAcceptableOrUnknown(data['singleton']!, _singletonMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('theme')) {
      context.handle(
        _themeMeta,
        theme.isAcceptableOrUnknown(data['theme']!, _themeMeta),
      );
    } else if (isInserting) {
      context.missing(_themeMeta);
    }
    if (data.containsKey('preferred_source_id')) {
      context.handle(
        _preferredSourceIdMeta,
        preferredSourceId.isAcceptableOrUnknown(
          data['preferred_source_id']!,
          _preferredSourceIdMeta,
        ),
      );
    }
    if (data.containsKey('selected_shelf_id')) {
      context.handle(
        _selectedShelfIdMeta,
        selectedShelfId.isAcceptableOrUnknown(
          data['selected_shelf_id']!,
          _selectedShelfIdMeta,
        ),
      );
    }
    if (data.containsKey('accent')) {
      context.handle(
        _accentMeta,
        accent.isAcceptableOrUnknown(data['accent']!, _accentMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singleton};
  @override
  AppPreference map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppPreference(
      singleton: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      theme: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}theme'],
      )!,
      preferredSourceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preferred_source_id'],
      ),
      selectedShelfId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}selected_shelf_id'],
      ),
      accent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}accent'],
      ),
    );
  }

  @override
  AppPreferences createAlias(String alias) {
    return AppPreferences(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class AppPreference extends DataClass implements Insertable<AppPreference> {
  final int singleton;
  final int version;
  final String theme;
  final String? preferredSourceId;
  final String? selectedShelfId;
  final String? accent;
  const AppPreference({
    required this.singleton,
    required this.version,
    required this.theme,
    this.preferredSourceId,
    this.selectedShelfId,
    this.accent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton'] = Variable<int>(singleton);
    map['version'] = Variable<int>(version);
    map['theme'] = Variable<String>(theme);
    if (!nullToAbsent || preferredSourceId != null) {
      map['preferred_source_id'] = Variable<String>(preferredSourceId);
    }
    if (!nullToAbsent || selectedShelfId != null) {
      map['selected_shelf_id'] = Variable<String>(selectedShelfId);
    }
    if (!nullToAbsent || accent != null) {
      map['accent'] = Variable<String>(accent);
    }
    return map;
  }

  AppPreferencesCompanion toCompanion(bool nullToAbsent) {
    return AppPreferencesCompanion(
      singleton: Value(singleton),
      version: Value(version),
      theme: Value(theme),
      preferredSourceId: preferredSourceId == null && nullToAbsent
          ? const Value.absent()
          : Value(preferredSourceId),
      selectedShelfId: selectedShelfId == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedShelfId),
      accent: accent == null && nullToAbsent
          ? const Value.absent()
          : Value(accent),
    );
  }

  factory AppPreference.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppPreference(
      singleton: serializer.fromJson<int>(json['singleton']),
      version: serializer.fromJson<int>(json['version']),
      theme: serializer.fromJson<String>(json['theme']),
      preferredSourceId: serializer.fromJson<String?>(
        json['preferred_source_id'],
      ),
      selectedShelfId: serializer.fromJson<String?>(json['selected_shelf_id']),
      accent: serializer.fromJson<String?>(json['accent']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton': serializer.toJson<int>(singleton),
      'version': serializer.toJson<int>(version),
      'theme': serializer.toJson<String>(theme),
      'preferred_source_id': serializer.toJson<String?>(preferredSourceId),
      'selected_shelf_id': serializer.toJson<String?>(selectedShelfId),
      'accent': serializer.toJson<String?>(accent),
    };
  }

  AppPreference copyWith({
    int? singleton,
    int? version,
    String? theme,
    Value<String?> preferredSourceId = const Value.absent(),
    Value<String?> selectedShelfId = const Value.absent(),
    Value<String?> accent = const Value.absent(),
  }) => AppPreference(
    singleton: singleton ?? this.singleton,
    version: version ?? this.version,
    theme: theme ?? this.theme,
    preferredSourceId: preferredSourceId.present
        ? preferredSourceId.value
        : this.preferredSourceId,
    selectedShelfId: selectedShelfId.present
        ? selectedShelfId.value
        : this.selectedShelfId,
    accent: accent.present ? accent.value : this.accent,
  );
  AppPreference copyWithCompanion(AppPreferencesCompanion data) {
    return AppPreference(
      singleton: data.singleton.present ? data.singleton.value : this.singleton,
      version: data.version.present ? data.version.value : this.version,
      theme: data.theme.present ? data.theme.value : this.theme,
      preferredSourceId: data.preferredSourceId.present
          ? data.preferredSourceId.value
          : this.preferredSourceId,
      selectedShelfId: data.selectedShelfId.present
          ? data.selectedShelfId.value
          : this.selectedShelfId,
      accent: data.accent.present ? data.accent.value : this.accent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppPreference(')
          ..write('singleton: $singleton, ')
          ..write('version: $version, ')
          ..write('theme: $theme, ')
          ..write('preferredSourceId: $preferredSourceId, ')
          ..write('selectedShelfId: $selectedShelfId, ')
          ..write('accent: $accent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singleton,
    version,
    theme,
    preferredSourceId,
    selectedShelfId,
    accent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppPreference &&
          other.singleton == this.singleton &&
          other.version == this.version &&
          other.theme == this.theme &&
          other.preferredSourceId == this.preferredSourceId &&
          other.selectedShelfId == this.selectedShelfId &&
          other.accent == this.accent);
}

class AppPreferencesCompanion extends UpdateCompanion<AppPreference> {
  final Value<int> singleton;
  final Value<int> version;
  final Value<String> theme;
  final Value<String?> preferredSourceId;
  final Value<String?> selectedShelfId;
  final Value<String?> accent;
  const AppPreferencesCompanion({
    this.singleton = const Value.absent(),
    this.version = const Value.absent(),
    this.theme = const Value.absent(),
    this.preferredSourceId = const Value.absent(),
    this.selectedShelfId = const Value.absent(),
    this.accent = const Value.absent(),
  });
  AppPreferencesCompanion.insert({
    this.singleton = const Value.absent(),
    this.version = const Value.absent(),
    required String theme,
    this.preferredSourceId = const Value.absent(),
    this.selectedShelfId = const Value.absent(),
    this.accent = const Value.absent(),
  }) : theme = Value(theme);
  static Insertable<AppPreference> custom({
    Expression<int>? singleton,
    Expression<int>? version,
    Expression<String>? theme,
    Expression<String>? preferredSourceId,
    Expression<String>? selectedShelfId,
    Expression<String>? accent,
  }) {
    return RawValuesInsertable({
      if (singleton != null) 'singleton': singleton,
      if (version != null) 'version': version,
      if (theme != null) 'theme': theme,
      if (preferredSourceId != null) 'preferred_source_id': preferredSourceId,
      if (selectedShelfId != null) 'selected_shelf_id': selectedShelfId,
      if (accent != null) 'accent': accent,
    });
  }

  AppPreferencesCompanion copyWith({
    Value<int>? singleton,
    Value<int>? version,
    Value<String>? theme,
    Value<String?>? preferredSourceId,
    Value<String?>? selectedShelfId,
    Value<String?>? accent,
  }) {
    return AppPreferencesCompanion(
      singleton: singleton ?? this.singleton,
      version: version ?? this.version,
      theme: theme ?? this.theme,
      preferredSourceId: preferredSourceId ?? this.preferredSourceId,
      selectedShelfId: selectedShelfId ?? this.selectedShelfId,
      accent: accent ?? this.accent,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singleton.present) {
      map['singleton'] = Variable<int>(singleton.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (theme.present) {
      map['theme'] = Variable<String>(theme.value);
    }
    if (preferredSourceId.present) {
      map['preferred_source_id'] = Variable<String>(preferredSourceId.value);
    }
    if (selectedShelfId.present) {
      map['selected_shelf_id'] = Variable<String>(selectedShelfId.value);
    }
    if (accent.present) {
      map['accent'] = Variable<String>(accent.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppPreferencesCompanion(')
          ..write('singleton: $singleton, ')
          ..write('version: $version, ')
          ..write('theme: $theme, ')
          ..write('preferredSourceId: $preferredSourceId, ')
          ..write('selectedShelfId: $selectedShelfId, ')
          ..write('accent: $accent')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final SourceRegistrations sourceRegistrations = SourceRegistrations(
    this,
  );
  late final LibraryEntries libraryEntries = LibraryEntries(this);
  late final BookTags bookTags = BookTags(this);
  late final LegacyBookMetadata legacyBookMetadata = LegacyBookMetadata(this);
  late final Shelves shelves = Shelves(this);
  late final ShelfMembers shelfMembers = ShelfMembers(this);
  late final ManualGroups manualGroups = ManualGroups(this);
  late final GroupMembers groupMembers = GroupMembers(this);
  late final SplitOverrides splitOverrides = SplitOverrides(this);
  late final MigrationDatasets migrationDatasets = MigrationDatasets(this);
  late final MigrationRuns migrationRuns = MigrationRuns(this);
  late final RecordReceipts recordReceipts = RecordReceipts(this);
  late final RecordOutcomes recordOutcomes = RecordOutcomes(this);
  late final SafeLegacyValues safeLegacyValues = SafeLegacyValues(this);
  late final LegacyIdentityMappings legacyIdentityMappings =
      LegacyIdentityMappings(this);
  late final LegacyChapterLocators legacyChapterLocators =
      LegacyChapterLocators(this);
  late final ReadingProgress readingProgress = ReadingProgress(this);
  late final ReaderPreferences readerPreferences = ReaderPreferences(this);
  late final AppPreferences appPreferences = AppPreferences(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    sourceRegistrations,
    libraryEntries,
    bookTags,
    legacyBookMetadata,
    shelves,
    shelfMembers,
    manualGroups,
    groupMembers,
    splitOverrides,
    migrationDatasets,
    migrationRuns,
    recordReceipts,
    recordOutcomes,
    safeLegacyValues,
    legacyIdentityMappings,
    legacyChapterLocators,
    readingProgress,
    readerPreferences,
    appPreferences,
  ];
}
