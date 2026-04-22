import 'dart:math' show max;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// SharedPreferences key holding the last successful AniList library sync
/// timestamp (UNIX seconds). Used to enable delta sync via `updatedAt`.
const String anilistLibraryLastSyncSecondsKey =
    'anilist_library_last_sync_s';

/// Minimum interval between automatic background AniList library syncs.
/// Manual user-triggered import/merge dialogs always force a sync.
const Duration anilistAutoSyncMinInterval = Duration(hours: 1);

int? _mediaListUpdatedAtMs(Map<String, dynamic> entry) {
  final raw = entry['updatedAt'];
  if (raw == null) return null;
  if (raw is! num) return null;
  final v = raw.toInt();
  if (v <= 0) return null;
  if (v < 20000000000) return v * 1000;
  return v;
}

Future<int> importAnilistToLocal({
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required String token,
  required String userName,
}) async {
  final anime = await graphql
      .fetchUserMediaList(token, userName, type: 'ANIME')
      .catchError((Object _) => <Map<String, dynamic>>[]);
  final manga = await graphql
      .fetchUserMediaList(token, userName, type: 'MANGA')
      .catchError((Object _) => <Map<String, dynamic>>[]);
  final count = await _writeAnilistEntriesToDb(
    db: db,
    entries: [...anime, ...manga],
  );
  return count;
}

/// Incrementally syncs AniList list changes since [sinceEpochSeconds].
/// Returns the number of entries written.
Future<int> deltaSyncAnilistToLocal({
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required String token,
  required int userId,
  required int sinceEpochSeconds,
}) async {
  final anime = await graphql
      .fetchUserMediaListUpdatedSince(
        token,
        userId,
        type: 'ANIME',
        sinceEpochSeconds: sinceEpochSeconds,
      )
      .catchError((Object _) => <Map<String, dynamic>>[]);
  final manga = await graphql
      .fetchUserMediaListUpdatedSince(
        token,
        userId,
        type: 'MANGA',
        sinceEpochSeconds: sinceEpochSeconds,
      )
      .catchError((Object _) => <Map<String, dynamic>>[]);
  return _writeAnilistEntriesToDb(
    db: db,
    entries: [...anime, ...manga],
  );
}

Future<int> _writeAnilistEntriesToDb({
  required AppDatabase db,
  required List<Map<String, dynamic>> entries,
}) async {
  final seen = <String>{};
  int count = 0;

  for (final entry in entries) {
    try {
      final media = entry['media'] as Map<String, dynamic>? ?? {};
      final mediaId = media['id']?.toString();
      if (mediaId == null || mediaId.isEmpty) continue;

      final mediaType = media['type'] as String?;
      final kind = mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;
      final dedupeKey = '${kind.code}_$mediaId';
      if (seen.contains(dedupeKey)) continue;
      seen.add(dedupeKey);

      final title = media['title'] as Map<String, dynamic>? ?? {};
      final coverImage = media['coverImage'] as Map<String, dynamic>? ?? {};

      final totalEp = kind == MediaKind.manga
          ? (media['chapters'] as num?)?.toInt()
          : (media['episodes'] as num?)?.toInt();

      final animeSt =
          kind == MediaKind.anime ? media['status'] as String? : null;
      final released = kind == MediaKind.anime
          ? AnimeAiringProgress.releasedEpisodesFromAnilistMedia(media)
          : null;
      final nextAirAt = kind == MediaKind.anime
          ? AnimeAiringProgress.nextEpisodeAirsAtSecondsFromAnilistMedia(media)
          : null;

      var listProgress = (entry['progress'] as num?)?.toInt();
      if (kind == MediaKind.anime) {
        final cap = AnimeAiringProgress.animeEpisodeProgressCap(
          mediaKindCode: kind.code,
          totalEpisodes: totalEp,
          releasedEpisodes: released,
        );
        if (cap != null && listProgress != null && listProgress > cap) {
          listProgress = cap;
        }
      }

      final existing = await db.getLibraryEntryByKindAndExternalId(
        kind.code,
        mediaId,
      );
      final apiMs = _mediaListUpdatedAtMs(entry);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final resolvedUpdatedAt = existing == null
          ? (apiMs ?? nowMs)
          : (apiMs == null)
              ? existing.updatedAt
              : max(existing.updatedAt, apiMs);

      await db.upsertLibraryEntry(LibraryEntriesCompanion(
        kind: drift.Value(kind.code),
        externalId: drift.Value(mediaId),
        title: drift.Value(
          (title['english'] as String?) ??
              (title['romaji'] as String?) ??
              'Unknown',
        ),
        posterUrl: drift.Value(coverImage['large'] as String?),
        status: drift.Value(entry['status'] as String? ?? 'PLANNING'),
        score: drift.Value((entry['score'] as num?)?.toInt()),
        progress: drift.Value(listProgress),
        totalEpisodes: drift.Value(totalEp),
        animeMediaStatus: drift.Value(animeSt),
        releasedEpisodes: drift.Value(released),
        nextEpisodeAirsAt: drift.Value(nextAirAt),
        notes: drift.Value(entry['notes'] as String?),
        updatedAt: drift.Value(resolvedUpdatedAt),
      ));
      count++;
    } catch (_) {
      continue;
    }
  }
  return count;
}

