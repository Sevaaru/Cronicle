import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbWebUnsupportedException;
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/games_home_section_slugs.dart';
import 'package:cronicle/features/games/presentation/games_review_home_card.dart';
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

/// Listado IGDB (popular, reseñas, próximos, etc.) para `/games` o el filtro Juegos del feed.
///
/// [igdbPopularProvider] y [igdbGamesHomeAsideProvider] cargan en paralelo para que
/// “Popular” aparezca antes que el resto.
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final popularAsync = ref.watch(igdbPopularProvider);
    final asideAsync = ref.watch(igdbGamesHomeAsideProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(igdbPopularProvider);
        ref.invalidate(igdbGamesHomeAsideProvider);
        await Future.wait([
          ref.read(igdbPopularProvider.future),
          ref.read(igdbGamesHomeAsideProvider.future),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          popularAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _errorBox(context, e, l10n),
            data: (popular) {
              if (popular.isEmpty) return const SizedBox.shrink();
              return _HomeGamesCarouselSection(
                title: l10n.gamesHomePopularNow,
                slug: GamesHomeSectionSlug.popular,
                items: popular,
                previewCount: _previewCount,
              );
            },
          ),
          asideAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: LinearProgressIndicator(minHeight: 3),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _errorBox(context, e, l10n),
            ),
            data: (aside) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HomeGamesCarouselSection(
                  title: l10n.gamesHomeMostAnticipated,
                  slug: GamesHomeSectionSlug.anticipated,
                  items: aside.anticipated,
                  previewCount: _previewCount,
                ),
                _HomeReviewsSection(
                  title: l10n.gamesHomeRecentReviews,
                  slug: GamesHomeSectionSlug.reviewsRecent,
                  reviews: aside.reviewsRecent,
                  previewCount: _previewCount,
                ),
                _HomeReviewsSection(
                  title: l10n.gamesHomeCriticsReviews,
                  slug: GamesHomeSectionSlug.reviewsCritics,
                  reviews: aside.reviewsFeatured,
                  previewCount: _previewCount,
                ),
                _HomeGamesCarouselSection(
                  title: l10n.gamesHomeRecentlyReleased,
                  slug: GamesHomeSectionSlug.recentlyReleased,
                  items: aside.recentlyReleased,
                  previewCount: _previewCount,
                ),
                _HomeGamesCarouselSection(
                  title: l10n.gamesHomeComingSoon,
                  slug: GamesHomeSectionSlug.comingSoon,
                  items: aside.comingSoon,
                  previewCount: _previewCount,
                  showReleaseDate: true,
                ),
              ],
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
    this.showReleaseDate = false,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final int previewCount;
  final bool showReleaseDate;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final maxShow = previewCount.clamp(0, items.length);
    final slice = items.take(maxShow).toList(growable: false);
    final rowHeight = showReleaseDate ? 206.0 : 188.0;

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
              child: Row(
                children: [
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
                    showReleaseDate ? _formatIgdbReleaseDate(context, item) : null;

                return GestureDetector(
                  onTap: id != null ? () => context.push('/game/$id') : null,
                  child: SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: cover != null
                              ? CachedNetworkImage(
                                  imageUrl: cover,
                                  width: 110,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 110,
                                  height: 150,
                                  color: cs.surfaceContainerHighest,
                                  child: Icon(Icons.sports_esports,
                                      color: cs.onSurfaceVariant),
                                ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
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
                              color: cs.primary,
                            ),
                          ),
                        ],
                        if (score != null)
                          Row(
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
