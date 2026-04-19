import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

/// Resumen / Discover tab – shows trending content from all the user's
/// visible feed categories plus a "random pick" button.
class SummaryFeedView extends ConsumerWidget {
  const SummaryFeedView({
    super.key,
    required this.onRefresh,
    required this.onSwitchCategory,
  });

  final VoidCallback onRefresh;

  /// Called when the user taps "See all" on a section header.
  /// The string matches the [_FeedFilter] enum name: 'anime', 'manga', etc.
  final ValueChanged<String> onSwitchCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visible =
        ref.watch(feedFilterLayoutProvider).visibleIdSet;

    // Collect sections dynamically based on the user's visible categories.
    final sections = <Widget>[];

    // ── Random pick card (always first) ─────────────────────────────────
    sections.add(_RandomPickCard(visible: visible));

    // ── Anime (hero layout) ─────────────────────────────────────────────
    if (visible.contains('anime')) {
      sections.add(
        _AsyncHeroSection(
          provider: anilistPopularProvider('ANIME'),
          title: l10n.summaryTrendingAnime,
          icon: Icons.animation_rounded,
          kind: MediaKind.anime,
          onSeeAll: () => onSwitchCategory('anime'),
        ),
      );
    }

    // ── Manga (standard poster carousel) ────────────────────────────────
    if (visible.contains('manga')) {
      sections.add(
        _AsyncCarouselSection(
          provider: anilistPopularProvider('MANGA'),
          title: l10n.summaryTrendingManga,
          icon: Icons.menu_book_rounded,
          kind: MediaKind.manga,
          onSeeAll: () => onSwitchCategory('manga'),
        ),
      );
    }

    // ── Movies (wide landscape + numbered anticipated) ──────────────────
    if (visible.contains('movie') && EnvConfig.traktClientId.isNotEmpty) {
      sections.add(
        _TraktCarouselSection(
          isMovie: true,
          titleTrending: l10n.summaryTrendingMovies,
          titleAnticipated: l10n.summaryAnticipatedMovies,
          onSeeAll: () => onSwitchCategory('movie'),
        ),
      );
    }

    // ── TV Shows (wide landscape + numbered anticipated) ────────────────
    if (visible.contains('tv') && EnvConfig.traktClientId.isNotEmpty) {
      sections.add(
        _TraktCarouselSection(
          isMovie: false,
          titleTrending: l10n.summaryTrendingShows,
          titleAnticipated: l10n.summaryAnticipatedShows,
          onSeeAll: () => onSwitchCategory('tv'),
        ),
      );
    }

    // ── Games (poster carousel + numbered anticipated) ──────────────────
    if (visible.contains('game')) {
      sections.add(
        _GamesCarouselSection(
          titlePopular: l10n.summaryPopularGames,
          titleAnticipated: l10n.summaryAnticipatedGames,
          onSeeAll: () => onSwitchCategory('game'),
        ),
      );
    }

    // ── Books (poster carousel) ─────────────────────────────────────────
    if (visible.contains('book')) {
      sections.add(
        _AsyncCarouselSection(
          provider: bookTrendingProvider,
          title: l10n.summaryTrendingBooks,
          icon: Icons.auto_stories_rounded,
          kind: MediaKind.book,
          onSeeAll: () => onSwitchCategory('book'),
        ),
      );
    }

