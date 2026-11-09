import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/utils/anilist_media_title.dart';
import 'package:cronicle/core/utils/anilist_notification_contexts.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';

Future<Uint8List?> _downloadImageBytes(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final res = await Dio().get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        receiveTimeout: const Duration(seconds: 8),
      ),
    );
    final data = res.data;
    if (data == null || data.isEmpty) return null;
    return Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _resolveNotificationImage(Map<String, dynamic> n) async {
  final media = n['media'] as Map<String, dynamic>?;
  if (media != null) {
    final cover = media['coverImage'] as Map<String, dynamic>?;
    final coverUrl = cover?['large'] as String?;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      return _downloadImageBytes(coverUrl);
    }
  }

  final user = n['user'] as Map<String, dynamic>?;
  if (user != null) {
    final avatar = user['avatar'] as Map<String, dynamic>?;
    final avatarUrl = avatar?['medium'] as String?;
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return _downloadImageBytes(avatarUrl);
    }
  }

  return null;
}

bool _shouldMirrorAnilistNotif(String? typename, bool includeSocial) {
  if (typename == 'AiringNotification') return true;
  if (!includeSocial) return false;
  return true;
}

int _stableNotifId(String salt, int id) {
  final h = (salt.hashCode ^ id).abs();
  return h == 0 ? id.abs() % 2000000000 : h % 2000000000;
}

String? _actorDisplayName(Map<String, dynamic> n) {
  final user = n['user'] as Map<String, dynamic>?;
  final uName = user?['name'] as String?;
  if (uName != null && uName.isNotEmpty) return uName;

  final staff = n['staff'] as Map<String, dynamic>?;
  if (staff != null) {
    final nm = staff['name'] as Map<String, dynamic>?;
    final full = nm?['full'] as String?;
    if (full != null && full.isNotEmpty) return full;
  }

  final character = n['character'] as Map<String, dynamic>?;
  if (character != null) {
    final nm = character['name'] as Map<String, dynamic>?;
    final full = nm?['full'] as String?;
    if (full != null && full.isNotEmpty) return full;
  }

  final submitted = n['submittedTitle'] as String?;
  if (submitted != null && submitted.isNotEmpty) return submitted;

  return null;
}

String _contextOrSummaryLine(Map<String, dynamic> n) {
  final ctx = n['context'] as String?;
  if (ctx != null && ctx.isNotEmpty) return ctx;
  final ctxs = n['contexts'];
  if (ctxs is List && ctxs.isNotEmpty) {
    final flat = anilistFlattenContexts(ctxs).trim();
    if (flat.isNotEmpty) return flat;
  }
  final t = n['__typename'] as String? ?? '';
  if (t == 'AiringNotification') {
    final ep = n['episode'];
    final media = n['media'] as Map<String, dynamic>? ?? {};
    final title = anilistMediaDisplayTitle(media);
    return '$title · $ep';
  }
  return '';
}

String _fallbackBodyWhenNoContext(Map<String, dynamic> n) {
  final media = n['media'] as Map<String, dynamic>?;
  if (media != null) return anilistMediaDisplayTitle(media);
  final thread = n['thread'] as Map<String, dynamic>?;
  if (thread != null) {
    final tt = thread['title'] as String?;
    if (tt != null && tt.isNotEmpty) return tt;
  }
  final del = n['deletedMediaTitle'] as String?;
  if (del != null && del.isNotEmpty) return del;
  final dels = n['deletedMediaTitles'] as List?;
  if (dels != null && dels.isNotEmpty) return dels.first.toString();
  return n['__typename'] as String? ?? '';
}

String _anilistNotifTitle(String? typename, bool isEs) {
  return switch (typename) {
    'AiringNotification' =>
      isEs ? 'Nuevo capítulo / episodio' : 'New episode / chapter',
    _ => isEs ? 'Anilist' : 'Anilist',
  };
}

