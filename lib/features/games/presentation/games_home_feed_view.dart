import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbWebUnsupportedException;
import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/games_review_home_card.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/library_add_badge.dart';


String? _formatRelDate(BuildContext ctx, Map<String, dynamic> item) {
  final ts = item['first_release_date'];
  if (ts == null) return null;
  final sec = ts is int ? ts : ts is num ? ts.toInt() : int.tryParse('$ts');
  if (sec == null || sec <= 0) return null;
  final dt =
      DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true).toLocal();
  return DateFormat.yMMMd(Localizations.localeOf(ctx).toString()).format(dt);
}

String? _coverUrl(Map<String, dynamic> item) =>
    (item['coverImage'] as Map?)?['large'] as String?;

String _gameName(Map<String, dynamic> item) =>
    ((item['title'] as Map?)?['english'] as String?) ??
    (item['name'] as String?) ??
    '';

int? _gameScore(Map<String, dynamic> item) => item['averageScore'] as int?;

Color _scoreColor(int s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFF94A3B8);
}


class GamesHomeFeedView extends ConsumerWidget {
  const GamesHomeFeedView({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(igdbPopularProvider);
    ref.invalidate(igdbGamesHomeFeedProvider);
    await Future.wait([
      ref.read(igdbPopularProvider.future),
      ref.read(igdbGamesHomeFeedProvider.future),
    ]);
  }

  static Widget _errorBox(
    BuildContext context,
    Object e,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    final cs = Theme.of(context).colorScheme;
    final msg = e is IgdbWebUnsupportedException
        ? l10n.igdbWebNotSupported
        : e.toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 32, color: cs.error),
            const SizedBox(height: 8),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: cs.onErrorContainer),
            ),
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: () {
                ref.invalidate(igdbGamesHomeFeedProvider);
              },
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final popularAsync = ref.watch(igdbPopularProvider);
    final asideAsync = ref.watch(igdbGamesHomeFeedProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: ListView(
        padding: EdgeInsets.only(
          bottom: kGlassBottomNavContentHeight + 28,
        ),
        children: [
          popularAsync.when(
            skipLoadingOnRefresh: true,
            skipError: true,
            loading: () => _ScoreCarouselSkeleton(
              title: l10n.gamesHomePopularNow,
              cardWidth: 126,
              cardHeight: 172,
            ),
            error: (e, _) => _errorBox(context, e, l10n, ref),
            data: (list) => list.isEmpty
                ? const SizedBox.shrink()
                : _ScoreCarouselSection(
                    title: l10n.gamesHomePopularNow,
                    slug: GamesFeedSection.popular,
                    items: list,
                    cardWidth: 126,
                    cardHeight: 172,
                    icon: Icons.local_fire_department_rounded,
                    accent: Theme.of(context).colorScheme.primary,
                  ),
          ),
          asideAsync.when(
            skipLoadingOnRefresh: true,
            skipError: false,
            loading: () => _AsideSkeletons(l10n: l10n),
            error: (e, _) => _errorBox(context, e, l10n, ref),
            data: (aside) => _AsideSections(aside: aside, l10n: l10n),
          ),
        ],
      ),
    );
  }
}


class _AsideSections extends StatelessWidget {
  const _AsideSections({required this.aside, required this.l10n});

