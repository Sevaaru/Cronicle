import 'package:cronicle/core/database/app_database.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<int> insertAnime({required String status, required int progress}) {
    return db.upsertLibraryEntry(
      LibraryEntriesCompanion(
        kind: const Value(0),
        externalId: const Value('1'),
        title: const Value('Test'),
        status: Value(status),
        progress: Value(progress),
        totalEpisodes: const Value(12),
      ),
    );
  }

  test('una entrada nueva empieza con 0 repeticiones', () async {
    final id = await insertAnime(status: 'CURRENT', progress: 0);
    final entry = await db.getLibraryEntryById(id);
    expect(entry!.repeatCount, 0);
  });

  test('terminar una repetición con +1 suma una repetición', () async {
    final id = await insertAnime(status: 'REPEATING', progress: 11);
    await db.incrementProgress(id);
    final entry = await db.getLibraryEntryById(id);
    expect(entry!.status, 'COMPLETED');
    expect(entry.repeatCount, 1);
  });

  test('completar por primera vez no suma repeticiones', () async {
    final id = await insertAnime(status: 'CURRENT', progress: 11);
    await db.incrementProgress(id);
    final entry = await db.getLibraryEntryById(id);
    expect(entry!.status, 'COMPLETED');
    expect(entry.repeatCount, 0);
  });
}
