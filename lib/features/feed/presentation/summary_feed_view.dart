import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

class SummaryFeedView extends ConsumerWidget {
  const SummaryFeedView({
    super.key,
    required this.onRefresh,
    required this.onSwitchCategory,
  });

  final VoidCallback onRefresh;

  final ValueChanged<String> onSwitchCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visible =
        ref.watch(feedFilterLayoutProvider).visibleIdSet;

    final sections = <Widget>[];

    sections.add(_RandomPickCard(visible: visible));

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

    if (visible.contains('game')) {
      sections.add(
        _GamesCarouselSection(
          titlePopular: l10n.summaryPopularGames,
          titleAnticipated: l10n.summaryAnticipatedGames,
          onSeeAll: () => onSwitchCategory('game'),
        ),
      );
    }

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
      return Center(child: Text(l10n.feedBrowseEmpty));
    }

    return RefreshIndicator(
      onRefresh: () async {
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


class _RandomPickCard extends ConsumerWidget {
  const _RandomPickCard({required this.visible});

  final Set<String> visible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    if (visible.contains('anime')) {
      ref.watch(anilistBrowseMediaProvider('ANIME', 'top_rated'));
      ref.watch(anilistBrowseMediaProvider('ANIME', 'popularity'));
    }
    if (visible.contains('manga')) {
      ref.watch(anilistBrowseMediaProvider('MANGA', 'top_rated'));
      ref.watch(anilistBrowseMediaProvider('MANGA', 'popularity'));
    }
    if (visible.contains('game')) {
      ref.watch(igdbGamesSectionListProvider(GamesFeedSection.bestRated));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.shuffle_rounded, color: cs.primary, size: 24),
                const SizedBox(width: 14),
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
    final perKind = <MediaKind, List<Map<String, dynamic>>>{};

    void addAll(MediaKind kind, Iterable<Map<String, dynamic>>? items) {
      if (items == null) return;
      perKind.putIfAbsent(kind, () => []).addAll(items);
    }

    void addAsync(
      MediaKind kind,
      AsyncValue<List<Map<String, dynamic>>> async,
    ) =>
        addAll(kind, async.valueOrNull);

    if (visible.contains('anime')) {
      addAsync(MediaKind.anime, ref.read(anilistPopularProvider('ANIME')));
      addAsync(MediaKind.anime,
          ref.read(anilistBrowseMediaProvider('ANIME', 'top_rated')));
      addAsync(MediaKind.anime,
          ref.read(anilistBrowseMediaProvider('ANIME', 'popularity')));
    }

    if (visible.contains('manga')) {
      addAsync(MediaKind.manga, ref.read(anilistPopularProvider('MANGA')));
      addAsync(MediaKind.manga,
          ref.read(anilistBrowseMediaProvider('MANGA', 'top_rated')));
      addAsync(MediaKind.manga,
          ref.read(anilistBrowseMediaProvider('MANGA', 'popularity')));
    }

    if (visible.contains('movie')) {
      final data = ref.read(traktMoviesHomeProvider).valueOrNull;
      if (data != null) {
        addAll(MediaKind.movie, data.trending);
        addAll(MediaKind.movie, data.popular);
        addAll(MediaKind.movie, data.anticipated);
      }
    }

    if (visible.contains('tv')) {
      final data = ref.read(traktShowsHomeProvider).valueOrNull;
      if (data != null) {
        addAll(MediaKind.tv, data.trending);
        addAll(MediaKind.tv, data.popular);
        addAll(MediaKind.tv, data.anticipated);
      }
    }

    if (visible.contains('game')) {
      addAsync(MediaKind.game, ref.read(igdbPopularProvider));
      addAsync(
          MediaKind.game,
          ref.read(igdbGamesSectionListProvider(GamesFeedSection.bestRated)));
      final feed = ref.read(igdbGamesHomeFeedProvider).valueOrNull;
      if (feed != null) {
        addAll(MediaKind.game, feed.anticipated);
        addAll(MediaKind.game, feed.recentlyReleased);
        addAll(MediaKind.game, feed.bestRated);
        addAll(MediaKind.game, feed.indie);
        addAll(MediaKind.game, feed.horror);
        addAll(MediaKind.game, feed.multiplayer);
        addAll(MediaKind.game, feed.rpg);
        addAll(MediaKind.game, feed.sports);
      }
    }

    if (visible.contains('book')) {
      addAsync(MediaKind.book, ref.read(bookTrendingProvider));
      for (final subject in const [
        'love',
        'fantasy',
        'science_fiction',
        'classics',
        'mystery',
      ]) {
        addAsync(MediaKind.book, ref.read(bookSubjectProvider(subject)));
      }
    }

    perKind.removeWhere((_, list) => list.isEmpty);
    if (perKind.isEmpty) return;

    final rng = Random();

    final kinds = perKind.keys.toList();
    final kind = kinds[rng.nextInt(kinds.length)];

    final seen = <String>{};
    final unique = <Map<String, dynamic>>[];
    for (final item in perKind[kind]!) {
      final key = (item['workKey'] as String?) ??
          (item['id']?.toString());
      if (key == null) continue;
      if (seen.add(key)) unique.add(item);
    }
    if (unique.isEmpty) return;

    final pick = unique[rng.nextInt(unique.length)];
    _navigateToItem(context, kind, pick);
  }
}


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


class _HeroSection extends StatefulWidget {
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
  State<_HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<_HeroSection> {
  // Layout constants for the morphing carousel.
  static const double _normalW = 110;
  static const double _normalH = 158;
  static const double _heroW = 170;
  static const double _heroH = 200;
  static const double _gap = 10;
  // Pitch == width by which the leftmost slot advances when one item shifts
  // out: regardless of the current morph state, swapping a hero for a normal
  // changes total width by (heroW - normalW), but a single full slot shift
  // moves the scroll offset by (normalW + gap). So pitch == normalW + gap
  // keeps the leftmost item perfectly aligned with the morph progress.
  static const double _pitch = _normalW + _gap;

  late final ScrollController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(
              title: widget.title,
              icon: widget.icon,
              onSeeAll: widget.onSeeAll,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: _heroH + 38,
            child: ListView.builder(
              controller: _controller,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(right: 16),
              itemCount: items.length,
              itemBuilder: (_, i) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (_, _) {
                    final offset = _controller.hasClients
                        ? _controller.offset
                        : 0.0;
                    final f = (offset / _pitch).clamp(
                      0.0,
                      (items.length - 1).toDouble(),
                    );
                    // Triangular peak: item closest to leftmost gets t=1.
                    final t = max(0.0, 1 - (i - f).abs()).toDouble();
                    final w = lerpDouble(_normalW, _heroW, t)!;
                    final h = lerpDouble(_normalH, _heroH, t)!;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i == items.length - 1 ? 0 : _gap,
                      ),
                      child: _MorphingHeroCard(
                        item: items[i],
                        kind: widget.kind,
                        width: w,
                        height: h,
                        t: t,
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _MorphingHeroCard extends StatelessWidget {
  const _MorphingHeroCard({
    required this.item,
    required this.kind,
    required this.width,
    required this.height,
    required this.t,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final double width;
  final double height;
  // t in [0, 1]: 0 == normal carousel card, 1 == hero card.
  final double t;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final radius = lerpDouble(10, 16, t)!;
    final fontSize = lerpDouble(11, 13, t)!;
    final maxLines = t > 0.55 ? 1 : 2;

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
                  borderRadius: BorderRadius.circular(radius),
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
                    top: lerpDouble(6, 8, t)!,
                    right: lerpDouble(6, 8, t)!,
                    child: _ScoreBadge(score: score, large: t > 0.55),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: t > 0.55 ? FontWeight.w700 : FontWeight.w600,
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
