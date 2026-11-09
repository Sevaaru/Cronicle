import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/igdb_detail_helpers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class IgdbGameReviewDetailPage extends ConsumerWidget {
  const IgdbGameReviewDetailPage({super.key, required this.reviewId});

  final int reviewId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(igdbReviewByIdProvider(reviewId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.gameDetailReviewsSection),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              l10n.errorWithMessage(e),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (review) {
          if (review == null) {
            return Center(child: Text(l10n.igdbReviewNotFound));
          }
          final title = (review['title'] as String?)?.trim();
          final content = review['content'] as String? ?? '';
          final body = stripSimpleHtml(content);
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
          final created = review['created_at'];
          DateTime? date;
          if (created is int) {
            date = DateTime.fromMillisecondsSinceEpoch(created * 1000);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (gameId != null)
                Material(
                  color: cs.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/game/$gameId'),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: coverUrl != null
                                ? CachedNetworkImage(
                                    imageUrl: coverUrl,
                                    width: 56,
                                    height: 72,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 56,
                                    height: 72,
                                    color: cs.surfaceContainerHigh,
                                    child: Icon(Icons.sports_esports,
                                        color: cs.onSurfaceVariant),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  gameName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.gamesHomeOpenGame,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right, color: cs.outline),
                        ],
                      ),
                    ),
                  ),
                ),
              if (gameId != null) const SizedBox(height: 16),
              if (title != null && title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              if (title != null && title.isNotEmpty) const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (score != null)
                    Chip(
                      avatar: Icon(Icons.star, size: 18, color: cs.primary),
                      label: Text('$score'),
                    ),
                  if (by.isNotEmpty)
                    Text(
                      l10n.gameDetailReviewBy(by),
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  if (date != null)
                    Text(
                      '${date.day}/${date.month}/${date.year}',
                      style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              SelectableText(
                body.isEmpty ? '—' : body,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.45,
                  color: cs.onSurface,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
