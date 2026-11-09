import 'dart:io';

import 'package:cronicle/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late File file;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('cronicle_v8_');
    file = File('${dir.path}/cronicle.db');
  });
  tearDown(() => dir.deleteSync(recursive: true));

  /// Crea una BD actual y la deja como una v7 a la que le falta [dropColumn].
  Future<void> seedV7Without(String dropColumn) async {
    final fresh = AppDatabase(NativeDatabase(file));
    await fresh.upsertLibraryEntry(
      const LibraryEntriesCompanion(
        kind: Value(0),
        externalId: Value('1'),
        title: Value('Test'),
        status: Value('COMPLETED'),
      ),
    );
    await fresh.close();
    final legacy = AppDatabase(
      NativeDatabase(
        file,
        setup: (raw) {
          raw.execute('ALTER TABLE library_entries DROP COLUMN $dropColumn');
          raw.execute('PRAGMA user_version = 7');
        },
      ),
    );
    await legacy.close();
  }

  Future<Set<String>> columnsAfterUpgrade() async {
    final db = AppDatabase(NativeDatabase(file));
    final cols = await db
        .customSelect('PRAGMA table_info(library_entries)')
        .map((r) => r.read<String>('name'))
        .get();
    final entry = await db.getLibraryEntryByKindAndExternalId(0, '1');
    expect(entry, isNotNull);
    expect(entry!.repeatCount, 0);
    await db.close();
    return cols.toSet();
  }

  test('v7 de main (sin repeat_count) migra a v8', () async {
    await seedV7Without('repeat_count');
    final cols = await columnsAfterUpgrade();
    expect(cols, containsAll(['repeat_count', 'steam_app_id']));
  });

  test('v7 de development (sin steam_app_id) migra a v8', () async {
    await seedV7Without('steam_app_id');
    final cols = await columnsAfterUpgrade();
    expect(cols, containsAll(['repeat_count', 'steam_app_id']));
  });
}