  final IgdbGamesHomeFeedData aside;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aside.comingSoon.isNotEmpty)
          _DateCardsSection(
            title: l10n.gamesHomeComingSoon,
            slug: GamesFeedSection.comingSoon,
            items: aside.comingSoon,
          ),
        if (aside.anticipated.isNotEmpty)
          _RankedListSection(
            title: l10n.gamesHomeMostAnticipated,
            slug: GamesFeedSection.anticipated,
            items: aside.anticipated,
          ),
        if (aside.recentlyReleased.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.gamesHomeRecentlyReleased,
            slug: GamesFeedSection.recentlyReleased,
            items: aside.recentlyReleased,
            cardWidth: 108,
            cardHeight: 148,
            icon: Icons.new_releases_outlined,
          ),
        if (aside.reviewsRecent.isNotEmpty)
          _ReviewsSection(
            title: l10n.gamesHomeRecentReviews,
            slug: GamesFeedSection.reviewsRecent,
            reviews: aside.reviewsRecent.take(3).toList(),
          ),
        if (aside.bestRated.isNotEmpty)
          _HeroSection(
            title: l10n.gamesHomeBestRated,
            slug: GamesFeedSection.bestRated,
            items: aside.bestRated,
            accent: Colors.amber.shade600,
            icon: Icons.star_rounded,
          ),
        if (aside.horror.isNotEmpty)
          _MoodBandSection(
            title: l10n.gamesHomeHorrorPicks,
            slug: GamesFeedSection.horror,
            items: aside.horror,
            accent: const Color(0xFF9333EA),
            darkBg: const Color(0xFF180B2A),
            icon: Icons.nights_stay_rounded,
          ),
        if (aside.rpg.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.gamesHomeRpgSpotlight,
            slug: GamesFeedSection.rpg,
            items: aside.rpg,
            cardWidth: 118,
            cardHeight: 162,
            icon: Icons.auto_fix_high_rounded,
            accent: const Color(0xFF8B5CF6),
          ),
        if (aside.multiplayer.isNotEmpty)
          _SpotlightRowsSection(
            title: l10n.gamesHomeMultiplayer,
            slug: GamesFeedSection.multiplayer,
            items: aside.multiplayer,
            accent: const Color(0xFF2563EB),
            icon: Icons.people_rounded,
          ),
        if (aside.reviewsCritics.isNotEmpty)
          _ReviewsSection(
            title: l10n.gamesHomeCriticsReviews,
            slug: GamesFeedSection.reviewsCritics,
            reviews: aside.reviewsCritics.take(3).toList(),
          ),
        if (aside.indie.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.gamesHomeIndiePicks,
            slug: GamesFeedSection.indie,
            items: aside.indie,
            cardWidth: 112,
            cardHeight: 154,
            icon: Icons.lightbulb_outline_rounded,
            accent: const Color(0xFF0D9488),
          ),
        if (aside.sports.isNotEmpty)
          _MoodBandSection(
            title: l10n.gamesHomeSportsSpotlight,
            slug: GamesFeedSection.sports,
            items: aside.sports,
            accent: const Color(0xFF3B82F6),
            darkBg: const Color(0xFF081424),
            icon: Icons.sports_soccer_rounded,
          ),
      ],
    );
  }
}


class _AsideSkeletons extends StatelessWidget {
  const _AsideSkeletons({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DateCardsSkeleton(title: l10n.gamesHomeComingSoon),
        _RankedListSkeleton(title: l10n.gamesHomeMostAnticipated),
        _ScoreCarouselSkeleton(
          title: l10n.gamesHomeRecentlyReleased,
          cardWidth: 108,
          cardHeight: 148,
        ),
        _ReviewsSkeleton(title: l10n.gamesHomeRecentReviews),
        _HeroSkeleton(title: l10n.gamesHomeBestRated),
        _MoodBandSkeleton(
          title: l10n.gamesHomeHorrorPicks,
          accent: const Color(0xFF9333EA),
          darkBg: const Color(0xFF180B2A),
        ),
        _ScoreCarouselSkeleton(
          title: l10n.gamesHomeRpgSpotlight,
          cardWidth: 118,
          cardHeight: 162,
        ),
        _SpotlightRowsSkeleton(title: l10n.gamesHomeMultiplayer),
        _ReviewsSkeleton(title: l10n.gamesHomeCriticsReviews),
        _ScoreCarouselSkeleton(
          title: l10n.gamesHomeIndiePicks,
          cardWidth: 112,
          cardHeight: 154,
        ),
        _MoodBandSkeleton(
          title: l10n.gamesHomeSportsSpotlight,
          accent: const Color(0xFF3B82F6),
          darkBg: const Color(0xFF081424),
        ),
      ],
    );
  }
}



class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.slug,
    this.accent,
    this.icon,
    this.onDark = false,
  });

  final String title;
  final String slug;
  final Color? accent;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.primary;
    final textColor = onDark ? Colors.white : cs.onSurface;
    final chevronColor = onDark ? Colors.white60 : cs.onSurfaceVariant;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push('/games/section/$slug'),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: chevronColor),
        ],
      ),
    );
  }
}


Widget _skel(BuildContext ctx,
    {required double w, required double h, double r = 8, Color? color}) {
  final cs = Theme.of(ctx).colorScheme;
  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color ?? cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}



