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
  Stream<List<LibraryEntry>> watchLibraryByKind(int kindCode) {
    return (select(libraryEntries)
          ..where((t) => t.kind.equals(kindCode))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Stream<List<LibraryEntry>> watchAllLibrary() {
    return (select(libraryEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .watch();
  }

  Future<int> upsertLibraryEntry(LibraryEntriesCompanion entry) {
    return into(libraryEntries).insertOnConflictUpdate(entry);
  }

  Future<void> deleteLibraryEntry(int id) {
    return (delete(libraryEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<List<LibraryEntry>> getAllLibraryEntries() {
    return select(libraryEntries).get();
  }

  Future<List<KeyValueEntry>> getAllKeyValues() {
    return select(keyValueEntries).get();
  }
}
