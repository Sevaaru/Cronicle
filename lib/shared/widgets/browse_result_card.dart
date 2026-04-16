import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

/// Tarjeta estilo búsqueda (portada, chips, géneros, nota, botón + a biblioteca).
class BrowseResultCard extends StatelessWidget {
  const BrowseResultCard({
    super.key,
    required this.item,
    required this.kind,
    required this.onAdd,
    this.releaseDateLine,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  /// Ej.: fecha de salida en listados IGDB “Próximamente”.
  final String? releaseDateLine;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final title = item['title'] as Map<String, dynamic>? ?? {};
    final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        (item['name'] as String?) ??
        '';
    final poster = coverImage['large'] as String?;
    final episodes = item['episodes'] as int?;
    final chapters = item['chapters'] as int?;
    final score = item['averageScore'] as int?;
    final genres =
        (item['genres'] as List?)?.cast<String>().take(3).join(', ');
    final format = item['format'] as String?;

    final bool isManga = kind == MediaKind.manga;
    final bool isGame = kind == MediaKind.game;
    final countLabel = isGame
        ? null
        : isManga
            ? (chapters != null ? '$chapters cap' : null)
            : (episodes != null ? '$episodes ep' : null);

    final itemId = item['id'] as int?;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (itemId != null) {
            if (kind == MediaKind.game) {
              context.push('/game/$itemId');
            } else if (kind == MediaKind.movie) {
              context.push('/trakt-movie/$itemId');
            } else if (kind == MediaKind.tv) {
              context.push('/trakt-show/$itemId');
            } else {
              context.push('/media/$itemId?kind=${kind.code}');
            }
          }
        },
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: poster != null
                  ? RemoteNetworkImage(
                      imageUrl: poster,
                      width: 75,
                      height: 105,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 75,
                      height: 105,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (format != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              format,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        if (format != null) const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            mediaKindLabel(kind, l10n),
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (genres != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        genres,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (releaseDateLine != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        releaseDateLine!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (countLabel != null) ...[
                          Icon(
                            isManga
                                ? Icons.menu_book
                                : isGame
                                    ? Icons.sports_esports
                                    : Icons.tv,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(countLabel,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 10),
                        ],
                        if (score != null) ...[
                          Icon(Icons.star,
                              size: 13, color: Colors.amber.shade600),
                          const SizedBox(width: 3),
                          Text('$score%',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon:
                    Icon(Icons.add_circle_outline, color: colorScheme.primary),
                onPressed: () => onAdd(item, kind),
                tooltip: l10n.addToLibrary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
