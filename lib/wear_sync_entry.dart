
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/shared/models/media_kind.dart';

const _channelName = 'cronicle.wear.sync';

@pragma('vm:entry-point')
Future<void> wearSyncMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  debugPrint('[Cronicle] wearSyncMain starting');

  const channel = MethodChannel(_channelName);
  try {
    await _drainPendingActions();
  } catch (e, st) {
    debugPrint('[Cronicle] wearSyncMain failed: $e\n$st');
  }
  debugPrint('[Cronicle] wearSyncMain finished, signalling done');
  try {
    await channel.invokeMethod<void>('done');
  } catch (_) {}
}

Future<void> _drainPendingActions() async {
  final dir = await getApplicationDocumentsDirectory();
  final file = File('${dir.path}/wear_pending.jsonl');
  if (!await file.exists()) return;
  final lines = await file.readAsLines();
  if (lines.isEmpty) {
    try {
      await file.delete();
    } catch (_) {}
    return;
  }
  try {
    await file.delete();
  } catch (_) {}

  final db = AppDatabase();
  final dio = Dio();
  const secure = FlutterSecureStorage();
  final anilist = AnilistGraphqlDatasource(dio);
  final trakt = TraktApiDatasource(dio);
  final traktAuth = TraktAuthDatasource(secure, dio);

  final seen = <String>{};
  final queue = <Map<String, dynamic>>[];
  for (final raw in lines.reversed) {
    if (raw.trim().isEmpty) continue;
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      final key = '${obj['kind']}:${obj['externalId']}';
      if (!seen.add(key)) continue;
      queue.add(obj);
    } catch (_) {}
  }

  for (final obj in queue) {
    try {
      final kindCode = obj['kind'] as int;
      final externalId = obj['externalId'].toString();
      final kind = MediaKind.fromCode(kindCode);
      final entry = await db.getLibraryEntryByKindAndExternalId(kindCode, externalId);
      if (entry == null) continue;
      if (kind == MediaKind.anime || kind == MediaKind.manga) {
        await _pushAnilist(anilist, secure, entry);
      } else if (kind == MediaKind.tv || kind == MediaKind.movie) {
        await _pushTrakt(trakt, traktAuth, entry, kind);
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        await AchievementsCounters.bumpWearUpdate(prefs);
        await AchievementsCounters.bumpProgressIncrement(prefs);
      } catch (_) {}
      debugPrint('[Cronicle] wearSync pushed $kind/$externalId');
    } catch (e, st) {
      debugPrint('[Cronicle] wearSync action failed: $e\n$st');
    }
  }

  await db.close();
}

Future<void> _pushAnilist(
  AnilistGraphqlDatasource anilist,
  FlutterSecureStorage secure,
  LibraryEntry entry,
) async {
  final token = await secure.read(key: 'anilist_access_token');
  if (token == null || token.isEmpty) return;
  final mediaId = int.tryParse(entry.externalId);
  if (mediaId == null) return;
  final progress = entry.progress ?? 0;
  final total = entry.totalEpisodes;
  final completed = total != null && total > 0 && progress >= total;
  await anilist.saveMediaListEntry(
    mediaId: mediaId,
    token: token,
    progress: progress,
    status: completed ? 'COMPLETED' : null,
  );
}

Future<void> _pushTrakt(
  TraktApiDatasource trakt,
  TraktAuthDatasource traktAuth,
  LibraryEntry entry,
  MediaKind kind,
) async {
  final token = await traktAuth.getValidAccessToken();
  if (token == null) return;
  final traktId = int.tryParse(entry.externalId);
  if (traktId == null) return;
  await pushCronicleLibraryStateToTrakt(
    trakt,
    token,
    kind: kind,
    traktId: traktId,
    status: entry.status,
    progress: entry.progress,
    totalEpisodes: entry.totalEpisodes,
    score: entry.score,
  );
}