Future<void> mergeAnilistLibraryIntoLocalIfSignedIn({
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required AnilistAuthDatasource auth,
  SharedPreferences? prefs,
  bool force = false,
}) async {
  final token = await auth.getToken();
  if (token == null || token.isEmpty) return;

  var userName = await auth.getUserName();
  Map<String, dynamic>? viewer;
  if (userName == null || userName.isEmpty) {
    viewer = await graphql.fetchViewer(token);
    userName = viewer?['name'] as String? ?? '';
    if (userName.isEmpty) return;
    await auth.saveUserName(userName);
  }

  final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  final lastSyncSeconds =
      prefs?.getInt(anilistLibraryLastSyncSecondsKey) ?? 0;

  // Skip background sync if a recent sync just happened, unless forced.
  if (!force && lastSyncSeconds > 0) {
    final age = Duration(seconds: nowSeconds - lastSyncSeconds);
    if (age < anilistAutoSyncMinInterval) return;
  }

  // If we have a previous sync timestamp, perform an incremental delta sync.
  if (lastSyncSeconds > 0) {
    viewer ??= await graphql.fetchViewer(token);
    final userId = (viewer?['id'] as num?)?.toInt() ?? 0;
    if (userId > 0) {
      try {
        // Subtract a small overlap so concurrent edits don't get missed.
        const overlapSeconds = 60;
        final since = (lastSyncSeconds - overlapSeconds).clamp(0, nowSeconds);
        await deltaSyncAnilistToLocal(
          graphql: graphql,
          db: db,
          token: token,
          userId: userId,
          sinceEpochSeconds: since,
        );
        await prefs?.setInt(anilistLibraryLastSyncSecondsKey, nowSeconds);
        return;
      } catch (_) {
        // Fallback to full import on delta failure.
      }
    }
  }

  await importAnilistToLocal(
    graphql: graphql,
    db: db,
    token: token,
    userName: userName,
  );
  await prefs?.setInt(anilistLibraryLastSyncSecondsKey, nowSeconds);
}

Future<bool> showAnilistSyncDialog({
  required BuildContext context,
  required AnilistGraphqlDatasource graphql,
  required AppDatabase db,
  required String token,
  SharedPreferences? prefs,
}) async {
  final l10n = AppLocalizations.of(context)!;

  final viewer = await graphql.fetchViewer(token);
  if (viewer == null) return false;
  final userName = viewer['name'] as String? ?? '';
  if (userName.isEmpty || !context.mounted) return false;

  final choice = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final cs = Theme.of(ctx).colorScheme;
      return AlertDialog(
        title: Text(l10n.syncTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.syncWelcome(userName),
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            _SyncOption(
              icon: Icons.cloud_download,
              title: l10n.syncImport,
              subtitle: l10n.syncImportDesc,
              cs: cs,
            ),
            const SizedBox(height: 8),
            _SyncOption(
              icon: Icons.merge_type,
              title: l10n.syncMerge,
              subtitle: l10n.syncMergeDesc,
              cs: cs,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'skip'),
            child: Text(l10n.syncNotNow),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, 'merge'),
            child: Text(l10n.syncMerge),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, 'import'),
            child: Text(l10n.syncImport),
          ),
        ],
      );
    },
  );

  if (choice == null || choice == 'skip' || !context.mounted) return false;

  final nav = Navigator.of(context, rootNavigator: true);

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(l10n.syncLoading),
          ],
        ),
      ),
    ),
  );

  try {
    if (choice == 'import') {
      final existing = await db.getAllLibraryEntries();
      for (final e in existing) {
        if (e.kind == MediaKind.anime.code || e.kind == MediaKind.manga.code) {
          await db.deleteLibraryEntry(e.id);
        }
      }
    }

    final count = await importAnilistToLocal(
      graphql: graphql,
      db: db,
      token: token,
      userName: userName,
    );
    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await prefs?.setInt(anilistLibraryLastSyncSecondsKey, nowSeconds);

    if (nav.mounted) {
      nav.pop();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.syncImportedCount(count))),
      );
    }
    return true;
  } catch (e) {
    if (nav.mounted) {
      nav.pop();
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSyncMessage(e))),
      );
    }
    return false;
  }
}

class _SyncOption extends StatelessWidget {
  const _SyncOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.cs,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: cs.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }
}
