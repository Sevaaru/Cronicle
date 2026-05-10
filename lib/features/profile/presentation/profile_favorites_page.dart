import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_kind.dart';
import 'package:cronicle/features/steam/data/datasources/steam_api_datasource.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

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
      ProfileFavoritesKind.books => l10n.sectionFavBooks,
      ProfileFavoritesKind.characters => l10n.sectionFavCharacters,
      ProfileFavoritesKind.staff => l10n.sectionFavStaff,
    };

    final body = switch (kind) {
      ProfileFavoritesKind.anime ||
      ProfileFavoritesKind.manga =>
        Consumer(
          builder: (context, ref, _) {
            final profileAsync = ref.watch(anilistProfileProvider);
            final localFavs = ref.watch(favoriteAnilistMediaProvider);
            final mediaTypeUpper =
                kind == ProfileFavoritesKind.anime ? 'ANIME' : 'MANGA';
            final mk =
                kind == ProfileFavoritesKind.anime ? MediaKind.anime : MediaKind.manga;
            return profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorWithMessage('$e'))),
              data: (profile) {
                final key = kind == ProfileFavoritesKind.anime ? 'anime' : 'manga';
                final apiNodes = profile == null
                    ? <dynamic>[]
                    : (((profile['favourites'] as Map?)?[key] as Map?)?['nodes']
                            as List? ??
                        []);
                final list = mergeAnilistFavoriteApiNodesWithLocal(
                  apiNodes: apiNodes,
                  localSnapshots: localFavs,
                  mediaTypeUpper: mediaTypeUpper,
                );
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        l10n.profileLibraryEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                return _FavoritesGrid(items: list, mediaKind: mk);
              },
            );
          },
        ),
      ProfileFavoritesKind.games => _gamesBody(context, ref, l10n),
      ProfileFavoritesKind.movies || ProfileFavoritesKind.tv => _localTraktFavoritesBody(
            context,
            ref,
            l10n,
            kind,
          ),
      ProfileFavoritesKind.books => _booksBody(context, ref, l10n),
      ProfileFavoritesKind.characters || ProfileFavoritesKind.staff =>
        _charStaffBody(context, ref, l10n, kind),
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

  Widget _booksBody(BuildContext context, WidgetRef ref, AppLocalizations l10n) {
    final books = ref.watch(favoriteBooksProvider);
    if (books.isEmpty) {
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
    return _FavoritesBooksGrid(books: books);
  }

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

  Widget _charStaffBody(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ProfileFavoritesKind kind,
  ) {
    final profileAsync = ref.watch(anilistProfileProvider);
    final cs = Theme.of(context).colorScheme;
    final localChars = ref.watch(favoriteAnilistCharactersProvider);
    final localStaff = ref.watch(favoriteAnilistStaffProvider);
    final isCharacters = kind == ProfileFavoritesKind.characters;
    final localList = isCharacters ? localChars : localStaff;

    Widget buildBodyFor(List<dynamic> apiNodes) {
      final merged = mergeAnilistFavoritePeopleApiNodesWithLocal(
        apiNodes: apiNodes,
        localSnapshots: localList,
      );
      if (merged.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(l10n.profileLibraryEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: cs.onSurfaceVariant)),
          ),
        );
      }
      return _PersonGrid(
        nodes: merged.cast<Map<String, dynamic>>(),
        isCharacter: isCharacters,
      );
    }

    return profileAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => buildBodyFor(const []),
      data: (profile) {
        final key = isCharacters ? 'characters' : 'staff';
        final apiNodes = profile == null
            ? const <dynamic>[]
            : (((profile['favourites'] as Map?)?[key] as Map?)?['nodes']
                    as List? ??
                const <dynamic>[]);
        return buildBodyFor(apiNodes);
      },
    );
  }
}

