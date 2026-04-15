import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbApiDatasource;
import 'package:cronicle/features/games/presentation/igdb_detail_helpers.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class GamesReviewHomeCard extends StatelessWidget {
  const GamesReviewHomeCard({super.key, required this.review});

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
