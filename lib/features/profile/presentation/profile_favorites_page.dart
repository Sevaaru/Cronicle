import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_kind.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Lista compacta de favoritos por categoría (anime, manga, cine, series, juegos).
class ProfileFavoritesPage extends ConsumerWidget {
  const ProfileFavoritesPage({super.key, required this.kind});

  final ProfileFavoritesKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final title = switch (kind) {
      ProfileFavoritesKind.anime => l10n.sectionFavAnime,
      ProfileFavoritesKind.manga => l10n.sectionFavManga,
      ProfileFavoritesKind.games => l10n.sectionFavGames,
      ProfileFavoritesKind.movies => l10n.sectionFavTraktMovies,
      ProfileFavoritesKind.tv => l10n.sectionFavTraktShows,
    };

    final body = switch (kind) {
      ProfileFavoritesKind.anime ||
      ProfileFavoritesKind.manga =>
        ref.watch(anilistProfileProvider).when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
              data: (profile) {
                if (profile == null) {
                  return Center(child: Text(l10n.profileConnectHint));
                }
                final favs = profile['favourites'] as Map<String, dynamic>? ?? {};
                final key = kind == ProfileFavoritesKind.anime ? 'anime' : 'manga';
                final nodes = (favs[key] as Map?)?['nodes'] as List? ?? [];
                final list = nodes.cast<Map<String, dynamic>>();
                final mk = kind == ProfileFavoritesKind.anime ? MediaKind.anime : MediaKind.manga;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.profileLibraryEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return _FavoritesGrid(items: list, mediaKind: mk);
              },
            ),
      ProfileFavoritesKind.games => _gamesBody(context, ref, l10n),
      ProfileFavoritesKind.movies || ProfileFavoritesKind.tv => _localTraktFavoritesBody(
            context,
            ref,
            l10n,
            kind,
          ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: body,
    );
  }

  Widget _gamesBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final games = ref.watch(favoriteGamesProvider);
    if (games.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.profileLibraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return _FavoritesGamesGrid(games: games);
  }

  /// Mismos títulos que el corazón en detalle Trakt ([favoriteTraktTitlesProvider]).
  Widget _localTraktFavoritesBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProfileFavoritesKind kind,
  ) {
    final all = ref.watch(favoriteTraktTitlesProvider);
    final list = kind == ProfileFavoritesKind.movies
        ? all.where((e) => (e['trakt_type'] as String?) != 'show').toList()
        : all.where((e) => (e['trakt_type'] as String?) == 'show').toList();
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.profileLibraryEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }
    return _FavoritesTraktGrid(items: list, isShow: kind == ProfileFavoritesKind.tv);
  }
}

class _FavoritesGrid extends StatelessWidget {
  const _FavoritesGrid({required this.items, required this.mediaKind});
  final List<Map<String, dynamic>> items;
  final MediaKind mediaKind;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.54,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _AnilistLikeTile(media: items[i], kind: mediaKind),
    );
  }
}

class _FavoritesGamesGrid extends StatelessWidget {
  const _FavoritesGamesGrid({required this.games});
  final List<Map<String, dynamic>> games;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.54,
      ),
      itemCount: games.length,
      itemBuilder: (context, i) => _GameTile(game: games[i]),
    );
  }
}

class _FavoritesTraktGrid extends StatelessWidget {
  const _FavoritesTraktGrid({required this.items, required this.isShow});
  final List<Map<String, dynamic>> items;
  final bool isShow;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.54,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _TraktTile(media: items[i], isShow: isShow),
    );
  }
}

class _AnilistLikeTile extends StatelessWidget {
  const _AnilistLikeTile({required this.media, required this.kind});
  final Map<String, dynamic> media;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?)?.trim().isNotEmpty == true
        ? title['english'] as String
        : (title['romaji'] as String?) ?? '';
    final cover = (media['coverImage'] as Map?)?['large'] as String?;
    final id = media['id'] as int?;

    return GestureDetector(
      onTap: id != null ? () => context.push('/media/$id?kind=${kind.code}') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover, width: double.infinity)
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _GameTile extends StatelessWidget {
  const _GameTile({required this.game});
  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = game['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?)?.trim().isNotEmpty == true
        ? title['english'] as String
        : (title['romaji'] as String?) ?? '';
    final cover = (game['coverImage'] as Map?)?['large'] as String?;
    final id = (game['id'] as num?)?.toInt();

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover, width: double.infinity)
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.sports_esports, color: cs.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}

class _TraktTile extends StatelessWidget {
  const _TraktTile({required this.media, required this.isShow});
  final Map<String, dynamic> media;
  final bool isShow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?)?.trim().isNotEmpty == true
        ? title['english'] as String
        : (title['romaji'] as String?) ?? '';
    final cover = (media['coverImage'] as Map?)?['large'] as String?;
    final id = (media['id'] as num?)?.toInt();

    return GestureDetector(
      onTap: id != null
          ? () => isShow ? context.push('/trakt-show/$id') : context.push('/trakt-movie/$id')
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(imageUrl: cover, fit: BoxFit.cover, width: double.infinity)
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(isShow ? Icons.tv_rounded : Icons.movie_outlined,
                          color: cs.onSurfaceVariant),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}