class _PersonGrid extends StatelessWidget {
  const _PersonGrid({required this.nodes, required this.isCharacter});
  final List<Map<String, dynamic>> nodes;
  final bool isCharacter;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.62,
      ),
      itemCount: nodes.length,
      itemBuilder: (context, i) {
        final n = nodes[i];
        final id = n['id'] as int?;
        final name = (n['name'] as Map?)?['full'] as String? ?? '';
        final img = (n['image'] as Map?)?['large'] as String? ??
            (n['image'] as Map?)?['medium'] as String?;
        final cs = Theme.of(context).colorScheme;
        return GestureDetector(
          onTap: id == null
              ? null
              : () => context.push(isCharacter ? '/character/$id' : '/staff/$id'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: img != null
                      ? CachedNetworkImage(
                          imageUrl: img,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        )
                      : ColoredBox(
                          color: cs.surfaceContainerHighest,
                          child: const Icon(Icons.person),
                        ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
              ),
            ],
          ),
        );
      },
    );
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
    final steamId = (game['steam_appid'] as num?)?.toInt();

    return GestureDetector(
      onTap: () {
        if (steamId != null) {
          context.push('/profile/steam/game/$steamId');
        } else if (id != null) {
          context.push('/game/$id');
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: steamId != null
                  ? _SteamChainedCover(
                      appId: steamId,
                      fallbackColor: cs.surfaceContainerHighest,
                      fallbackIcon: Icons.sports_esports,
                      fallbackIconColor: cs.onSurfaceVariant,
                    )
                  : cover != null
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

class _FavoritesBooksGrid extends StatelessWidget {
  const _FavoritesBooksGrid({required this.books});
  final List<Map<String, dynamic>> books;

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
      itemCount: books.length,
      itemBuilder: (context, i) => _BookTile(book: books[i]),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.book});
  final Map<String, dynamic> book;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = book['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?)?.trim().isNotEmpty == true
        ? title['english'] as String
        : (title['romaji'] as String?) ?? '';
    final cover = (book['coverImage'] as Map?)?['large'] as String?;
    final workKey = book['workKey'] as String?;

    return GestureDetector(
      onTap: workKey != null ? () => context.push('/book/$workKey') : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      fit: BoxFit.cover,
                      width: double.infinity)
                  : ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: Icon(Icons.menu_book,
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
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, height: 1.2),
          ),
        ],
      ),
    );
  }
}

/// Chains through [SteamApiDatasource.artworkCandidates] in order, advancing
/// to the next URL on each 404/network error. A static session-level cache
/// remembers the first working index per appId so F2P games (whose primary
/// CDN asset doesn't exist) don't re-probe failing URLs on every rebuild.
class _SteamChainedCover extends StatefulWidget {
  const _SteamChainedCover({
    required this.appId,
    required this.fallbackColor,
    required this.fallbackIcon,
    required this.fallbackIconColor,
  });

  final int appId;
  final Color fallbackColor;
  final IconData fallbackIcon;
  final Color fallbackIconColor;

  @override
  State<_SteamChainedCover> createState() => _SteamChainedCoverState();
}

class _SteamChainedCoverState extends State<_SteamChainedCover> {
  static final Map<int, int> _startIndexCache = {};

  late int _index;
  late List<String> _urls;

  @override
  void initState() {
    super.initState();
    _urls = SteamApiDatasource.artworkCandidates(widget.appId);
    _index = _startIndexCache[widget.appId] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_index >= _urls.length) {
      return ColoredBox(
        color: widget.fallbackColor,
        child: Icon(widget.fallbackIcon, color: widget.fallbackIconColor),
      );
    }
    return CachedNetworkImage(
      imageUrl: _urls[_index],
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, _) => ColoredBox(color: widget.fallbackColor),
      errorWidget: (_, _, _) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _index += 1;
              _startIndexCache[widget.appId] = _index;
            });
          }
        });
        return ColoredBox(color: widget.fallbackColor);
      },
    );
  }
}
