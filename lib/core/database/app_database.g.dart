// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $KeyValueEntriesTable extends KeyValueEntries
    with TableInfo<$KeyValueEntriesTable, KeyValueEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  KeyValueEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $KeyValueEntriesTable createAlias(String alias) {
    return $KeyValueEntriesTable(attachedDatabase, alias);
  }
}

class KeyValueEntry extends DataClass implements Insertable<KeyValueEntry> {
  final int id;
  final String key;
  final String? value;
  const KeyValueEntry({required this.id, required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KeyValueEntriesCompanion toCompanion(bool nullToAbsent) {
    return KeyValueEntriesCompanion(
      id: Value(id),
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory KeyValueEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueEntry(
      id: serializer.fromJson<int>(json['id']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  KeyValueEntry copyWith({
    int? id,
    String? key,
    Value<String?> value = const Value.absent(),
  }) => KeyValueEntry(
    id: id ?? this.id,
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  KeyValueEntry copyWithCompanion(KeyValueEntriesCompanion data) {
    return KeyValueEntry(
      id: data.id.present ? data.id.value : this.id,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntry(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueEntry &&
          other.id == this.id &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueEntriesCompanion extends UpdateCompanion<KeyValueEntry> {
  final Value<int> id;
  final Value<String> key;
  final Value<String?> value;
  const KeyValueEntriesCompanion({
    this.id = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
  });
  KeyValueEntriesCompanion.insert({
    this.id = const Value.absent(),
    required String key,
    this.value = const Value.absent(),
  }) : key = Value(key);
  static Insertable<KeyValueEntry> custom({
    Expression<int>? id,
    Expression<String>? key,
    Expression<String>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
    });
  }

  KeyValueEntriesCompanion copyWith({
    Value<int>? id,
    Value<String>? key,
    Value<String?>? value,
  }) {
    return KeyValueEntriesCompanion(
      id: id ?? this.id,
      key: key ?? this.key,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueEntriesCompanion(')
          ..write('id: $id, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

class $LibraryEntriesTable extends LibraryEntries
    with TableInfo<$LibraryEntriesTable, LibraryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LibraryEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<int> kind = GeneratedColumn<int>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _externalIdMeta = const VerificationMeta(
    'externalId',
  );
  @override
  late final GeneratedColumn<String> externalId = GeneratedColumn<String>(
    'external_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _posterUrlMeta = const VerificationMeta(
    'posterUrl',
  );
  @override
  late final GeneratedColumn<String> posterUrl = GeneratedColumn<String>(
    'poster_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('planning'),
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<int> progress = GeneratedColumn<int>(
    'progress',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalEpisodesMeta = const VerificationMeta(
    'totalEpisodes',
  );
  @override
  late final GeneratedColumn<int> totalEpisodes = GeneratedColumn<int>(
    'total_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _editionKeyMeta = const VerificationMeta(
    'editionKey',
  );
  @override
  late final GeneratedColumn<String> editionKey = GeneratedColumn<String>(
    'edition_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isbnMeta = const VerificationMeta('isbn');
  @override
  late final GeneratedColumn<String> isbn = GeneratedColumn<String>(
    'isbn',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalPagesFromApiMeta = const VerificationMeta(
    'totalPagesFromApi',
  );
  @override
  late final GeneratedColumn<int> totalPagesFromApi = GeneratedColumn<int>(
    'total_pages_from_api',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _totalChaptersFromApiMeta =
      const VerificationMeta('totalChaptersFromApi');
  @override
  late final GeneratedColumn<int> totalChaptersFromApi = GeneratedColumn<int>(
    'total_chapters_from_api',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userTotalPagesOverrideMeta =
      const VerificationMeta('userTotalPagesOverride');
  @override
  late final GeneratedColumn<int> userTotalPagesOverride = GeneratedColumn<int>(
    'user_total_pages_override',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _userTotalChaptersOverrideMeta =
      const VerificationMeta('userTotalChaptersOverride');
  @override
  late final GeneratedColumn<int> userTotalChaptersOverride =
      GeneratedColumn<int>(
        'user_total_chapters_override',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _currentChapterMeta = const VerificationMeta(
    'currentChapter',
  );
  @override
  late final GeneratedColumn<int> currentChapter = GeneratedColumn<int>(
    'current_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bookTrackingModeMeta = const VerificationMeta(
    'bookTrackingMode',
  );
  @override
  late final GeneratedColumn<String> bookTrackingMode = GeneratedColumn<String>(
    'book_tracking_mode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _animeMediaStatusMeta = const VerificationMeta(
    'animeMediaStatus',
  );
  @override
  late final GeneratedColumn<String> animeMediaStatus = GeneratedColumn<String>(
    'anime_media_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releasedEpisodesMeta = const VerificationMeta(
    'releasedEpisodes',
  );
  @override
  late final GeneratedColumn<int> releasedEpisodes = GeneratedColumn<int>(
    'released_episodes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nextEpisodeAirsAtMeta = const VerificationMeta(
    'nextEpisodeAirsAt',
  );
  @override
  late final GeneratedColumn<int> nextEpisodeAirsAt = GeneratedColumn<int>(
    'next_episode_airs_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _steamAppIdMeta = const VerificationMeta(
    'steamAppId',
  );
  @override
  late final GeneratedColumn<int> steamAppId = GeneratedColumn<int>(
    'steam_app_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: Constant(DateTime.now().millisecondsSinceEpoch),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    externalId,
    title,
    posterUrl,
    status,
    score,
    progress,
    totalEpisodes,
    notes,
    editionKey,
    isbn,
    totalPagesFromApi,
    totalChaptersFromApi,
    userTotalPagesOverride,
    userTotalChaptersOverride,
    currentChapter,
    bookTrackingMode,
    animeMediaStatus,
    releasedEpisodes,
    nextEpisodeAirsAt,
    steamAppId,
    updatedAt,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('external_id')) {
      context.handle(
        _externalIdMeta,
        externalId.isAcceptableOrUnknown(data['external_id']!, _externalIdMeta),
      );
    } else if (isInserting) {
      context.missing(_externalIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('poster_url')) {
      context.handle(
        _posterUrlMeta,
        posterUrl.isAcceptableOrUnknown(data['poster_url']!, _posterUrlMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('total_episodes')) {
      context.handle(
        _totalEpisodesMeta,
        totalEpisodes.isAcceptableOrUnknown(
          data['total_episodes']!,
          _totalEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('edition_key')) {
      context.handle(
        _editionKeyMeta,
        editionKey.isAcceptableOrUnknown(data['edition_key']!, _editionKeyMeta),
      );
    }
    if (data.containsKey('isbn')) {
      context.handle(
        _isbnMeta,
        isbn.isAcceptableOrUnknown(data['isbn']!, _isbnMeta),
      );
    }
    if (data.containsKey('total_pages_from_api')) {
      context.handle(
        _totalPagesFromApiMeta,
        totalPagesFromApi.isAcceptableOrUnknown(
          data['total_pages_from_api']!,
          _totalPagesFromApiMeta,
        ),
      );
    }
    if (data.containsKey('total_chapters_from_api')) {
      context.handle(
        _totalChaptersFromApiMeta,
        totalChaptersFromApi.isAcceptableOrUnknown(
          data['total_chapters_from_api']!,
          _totalChaptersFromApiMeta,
        ),
      );
    }
    if (data.containsKey('user_total_pages_override')) {
      context.handle(
        _userTotalPagesOverrideMeta,
        userTotalPagesOverride.isAcceptableOrUnknown(
          data['user_total_pages_override']!,
          _userTotalPagesOverrideMeta,
        ),
      );
    }
    if (data.containsKey('user_total_chapters_override')) {
      context.handle(
        _userTotalChaptersOverrideMeta,
        userTotalChaptersOverride.isAcceptableOrUnknown(
          data['user_total_chapters_override']!,
          _userTotalChaptersOverrideMeta,
        ),
      );
    }
    if (data.containsKey('current_chapter')) {
      context.handle(
        _currentChapterMeta,
        currentChapter.isAcceptableOrUnknown(
          data['current_chapter']!,
          _currentChapterMeta,
        ),
      );
    }
    if (data.containsKey('book_tracking_mode')) {
      context.handle(
        _bookTrackingModeMeta,
        bookTrackingMode.isAcceptableOrUnknown(
          data['book_tracking_mode']!,
          _bookTrackingModeMeta,
        ),
      );
    }
    if (data.containsKey('anime_media_status')) {
      context.handle(
        _animeMediaStatusMeta,
        animeMediaStatus.isAcceptableOrUnknown(
          data['anime_media_status']!,
          _animeMediaStatusMeta,
        ),
      );
    }
    if (data.containsKey('released_episodes')) {
      context.handle(
        _releasedEpisodesMeta,
        releasedEpisodes.isAcceptableOrUnknown(
          data['released_episodes']!,
          _releasedEpisodesMeta,
        ),
      );
    }
    if (data.containsKey('next_episode_airs_at')) {
      context.handle(
        _nextEpisodeAirsAtMeta,
        nextEpisodeAirsAt.isAcceptableOrUnknown(
          data['next_episode_airs_at']!,
          _nextEpisodeAirsAtMeta,
        ),
      );
    }
    if (data.containsKey('steam_app_id')) {
      context.handle(
        _steamAppIdMeta,
        steamAppId.isAcceptableOrUnknown(
          data['steam_app_id']!,
          _steamAppIdMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {kind, externalId},
  ];
  @override
  LibraryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LibraryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kind'],
      )!,
      externalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}external_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      posterUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_url'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      ),
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}progress'],
      ),
      totalEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_episodes'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      editionKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}edition_key'],
      ),
      isbn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}isbn'],
      ),
      totalPagesFromApi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_pages_from_api'],
      ),
      totalChaptersFromApi: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_chapters_from_api'],
      ),
      userTotalPagesOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_total_pages_override'],
      ),
      userTotalChaptersOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}user_total_chapters_override'],
      ),
      currentChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_chapter'],
      ),
      bookTrackingMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book_tracking_mode'],
      ),
      animeMediaStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anime_media_status'],
      ),
      releasedEpisodes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}released_episodes'],
      ),
      nextEpisodeAirsAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_episode_airs_at'],
      ),
      steamAppId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}steam_app_id'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LibraryEntriesTable createAlias(String alias) {
    return $LibraryEntriesTable(attachedDatabase, alias);
  }
}

class LibraryEntry extends DataClass implements Insertable<LibraryEntry> {
  final int id;
  final int kind;
  final String externalId;
  final String title;
  final String? posterUrl;
  final String status;
  final int? score;
  final int? progress;
  final int? totalEpisodes;
  final String? notes;
  final String? editionKey;
  final String? isbn;
  final int? totalPagesFromApi;
  final int? totalChaptersFromApi;
  final int? userTotalPagesOverride;
  final int? userTotalChaptersOverride;
  final int? currentChapter;
  final String? bookTrackingMode;
  final String? animeMediaStatus;
  final int? releasedEpisodes;
  final int? nextEpisodeAirsAt;

  /// Steam app ID — set when this entry was added from the Steam library view.
  /// Null for entries added from other sources (IGDB search, Trakt, etc.).
  final int? steamAppId;
  final int updatedAt;
  const LibraryEntry({
    required this.id,
    required this.kind,
    required this.externalId,
    required this.title,
    this.posterUrl,
    required this.status,
    this.score,
    this.progress,
    this.totalEpisodes,
    this.notes,
    this.editionKey,
    this.isbn,
    this.totalPagesFromApi,
    this.totalChaptersFromApi,
    this.userTotalPagesOverride,
    this.userTotalChaptersOverride,
    this.currentChapter,
    this.bookTrackingMode,
    this.animeMediaStatus,
    this.releasedEpisodes,
    this.nextEpisodeAirsAt,
    this.steamAppId,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['kind'] = Variable<int>(kind);
    map['external_id'] = Variable<String>(externalId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || posterUrl != null) {
      map['poster_url'] = Variable<String>(posterUrl);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || score != null) {
      map['score'] = Variable<int>(score);
    }
    if (!nullToAbsent || progress != null) {
      map['progress'] = Variable<int>(progress);
    }
    if (!nullToAbsent || totalEpisodes != null) {
      map['total_episodes'] = Variable<int>(totalEpisodes);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || editionKey != null) {
      map['edition_key'] = Variable<String>(editionKey);
    }
    if (!nullToAbsent || isbn != null) {
      map['isbn'] = Variable<String>(isbn);
    }
    if (!nullToAbsent || totalPagesFromApi != null) {
      map['total_pages_from_api'] = Variable<int>(totalPagesFromApi);
    }
    if (!nullToAbsent || totalChaptersFromApi != null) {
      map['total_chapters_from_api'] = Variable<int>(totalChaptersFromApi);
    }
    if (!nullToAbsent || userTotalPagesOverride != null) {
      map['user_total_pages_override'] = Variable<int>(userTotalPagesOverride);
    }
    if (!nullToAbsent || userTotalChaptersOverride != null) {
      map['user_total_chapters_override'] = Variable<int>(
        userTotalChaptersOverride,
      );
    }
    if (!nullToAbsent || currentChapter != null) {
      map['current_chapter'] = Variable<int>(currentChapter);
    }
    if (!nullToAbsent || bookTrackingMode != null) {
      map['book_tracking_mode'] = Variable<String>(bookTrackingMode);
    }
    if (!nullToAbsent || animeMediaStatus != null) {
      map['anime_media_status'] = Variable<String>(animeMediaStatus);
    }
    if (!nullToAbsent || releasedEpisodes != null) {
      map['released_episodes'] = Variable<int>(releasedEpisodes);
    }
    if (!nullToAbsent || nextEpisodeAirsAt != null) {
      map['next_episode_airs_at'] = Variable<int>(nextEpisodeAirsAt);
    }
    if (!nullToAbsent || steamAppId != null) {
      map['steam_app_id'] = Variable<int>(steamAppId);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  LibraryEntriesCompanion toCompanion(bool nullToAbsent) {
    return LibraryEntriesCompanion(
      id: Value(id),
      kind: Value(kind),
      externalId: Value(externalId),
      title: Value(title),
      posterUrl: posterUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(posterUrl),
      status: Value(status),
      score: score == null && nullToAbsent
          ? const Value.absent()
          : Value(score),
      progress: progress == null && nullToAbsent
          ? const Value.absent()
          : Value(progress),
      totalEpisodes: totalEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(totalEpisodes),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      editionKey: editionKey == null && nullToAbsent
          ? const Value.absent()
          : Value(editionKey),
      isbn: isbn == null && nullToAbsent ? const Value.absent() : Value(isbn),
      totalPagesFromApi: totalPagesFromApi == null && nullToAbsent
          ? const Value.absent()
          : Value(totalPagesFromApi),
      totalChaptersFromApi: totalChaptersFromApi == null && nullToAbsent
          ? const Value.absent()
          : Value(totalChaptersFromApi),
      userTotalPagesOverride: userTotalPagesOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(userTotalPagesOverride),
      userTotalChaptersOverride:
          userTotalChaptersOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(userTotalChaptersOverride),
      currentChapter: currentChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(currentChapter),
      bookTrackingMode: bookTrackingMode == null && nullToAbsent
          ? const Value.absent()
          : Value(bookTrackingMode),
      animeMediaStatus: animeMediaStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(animeMediaStatus),
      releasedEpisodes: releasedEpisodes == null && nullToAbsent
          ? const Value.absent()
          : Value(releasedEpisodes),
      nextEpisodeAirsAt: nextEpisodeAirsAt == null && nullToAbsent
          ? const Value.absent()
          : Value(nextEpisodeAirsAt),
      steamAppId: steamAppId == null && nullToAbsent
          ? const Value.absent()
          : Value(steamAppId),
      updatedAt: Value(updatedAt),
    );
  }

  factory LibraryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LibraryEntry(
      id: serializer.fromJson<int>(json['id']),
      kind: serializer.fromJson<int>(json['kind']),
      externalId: serializer.fromJson<String>(json['externalId']),
      title: serializer.fromJson<String>(json['title']),
      posterUrl: serializer.fromJson<String?>(json['posterUrl']),
      status: serializer.fromJson<String>(json['status']),
      score: serializer.fromJson<int?>(json['score']),
      progress: serializer.fromJson<int?>(json['progress']),
      totalEpisodes: serializer.fromJson<int?>(json['totalEpisodes']),
      notes: serializer.fromJson<String?>(json['notes']),
      editionKey: serializer.fromJson<String?>(json['editionKey']),
      isbn: serializer.fromJson<String?>(json['isbn']),
      totalPagesFromApi: serializer.fromJson<int?>(json['totalPagesFromApi']),
      totalChaptersFromApi: serializer.fromJson<int?>(
        json['totalChaptersFromApi'],
      ),
      userTotalPagesOverride: serializer.fromJson<int?>(
        json['userTotalPagesOverride'],
      ),
      userTotalChaptersOverride: serializer.fromJson<int?>(
        json['userTotalChaptersOverride'],
      ),
      currentChapter: serializer.fromJson<int?>(json['currentChapter']),
      bookTrackingMode: serializer.fromJson<String?>(json['bookTrackingMode']),
      animeMediaStatus: serializer.fromJson<String?>(json['animeMediaStatus']),
      releasedEpisodes: serializer.fromJson<int?>(json['releasedEpisodes']),
      nextEpisodeAirsAt: serializer.fromJson<int?>(json['nextEpisodeAirsAt']),
      steamAppId: serializer.fromJson<int?>(json['steamAppId']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'kind': serializer.toJson<int>(kind),
      'externalId': serializer.toJson<String>(externalId),
      'title': serializer.toJson<String>(title),
      'posterUrl': serializer.toJson<String?>(posterUrl),
      'status': serializer.toJson<String>(status),
      'score': serializer.toJson<int?>(score),
      'progress': serializer.toJson<int?>(progress),
      'totalEpisodes': serializer.toJson<int?>(totalEpisodes),
      'notes': serializer.toJson<String?>(notes),
      'editionKey': serializer.toJson<String?>(editionKey),
      'isbn': serializer.toJson<String?>(isbn),
      'totalPagesFromApi': serializer.toJson<int?>(totalPagesFromApi),
      'totalChaptersFromApi': serializer.toJson<int?>(totalChaptersFromApi),
      'userTotalPagesOverride': serializer.toJson<int?>(userTotalPagesOverride),
      'userTotalChaptersOverride': serializer.toJson<int?>(
        userTotalChaptersOverride,
      ),
      'currentChapter': serializer.toJson<int?>(currentChapter),
      'bookTrackingMode': serializer.toJson<String?>(bookTrackingMode),
      'animeMediaStatus': serializer.toJson<String?>(animeMediaStatus),
      'releasedEpisodes': serializer.toJson<int?>(releasedEpisodes),
      'nextEpisodeAirsAt': serializer.toJson<int?>(nextEpisodeAirsAt),
      'steamAppId': serializer.toJson<int?>(steamAppId),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  LibraryEntry copyWith({
    int? id,
    int? kind,
    String? externalId,
    String? title,
    Value<String?> posterUrl = const Value.absent(),
    String? status,
    Value<int?> score = const Value.absent(),
    Value<int?> progress = const Value.absent(),
    Value<int?> totalEpisodes = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> editionKey = const Value.absent(),
    Value<String?> isbn = const Value.absent(),
    Value<int?> totalPagesFromApi = const Value.absent(),
    Value<int?> totalChaptersFromApi = const Value.absent(),
    Value<int?> userTotalPagesOverride = const Value.absent(),
    Value<int?> userTotalChaptersOverride = const Value.absent(),
    Value<int?> currentChapter = const Value.absent(),
    Value<String?> bookTrackingMode = const Value.absent(),
    Value<String?> animeMediaStatus = const Value.absent(),
    Value<int?> releasedEpisodes = const Value.absent(),
    Value<int?> nextEpisodeAirsAt = const Value.absent(),
    Value<int?> steamAppId = const Value.absent(),
    int? updatedAt,
  }) => LibraryEntry(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    externalId: externalId ?? this.externalId,
    title: title ?? this.title,
    posterUrl: posterUrl.present ? posterUrl.value : this.posterUrl,
    status: status ?? this.status,
    score: score.present ? score.value : this.score,
    progress: progress.present ? progress.value : this.progress,
    totalEpisodes: totalEpisodes.present
        ? totalEpisodes.value
        : this.totalEpisodes,
    notes: notes.present ? notes.value : this.notes,
    editionKey: editionKey.present ? editionKey.value : this.editionKey,
    isbn: isbn.present ? isbn.value : this.isbn,
    totalPagesFromApi: totalPagesFromApi.present
        ? totalPagesFromApi.value
        : this.totalPagesFromApi,
    totalChaptersFromApi: totalChaptersFromApi.present
        ? totalChaptersFromApi.value
        : this.totalChaptersFromApi,
    userTotalPagesOverride: userTotalPagesOverride.present
        ? userTotalPagesOverride.value
        : this.userTotalPagesOverride,
    userTotalChaptersOverride: userTotalChaptersOverride.present
        ? userTotalChaptersOverride.value
        : this.userTotalChaptersOverride,
    currentChapter: currentChapter.present
        ? currentChapter.value
        : this.currentChapter,
    bookTrackingMode: bookTrackingMode.present
        ? bookTrackingMode.value
        : this.bookTrackingMode,
    animeMediaStatus: animeMediaStatus.present
        ? animeMediaStatus.value
        : this.animeMediaStatus,
    releasedEpisodes: releasedEpisodes.present
        ? releasedEpisodes.value
        : this.releasedEpisodes,
    nextEpisodeAirsAt: nextEpisodeAirsAt.present
        ? nextEpisodeAirsAt.value
        : this.nextEpisodeAirsAt,
    steamAppId: steamAppId.present ? steamAppId.value : this.steamAppId,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LibraryEntry copyWithCompanion(LibraryEntriesCompanion data) {
    return LibraryEntry(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      externalId: data.externalId.present
          ? data.externalId.value
          : this.externalId,
      title: data.title.present ? data.title.value : this.title,
      posterUrl: data.posterUrl.present ? data.posterUrl.value : this.posterUrl,
      status: data.status.present ? data.status.value : this.status,
      score: data.score.present ? data.score.value : this.score,
      progress: data.progress.present ? data.progress.value : this.progress,
      totalEpisodes: data.totalEpisodes.present
          ? data.totalEpisodes.value
          : this.totalEpisodes,
      notes: data.notes.present ? data.notes.value : this.notes,
      editionKey: data.editionKey.present
          ? data.editionKey.value
          : this.editionKey,
      isbn: data.isbn.present ? data.isbn.value : this.isbn,
      totalPagesFromApi: data.totalPagesFromApi.present
          ? data.totalPagesFromApi.value
          : this.totalPagesFromApi,
      totalChaptersFromApi: data.totalChaptersFromApi.present
          ? data.totalChaptersFromApi.value
          : this.totalChaptersFromApi,
      userTotalPagesOverride: data.userTotalPagesOverride.present
          ? data.userTotalPagesOverride.value
          : this.userTotalPagesOverride,
      userTotalChaptersOverride: data.userTotalChaptersOverride.present
          ? data.userTotalChaptersOverride.value
          : this.userTotalChaptersOverride,
      currentChapter: data.currentChapter.present
          ? data.currentChapter.value
          : this.currentChapter,
      bookTrackingMode: data.bookTrackingMode.present
          ? data.bookTrackingMode.value
          : this.bookTrackingMode,
      animeMediaStatus: data.animeMediaStatus.present
          ? data.animeMediaStatus.value
          : this.animeMediaStatus,
      releasedEpisodes: data.releasedEpisodes.present
          ? data.releasedEpisodes.value
          : this.releasedEpisodes,
      nextEpisodeAirsAt: data.nextEpisodeAirsAt.present
          ? data.nextEpisodeAirsAt.value
          : this.nextEpisodeAirsAt,
      steamAppId: data.steamAppId.present
          ? data.steamAppId.value
          : this.steamAppId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntry(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('externalId: $externalId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('progress: $progress, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('notes: $notes, ')
          ..write('editionKey: $editionKey, ')
          ..write('isbn: $isbn, ')
          ..write('totalPagesFromApi: $totalPagesFromApi, ')
          ..write('totalChaptersFromApi: $totalChaptersFromApi, ')
          ..write('userTotalPagesOverride: $userTotalPagesOverride, ')
          ..write('userTotalChaptersOverride: $userTotalChaptersOverride, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('bookTrackingMode: $bookTrackingMode, ')
          ..write('animeMediaStatus: $animeMediaStatus, ')
          ..write('releasedEpisodes: $releasedEpisodes, ')
          ..write('nextEpisodeAirsAt: $nextEpisodeAirsAt, ')
          ..write('steamAppId: $steamAppId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    kind,
    externalId,
    title,
    posterUrl,
    status,
    score,
    progress,
    totalEpisodes,
    notes,
    editionKey,
    isbn,
    totalPagesFromApi,
    totalChaptersFromApi,
    userTotalPagesOverride,
    userTotalChaptersOverride,
    currentChapter,
    bookTrackingMode,
    animeMediaStatus,
    releasedEpisodes,
    nextEpisodeAirsAt,
    steamAppId,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LibraryEntry &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.externalId == this.externalId &&
          other.title == this.title &&
          other.posterUrl == this.posterUrl &&
          other.status == this.status &&
          other.score == this.score &&
          other.progress == this.progress &&
          other.totalEpisodes == this.totalEpisodes &&
          other.notes == this.notes &&
          other.editionKey == this.editionKey &&
          other.isbn == this.isbn &&
          other.totalPagesFromApi == this.totalPagesFromApi &&
          other.totalChaptersFromApi == this.totalChaptersFromApi &&
          other.userTotalPagesOverride == this.userTotalPagesOverride &&
          other.userTotalChaptersOverride == this.userTotalChaptersOverride &&
          other.currentChapter == this.currentChapter &&
          other.bookTrackingMode == this.bookTrackingMode &&
          other.animeMediaStatus == this.animeMediaStatus &&
          other.releasedEpisodes == this.releasedEpisodes &&
          other.nextEpisodeAirsAt == this.nextEpisodeAirsAt &&
          other.steamAppId == this.steamAppId &&
          other.updatedAt == this.updatedAt);
}

class LibraryEntriesCompanion extends UpdateCompanion<LibraryEntry> {
  final Value<int> id;
  final Value<int> kind;
  final Value<String> externalId;
  final Value<String> title;
  final Value<String?> posterUrl;
  final Value<String> status;
  final Value<int?> score;
  final Value<int?> progress;
  final Value<int?> totalEpisodes;
  final Value<String?> notes;
  final Value<String?> editionKey;
  final Value<String?> isbn;
  final Value<int?> totalPagesFromApi;
  final Value<int?> totalChaptersFromApi;
  final Value<int?> userTotalPagesOverride;
  final Value<int?> userTotalChaptersOverride;
  final Value<int?> currentChapter;
  final Value<String?> bookTrackingMode;
  final Value<String?> animeMediaStatus;
  final Value<int?> releasedEpisodes;
  final Value<int?> nextEpisodeAirsAt;
  final Value<int?> steamAppId;
  final Value<int> updatedAt;
  const LibraryEntriesCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.externalId = const Value.absent(),
    this.title = const Value.absent(),
    this.posterUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.notes = const Value.absent(),
    this.editionKey = const Value.absent(),
    this.isbn = const Value.absent(),
    this.totalPagesFromApi = const Value.absent(),
    this.totalChaptersFromApi = const Value.absent(),
    this.userTotalPagesOverride = const Value.absent(),
    this.userTotalChaptersOverride = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.bookTrackingMode = const Value.absent(),
    this.animeMediaStatus = const Value.absent(),
    this.releasedEpisodes = const Value.absent(),
    this.nextEpisodeAirsAt = const Value.absent(),
    this.steamAppId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  LibraryEntriesCompanion.insert({
    this.id = const Value.absent(),
    required int kind,
    required String externalId,
    required String title,
    this.posterUrl = const Value.absent(),
    this.status = const Value.absent(),
    this.score = const Value.absent(),
    this.progress = const Value.absent(),
    this.totalEpisodes = const Value.absent(),
    this.notes = const Value.absent(),
    this.editionKey = const Value.absent(),
    this.isbn = const Value.absent(),
    this.totalPagesFromApi = const Value.absent(),
    this.totalChaptersFromApi = const Value.absent(),
    this.userTotalPagesOverride = const Value.absent(),
    this.userTotalChaptersOverride = const Value.absent(),
    this.currentChapter = const Value.absent(),
    this.bookTrackingMode = const Value.absent(),
    this.animeMediaStatus = const Value.absent(),
    this.releasedEpisodes = const Value.absent(),
    this.nextEpisodeAirsAt = const Value.absent(),
    this.steamAppId = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : kind = Value(kind),
       externalId = Value(externalId),
       title = Value(title);
  static Insertable<LibraryEntry> custom({
    Expression<int>? id,
    Expression<int>? kind,
    Expression<String>? externalId,
    Expression<String>? title,
    Expression<String>? posterUrl,
    Expression<String>? status,
    Expression<int>? score,
    Expression<int>? progress,
    Expression<int>? totalEpisodes,
    Expression<String>? notes,
    Expression<String>? editionKey,
    Expression<String>? isbn,
    Expression<int>? totalPagesFromApi,
    Expression<int>? totalChaptersFromApi,
    Expression<int>? userTotalPagesOverride,
    Expression<int>? userTotalChaptersOverride,
    Expression<int>? currentChapter,
    Expression<String>? bookTrackingMode,
    Expression<String>? animeMediaStatus,
    Expression<int>? releasedEpisodes,
    Expression<int>? nextEpisodeAirsAt,
    Expression<int>? steamAppId,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (externalId != null) 'external_id': externalId,
      if (title != null) 'title': title,
      if (posterUrl != null) 'poster_url': posterUrl,
      if (status != null) 'status': status,
      if (score != null) 'score': score,
      if (progress != null) 'progress': progress,
      if (totalEpisodes != null) 'total_episodes': totalEpisodes,
      if (notes != null) 'notes': notes,
      if (editionKey != null) 'edition_key': editionKey,
      if (isbn != null) 'isbn': isbn,
      if (totalPagesFromApi != null) 'total_pages_from_api': totalPagesFromApi,
      if (totalChaptersFromApi != null)
        'total_chapters_from_api': totalChaptersFromApi,
      if (userTotalPagesOverride != null)
        'user_total_pages_override': userTotalPagesOverride,
      if (userTotalChaptersOverride != null)
        'user_total_chapters_override': userTotalChaptersOverride,
      if (currentChapter != null) 'current_chapter': currentChapter,
      if (bookTrackingMode != null) 'book_tracking_mode': bookTrackingMode,
      if (animeMediaStatus != null) 'anime_media_status': animeMediaStatus,
      if (releasedEpisodes != null) 'released_episodes': releasedEpisodes,
      if (nextEpisodeAirsAt != null) 'next_episode_airs_at': nextEpisodeAirsAt,
      if (steamAppId != null) 'steam_app_id': steamAppId,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  LibraryEntriesCompanion copyWith({
    Value<int>? id,
    Value<int>? kind,
    Value<String>? externalId,
    Value<String>? title,
    Value<String?>? posterUrl,
    Value<String>? status,
    Value<int?>? score,
    Value<int?>? progress,
    Value<int?>? totalEpisodes,
    Value<String?>? notes,
    Value<String?>? editionKey,
    Value<String?>? isbn,
    Value<int?>? totalPagesFromApi,
    Value<int?>? totalChaptersFromApi,
    Value<int?>? userTotalPagesOverride,
    Value<int?>? userTotalChaptersOverride,
    Value<int?>? currentChapter,
    Value<String?>? bookTrackingMode,
    Value<String?>? animeMediaStatus,
    Value<int?>? releasedEpisodes,
    Value<int?>? nextEpisodeAirsAt,
    Value<int?>? steamAppId,
    Value<int>? updatedAt,
  }) {
    return LibraryEntriesCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      externalId: externalId ?? this.externalId,
      title: title ?? this.title,
      posterUrl: posterUrl ?? this.posterUrl,
      status: status ?? this.status,
      score: score ?? this.score,
      progress: progress ?? this.progress,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      notes: notes ?? this.notes,
      editionKey: editionKey ?? this.editionKey,
      isbn: isbn ?? this.isbn,
      totalPagesFromApi: totalPagesFromApi ?? this.totalPagesFromApi,
      totalChaptersFromApi: totalChaptersFromApi ?? this.totalChaptersFromApi,
      userTotalPagesOverride:
          userTotalPagesOverride ?? this.userTotalPagesOverride,
      userTotalChaptersOverride:
          userTotalChaptersOverride ?? this.userTotalChaptersOverride,
      currentChapter: currentChapter ?? this.currentChapter,
      bookTrackingMode: bookTrackingMode ?? this.bookTrackingMode,
      animeMediaStatus: animeMediaStatus ?? this.animeMediaStatus,
      releasedEpisodes: releasedEpisodes ?? this.releasedEpisodes,
      nextEpisodeAirsAt: nextEpisodeAirsAt ?? this.nextEpisodeAirsAt,
      steamAppId: steamAppId ?? this.steamAppId,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<int>(kind.value);
    }
    if (externalId.present) {
      map['external_id'] = Variable<String>(externalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (posterUrl.present) {
      map['poster_url'] = Variable<String>(posterUrl.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (progress.present) {
      map['progress'] = Variable<int>(progress.value);
    }
    if (totalEpisodes.present) {
      map['total_episodes'] = Variable<int>(totalEpisodes.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (editionKey.present) {
      map['edition_key'] = Variable<String>(editionKey.value);
    }
    if (isbn.present) {
      map['isbn'] = Variable<String>(isbn.value);
    }
    if (totalPagesFromApi.present) {
      map['total_pages_from_api'] = Variable<int>(totalPagesFromApi.value);
    }
    if (totalChaptersFromApi.present) {
      map['total_chapters_from_api'] = Variable<int>(
        totalChaptersFromApi.value,
      );
    }
    if (userTotalPagesOverride.present) {
      map['user_total_pages_override'] = Variable<int>(
        userTotalPagesOverride.value,
      );
    }
    if (userTotalChaptersOverride.present) {
      map['user_total_chapters_override'] = Variable<int>(
        userTotalChaptersOverride.value,
      );
    }
    if (currentChapter.present) {
      map['current_chapter'] = Variable<int>(currentChapter.value);
    }
    if (bookTrackingMode.present) {
      map['book_tracking_mode'] = Variable<String>(bookTrackingMode.value);
    }
    if (animeMediaStatus.present) {
      map['anime_media_status'] = Variable<String>(animeMediaStatus.value);
    }
    if (releasedEpisodes.present) {
      map['released_episodes'] = Variable<int>(releasedEpisodes.value);
    }
    if (nextEpisodeAirsAt.present) {
      map['next_episode_airs_at'] = Variable<int>(nextEpisodeAirsAt.value);
    }
    if (steamAppId.present) {
      map['steam_app_id'] = Variable<int>(steamAppId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LibraryEntriesCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('externalId: $externalId, ')
          ..write('title: $title, ')
          ..write('posterUrl: $posterUrl, ')
          ..write('status: $status, ')
          ..write('score: $score, ')
          ..write('progress: $progress, ')
          ..write('totalEpisodes: $totalEpisodes, ')
          ..write('notes: $notes, ')
          ..write('editionKey: $editionKey, ')
          ..write('isbn: $isbn, ')
          ..write('totalPagesFromApi: $totalPagesFromApi, ')
          ..write('totalChaptersFromApi: $totalChaptersFromApi, ')
          ..write('userTotalPagesOverride: $userTotalPagesOverride, ')
          ..write('userTotalChaptersOverride: $userTotalChaptersOverride, ')
          ..write('currentChapter: $currentChapter, ')
          ..write('bookTrackingMode: $bookTrackingMode, ')
          ..write('animeMediaStatus: $animeMediaStatus, ')
          ..write('releasedEpisodes: $releasedEpisodes, ')
          ..write('nextEpisodeAirsAt: $nextEpisodeAirsAt, ')
          ..write('steamAppId: $steamAppId, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $KeyValueEntriesTable keyValueEntries = $KeyValueEntriesTable(
    this,
  );
  late final $LibraryEntriesTable libraryEntries = $LibraryEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueEntries,
    libraryEntries,
  ];
}

typedef $$KeyValueEntriesTableCreateCompanionBuilder =
    KeyValueEntriesCompanion Function({
      Value<int> id,
      required String key,
      Value<String?> value,
    });
typedef $$KeyValueEntriesTableUpdateCompanionBuilder =
    KeyValueEntriesCompanion Function({
      Value<int> id,
      Value<String> key,
      Value<String?> value,
    });

class $$KeyValueEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $KeyValueEntriesTable> {
  $$KeyValueEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $KeyValueEntriesTable,
          KeyValueEntry,
          $$KeyValueEntriesTableFilterComposer,
          $$KeyValueEntriesTableOrderingComposer,
          $$KeyValueEntriesTableAnnotationComposer,
          $$KeyValueEntriesTableCreateCompanionBuilder,
          $$KeyValueEntriesTableUpdateCompanionBuilder,
          (
            KeyValueEntry,
            BaseReferences<_$AppDatabase, $KeyValueEntriesTable, KeyValueEntry>,
          ),
          KeyValueEntry,
          PrefetchHooks Function()
        > {
  $$KeyValueEntriesTableTableManager(
    _$AppDatabase db,
    $KeyValueEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
              }) => KeyValueEntriesCompanion(id: id, key: key, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String key,
                Value<String?> value = const Value.absent(),
              }) => KeyValueEntriesCompanion.insert(
                id: id,
                key: key,
                value: value,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $KeyValueEntriesTable,
      KeyValueEntry,
      $$KeyValueEntriesTableFilterComposer,
      $$KeyValueEntriesTableOrderingComposer,
      $$KeyValueEntriesTableAnnotationComposer,
      $$KeyValueEntriesTableCreateCompanionBuilder,
      $$KeyValueEntriesTableUpdateCompanionBuilder,
      (
        KeyValueEntry,
        BaseReferences<_$AppDatabase, $KeyValueEntriesTable, KeyValueEntry>,
      ),
      KeyValueEntry,
      PrefetchHooks Function()
    >;
typedef $$LibraryEntriesTableCreateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<int> id,
      required int kind,
      required String externalId,
      required String title,
      Value<String?> posterUrl,
      Value<String> status,
      Value<int?> score,
      Value<int?> progress,
      Value<int?> totalEpisodes,
      Value<String?> notes,
      Value<String?> editionKey,
      Value<String?> isbn,
      Value<int?> totalPagesFromApi,
      Value<int?> totalChaptersFromApi,
      Value<int?> userTotalPagesOverride,
      Value<int?> userTotalChaptersOverride,
      Value<int?> currentChapter,
      Value<String?> bookTrackingMode,
      Value<String?> animeMediaStatus,
      Value<int?> releasedEpisodes,
      Value<int?> nextEpisodeAirsAt,
      Value<int?> steamAppId,
      Value<int> updatedAt,
    });
typedef $$LibraryEntriesTableUpdateCompanionBuilder =
    LibraryEntriesCompanion Function({
      Value<int> id,
      Value<int> kind,
      Value<String> externalId,
      Value<String> title,
      Value<String?> posterUrl,
      Value<String> status,
      Value<int?> score,
      Value<int?> progress,
      Value<int?> totalEpisodes,
      Value<String?> notes,
      Value<String?> editionKey,
      Value<String?> isbn,
      Value<int?> totalPagesFromApi,
      Value<int?> totalChaptersFromApi,
      Value<int?> userTotalPagesOverride,
      Value<int?> userTotalChaptersOverride,
      Value<int?> currentChapter,
      Value<String?> bookTrackingMode,
      Value<String?> animeMediaStatus,
      Value<int?> releasedEpisodes,
      Value<int?> nextEpisodeAirsAt,
      Value<int?> steamAppId,
      Value<int> updatedAt,
    });

class $$LibraryEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get editionKey => $composableBuilder(
    column: $table.editionKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalPagesFromApi => $composableBuilder(
    column: $table.totalPagesFromApi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalChaptersFromApi => $composableBuilder(
    column: $table.totalChaptersFromApi,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userTotalPagesOverride => $composableBuilder(
    column: $table.userTotalPagesOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get userTotalChaptersOverride => $composableBuilder(
    column: $table.userTotalChaptersOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get bookTrackingMode => $composableBuilder(
    column: $table.bookTrackingMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get animeMediaStatus => $composableBuilder(
    column: $table.animeMediaStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get releasedEpisodes => $composableBuilder(
    column: $table.releasedEpisodes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextEpisodeAirsAt => $composableBuilder(
    column: $table.nextEpisodeAirsAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get steamAppId => $composableBuilder(
    column: $table.steamAppId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LibraryEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterUrl => $composableBuilder(
    column: $table.posterUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get editionKey => $composableBuilder(
    column: $table.editionKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get isbn => $composableBuilder(
    column: $table.isbn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalPagesFromApi => $composableBuilder(
    column: $table.totalPagesFromApi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalChaptersFromApi => $composableBuilder(
    column: $table.totalChaptersFromApi,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userTotalPagesOverride => $composableBuilder(
    column: $table.userTotalPagesOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get userTotalChaptersOverride => $composableBuilder(
    column: $table.userTotalChaptersOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get bookTrackingMode => $composableBuilder(
    column: $table.bookTrackingMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get animeMediaStatus => $composableBuilder(
    column: $table.animeMediaStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get releasedEpisodes => $composableBuilder(
    column: $table.releasedEpisodes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextEpisodeAirsAt => $composableBuilder(
    column: $table.nextEpisodeAirsAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get steamAppId => $composableBuilder(
    column: $table.steamAppId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LibraryEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LibraryEntriesTable> {
  $$LibraryEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get externalId => $composableBuilder(
    column: $table.externalId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get posterUrl =>
      $composableBuilder(column: $table.posterUrl, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<int> get totalEpisodes => $composableBuilder(
    column: $table.totalEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get editionKey => $composableBuilder(
    column: $table.editionKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get isbn =>
      $composableBuilder(column: $table.isbn, builder: (column) => column);

  GeneratedColumn<int> get totalPagesFromApi => $composableBuilder(
    column: $table.totalPagesFromApi,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalChaptersFromApi => $composableBuilder(
    column: $table.totalChaptersFromApi,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userTotalPagesOverride => $composableBuilder(
    column: $table.userTotalPagesOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get userTotalChaptersOverride => $composableBuilder(
    column: $table.userTotalChaptersOverride,
    builder: (column) => column,
  );

  GeneratedColumn<int> get currentChapter => $composableBuilder(
    column: $table.currentChapter,
    builder: (column) => column,
  );

  GeneratedColumn<String> get bookTrackingMode => $composableBuilder(
    column: $table.bookTrackingMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get animeMediaStatus => $composableBuilder(
    column: $table.animeMediaStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get releasedEpisodes => $composableBuilder(
    column: $table.releasedEpisodes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get nextEpisodeAirsAt => $composableBuilder(
    column: $table.nextEpisodeAirsAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get steamAppId => $composableBuilder(
    column: $table.steamAppId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LibraryEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LibraryEntriesTable,
          LibraryEntry,
          $$LibraryEntriesTableFilterComposer,
          $$LibraryEntriesTableOrderingComposer,
          $$LibraryEntriesTableAnnotationComposer,
          $$LibraryEntriesTableCreateCompanionBuilder,
          $$LibraryEntriesTableUpdateCompanionBuilder,
          (
            LibraryEntry,
            BaseReferences<_$AppDatabase, $LibraryEntriesTable, LibraryEntry>,
          ),
          LibraryEntry,
          PrefetchHooks Function()
        > {
  $$LibraryEntriesTableTableManager(
    _$AppDatabase db,
    $LibraryEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LibraryEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LibraryEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LibraryEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> kind = const Value.absent(),
                Value<String> externalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> posterUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> progress = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> editionKey = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<int?> totalPagesFromApi = const Value.absent(),
                Value<int?> totalChaptersFromApi = const Value.absent(),
                Value<int?> userTotalPagesOverride = const Value.absent(),
                Value<int?> userTotalChaptersOverride = const Value.absent(),
                Value<int?> currentChapter = const Value.absent(),
                Value<String?> bookTrackingMode = const Value.absent(),
                Value<String?> animeMediaStatus = const Value.absent(),
                Value<int?> releasedEpisodes = const Value.absent(),
                Value<int?> nextEpisodeAirsAt = const Value.absent(),
                Value<int?> steamAppId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => LibraryEntriesCompanion(
                id: id,
                kind: kind,
                externalId: externalId,
                title: title,
                posterUrl: posterUrl,
                status: status,
                score: score,
                progress: progress,
                totalEpisodes: totalEpisodes,
                notes: notes,
                editionKey: editionKey,
                isbn: isbn,
                totalPagesFromApi: totalPagesFromApi,
                totalChaptersFromApi: totalChaptersFromApi,
                userTotalPagesOverride: userTotalPagesOverride,
                userTotalChaptersOverride: userTotalChaptersOverride,
                currentChapter: currentChapter,
                bookTrackingMode: bookTrackingMode,
                animeMediaStatus: animeMediaStatus,
                releasedEpisodes: releasedEpisodes,
                nextEpisodeAirsAt: nextEpisodeAirsAt,
                steamAppId: steamAppId,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int kind,
                required String externalId,
                required String title,
                Value<String?> posterUrl = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int?> score = const Value.absent(),
                Value<int?> progress = const Value.absent(),
                Value<int?> totalEpisodes = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> editionKey = const Value.absent(),
                Value<String?> isbn = const Value.absent(),
                Value<int?> totalPagesFromApi = const Value.absent(),
                Value<int?> totalChaptersFromApi = const Value.absent(),
                Value<int?> userTotalPagesOverride = const Value.absent(),
                Value<int?> userTotalChaptersOverride = const Value.absent(),
                Value<int?> currentChapter = const Value.absent(),
                Value<String?> bookTrackingMode = const Value.absent(),
                Value<String?> animeMediaStatus = const Value.absent(),
                Value<int?> releasedEpisodes = const Value.absent(),
                Value<int?> nextEpisodeAirsAt = const Value.absent(),
                Value<int?> steamAppId = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => LibraryEntriesCompanion.insert(
                id: id,
                kind: kind,
                externalId: externalId,
                title: title,
                posterUrl: posterUrl,
                status: status,
                score: score,
                progress: progress,
                totalEpisodes: totalEpisodes,
                notes: notes,
                editionKey: editionKey,
                isbn: isbn,
                totalPagesFromApi: totalPagesFromApi,
                totalChaptersFromApi: totalChaptersFromApi,
                userTotalPagesOverride: userTotalPagesOverride,
                userTotalChaptersOverride: userTotalChaptersOverride,
                currentChapter: currentChapter,
                bookTrackingMode: bookTrackingMode,
                animeMediaStatus: animeMediaStatus,
                releasedEpisodes: releasedEpisodes,
                nextEpisodeAirsAt: nextEpisodeAirsAt,
                steamAppId: steamAppId,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LibraryEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LibraryEntriesTable,
      LibraryEntry,
      $$LibraryEntriesTableFilterComposer,
      $$LibraryEntriesTableOrderingComposer,
      $$LibraryEntriesTableAnnotationComposer,
      $$LibraryEntriesTableCreateCompanionBuilder,
      $$LibraryEntriesTableUpdateCompanionBuilder,
      (
        LibraryEntry,
        BaseReferences<_$AppDatabase, $LibraryEntriesTable, LibraryEntry>,
      ),
      LibraryEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$KeyValueEntriesTableTableManager get keyValueEntries =>
      $$KeyValueEntriesTableTableManager(_db, _db.keyValueEntries);
  $$LibraryEntriesTableTableManager get libraryEntries =>
      $$LibraryEntriesTableTableManager(_db, _db.libraryEntries);
}
