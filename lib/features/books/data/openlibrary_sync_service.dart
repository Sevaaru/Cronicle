import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Imports a user's Open Library public reading log into the local database.
///
/// Maps shelves: want-to-read → PLANNING, currently-reading → CURRENT,
/// already-read → COMPLETED. Does NOT overwrite entries the user already has.
Future<int> syncOpenLibraryReadingLog(WidgetRef ref) async {
  final username = ref.read(openLibraryUsernameProvider);
  if (username == null || username.isEmpty) return 0;

  final api = ref.read(openLibraryApiProvider);
  final db = ref.read(databaseProvider);

  const shelves = {
    'want-to-read': 'PLANNING',
    'currently-reading': 'CURRENT',
    'already-read': 'COMPLETED',
  };

  var importedCount = 0;

  for (final entry in shelves.entries) {
    try {
      final items = await api.fetchUserReadingLog(username, entry.key, limit: 200);
      for (final item in items) {
        final workKey = item['workKey'] as String?;
        if (workKey == null || workKey.isEmpty) continue;

        // Skip if already in local library.
        final existing = await db.getLibraryEntryByKindAndExternalId(
          MediaKind.book.code,
          workKey,
        );
        if (existing != null) continue;

        final title = item['title'] as Map<String, dynamic>? ?? {};
        final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};

        await db.upsertLibraryEntry(
          LibraryEntriesCompanion(
            kind: drift.Value(MediaKind.book.code),
            externalId: drift.Value(workKey),
            title: drift.Value(
              (title['english'] as String?) ??
                  (title['romaji'] as String?) ??
                  'Unknown',
            ),
            posterUrl: drift.Value(
              (coverImage['extraLarge'] as String?) ??
                  (coverImage['large'] as String?),
            ),
            status: drift.Value(entry.value),
            score: const drift.Value(null),
            progress: const drift.Value(0),
            totalEpisodes: const drift.Value(null),
            notes: const drift.Value(null),
            updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
        importedCount++;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Cronicle] OL sync error for ${entry.key}: $e');
    }
  }

  return importedCount;
}
