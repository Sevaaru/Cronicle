import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

@DataClassName('KeyValueEntry')
class KeyValueEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get key => text().unique()();
  TextColumn get value => text().nullable()();
}

@DataClassName('LibraryEntry')
class LibraryEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get kind => integer()();
  TextColumn get externalId => text()();
  TextColumn get title => text()();
  TextColumn get posterUrl => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('planning'))();
  IntColumn get score => integer().nullable()();
  IntColumn get progress => integer().nullable()();
  IntColumn get totalEpisodes => integer().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get updatedAt =>
      integer().withDefault(Constant(DateTime.now().millisecondsSinceEpoch))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {kind, externalId},
      ];
}

@DriftDatabase(tables: [KeyValueEntries, LibraryEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(libraryEntries);
          }
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'cronicle.db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  // Key-value helpers
  Future<void> setKeyValue(String key, String? value) async {
    await into(keyValueEntries).insertOnConflictUpdate(
      KeyValueEntriesCompanion.insert(
        key: key,
        value: value == null ? const Value.absent() : Value(value),
      ),
    );
  }

  Future<String?> getKeyValue(String key) async {
    final row = await (select(keyValueEntries)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  // Library helpers
  Stream<List<LibraryEntry>> watchLibraryByKind(int kindCode, {String? status}) {
    return (select(libraryEntries)
          ..where((t) {
            var expr = t.kind.equals(kindCode);
            if (status != null) {
              expr = expr & t.status.upper().equals(status.toUpperCase());
            }
            return expr;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<LibraryEntry>> watchAllLibrary({String? status}) {
    return (select(libraryEntries)
          ..where((t) {
            if (status != null) {
              return t.status.upper().equals(status.toUpperCase());
            }
            return const Constant(true);
          })
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<int> upsertLibraryEntry(LibraryEntriesCompanion entry) {
    return into(libraryEntries).insert(
      entry,
      onConflict: DoUpdate(
        (old) => entry,
        target: [libraryEntries.kind, libraryEntries.externalId],
      ),
    );
  }

  Future<void> deleteLibraryEntry(int id) {
    return (delete(libraryEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<List<LibraryEntry>> getAllLibraryEntries() {
    return select(libraryEntries).get();
  }

  Future<List<LibraryEntry>> getLibraryPage({
    int? kindCode,
    String? status,
    required int limit,
    required int offset,
    String orderBy = 'updatedAt',
    bool ascending = false,
  }) {
    final q = select(libraryEntries)
      ..where((t) {
        Expression<bool> expr = const Constant(true);
        if (kindCode != null) expr = expr & t.kind.equals(kindCode);
        if (status != null) expr = expr & t.status.upper().equals(status.toUpperCase());
        return expr;
      })
      ..orderBy([
        (t) => switch (orderBy) {
              'title' => ascending ? OrderingTerm.asc(t.title) : OrderingTerm.desc(t.title),
              'score' => ascending ? OrderingTerm.asc(t.score) : OrderingTerm.desc(t.score),
              'progress' => ascending ? OrderingTerm.asc(t.progress) : OrderingTerm.desc(t.progress),
              _ => ascending ? OrderingTerm.asc(t.updatedAt) : OrderingTerm.desc(t.updatedAt),
            },
      ])
      ..limit(limit, offset: offset);
    return q.get();
  }

  Future<int> countLibrary({int? kindCode, String? status}) async {
    final countExp = libraryEntries.id.count();
    final q = selectOnly(libraryEntries)..addColumns([countExp]);
    if (kindCode != null) {
      q.where(libraryEntries.kind.equals(kindCode));
    }
    if (status != null) {
      q.where(libraryEntries.status.upper().equals(status.toUpperCase()));
    }
    final row = await q.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<LibraryEntry?> getLibraryEntryById(int id) {
    return (select(libraryEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<LibraryEntry?> getLibraryEntryByKindAndExternalId(int kindCode, String externalId) {
    return (select(libraryEntries)
          ..where((t) => t.kind.equals(kindCode) & t.externalId.equals(externalId)))
        .getSingleOrNull();
  }

  Future<void> incrementProgress(int entryId) async {
    final entry = await getLibraryEntryById(entryId);
    if (entry == null) return;
    final current = entry.progress ?? 0;
    if (entry.totalEpisodes != null && current >= entry.totalEpisodes!) return;
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(current + 1),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setLibraryProgress(int entryId, int progress) async {
    final entry = await getLibraryEntryById(entryId);
    if (entry == null) return;
    var p = progress;
    if (p < 0) p = 0;
    if (entry.totalEpisodes != null && p > entry.totalEpisodes!) {
      p = entry.totalEpisodes!;
    }
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(p),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setLibraryProgressAndStatus(
    int entryId,
    int progress,
    String status,
  ) async {
    final entry = await getLibraryEntryById(entryId);
    if (entry == null) return;
    var p = progress;
    if (p < 0) p = 0;
    if (entry.totalEpisodes != null && p > entry.totalEpisodes!) {
      p = entry.totalEpisodes!;
    }
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(p),
        status: Value(status.toUpperCase()),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  /// Normaliza todos los status a uppercase para corregir entries guardados con lowercase.
  Future<void> normalizeStatuses() async {
    final all = await select(libraryEntries).get();
    for (final entry in all) {
      final upper = entry.status.toUpperCase();
      if (entry.status != upper) {
        await (update(libraryEntries)..where((t) => t.id.equals(entry.id)))
            .write(LibraryEntriesCompanion(status: Value(upper)));
      }
    }
  }

  Future<List<KeyValueEntry>> getAllKeyValues() {
    return select(keyValueEntries).get();
  }
}