    if (sections.length <= 1) {
      // Only the random card – nothing visible.
      return Center(child: Text(l10n.feedBrowseEmpty));
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Invalidate all summary-relevant providers.
        if (visible.contains('anime')) {
          ref.invalidate(anilistPopularProvider('ANIME'));
        }
        if (visible.contains('manga')) {
          ref.invalidate(anilistPopularProvider('MANGA'));
        }
        if (visible.contains('movie')) {
          ref.invalidate(traktMoviesHomeProvider);
        }
        if (visible.contains('tv')) {
          ref.invalidate(traktShowsHomeProvider);
        }
        if (visible.contains('game')) {
          ref.invalidate(igdbPopularProvider);
          ref.invalidate(igdbGamesHomeFeedProvider);
        }
        if (visible.contains('book')) {
          ref.invalidate(bookTrendingProvider);
        }
        onRefresh();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: sections,
      ),
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// RANDOM PICK CARD
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _RandomPickCard extends ConsumerWidget {
  const _RandomPickCard({required this.visible});

  final Set<String> visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Card(
        elevation: 0,
        color: cs.primaryContainer.withAlpha(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.primary.withAlpha(40)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickRandom(context, ref),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                Icon(Icons.shuffle_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.summaryRandomButton,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        l10n.summaryRandomSub,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: cs.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _pickRandom(BuildContext context, WidgetRef ref) {
    final pool = <_RandomEntry>[];

    if (visible.contains('anime')) {
      _addFromAsync(pool, ref.read(anilistPopularProvider('ANIME')), MediaKind.anime);
    }
    if (visible.contains('manga')) {
      _addFromAsync(pool, ref.read(anilistPopularProvider('MANGA')), MediaKind.manga);
    }
    if (visible.contains('movie')) {
      final data = ref.read(traktMoviesHomeProvider).valueOrNull;
      if (data != null) {
        for (final m in data.trending) {
          final id = m['id'] as int?;
          if (id != null) pool.add(_RandomEntry(id, MediaKind.movie));
        }
      }
    }
    if (visible.contains('tv')) {
      final data = ref.read(traktShowsHomeProvider).valueOrNull;
      if (data != null) {
        for (final m in data.trending) {
          final id = m['id'] as int?;
          if (id != null) pool.add(_RandomEntry(id, MediaKind.tv));
        }
      }
    }
    if (visible.contains('game')) {
      _addFromAsync(pool, ref.read(igdbPopularProvider), MediaKind.game);
    }

    if (pool.isEmpty) return;
    final pick = pool[Random().nextInt(pool.length)];
    context.push(_routeFor(pick.kind, pick.id));
  }

  void _addFromAsync(
    List<_RandomEntry> pool,
    AsyncValue<List<Map<String, dynamic>>> async,
    MediaKind kind,
  ) {
    final items = async.valueOrNull;
    if (items == null) return;
    for (final m in items) {
      final id = m['id'] as int?;
      if (id != null) pool.add(_RandomEntry(id, kind));
    }
  }
}

class _RandomEntry {
  const _RandomEntry(this.id, this.kind);
  final int id;
  final MediaKind kind;
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// CAROUSEL SECTIONS
// ╚═══════════════════════════════════════════════════════════════════════════╝

/// Hero layout: first item big, rest as small poster cards.
class _AsyncHeroSection extends ConsumerWidget {
  const _AsyncHeroSection({
    required this.provider,
    required this.title,
    required this.icon,
    required this.kind,
    required this.onSeeAll,
  });

  final ProviderListenable<AsyncValue<List<Map<String, dynamic>>>> provider;
  final String title;
  final IconData icon;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => _SectionShimmer(title: title, icon: icon),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _HeroSection(
          title: title,
          icon: icon,
          items: items.take(10).toList(),
          kind: kind,
          onSeeAll: onSeeAll,
        );
      },
    );
  }
}

/// Standard poster carousel that watches an async provider.
class _AsyncCarouselSection extends ConsumerWidget {
  const _AsyncCarouselSection({
    required this.provider,
    required this.title,
    required this.icon,
    required this.kind,
    required this.onSeeAll,
  });

  final ProviderListenable<AsyncValue<List<Map<String, dynamic>>>> provider;
  final String title;
  final IconData icon;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      loading: () => _SectionShimmer(title: title, icon: icon),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return _PosterCarouselSection(
          title: title,
          icon: icon,
          items: items.take(12).toList(),
          kind: kind,
          onSeeAll: onSeeAll,
        );
      },
    );
  }
}

/// Trakt section – wide landscape trending + numbered anticipated.
class _TraktCarouselSection extends ConsumerWidget {
  const _TraktCarouselSection({
    required this.isMovie,
    required this.titleTrending,
    required this.titleAnticipated,
    required this.onSeeAll,
  });

  final bool isMovie;
  final String titleTrending;
  final String titleAnticipated;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = isMovie ? MediaKind.movie : MediaKind.tv;
    final icon = isMovie ? Icons.movie_rounded : Icons.tv_rounded;

