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
import 'package:cronicle/features/games/presentation/games_section_titles.dart';
import 'package:cronicle/l10n/app_localizations.dart';

String? _formatIgdbReleaseDate(BuildContext context, Map<String, dynamic> item) {
  final ts = item['first_release_date'];
  if (ts == null) return null;
  final sec = ts is int ? ts : ts is num ? ts.toInt() : int.tryParse('$ts');
  if (sec == null || sec <= 0) return null;
  final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true)
      .toLocal();
  final locale = Localizations.localeOf(context).toString();
  return DateFormat.yMMMd(locale).format(dt);
}

/// IGDB home: [igdbPopularProvider] + [igdbGamesHomeFeedProvider] (sequential IGDB).
class GamesHomeFeedView extends ConsumerWidget {
  const GamesHomeFeedView({super.key});

  static const int _previewCount = 6;

  static Widget _errorBox(BuildContext context, Object e, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        e is IgdbWebUnsupportedException
            ? l10n.igdbWebNotSupported
            : l10n.errorWithMessage(e),
        textAlign: TextAlign.center,
      ),
    );
  }

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(igdbPopularProvider);
    ref.invalidate(igdbGamesHomeFeedProvider);
    await Future.wait([
      ref.read(igdbPopularProvider.future),
      ref.read(igdbGamesHomeFeedProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final popularAsync = ref.watch(igdbPopularProvider);
    final asideAsync = ref.watch(igdbGamesHomeFeedProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          popularAsync.when(
            skipLoadingOnRefresh: true,
            skipError: true,
            loading: () => _PopularSkeleton(title: l10n.gamesHomePopularNow),
            error: (e, _) => _errorBox(context, e, l10n),
            data: (popular) {
              if (popular.isEmpty) return const SizedBox.shrink();
              return _HomeGamesCarouselSection(
                title: l10n.gamesHomePopularNow,
                slug: GamesFeedSection.popular,
                items: popular,
                previewCount: _previewCount,
                style: _GameRailStyle.popular(context),
              );
            },
          ),
          asideAsync.when(
            skipLoadingOnRefresh: true,
            skipError: true,
            loading: () => _AsideLoadingSkeletons(l10n: l10n),
            error: (e, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _errorBox(context, e, l10n),
            ),
            data: (aside) => _AsideFromData(
              l10n: l10n,
              aside: aside,
              previewCount: _previewCount,
            ),
          ),
        ],
      ),
    );
  }
}

class _AsideFromData extends StatelessWidget {
  const _AsideFromData({
    required this.l10n,
    required this.aside,
    required this.previewCount,
  });

  final AppLocalizations l10n;
  final IgdbGamesHomeFeedData aside;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (aside.anticipated.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.anticipated),
            slug: GamesFeedSection.anticipated,
            items: aside.anticipated,
            previewCount: previewCount,
            style: _GameRailStyle.featured(context),
          ),
        if (aside.recentlyReleased.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.recentlyReleased),
            slug: GamesFeedSection.recentlyReleased,
            items: aside.recentlyReleased,
            previewCount: previewCount,
            style: _GameRailStyle.standard(context),
          ),
        if (aside.reviewsRecent.isNotEmpty)
          _HomeReviewsSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.reviewsRecent),
            slug: GamesFeedSection.reviewsRecent,
            reviews: aside.reviewsRecent,
            previewCount: previewCount,
          ),
        if (aside.comingSoon.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.comingSoon),
            slug: GamesFeedSection.comingSoon,
            items: aside.comingSoon,
            previewCount: previewCount,
            style: _GameRailStyle.compactDates(context),
            showReleaseDate: true,
          ),
        if (aside.bestRated.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.bestRated),
            slug: GamesFeedSection.bestRated,
            items: aside.bestRated,
            previewCount: previewCount,
            style: _GameRailStyle.tallScores(context),
          ),
        if (aside.reviewsCritics.isNotEmpty)
          _HomeReviewsSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.reviewsCritics),
            slug: GamesFeedSection.reviewsCritics,
            reviews: aside.reviewsCritics,
            previewCount: previewCount,
          ),
        if (aside.indie.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.indie),
            slug: GamesFeedSection.indie,
            items: aside.indie,
            previewCount: previewCount,
            style: _GameRailStyle.wideTint(context, const Color(0xFF0D9488)),
          ),
        if (aside.horror.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.horror),
            slug: GamesFeedSection.horror,
            items: aside.horror,
            previewCount: previewCount,
            style: _GameRailStyle.wideTint(context, const Color(0xFF7C3AED)),
          ),
        if (aside.multiplayer.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.multiplayer),
            slug: GamesFeedSection.multiplayer,
            items: aside.multiplayer,
            previewCount: previewCount,
            style: _GameRailStyle.standard(context),
          ),
        if (aside.rpg.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.rpg),
            slug: GamesFeedSection.rpg,
            items: aside.rpg,
            previewCount: previewCount,
            style: _GameRailStyle.posterFocus(context),
          ),
        if (aside.sports.isNotEmpty)
          _HomeGamesCarouselSection(
            title: gamesHomeSectionTitle(l10n, GamesFeedSection.sports),
            slug: GamesFeedSection.sports,
            items: aside.sports,
            previewCount: previewCount,
            style: _GameRailStyle.wideTint(context, const Color(0xFF2563EB)),
          ),
      ],
    );
  }
}

