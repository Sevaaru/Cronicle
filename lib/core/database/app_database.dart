import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:cronicle/features/library/domain/anime_airing_progress.dart';

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

  TextColumn get editionKey => text().nullable()();
  TextColumn get isbn => text().nullable()();
  IntColumn get totalPagesFromApi => integer().nullable()();
  IntColumn get totalChaptersFromApi => integer().nullable()();
  IntColumn get userTotalPagesOverride => integer().nullable()();
  IntColumn get userTotalChaptersOverride => integer().nullable()();
  IntColumn get currentChapter => integer().nullable()();
  TextColumn get bookTrackingMode => text().nullable()();

  TextColumn get animeMediaStatus => text().nullable()();

  IntColumn get releasedEpisodes => integer().nullable()();

  IntColumn get nextEpisodeAirsAt => integer().nullable()();

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
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(libraryEntries);
          }
          if (from < 3) {
            await customStatement(
              'UPDATE library_entries SET score = score * 10 WHERE score IS NOT NULL AND score > 0',
            );
          }
          if (from < 4) {
            await customStatement('ALTER TABLE library_entries ADD COLUMN edition_key TEXT');
            await customStatement('ALTER TABLE library_entries ADD COLUMN isbn TEXT');
            await customStatement('ALTER TABLE library_entries ADD COLUMN total_pages_from_api INTEGER');
            await customStatement('ALTER TABLE library_entries ADD COLUMN total_chapters_from_api INTEGER');
            await customStatement('ALTER TABLE library_entries ADD COLUMN user_total_pages_override INTEGER');
            await customStatement('ALTER TABLE library_entries ADD COLUMN user_total_chapters_override INTEGER');
            await customStatement('ALTER TABLE library_entries ADD COLUMN current_chapter INTEGER');
            await customStatement('ALTER TABLE library_entries ADD COLUMN book_tracking_mode TEXT');
          }
          if (from < 5) {
            await customStatement('ALTER TABLE library_entries ADD COLUMN anime_media_status TEXT');
            await customStatement('ALTER TABLE library_entries ADD COLUMN released_episodes INTEGER');
          }
          if (from < 6) {
            await customStatement(
              'ALTER TABLE library_entries ADD COLUMN next_episode_airs_at INTEGER',
            );
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

  Stream<List<LibraryEntry>> watchLibraryByKind(int kindCode, {String? status}) {
    return (select(libraryEntries)
          ..where((t) {
            var expr = t.kind.equals(kindCode);
            if (status != null) {
              expr = expr & t.status.upper().equals(status.toUpperCase());
            }
            return expr;
          })
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
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
          ..orderBy([
            (t) => OrderingTerm.desc(t.updatedAt),
            (t) => OrderingTerm.desc(t.id),
          ]))
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

  Future<int> upsertLibraryEntryIfNewer(LibraryEntriesCompanion entry) async {
    final kindVal = entry.kind.value;
    final extId = entry.externalId.value;
    final existing = await getLibraryEntryByKindAndExternalId(kindVal, extId);
    if (existing == null) {
      return into(libraryEntries).insert(entry, mode: InsertMode.insertOrReplace);
    }
    final incomingMs = entry.updatedAt.value;
    if (incomingMs > existing.updatedAt) {
      return into(libraryEntries).insert(
        entry,
        onConflict: DoUpdate(
          (old) => entry,
          target: [libraryEntries.kind, libraryEntries.externalId],
        ),
      );
    }
    return existing.id;
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
        (t) => ascending ? OrderingTerm.asc(t.id) : OrderingTerm.desc(t.id),
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
    final cap = AnimeAiringProgress.animeEpisodeProgressCap(
      mediaKindCode: entry.kind,
      totalEpisodes: entry.totalEpisodes,
      releasedEpisodes: entry.releasedEpisodes,
    );
    if (cap != null && current >= cap) return;
    final next = current + 1;
    final seriesTotal = entry.totalEpisodes;
    final reachedTotal =
        seriesTotal != null && seriesTotal > 0 && next >= seriesTotal;
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(next),
        status: reachedTotal ? const Value('COMPLETED') : const Value.absent(),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> incrementBookProgress(int entryId) async {
    final entry = await getLibraryEntryById(entryId);
    if (entry == null) return;
    if (entry.kind != 5) return;

    final mode = (entry.bookTrackingMode ?? 'pages').toLowerCase();

    if (mode == 'chapters') {
      final current = entry.currentChapter ?? 0;
      final total = entry.userTotalChaptersOverride ?? entry.totalChaptersFromApi;
      if (total != null && current >= total) return;
      final next = current + 1;
      final reachedTotal = total != null && total > 0 && next >= total;
      await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
        LibraryEntriesCompanion(
          currentChapter: Value(next),
          status: reachedTotal ? const Value('COMPLETED') : const Value.absent(),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ),
      );
      return;
    }

    final current = entry.progress ?? 0;
    final total = mode == 'percentage'
        ? 100
        : entry.userTotalPagesOverride ?? entry.totalPagesFromApi ?? entry.totalEpisodes;
    if (total != null && current >= total) return;
    final next = current + 1;
    final reachedTotal = total != null && total > 0 && next >= total;
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(next),
        status: reachedTotal ? const Value('COMPLETED') : const Value.absent(),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> setLibraryProgress(int entryId, int progress) async {
    final entry = await getLibraryEntryById(entryId);
    if (entry == null) return;
    var p = progress;
    if (p < 0) p = 0;
    final cap = AnimeAiringProgress.animeEpisodeProgressCap(
      mediaKindCode: entry.kind,
      totalEpisodes: entry.totalEpisodes,
      releasedEpisodes: entry.releasedEpisodes,
    );
    if (cap != null && p > cap) p = cap;
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
    final cap = AnimeAiringProgress.animeEpisodeProgressCap(
      mediaKindCode: entry.kind,
      totalEpisodes: entry.totalEpisodes,
      releasedEpisodes: entry.releasedEpisodes,
    );
    if (cap != null && p > cap) p = cap;
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        progress: Value(p),
        status: Value(status.toUpperCase()),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateLibraryEntryRatingAndNotes({
    required int entryId,
    required int? score,
    required String? notes,
  }) async {
    await (update(libraryEntries)..where((t) => t.id.equals(entryId))).write(
      LibraryEntriesCompanion(
        score: Value(score),
        notes: Value(notes),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateAnimeAiringMetadata({
    required int id,
    required String? animeMediaStatus,
    required int? releasedEpisodes,
    required int? nextEpisodeAirsAt,
  }) async {
    final entry = await getLibraryEntryById(id);
    if (entry == null) return;
    final cap = AnimeAiringProgress.animeEpisodeProgressCap(
      mediaKindCode: entry.kind,
      totalEpisodes: entry.totalEpisodes,
      releasedEpisodes: releasedEpisodes,
    );
    var p = entry.progress ?? 0;
    if (cap != null && p > cap) p = cap;
    await (update(libraryEntries)..where((t) => t.id.equals(id))).write(
      LibraryEntriesCompanion(
        animeMediaStatus: Value(animeMediaStatus),
        releasedEpisodes: Value(releasedEpisodes),
        nextEpisodeAirsAt: Value(nextEpisodeAirsAt),
        progress: p != (entry.progress ?? 0) ? Value(p) : const Value.absent(),
      ),
    );
  }

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