    if (isMovie) {
      final async = ref.watch(traktMoviesHomeProvider);
      return async.when(
        loading: () => _SectionShimmer(title: titleTrending, icon: icon),
        error: (_, _) => const SizedBox.shrink(),
        data: (data) => Column(
          children: [
            if (data.trending.isNotEmpty)
              _WideCarouselSection(
                title: titleTrending,
                icon: icon,
                items: data.trending.take(10).toList(),
                kind: kind,
                onSeeAll: onSeeAll,
              ),
            if (data.anticipated.isNotEmpty)
              _NumberedRankSection(
                title: titleAnticipated,
                icon: icon,
                items: data.anticipated.take(8).toList(),
                kind: kind,
                onSeeAll: onSeeAll,
              ),
          ],
        ),
      );
    }

    final async = ref.watch(traktShowsHomeProvider);
    return async.when(
      loading: () => _SectionShimmer(title: titleTrending, icon: icon),
      error: (_, _) => const SizedBox.shrink(),
      data: (data) => Column(
        children: [
          if (data.trending.isNotEmpty)
            _WideCarouselSection(
              title: titleTrending,
              icon: icon,
              items: data.trending.take(10).toList(),
              kind: kind,
              onSeeAll: onSeeAll,
            ),
          if (data.anticipated.isNotEmpty)
            _NumberedRankSection(
              title: titleAnticipated,
              icon: icon,
              items: data.anticipated.take(8).toList(),
              kind: kind,
              onSeeAll: onSeeAll,
            ),
        ],
      ),
    );
  }
}

/// Games section – poster carousel for popular, numbered for anticipated.
class _GamesCarouselSection extends ConsumerWidget {
  const _GamesCarouselSection({
    required this.titlePopular,
    required this.titleAnticipated,
    required this.onSeeAll,
  });

  final String titlePopular;
  final String titleAnticipated;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(igdbPopularProvider);
    final homeFeed = ref.watch(igdbGamesHomeFeedProvider);

    return Column(
      children: [
        popular.when(
          loading: () => _SectionShimmer(
            title: titlePopular,
            icon: Icons.sports_esports_rounded,
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (items) {
            if (items.isEmpty) return const SizedBox.shrink();
            return _PosterCarouselSection(
              title: titlePopular,
              icon: Icons.sports_esports_rounded,
              items: items.take(12).toList(),
              kind: MediaKind.game,
              onSeeAll: onSeeAll,
            );
          },
        ),
        homeFeed.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (data) {
            if (data.anticipated.isEmpty) return const SizedBox.shrink();
            return _NumberedRankSection(
              title: titleAnticipated,
              icon: Icons.sports_esports_rounded,
              items: data.anticipated.take(8).toList(),
              kind: MediaKind.game,
              onSeeAll: onSeeAll,
            );
          },
        ),
      ],
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// LAYOUT VARIANT 1 – HERO (big first card + small side cards)
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.kind,
    required this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                if (i == 0) {
                  return _HeroCard(item: items[0], kind: kind);
                }
                return _CarouselCard(
                  item: items[i],
                  kind: kind,
                  width: 100,
                  height: 145,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item, required this.kind});

