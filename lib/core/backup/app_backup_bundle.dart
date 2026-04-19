import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/library_kind_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:drift/drift.dart' show Value;

/// Claves en [FlutterSecureStorage] que se incluyen en el backup cifrado en Drive.
const _secureKeysForBackup = <String>[
  'anilist_access_token',
  'anilist_user_name',
  'igdb_access_token',
  'igdb_token_expires_at',
  'twitch_user_access_token',
  'twitch_user_refresh_token',
  'twitch_user_token_expires_ms',
  'twitch_user_login',
  'trakt_access_token',
  'trakt_refresh_token',
  'trakt_token_expires_at_ms',
  'trakt_user_slug',
  'trakt_user_name',
  'trakt_user_avatar_url',
];

/// JSON de copia: biblioteca Drift, key-value Drift, SharedPreferences y tokens seguros.
abstract final class AppBackupBundle {
  static const currentVersion = 3;

  static Future<Map<String, dynamic>> build({
    required AppDatabase db,
    required SharedPreferences prefs,
    required FlutterSecureStorage secure,
  }) async {
    final entries = await db.getAllLibraryEntries();
    final kv = await db.getAllKeyValues();

    final secureOut = <String, String>{};
    for (final key in _secureKeysForBackup) {
      final v = await secure.read(key: key);
      if (v != null && v.isNotEmpty) {
        secureOut[key] = v;
      }
    }

    return {
      'version': currentVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'library': entries
          .map((e) => {
                'kind': e.kind,
                'externalId': e.externalId,
                'title': e.title,
                'posterUrl': e.posterUrl,
                'status': e.status,
                'score': e.score,
                'progress': e.progress,
                'totalEpisodes': e.totalEpisodes,
                'animeMediaStatus': e.animeMediaStatus,
                'releasedEpisodes': e.releasedEpisodes,
                'nextEpisodeAirsAt': e.nextEpisodeAirsAt,
                'notes': e.notes,
                'updatedAt': e.updatedAt,
              })
          .toList(),
      'keyValues': kv.map((e) => {'key': e.key, 'value': e.value}).toList(),
      'sharedPreferences': _prefsToJson(prefs),
      'secureStorage': secureOut,
    };
  }

  static Map<String, dynamic> _prefsToJson(SharedPreferences p) {
    final m = <String, dynamic>{};
    for (final key in p.getKeys()) {
      final o = p.get(key);
      if (o is String) {
        m[key] = {'t': 's', 'v': o};
      } else if (o is int) {
        m[key] = {'t': 'i', 'v': o};
      } else if (o is bool) {
        m[key] = {'t': 'b', 'v': o};
      } else if (o is double) {
        m[key] = {'t': 'd', 'v': o};
      } else if (o is List<String>) {
        m[key] = {'t': 'sl', 'v': o};
      }
    }
    return m;
  }

  /// Restaura desde JSON (v1 solo library/keyValues; v2 añade prefs y secure; v3 scores 0-100).
  /// Devuelve número de filas de biblioteca importadas.
  static Future<int> restoreFromJson({
    required Map<String, dynamic> json,
    required AppDatabase db,
    required SharedPreferences prefs,
    required FlutterSecureStorage secure,
    required WidgetRef ref,
  }) async {
    final backupVersion = (json['version'] as int?) ?? 1;
    final secureMap = json['secureStorage'];
    if (secureMap is Map) {
      for (final e in secureMap.entries) {
        final key = e.key.toString();
        final val = e.value;
        if (val is String && val.isNotEmpty) {
          await secure.write(key: key, value: val);
        }
      }
    }

    final prefsMap = json['sharedPreferences'];
    if (prefsMap is Map) {
      for (final e in prefsMap.entries) {
        final key = e.key.toString();
        final wrapped = e.value;
        if (wrapped is! Map) continue;
        final t = wrapped['t'] as String?;
        final v = wrapped['v'];
        try {
          switch (t) {
            case 's':
              if (v is String) await prefs.setString(key, v);
            case 'i':
              if (v is int) {
                await prefs.setInt(key, v);
              } else if (v is num) {
                await prefs.setInt(key, v.toInt());
              }
            case 'b':
              if (v is bool) await prefs.setBool(key, v);
            case 'd':
              if (v is double) {
                await prefs.setDouble(key, v);
              } else if (v is num) {
                await prefs.setDouble(key, v.toDouble());
              }
            case 'sl':
              if (v is List) {
                await prefs.setStringList(
                  key,
                  v.map((x) => x.toString()).toList(),
                );
              }
          }
        } catch (_) {}
      }
    }

    final kvList = (json['keyValues'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    for (final row in kvList) {
      try {
        final k = row['key'] as String?;
        if (k == null) continue;
        await db.setKeyValue(k, row['value'] as String?);
      } catch (_) {}
    }

    final entries = (json['library'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    var imported = 0;
    for (final e in entries) {
      try {
        final rawScore = e['score'] as int?;
        // v1/v2 backups stored scores as 0-10; v3+ stores 0-100.
        final score100 = (backupVersion < 3 && rawScore != null && rawScore > 0)
            ? rawScore * 10
            : rawScore;
        await db.upsertLibraryEntry(
          LibraryEntriesCompanion(
            kind: Value(e['kind'] as int),
            externalId: Value(e['externalId'] as String),
            title: Value(e['title'] as String),
            posterUrl: Value(e['posterUrl'] as String?),
            status: Value((e['status'] as String?) ?? 'PLANNING'),
            score: Value(score100),
            progress: Value(e['progress'] as int?),
            totalEpisodes: Value(e['totalEpisodes'] as int?),
            animeMediaStatus: Value(e['animeMediaStatus'] as String?),
            releasedEpisodes: Value(e['releasedEpisodes'] as int?),
            nextEpisodeAirsAt: Value(e['nextEpisodeAirsAt'] as int?),
            notes: Value(e['notes'] as String?),
            updatedAt: Value(
              (e['updatedAt'] as int?) ?? DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
        imported++;
      } catch (_) {}
    }

    _invalidateAfterRestore(ref);
    return imported;
  }

  static void _invalidateAfterRestore(WidgetRef ref) {
    ref.invalidate(anilistTokenProvider);
    ref.invalidate(twitchIgdbAccountProvider);
    ref.invalidate(paginatedLibraryProvider);
    ref.invalidate(themeModeNotifierProvider);
    ref.invalidate(localeNotifierProvider);
    ref.invalidate(defaultStartPageProvider);
    ref.invalidate(defaultFeedTabProvider);
    ref.invalidate(defaultFeedActivityScopeProvider);
    ref.invalidate(hideTextActivitiesProvider);
    ref.invalidate(libraryKindLayoutProvider);
    ref.invalidate(feedFilterLayoutProvider);
    ref.invalidate(defaultLibraryFilterProvider);
    ref.invalidate(favoriteGamesProvider);
    ref.invalidate(favoriteTraktTitlesProvider);
    ref.invalidate(favoriteAnilistMediaProvider);
    ref.invalidate(igdbPopularProvider);
    ref.invalidate(igdbGamesHomeFeedProvider);
    ref.invalidate(igdbGamesSectionListProvider);
    ref.invalidate(igdbGameDetailProvider);
    ref.invalidate(igdbReviewByIdProvider);
    ref.invalidate(igdbSearchProvider);
    ref.invalidate(traktSessionProvider);
    ref.invalidate(traktMoviesHomeProvider);
    ref.invalidate(traktShowsHomeProvider);
    ref.invalidate(traktSearchMoviesProvider);
    ref.invalidate(traktSearchShowsProvider);
  }
}