(String title, String body) _anilistPushTitleAndBody(
  Map<String, dynamic> n,
  bool isEs,
) {
  final typename = n['__typename'] as String?;
  final actor = _actorDisplayName(n);
  var contextLine = _contextOrSummaryLine(n);
  if (contextLine.isEmpty) {
    contextLine = _fallbackBodyWhenNoContext(n);
  }

  if (typename == 'AiringNotification') {
    final media = n['media'] as Map<String, dynamic>? ?? {};
    final mediaTitle = anilistMediaDisplayTitle(media);
    final episode = (n['episode'] as num?)?.toInt();
    final isManga = (media['type'] as String? ?? '') == 'MANGA';
    final kindWord = isManga
        ? (isEs ? 'Capítulo' : 'Chapter')
        : (isEs ? 'Episodio' : 'Episode');
    final title = mediaTitle != 'Media' && mediaTitle.isNotEmpty
        ? mediaTitle
        : _anilistNotifTitle(typename, isEs);
    final body = episode != null
        ? '$kindWord $episode'
        : (contextLine.isNotEmpty
            ? contextLine
            : (mediaTitle != 'Media'
                ? mediaTitle
                : _anilistNotifTitle(typename, isEs)));
    return (title, body);
  }

  if (actor != null && actor.isNotEmpty) {
    if (contextLine.isNotEmpty) {
      return (actor, contextLine);
    }
    return (actor, _anilistNotifTitle(typename, isEs));
  }

  if (contextLine.isNotEmpty) {
    return (_anilistNotifTitle(typename, isEs), contextLine);
  }

  return (_anilistNotifTitle(typename, isEs), '');
}

Future<bool> runNotificationSyncTask() async {
  try {
    await CronicleLocalNotifications.init();
    final prefs = await SharedPreferences.getInstance();

    if (!(prefs.getBool(DeviceNotificationPrefs.masterEnabled) ?? false)) {
      return true;
    }

    // Throttle: WorkManager / boot retries can fire this multiple times in
    // quick succession. Each run does at minimum 2 AniList GraphQL calls
    // (airing + inbox). Skip if we ran less than 10 minutes ago to keep the
    // rate-limit footprint small while still being responsive enough.
    const _minSyncIntervalMs = 10 * 60 * 1000;
    const _lastRunPrefsKey = 'notification_sync_last_run_ms';
    final lastRun = prefs.getInt(_lastRunPrefsKey) ?? 0;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - lastRun < _minSyncIntervalMs) {
      return true;
    }
    await prefs.setInt(_lastRunPrefsKey, nowMs);

    final airingOn =
        prefs.getBool(DeviceNotificationPrefs.airingEnabled) ?? true;
    final anilistOn =
        prefs.getBool(DeviceNotificationPrefs.anilistInboxEnabled) ?? true;
    final socialOn =
        prefs.getBool(DeviceNotificationPrefs.anilistSocialEnabled) ?? true;

    if (!airingOn && !anilistOn) {
      return true;
    }

    const secure = FlutterSecureStorage();
    final token = await secure.read(key: 'anilist_access_token');
    if (token == null || token.isEmpty) {
      return true;
    }

    var userName = await secure.read(key: 'anilist_user_name');
    final graphql = AnilistGraphqlDatasource(Dio());
    if (userName == null || userName.isEmpty) {
      final viewer = await graphql.fetchViewer(token);
      userName = viewer?['name'] as String? ?? '';
      if (userName.isNotEmpty) {
        await secure.write(key: 'anilist_user_name', value: userName);
      }
    }
    if (userName.isEmpty) {
      return true;
    }

    final lang = prefs.getString('locale_code') ?? 'es';
    final isEs = lang == 'es';

    if (airingOn) {
      await _syncAiringReleases(
        graphql,
        token,
        userName,
        prefs,
        isEs,
      );
    }

    if (anilistOn) {
      await _syncAnilistInbox(
        graphql,
        token,
        prefs,
        isEs,
        includeSocial: socialOn,
      );
    }

    return true;
  } catch (e, st) {
    if (kDebugMode) {
      debugPrint('[Cronicle] runNotificationSyncTask error: $e\n$st');
    }
    return false;
  }
}