  final Map<String, dynamic> item;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: () => _navigateToItem(context, kind, item),
      child: SizedBox(
        width: 155,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null
                      ? RemoteNetworkImage(
                          imageUrl: url,
                          width: 155,
                          height: 190,
                          fit: BoxFit.cover,
                        )
                      : _PosterPlaceholder(width: 155, height: 190),
                ),
                if (score != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _ScoreBadge(score: score, large: true),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// LAYOUT VARIANT 2 – STANDARD POSTER CAROUSEL
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _PosterCarouselSection extends StatelessWidget {
  const _PosterCarouselSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.kind,
    required this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    const cardW = 110.0;
    const cardH = 160.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardH + 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _CarouselCard(
                item: items[i],
                kind: kind,
                width: cardW,
                height: cardH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// LAYOUT VARIANT 3 – WIDE LANDSCAPE CARDS
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _WideCarouselSection extends StatelessWidget {
  const _WideCarouselSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.kind,
    required this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    const cardW = 200.0;
    const cardH = 120.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: cardH + 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _WideCard(
                item: items[i],
                kind: kind,
                width: cardW,
                height: cardH,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideCard extends StatelessWidget {
  const _WideCard({
    required this.item,
    required this.kind,
    required this.width,
    required this.height,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: () => _navigateToItem(context, kind, item),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: url != null
                      ? RemoteNetworkImage(
                          imageUrl: url,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        )
                      : _PosterPlaceholder(width: width, height: height),
                ),
                // Gradient overlay for readability
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(160),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 10,
                  right: 10,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// LAYOUT VARIANT 4 – NUMBERED RANK HORIZONTAL LIST
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _NumberedRankSection extends StatelessWidget {
  const _NumberedRankSection({
    required this.title,
    required this.icon,
    required this.items,
    required this.kind,
    required this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(title: title, icon: icon, onSeeAll: onSeeAll),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) => _RankCard(
                item: items[i],
                kind: kind,
                rank: i + 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  const _RankCard({
    required this.item,
    required this.kind,
    required this.rank,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: () => _navigateToItem(context, kind, item),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 24,
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3 ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Small poster
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: url != null
                  ? RemoteNetworkImage(
                      imageUrl: url,
                      width: 42,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(width: 42, height: 60),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      color: cs.onSurface,
                    ),
                  ),
                  if (score != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.star_rounded, size: 13, color: _scoreColor(score)),
                        const SizedBox(width: 3),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _scoreColor(score),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CarouselCard extends StatelessWidget {
  const _CarouselCard({
    required this.item,
    required this.kind,
    required this.width,
    required this.height,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: () => _navigateToItem(context, kind, item),
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url != null
                      ? RemoteNetworkImage(
                          imageUrl: url,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        )
                      : _PosterPlaceholder(width: width, height: height),
                ),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, this.large = false});

  final int score;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 8 : 6,
        vertical: large ? 4 : 3,
      ),
      decoration: BoxDecoration(
        color: _scoreColor(score),
        borderRadius: BorderRadius.circular(large ? 8 : 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(77),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: Colors.white,
          fontSize: large ? 13 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    this.onSeeAll,
  });

  final String title;
  final IconData icon;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ),
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.summarySeeAll,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 2),
                Icon(Icons.chevron_right_rounded, size: 18, color: cs.primary),
              ],
            ),
          ),
      ],
    );
  }
}

class _SectionShimmer extends StatelessWidget {
  const _SectionShimmer({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, icon: icon),
          const SizedBox(height: 10),
          SizedBox(
            height: 196,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => Container(
                width: 110,
                height: 160,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ╔═══════════════════════════════════════════════════════════════════════════╗
// HELPERS
// ╚═══════════════════════════════════════════════════════════════════════════╝

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(Icons.image_outlined, color: cs.onSurfaceVariant),
    );
  }
}

String? _coverUrl(Map<String, dynamic> item) =>
    (item['coverImage'] as Map?)?['large'] as String?;

String _itemTitle(Map<String, dynamic> item) =>
    ((item['title'] as Map?)?['english'] as String?) ??
    (item['name'] as String?) ??
    '';

int? _itemScore(Map<String, dynamic> item) => item['averageScore'] as int?;

Color _scoreColor(int s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFF94A3B8);
}

String _routeFor(MediaKind kind, int id) => switch (kind) {
      MediaKind.anime => '/media/$id?kind=${MediaKind.anime.code}',
      MediaKind.manga => '/media/$id?kind=${MediaKind.manga.code}',
      MediaKind.movie => '/trakt-movie/$id',
      MediaKind.tv => '/trakt-show/$id',
      MediaKind.game => '/game/$id',
      MediaKind.book => '/book/$id', // fallback – books prefer workKey routing
    };

void _navigateToItem(BuildContext context, MediaKind kind, Map<String, dynamic> item) {
  final workKey = item['workKey'] as String?;
  if (kind == MediaKind.book && workKey != null) {
    context.push('/book/$workKey');
    return;
  }
  final id = item['id'] as int?;
  if (id != null) context.push(_routeFor(kind, id));
}
