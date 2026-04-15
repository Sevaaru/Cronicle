import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbApiDatasource, IgdbWebUnsupportedException;
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/igdb_detail_helpers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class GamesPage extends ConsumerWidget {
  const GamesPage({super.key});

  static const int _gamesCollapsed = 6;
  static const int _gamesExpanded = 24;
  static const int _reviewsCollapsed = 3;
  static const int _reviewsExpanded = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final home = ref.watch(igdbGamesHomeProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navGames)),
      body: home.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              e is IgdbWebUnsupportedException
                  ? l10n.igdbWebNotSupported
                  : l10n.errorWithMessage(e),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(igdbGamesHomeProvider);
            await ref.read(igdbGamesHomeProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ExpandableGamesSection(
                title: l10n.gamesHomePopularNow,
                items: data.popular,
                collapsedCount: _gamesCollapsed,
                expandedCount: _gamesExpanded,
              ),
              _ExpandableGamesSection(
                title: l10n.gamesHomeMostAnticipated,
                items: data.anticipated,
                collapsedCount: _gamesCollapsed,
                expandedCount: _gamesExpanded,
              ),
              _ExpandableReviewsSection(
                title: l10n.gamesHomeRecentReviews,
                reviews: data.reviewsRecent,
                collapsedCount: _reviewsCollapsed,
                expandedCount: _reviewsExpanded,
              ),
              _ExpandableReviewsSection(
                title: l10n.gamesHomeCriticsReviews,
                reviews: data.reviewsFeatured,
                collapsedCount: _reviewsCollapsed,
                expandedCount: _reviewsExpanded,
              ),
              _ExpandableGamesSection(
                title: l10n.gamesHomeRecentlyReleased,
                items: data.recentlyReleased,
                collapsedCount: _gamesCollapsed,
                expandedCount: _gamesExpanded,
              ),
              _ExpandableGamesSection(
                title: l10n.gamesHomeComingSoon,
                items: data.comingSoon,
                collapsedCount: _gamesCollapsed,
                expandedCount: _gamesExpanded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpandableGamesSection extends StatefulWidget {
  const _ExpandableGamesSection({
    required this.title,
    required this.items,
    required this.collapsedCount,
    required this.expandedCount,
  });

  final String title;
  final List<Map<String, dynamic>> items;
  final int collapsedCount;
  final int expandedCount;

  @override
  State<_ExpandableGamesSection> createState() => _ExpandableGamesSectionState();
}

class _ExpandableGamesSectionState extends State<_ExpandableGamesSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final maxShow = _expanded
        ? widget.expandedCount.clamp(0, widget.items.length)
        : widget.collapsedCount.clamp(0, widget.items.length);
    final slice = widget.items.take(maxShow).toList(growable: false);
    final canToggle = widget.items.length > widget.collapsedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: canToggle
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (canToggle)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.primary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final item = slice[i];
                final title = item['title'] as Map<String, dynamic>? ?? {};
                final cover =
                    (item['coverImage'] as Map?)?['large'] as String?;
                final name = (title['english'] as String?) ?? '';
                final score = item['averageScore'] as int?;
                final id = item['id'] as int?;

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
          if (canToggle)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                child: Text(
                  _expanded
                      ? l10n.gamesHomeSectionCollapse
                      : l10n.gamesHomeSectionExpand,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExpandableReviewsSection extends StatefulWidget {
  const _ExpandableReviewsSection({
    required this.title,
    required this.reviews,
    required this.collapsedCount,
    required this.expandedCount,
  });

  final String title;
  final List<Map<String, dynamic>> reviews;
  final int collapsedCount;
  final int expandedCount;

  @override
  State<_ExpandableReviewsSection> createState() =>
      _ExpandableReviewsSectionState();
}

class _ExpandableReviewsSectionState extends State<_ExpandableReviewsSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.reviews.isEmpty) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final maxShow = _expanded
        ? widget.expandedCount.clamp(0, widget.reviews.length)
        : widget.collapsedCount.clamp(0, widget.reviews.length);
    final slice = widget.reviews.take(maxShow).toList(growable: false);
    final canToggle = widget.reviews.length > widget.collapsedCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: canToggle
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (canToggle)
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: cs.primary,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          ...slice.map((r) => _ReviewHomeCard(review: r)),
          if (canToggle)
            TextButton(
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? l10n.gamesHomeSectionCollapse
                    : l10n.gamesHomeSectionExpand,
              ),
            ),
        ],
      ),
    );
  }
}

class _ReviewHomeCard extends StatelessWidget {
  const _ReviewHomeCard({required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final id = review['id'];
    final reviewId = id is int ? id : id is num ? id.toInt() : null;
    final title = (review['title'] as String?)?.trim();
    final content = review['content'] as String? ?? '';
    final excerpt = gameDetailLinkChipTitle(
      stripSimpleHtml(content),
      maxChars: 140,
    );
    final scoreVal = review['score'];
    int? score;
    if (scoreVal is int) {
      score = scoreVal;
    } else if (scoreVal is num) {
      score = scoreVal.toInt();
    }
    final user = review['user'] as Map<String, dynamic>?;
    final by = user?['username'] as String? ?? '';
    final game = review['game'] as Map<String, dynamic>?;
    final gameName = game?['name'] as String? ?? '';
    final gameId = game?['id'] as int?;
    final cover = game?['cover'] as Map<String, dynamic>?;
    final imgId = cover?['image_id'] as String?;
    final coverUrl =
        imgId != null ? IgdbApiDatasource.coverUrl(imgId) : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: reviewId != null
              ? () => context.push('/igdb-review/$reviewId')
              : null,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: coverUrl,
                          width: 48,
                          height: 64,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 64,
                          color: cs.surfaceContainerHigh,
                          child: Icon(Icons.sports_esports,
                              size: 22, color: cs.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (gameName.isNotEmpty)
                        Text(
                          gameName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: cs.primary,
                          ),
                        ),
                      if (title != null && title.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                      if (excerpt.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          excerpt,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (score != null) ...[
                            Icon(Icons.star,
                                size: 14, color: Colors.amber.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '$score',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          if (by.isNotEmpty)
                            Expanded(
                              child: Text(
                                l10n.gameDetailReviewBy(by),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (gameId != null)
                  IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    tooltip: l10n.gamesHomeOpenGame,
                    onPressed: () => context.push('/game/$gameId'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