Future<void> _syncAiringReleases(
  AnilistGraphqlDatasource gql,
  String token,
  String userName,
  SharedPreferences prefs,
  bool isEs,
) async {
  final entries = await gql.fetchCurrentListsWithAiringSchedule(
    token: token,
    userName: userName,
  );

  final now = DateTime.now().millisecondsSinceEpoch;

  for (final entry in entries) {
    final media = entry['media'] as Map<String, dynamic>? ?? {};
    if (media['status'] != 'RELEASING') continue;

    final next = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (next == null) continue;

    final episode = (next['episode'] as num?)?.toInt();
    final airingAt = (next['airingAt'] as num?)?.toInt();
    if (episode == null || airingAt == null) continue;

    if (now < airingAt * 1000) continue;

    final progress = (entry['progress'] as num?)?.toInt() ?? 0;
    if (progress >= episode) continue;

    final mediaId = (media['id'] as num?)?.toInt();
    if (mediaId == null) continue;

    final dedupe = DeviceNotificationPrefs.airingDedupeKey(mediaId, episode);
    if (prefs.getBool(dedupe) == true) continue;

    final mediaTitle = anilistMediaDisplayTitle(media);
    final isManga = (media['type'] as String? ?? '') == 'MANGA';
    final kindWord = isManga
        ? (isEs ? 'Capítulo' : 'Chapter')
        : (isEs ? 'Episodio' : 'Episode');
    final body = '$kindWord $episode';
    final notifTitle =
        mediaTitle != 'Media' && mediaTitle.isNotEmpty ? mediaTitle : 'Cronicle';
    final expandedBody = mediaTitle != 'Media' && mediaTitle.isNotEmpty
        ? '$kindWord $episode · $mediaTitle'
        : body;

    final notifId = _stableNotifId('air', mediaId * 100000 + episode);

    final cover = media['coverImage'] as Map<String, dynamic>?;
    final coverUrl = cover?['large'] as String?;
    final imageBytes = await _downloadImageBytes(coverUrl);

    await CronicleLocalNotifications.showAiringNewEpisode(
      notificationId: notifId,
      title: notifTitle,
      body: body,
      expandedBody: expandedBody,
      largeIconBytes: imageBytes,
    );

    await prefs.setBool(dedupe, true);
  }
}

Future<void> _syncAnilistInbox(
  AnilistGraphqlDatasource gql,
  String token,
  SharedPreferences prefs,
  bool isEs, {
  required bool includeSocial,
}) async {
  final list = await gql.fetchNotifications(
    token: token,
    page: 1,
    perPage: 25,
    resetNotificationCount: false,
  );

  final seenRaw = prefs.getString(DeviceNotificationPrefs.anilistSeenIdsJson);
  var seen = <int>{
    if (seenRaw != null)
      ...((jsonDecode(seenRaw) as List?) ?? [])
          .map((e) => (e as num).toInt()),
  };

  final backfillDone =
      prefs.getBool(DeviceNotificationPrefs.anilistBackfillDone) ?? false;

  if (!backfillDone) {
    for (final n in list) {
      final id = (n['id'] as num?)?.toInt();
      if (id != null) seen.add(id);
    }
    await prefs.setString(
      DeviceNotificationPrefs.anilistSeenIdsJson,
      jsonEncode(seen.take(400).toList()),
    );
    await prefs.setBool(DeviceNotificationPrefs.anilistBackfillDone, true);
    return;
  }

  for (final n in list) {
    final id = (n['id'] as num?)?.toInt();
    if (id == null) continue;
    if (seen.contains(id)) continue;

    final typename = n['__typename'] as String?;

    if (!_shouldMirrorAnilistNotif(typename, includeSocial)) {
      seen = {...seen, id};
      continue;
    }

    final (title, body) = _anilistPushTitleAndBody(n, isEs);
    if (body.isEmpty) {
      seen = {...seen, id};
      continue;
    }

    final imageBytes = await _resolveNotificationImage(n);

    await CronicleLocalNotifications.showAnilistMirror(
      notificationId: _stableNotifId('anl', id),
      title: title,
      body: body,
      largeIconBytes: imageBytes,
    );
    seen = {...seen, id};
  }

  await prefs.setString(
    DeviceNotificationPrefs.anilistSeenIdsJson,
    jsonEncode(seen.take(400).toList()),
  );
}