class _ScoreCarouselSection extends StatelessWidget {
  const _ScoreCarouselSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.cardWidth,
    required this.cardHeight,
    this.icon,
    this.accent,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final double cardWidth;
  final double cardHeight;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(
              title: title,
              slug: slug,
              accent: accent,
              icon: icon,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _ScoreCarouselCard(
                item: slice[i],
                width: cardWidth,
                height: cardHeight,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCarouselCard extends StatelessWidget {
  const _ScoreCarouselCard({
    required this.item,
    required this.width,
    required this.height,
    this.accent,
  });

  final Map<String, dynamic> item;
  final double width;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _gameName(item);
    final score = _gameScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
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
                      ? CachedNetworkImage(
                          imageUrl: url,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => _PosterPlaceholder(
                              width: width, height: height, radius: 10),
                        )
                      : _PosterPlaceholder(
                          width: width, height: height, radius: 10),
                ),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: LibraryAddBadge(
                      item: item, kind: MediaKind.game),
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


class _DateCardsSection extends StatelessWidget {
  const _DateCardsSection({
    required this.title,
    required this.slug,
    required this.items,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;

  static const double _cardW = 156;
  static const double _cardH = 216;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final slice = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(
              title: title,
              slug: slug,
              icon: Icons.calendar_month_rounded,
              accent: cs.tertiary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _DateCard(item: slice[i]),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _gameName(item);
    final dateStr = _formatRelDate(context, item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: _DateCardsSection._cardW,
          height: _DateCardsSection._cardH,
          child: Stack(
            fit: StackFit.expand,
            children: [
              url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          Container(color: cs.surfaceContainerHighest),
                    )
                  : Container(color: cs.surfaceContainerHighest),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.4, 1.0],
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (dateStr != null)
                      Text(
                        dateStr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child:
                    LibraryAddBadge(item: item, kind: MediaKind.game),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _RankedListSection extends StatelessWidget {
  const _RankedListSection({
    required this.title,
    required this.slug,
    required this.items,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final slice = items.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            slug: slug,
            icon: Icons.rocket_launch_rounded,
            accent: cs.tertiary,
          ),
          const SizedBox(height: 10),
          ...List.generate(
            slice.length,
            (i) => _RankedRow(item: slice[i], rank: i + 1),
          ),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({required this.item, required this.rank});

  final Map<String, dynamic> item;
  final int rank;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _gameName(item);
    final dateStr = _formatRelDate(context, item);
    final id = item['id'] as int?;
    final platforms = item['format'] as String?;
    final rawMap = item['_raw'] as Map<String, dynamic>?;
    final hypesVal = rawMap?['hypes'];
    final hypes = hypesVal is int
        ? hypesVal
        : hypesVal is num
            ? hypesVal.toInt()
            : null;

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.45),
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _PosterPlaceholder(width: 48, height: 64, radius: 7),
                    )
                  : _PosterPlaceholder(width: 48, height: 64, radius: 7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (platforms != null && platforms.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      platforms,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (hypes != null && hypes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department_rounded,
                            size: 13, color: Colors.orange.shade400),
                        const SizedBox(width: 3),
                        Text(
                          '$hypes hypes',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else if (dateStr != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
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


class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hero = items.first;
    final rest = items.skip(1).take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            slug: slug,
            accent: accent,
            icon: icon,
          ),
          const SizedBox(height: 12),
          _HeroCard(item: hero, accent: accent),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rest.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = rest[i];
                  final id = it['id'] as int?;
                  final url = _coverUrl(it);
                  final score = _gameScore(it);
                  return GestureDetector(
                    onTap: id != null ? () => ctx.push('/game/$id') : null,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url != null
                              ? CachedNetworkImage(
                                  imageUrl: url,
                                  width: 70,
                                  height: 96,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, _, _) =>
                                      _PosterPlaceholder(
                                          width: 70, height: 96, radius: 8),
                                )
                              : _PosterPlaceholder(
                                  width: 70, height: 96, radius: 8),
                        ),
                        if (score != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _ScoreBadge(score: score, small: true),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.item, required this.accent});

  final Map<String, dynamic> item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _gameName(item);
    final score = _gameScore(item);
    final id = item['id'] as int?;
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres =
        genresList != null && genresList.isNotEmpty ? genresList.take(2).join(' · ') : '';
    final platforms = item['format'] as String?;

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 88,
                      height: 120,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _PosterPlaceholder(width: 88, height: 120, radius: 0),
                    )
                  : _PosterPlaceholder(width: 88, height: 120, radius: 0),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (score != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Icon(Icons.star_rounded, size: 15, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        genres,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (platforms != null && platforms.isNotEmpty)
                      Text(
                        platforms,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _MoodBandSection extends StatelessWidget {
  const _MoodBandSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.darkBg,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final Color darkBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _SectionHeader(
                title: title,
                slug: slug,
                accent: accent,
                icon: icon,
                onDark: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slice.length,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = slice[i];
                  final url = _coverUrl(it);
                  final id = it['id'] as int?;
                  return GestureDetector(
                    onTap: id != null ? () => ctx.push('/game/$id') : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? CachedNetworkImage(
                              imageUrl: url,
                              width: 108,
                              height: 148,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Container(
                                width: 108,
                                height: 148,
                                color: accent.withValues(alpha: 0.15),
                              ),
                            )
                          : Container(
                              width: 108,
                              height: 148,
                              color: accent.withValues(alpha: 0.15),
                              child: const Icon(Icons.sports_esports_rounded,
                                  color: Colors.white24),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}


class _SpotlightRowsSection extends StatelessWidget {
  const _SpotlightRowsSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            slug: slug,
            accent: accent,
            icon: icon,
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(slice.length, (i) {
                final isLast = i == slice.length - 1;
                return Column(
                  children: [
                    _SpotlightRow(item: slice[i], accent: accent),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: accent.withValues(alpha: 0.15),
                        indent: 72,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({required this.item, required this.accent});

  final Map<String, dynamic> item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _gameName(item);
    final score = _gameScore(item);
    final id = item['id'] as int?;
    final platforms = item['format'] as String?;
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres = genresList != null && genresList.isNotEmpty
        ? genresList.take(2).join(' · ')
        : '';

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? CachedNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          _PosterPlaceholder(width: 48, height: 64, radius: 7),
                    )
                  : _PosterPlaceholder(width: 48, height: 64, radius: 7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (genres.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      genres,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (platforms != null && platforms.isNotEmpty)
                    Text(
                      platforms,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                ],
              ),
            ),
            if (score != null) ...[
              const SizedBox(width: 8),
              _ScoreBadge(score: score),
            ],
          ],
        ),
      ),
    );
  }
}


class _ReviewsSection extends StatelessWidget {
  const _ReviewsSection({
    required this.title,
    required this.slug,
    required this.reviews,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> reviews;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: title,
            slug: slug,
            icon: Icons.rate_review_outlined,
          ),
          const SizedBox(height: 10),
          ...reviews.map((r) => GamesReviewHomeCard(review: r)),
        ],
      ),
    );
  }
}


class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder(
      {required this.width, required this.height, required this.radius});

  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(Icons.sports_esports_rounded,
          size: width * 0.4, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, this.small = false});

  final int score;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 6,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _scoreColor(score),
        borderRadius: BorderRadius.circular(small ? 5 : 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}


class _ScoreCarouselSkeleton extends StatelessWidget {
  const _ScoreCarouselSkeleton({
    required this.title,
    required this.cardWidth,
    required this.cardHeight,
  });

  final String title;
  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _skel(context, w: 18, h: 18, r: 4),
                const SizedBox(width: 8),
                _skel(context, w: 140, h: 16, r: 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skel(ctx, w: cardWidth, h: cardHeight, r: 10),
                  const SizedBox(height: 5),
                  _skel(ctx, w: cardWidth * 0.75, h: 10, r: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCardsSkeleton extends StatelessWidget {
  const _DateCardsSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _skel(context, w: 18, h: 18, r: 4),
                const SizedBox(width: 8),
                _skel(context, w: 130, h: 16, r: 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: _DateCardsSection._cardH,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 4,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, _) => _skel(
                ctx,
                w: _DateCardsSection._cardW,
                h: _DateCardsSection._cardH,
                r: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedListSkeleton extends StatelessWidget {
  const _RankedListSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 140, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _skel(context, w: 30, h: 24, r: 4),
                  const SizedBox(width: 10),
                  _skel(context, w: 48, h: 64, r: 7),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skel(context, w: double.infinity, h: 13, r: 4),
                        const SizedBox(height: 5),
                        _skel(context, w: 90, h: 11, r: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 130, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 12),
          _skel(context, w: double.infinity, h: 120, r: 14),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, _) => _skel(ctx, w: 70, h: 96, r: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBandSkeleton extends StatelessWidget {
  const _MoodBandSkeleton({
    required this.title,
    required this.accent,
    required this.darkBg,
  });

  final String title;
  final Color accent;
  final Color darkBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, _) => Container(
                  width: 108,
                  height: 148,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _SpotlightRowsSkeleton extends StatelessWidget {
  const _SpotlightRowsSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 140, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(4, (i) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          _skel(context, w: 48, h: 64, r: 7),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _skel(context,
                                    w: double.infinity, h: 13, r: 4),
                                const SizedBox(height: 5),
                                _skel(context, w: 90, h: 11, r: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < 3)
                      Divider(
                          height: 1, color: cs.surfaceContainerHighest),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 140, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(
            3,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _skel(context, w: double.infinity, h: 88, r: 12),
            ),
          ),
        ],
      ),
    );
  }
}
