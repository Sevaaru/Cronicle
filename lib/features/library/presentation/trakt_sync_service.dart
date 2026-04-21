import 'dart:math' show max;

import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/trakt_normalize.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

int? _traktDateToMs(dynamic raw) {
  if (raw == null) return null;
  if (raw is! String || raw.isEmpty) return null;
  final dt = DateTime.tryParse(raw);
  return dt?.millisecondsSinceEpoch;
}

Future<int> importTraktWatchedToLocal({
  required TraktApiDatasource api,
  required AppDatabase db,
  required String accessToken,
}) async {
  final movies = await api.syncWatchedMovies(accessToken);
  final shows = await api.syncWatchedShows(accessToken);

  final seen = <String>{};
  var count = 0;

  for (final row in movies) {
    try {
      final raw = row['movie'] as Map<String, dynamic>? ?? {};
      if (rawTraktMovieIsAnime(raw)) continue;
      final norm = normalizeTraktMovie(raw);
      final id = norm['id'] as int?;
      if (id == null || id <= 0) continue;
      final key = '${MediaKind.movie.code}_$id';
      if (seen.contains(key)) continue;
      seen.add(key);

      final plays = (row['plays'] as num?)?.toInt() ?? 0;
      final status = plays > 0 ? 'COMPLETED' : 'PLANNING';
      final titleMap = norm['title'] as Map<String, dynamic>? ?? {};
      final cover = norm['coverImage'] as Map<String, dynamic>? ?? {};
      final rating10 =
          ((raw['rating'] as num?) ?? 0).round().clamp(0, 10);
      final score100 = rating10 * 10;

      final existing = await db.getLibraryEntryByKindAndExternalId(
        MediaKind.movie.code,
        id.toString(),
      );
      final apiMs = _traktDateToMs(row['last_watched_at']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final resolvedUpdatedAt = existing == null
          ? (apiMs ?? nowMs)
          : (apiMs == null)
              ? existing.updatedAt
              : max(existing.updatedAt, apiMs);

      await db.upsertLibraryEntry(LibraryEntriesCompanion(
        kind: drift.Value(MediaKind.movie.code),
        externalId: drift.Value(id.toString()),
        title: drift.Value(
          (titleMap['english'] as String?) ??
              (titleMap['romaji'] as String?) ??
              'Unknown',
        ),
        posterUrl: drift.Value(cover['large'] as String?),
        status: drift.Value(status),
        score: drift.Value(score100 > 0 ? score100 : null),
        progress: drift.Value(plays > 0 ? 1 : 0),
        totalEpisodes: drift.Value(1),
        notes: drift.Value(null),
        updatedAt: drift.Value(resolvedUpdatedAt),
      ));
      count++;
    } catch (_) {
      continue;
    }
  }

  for (final row in shows) {
    try {
      final raw = row['show'] as Map<String, dynamic>? ?? {};
      if (rawTraktShowIsAnime(raw)) continue;
      final norm = normalizeTraktShow(raw);
      final id = norm['id'] as int?;
      if (id == null || id <= 0) continue;
      final key = '${MediaKind.tv.code}_$id';
      if (seen.contains(key)) continue;
      seen.add(key);

      final seasons = row['seasons'];
      final watchedEps = countWatchedEpisodesFromSeasons(seasons);
      final total = (norm['episodes'] as int?) ?? watchedEps;
      final status = watchedEps > 0 && total > 0 && watchedEps >= total
          ? 'COMPLETED'
          : watchedEps > 0
              ? 'CURRENT'
              : 'PLANNING';

      final titleMap = norm['title'] as Map<String, dynamic>? ?? {};
      final cover = norm['coverImage'] as Map<String, dynamic>? ?? {};
      final rating10 =
          ((raw['rating'] as num?) ?? 0).round().clamp(0, 10);
      final score100 = rating10 * 10;

      final existing = await db.getLibraryEntryByKindAndExternalId(
        MediaKind.tv.code,
        id.toString(),
      );
      final apiMs = _traktDateToMs(row['last_watched_at']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final resolvedUpdatedAt = existing == null
          ? (apiMs ?? nowMs)
          : (apiMs == null)
              ? existing.updatedAt
              : max(existing.updatedAt, apiMs);

      await db.upsertLibraryEntry(LibraryEntriesCompanion(
        kind: drift.Value(MediaKind.tv.code),
        externalId: drift.Value(id.toString()),
        title: drift.Value(
          (titleMap['english'] as String?) ??
              (titleMap['romaji'] as String?) ??
              'Unknown',
        ),
        posterUrl: drift.Value(cover['large'] as String?),
        status: drift.Value(status),
        score: drift.Value(score100 > 0 ? score100 : null),
        progress: drift.Value(watchedEps),
        totalEpisodes: drift.Value(total > 0 ? total : null),
        notes: drift.Value(null),
        updatedAt: drift.Value(resolvedUpdatedAt),
      ));
      count++;
    } catch (_) {
      continue;
    }
  }

  return count;
}

Future<void> mergeTraktLibraryIntoLocalIfSignedIn({
  required TraktApiDatasource api,
  required AppDatabase db,
  required Future<String?> Function() getValidAccessToken,
}) async {
  final token = await getValidAccessToken();
  if (token == null || token.isEmpty) return;
  await importTraktWatchedToLocal(api: api, db: db, accessToken: token);
}

Future<bool> showTraktImportDialog({
  required BuildContext context,
  required TraktApiDatasource api,
  required AppDatabase db,
  required String accessToken,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.traktImportTitle),
      content: Text(l10n.traktImportDesc),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(l10n.syncNotNow),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.traktImportConfirm),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return false;

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
    final n = await importTraktWatchedToLocal(
      api: api,
      db: db,
      accessToken: accessToken,
    );
    if (nav.mounted) nav.pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.traktImportedCount(n))),
      );
    }
    return true;
  } catch (e) {
    if (nav.mounted) nav.pop();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorSyncMessage(e))),
      );
    }
    return false;
  }
}
