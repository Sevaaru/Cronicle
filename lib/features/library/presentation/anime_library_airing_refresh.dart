import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Actualiza `releasedEpisodes` / `animeMediaStatus` para anime en CURRENT (API pública).
Future<void> refreshAnimeLibraryAiringMetadata(WidgetRef ref) async {
  final db = ref.read(databaseProvider);
  final graphql = ref.read(anilistGraphqlProvider);
  final all = await db.getAllLibraryEntries();
  final animeCurrent = all
      .where(
        (e) =>
            e.kind == MediaKind.anime.code &&
            e.status.toUpperCase() == 'CURRENT',
      )
      .toList();
  if (animeCurrent.isEmpty) return;
  final ids = animeCurrent
      .map((e) => int.tryParse(e.externalId))
      .whereType<int>()
      .toList();
  if (ids.isEmpty) return;

  try {
    final snapshots = await graphql.fetchMediaAiringSnapshots(ids);
    for (final e in animeCurrent) {
      final id = int.tryParse(e.externalId);
      if (id == null) continue;
      final snap = snapshots[id];
      if (snap == null) continue;
      final st = snap['status'] as String?;
      final rel = AnimeAiringProgress.releasedEpisodesFromAnilistMedia(snap);
      final airAt =
          AnimeAiringProgress.nextEpisodeAirsAtSecondsFromAnilistMedia(snap);
      await db.updateAnimeAiringMetadata(
        id: e.id,
        animeMediaStatus: st,
        releasedEpisodes: rel,
        nextEpisodeAirsAt: airAt,
      );
    }
    ref.invalidate(paginatedLibraryProvider);
  } catch (_) {}
}
