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
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
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
    updatedAt,
  );
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