class _AsideLoadingSkeletons extends StatelessWidget {
  const _AsideLoadingSkeletons({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.anticipated),
          style: _GameRailStyle.featured(context),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.recentlyReleased),
          style: _GameRailStyle.standard(context),
        ),
        _ReviewsSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.reviewsRecent),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.comingSoon),
          style: _GameRailStyle.compactDates(context),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.bestRated),
          style: _GameRailStyle.tallScores(context),
        ),
        _ReviewsSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.reviewsCritics),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.indie),
          style: _GameRailStyle.wideTint(context, const Color(0xFF0D9488)),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.horror),
          style: _GameRailStyle.wideTint(context, const Color(0xFF7C3AED)),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.multiplayer),
          style: _GameRailStyle.standard(context),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.rpg),
          style: _GameRailStyle.posterFocus(context),
        ),
        _GameRailSkeleton(
          title: gamesHomeSectionTitle(l10n, GamesFeedSection.sports),
          style: _GameRailStyle.wideTint(context, const Color(0xFF2563EB)),
        ),
      ],
    );
  }
}

class _GameRailStyle {
  const _GameRailStyle({
    required this.cardWidth,
    required this.posterHeight,
    this.showReleaseDate = false,
    this.accent,
    this.titleChip = false,
  });

  final double cardWidth;
  final double posterHeight;
  final bool showReleaseDate;
  final Color? accent;
  final bool titleChip;

  double get rowHeight => posterHeight + (showReleaseDate ? 56 : 38);

  factory _GameRailStyle.popular(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _GameRailStyle(
      cardWidth: 118,
      posterHeight: 160,
      accent: cs.primary,
      titleChip: true,
    );
  }

  factory _GameRailStyle.featured(BuildContext context) {
    return _GameRailStyle(
      cardWidth: 124,
      posterHeight: 168,
      accent: Theme.of(context).colorScheme.tertiary,
    );
  }

  factory _GameRailStyle.standard(BuildContext context) {
    return _GameRailStyle(
      cardWidth: 110,
      posterHeight: 150,
    );
  }

  factory _GameRailStyle.compactDates(BuildContext context) {
    return _GameRailStyle(
      cardWidth: 104,
      posterHeight: 148,
      showReleaseDate: true,
      accent: Theme.of(context).colorScheme.primary,
    );
  }

  factory _GameRailStyle.tallScores(BuildContext context) {
    return _GameRailStyle(
      cardWidth: 116,
      posterHeight: 164,
      accent: Colors.amber.shade700,
    );
  }

  factory _GameRailStyle.wideTint(BuildContext context, Color accent) {
    return _GameRailStyle(
      cardWidth: 120,
      posterHeight: 156,
      accent: accent,
    );
  }

  factory _GameRailStyle.posterFocus(BuildContext context) {
    return _GameRailStyle(
      cardWidth: 108,
      posterHeight: 172,
    );
  }
}

class _PopularSkeleton extends StatelessWidget {
  const _PopularSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonTitleBar(title: title, accent: cs.primary, chip: true),
          const SizedBox(height: 10),
          SizedBox(
            height: 160 + 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) =>
                  _SkeletonPoster(width: 118, height: 160, cs: cs),
            ),
          ),
        ],
      ),
    );
  }
}

