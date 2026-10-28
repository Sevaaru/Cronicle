import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';

String _watchedAtIso() => DateTime.now().toUtc().toIso8601String();

bool _showFullyWatched(String status, int? prog, int? total) {
  final s = status.toUpperCase();
  if (s == 'COMPLETED') return true;
  if (total != null && total > 0 && (prog ?? 0) >= total) return true;
  return false;
}

bool _movieWatched(String status, int? prog) {
  final s = status.toUpperCase();
  return s == 'COMPLETED' || (prog ?? 0) >= 1;
}

bool _traktWatchlistOn(String status, bool watched) {
  switch (status.toUpperCase()) {
    case 'DROPPED':
    case 'COMPLETED':
      return false;
    case 'CURRENT':
      return !watched;
    default:
      return true;
  }
}

Future<void> pushCronicleLibraryStateToTrakt(
  TraktApiDatasource api,
  String token, {
  required MediaKind kind,
  required int traktId,
  required String status,
  required int? progress,
  required int? totalEpisodes,
  required int? score,
}) async {
  final s = status.toUpperCase();
  final prog = progress ?? 0;
  final total = totalEpisodes;

  if (kind == MediaKind.movie) {
    final watched = _movieWatched(s, prog);
    final wl = _traktWatchlistOn(s, watched);

    if (score != null && score > 0) {
      await api.syncRatingsMovies(token, [
        {'rating': (score / 10).round().clamp(1, 10), 'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    } else {
      await api.syncRatingsRemoveMovies(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    }

    await api.syncHistoryRemoveMovies(token, [
      <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
    ]);
    if (watched) {
      await api.syncHistoryAddMovies(token, [
        <String, dynamic>{
          'ids': <String, dynamic>{'trakt': traktId},
          'watched_at': _watchedAtIso(),
        },
      ]);
    }

    if (wl) {
      await api.syncWatchlistAddMovies(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    } else {
      await api.syncWatchlistRemoveMovies(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    }
    return;
  }

  if (kind == MediaKind.tv) {
    final watched = _showFullyWatched(s, prog, total);
    final wl = _traktWatchlistOn(s, watched);

    if (score != null && score > 0) {
      await api.syncRatingsShows(token, [
        {'rating': (score / 10).round().clamp(1, 10), 'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    } else {
      await api.syncRatingsRemoveShows(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    }

    await api.syncHistoryRemoveShows(token, [
      <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
    ]);

    final cap = total != null && total > 0 ? prog.clamp(0, total) : prog;
    if (cap > 0) {
      final order = await api.fetchShowEpisodesAiringOrder(traktId);
      if (order.isNotEmpty) {
        final n = cap > order.length ? order.length : cap;
        final bySeason = <int, List<int>>{};
        for (var i = 0; i < n; i++) {
          final pair = order[i];
          bySeason.putIfAbsent(pair.$1, () => []).add(pair.$2);
        }
        final seasons = bySeason.entries.map((e) {
          final uniq = e.value.toSet().toList()..sort();
          return <String, dynamic>{
            'number': e.key,
            'episodes': [for (final num in uniq) <String, dynamic>{'number': num}],
          };
        }).toList()
          ..sort(
            (a, b) => ((a['number'] as num).toInt()).compareTo((b['number'] as num).toInt()),
          );
        await api.syncHistoryAddShows(token, [
          <String, dynamic>{
            'ids': <String, dynamic>{'trakt': traktId},
            'watched_at': _watchedAtIso(),
            'seasons': seasons,
          },
        ]);
      }
    }

    if (wl) {
      await api.syncWatchlistAddShows(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    } else {
      await api.syncWatchlistRemoveShows(token, [
        <String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}},
      ]);
    }
  }
}

Future<void> syncTraktEntryFromLocalDatabase(WidgetRef ref, MediaKind kind, int traktId) async {
  final token = await ref.read(traktAuthProvider).getValidAccessToken();
  if (token == null) return;
  final db = ref.read(databaseProvider);
  final entry = await db.getLibraryEntryByKindAndExternalId(kind.code, '$traktId');
  if (entry == null) return;
  try {
    await pushCronicleLibraryStateToTrakt(
      ref.read(traktApiProvider),
      token,
      kind: kind,
      traktId: traktId,
      status: entry.status,
      progress: entry.progress,
      totalEpisodes: entry.totalEpisodes,
      score: entry.score,
    );
  } catch (e, st) {
    debugPrint('[Cronicle] Trakt library sync: $e\n$st');
  }
}

Future<void> removeTraktRemoteForDeletedEntry(WidgetRef ref, MediaKind kind, int traktId) async {
  final token = await ref.read(traktAuthProvider).getValidAccessToken();
  if (token == null) return;
  final api = ref.read(traktApiProvider);
  try {
    if (kind == MediaKind.movie) {
      final m = [<String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}}];
      await api.syncHistoryRemoveMovies(token, m);
      await api.syncWatchlistRemoveMovies(token, m);
      await api.syncRatingsRemoveMovies(token, m);
    } else if (kind == MediaKind.tv) {
      final s = [<String, dynamic>{'ids': <String, dynamic>{'trakt': traktId}}];
      await api.syncHistoryRemoveShows(token, s);
      await api.syncWatchlistRemoveShows(token, s);
      await api.syncRatingsRemoveShows(token, s);
    }
  } catch (e, st) {
    debugPrint('[Cronicle] Trakt remove sync: $e\n$st');
  }
}