class _GameRailSkeleton extends StatelessWidget {
  const _GameRailSkeleton({required this.title, required this.style});

  final String title;
  final _GameRailStyle style;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonTitleBar(
            title: title,
            accent: style.accent,
            chip: style.titleChip,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: style.rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _SkeletonPoster(
                width: style.cardWidth,
                height: style.posterHeight,
                cs: cs,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SkeletonTitleBar extends StatelessWidget {
  const _SkeletonTitleBar({
    required this.title,
    this.accent,
    this.chip = false,
  });

  final String title;
  final Color? accent;
  final bool chip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = accent?.withValues(alpha: 0.12) ?? cs.surfaceContainerHighest;
    if (chip) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: accent ?? cs.onSurface,
          ),
        ),
      );
    }
    return Row(
      children: [
        if (accent != null)
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        if (accent != null) const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
        ),
      ],
    );
  }
}

class _SkeletonPoster extends StatelessWidget {
  const _SkeletonPoster({
    required this.width,
    required this.height,
    required this.cs,
  });

  final double width;
  final double height;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 10,
          width: width * 0.85,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}

class _ReviewsSkeleton extends StatelessWidget {
  const _ReviewsSkeleton({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 10),
          ...List.generate(
            3,
            (i) => Padding(
              padding: EdgeInsets.only(bottom: i < 2 ? 10 : 0),
              child: Container(
                height: 88,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeGamesCarouselSection extends StatelessWidget {
  const _HomeGamesCarouselSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.previewCount,
    required this.style,
    this.showReleaseDate,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final int previewCount;
  final _GameRailStyle style;
  final bool? showReleaseDate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final maxShow = previewCount.clamp(0, items.length);
    final slice = items.take(maxShow).toList(growable: false);
    final rowHeight = style.rowHeight;
    final useDates = showReleaseDate ?? style.showReleaseDate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/games/section/$slug'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: style.titleChip
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (style.accent ?? cs.primary)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: style.accent ?? cs.primary,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: style.accent ?? cs.primary),
                        ],
                      ),
                    )
                  : Row(
                      children: [
                        if (style.accent != null) ...[
                          Container(
                            width: 4,
                            height: 22,
                            decoration: BoxDecoration(
                              color: style.accent,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: cs.primary),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: rowHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = slice[i];
                final titleMap = item['title'] as Map<String, dynamic>? ?? {};
                final cover =
                    (item['coverImage'] as Map?)?['large'] as String?;
                final name = (titleMap['english'] as String?) ?? '';
                final score = item['averageScore'] as int?;
                final id = item['id'] as int?;
                final dateLine =
                    useDates ? _formatIgdbReleaseDate(context, item) : null;

                return GestureDetector(
                  onTap: id != null ? () => context.push('/game/$id') : null,
                  child: SizedBox(
                    width: style.cardWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: cover != null
                              ? CachedNetworkImage(
                                  imageUrl: cover,
                                  width: style.cardWidth,
                                  height: style.posterHeight,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: style.cardWidth,
                                  height: style.posterHeight,
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.sports_esports,
                                      color: cs.onSurfaceVariant),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: useDates ? 1 : 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: style.posterHeight > 165 ? 11.5 : 11,
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                        ),
                        if (dateLine != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            dateLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: style.accent ?? cs.primary,
                            ),
                          ),
                        ],
                        if (score != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              children: [
                                Icon(Icons.star,
                                    size: 11, color: Colors.amber.shade600),
                                const SizedBox(width: 2),
                                Text(
                                  '$score%',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeReviewsSection extends StatelessWidget {
  const _HomeReviewsSection({
    required this.title,
    required this.slug,
    required this.reviews,
    required this.previewCount,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> reviews;
  final int previewCount;

  @override
  Widget build(BuildContext context) {
    if (reviews.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final maxShow = previewCount.clamp(0, reviews.length);
    final slice = reviews.take(maxShow).toList(growable: false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => context.push('/games/section/$slug'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.rate_review_outlined, color: cs.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(Icons.chevron_right, color: cs.primary),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...slice.map((r) => GamesReviewHomeCard(review: r)),
        ],
      ),
    );
  }
}
