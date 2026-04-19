import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';

class MediaDetailPage extends ConsumerWidget {
  const MediaDetailPage({
    super.key,
    required this.mediaId,
    required this.kind,
  });

  final int mediaId;
  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(anilistMediaDetailProvider(mediaId));

    return Scaffold(
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (media) {
          if (media == null) {
            return Center(child: Text(l10n.mediaNoData));
          }
          return _DetailContent(media: media, kind: kind);
        },
      ),
    );
  }
}

class _DetailContent extends StatefulWidget {
  const _DetailContent({required this.media, required this.kind});

  final Map<String, dynamic> media;
  final MediaKind kind;

  @override
  State<_DetailContent> createState() => _DetailContentState();
}

class _DetailContentState extends State<_DetailContent> {
  /// Primera fila aprox.; si hay más chips, se ofrece «Mostrar más».
  static const int _kCollapsedChipCount = 6;

  bool _genresExpanded = false;
  bool _tagsExpanded = false;

  Map<String, dynamic> get media => widget.media;
  MediaKind get kind => widget.kind;

  List<Map<String, dynamic>> _sortedBrowseTags() {
    final raw = (media['tags'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final filtered = raw.where((t) {
      final r = t['rank'] as int?;
      return r != null && r >= 46;
    }).toList();
    filtered.sort((a, b) =>
        ((b['rank'] as int?) ?? 0).compareTo((a['rank'] as int?) ?? 0));
    return filtered.take(28).toList();
  }

  void _openBrowseByGenre(String genre) {
    final kindCode = widget.kind.code;
    context.push(
      '/browse/media?kind=$kindCode&genre=${Uri.encodeQueryComponent(genre)}&sort=popularity',
    );
  }

  void _openBrowseByTag(String tagName) {
    final kindCode = widget.kind.code;
    context.push(
      '/browse/media?kind=$kindCode&tag=${Uri.encodeQueryComponent(tagName)}&sort=popularity',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final coverImage = media['coverImage'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';
    final nativeTitle = title['native'] as String?;
    final romajiTitle = title['romaji'] as String?;
    final banner = media['bannerImage'] as String?;
    final poster = (coverImage['extraLarge'] as String?) ??
        (coverImage['large'] as String?);
    final description = media['description'] as String?;
    final score = media['averageScore'] as int?;
    final meanScore = media['meanScore'] as int?;
    final popularity = media['popularity'] as int?;
    final favourites = media['favourites'] as int?;
    final format = media['format'] as String?;
    final status = media['status'] as String?;
    final episodes = media['episodes'] as int?;
    final chapters = media['chapters'] as int?;
    final volumes = media['volumes'] as int?;
    final duration = media['duration'] as int?;
    final season = media['season'] as String?;
    final seasonYear = media['seasonYear'] as int?;
    final source = media['source'] as String?;
    final isAdult = media['isAdult'] as bool? ?? false;
    final genres = (media['genres'] as List?)?.cast<String>() ?? [];
    final browseTags = _sortedBrowseTags();
    final startDate = media['startDate'] as Map<String, dynamic>?;
    final endDate = media['endDate'] as Map<String, dynamic>?;

    final bool isManga = (media['type'] as String?) == 'MANGA';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    const bannerHeight = 170.0;
    const posterHeight = 130.0;
    const posterWidth = 90.0;
    const overlapAmount = 50.0;
    const headerOverflowAllowance = 10.0;
    final endDateLabel = _formatDate(endDate);
    final isReleasing = status == 'RELEASING';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: (banner != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness: (banner != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: bannerHeight + posterHeight - overlapAmount + headerOverflowAllowance,
                child: Stack(
                children: [
                  GestureDetector(
                    onTap: banner != null ? () => showFullscreenImage(context, banner) : null,
                    child: Container(
                      height: bannerHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        image: banner != null
                            ? DecorationImage(
                                image: CachedNetworkImageProvider(banner),
                                fit: BoxFit.cover,
                                colorFilter: ColorFilter.mode(
                                    Colors.black.withAlpha(60), BlendMode.darken),
                              )
                            : null,
                        color: banner == null ? colorScheme.surfaceContainerHighest : null,
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              style: IconButton.styleFrom(backgroundColor: Colors.black26),
                              onPressed: () => Navigator.of(context).maybePop(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 16,
                    right: 16,
                    top: bannerHeight - overlapAmount,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (poster != null)
                          GestureDetector(
                            onTap: () => showFullscreenImage(context, poster),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: colorScheme.surface, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(60),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: CachedNetworkImage(
                                  imageUrl: poster,
                                  width: posterWidth,
                                  height: posterHeight,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colorScheme.surface.withAlpha(210),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (romajiTitle != null && romajiTitle != name)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 2),
                                    child: Text(
                                      romajiTitle,
                                      style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (nativeTitle != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 1),
                                    child: Text(
                                      nativeTitle,
                                      style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (format != null) _Tag(_formatMediaStatus(format, false, l10n), colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer),
                    if (status != null) _Tag(_formatMediaStatus(status, true, l10n), colorScheme.secondaryContainer, colorScheme.onSecondaryContainer),
                    if (isAdult) _Tag('18+', colorScheme.errorContainer, colorScheme.onErrorContainer),
                  ],
                ),
              ),
            ],
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (media['id'] != null) _MediaFavoriteToggle(media: media),
                    if (media['id'] != null) const SizedBox(width: 8),
                    Expanded(
                      child: _AddToLibraryButton(media: media, kind: kind),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (score != null || meanScore != null)
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (score != null)
                          _StatColumn(Icons.star, Colors.amber.shade600, '$score%', l10n.statMeanScore),
                        if (meanScore != null && meanScore != score)
                          _StatColumn(Icons.bar_chart, colorScheme.primary, '$meanScore%', l10n.statMeanScore),
                        if (popularity != null)
                          _StatColumn(Icons.trending_up, Colors.teal, _formatNumber(popularity), l10n.statPopularity),
                        if (favourites != null)
                          _StatColumn(Icons.favorite, Colors.redAccent, _formatNumber(favourites), l10n.statFavourites),
                      ],
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  child: GlassCard(
                    padding: const EdgeInsets.all(14),
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.mediaInfo, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 24,
                          runSpacing: 6,
                          children: [
                            if (!isManga && episodes != null) _InfoPill(l10n.mediaEpisodes, '$episodes'),
                            if (isManga && chapters != null) _InfoPill(l10n.mediaChapters, '$chapters'),
                            if (isManga && volumes != null) _InfoPill(l10n.mediaVolumes, '$volumes'),
                            if (duration != null) _InfoPill(l10n.mediaDuration, '$duration min/ep'),
                            if (season != null && seasonYear != null) _InfoPill(l10n.mediaSeason, '$season $seasonYear'),
                            if (source != null) _InfoPill(l10n.mediaSource, source.replaceAll('_', ' ')),
                            if (startDate != null) _InfoPill(l10n.mediaStart, _formatDate(startDate)),
                            if (endDateLabel.isNotEmpty || isReleasing)
                              _InfoPill(l10n.mediaEnd, endDateLabel.isNotEmpty ? endDateLabel : 'Releasing'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                if (media['nextAiringEpisode'] != null)
                  _buildAiringCard(media['nextAiringEpisode'] as Map<String, dynamic>, colorScheme, l10n),

                if (genres.isNotEmpty) ...[
                  Text(
                    l10n.mediaGenresSection,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final g in (_genresExpanded ||
                              genres.length <= _kCollapsedChipCount)
                          ? genres
                          : genres.take(_kCollapsedChipCount))
                        ActionChip(
                          label: Text(g, style: const TextStyle(fontSize: 12)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          onPressed: () => _openBrowseByGenre(g),
                        ),
                    ],
                  ),
                  if (genres.length > _kCollapsedChipCount)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        onPressed: () => setState(
                          () => _genresExpanded = !_genresExpanded,
                        ),
                        child: Text(
                          _genresExpanded
                              ? l10n.mediaDetailChipsShowLess
                              : l10n.mediaDetailChipsShowMore,
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                ],

                if (browseTags.isNotEmpty) ...[
                  Text(
                    l10n.mediaTagsSection,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Builder(
                    builder: (context) {
                      final namedTags = browseTags
                          .where(
                            (t) =>
                                (t['name'] as String?)?.isNotEmpty ?? false,
                          )
                          .toList();
                      final visible =
                          (_tagsExpanded ||
                                  namedTags.length <= _kCollapsedChipCount)
                              ? namedTags
                              : namedTags
                                  .take(_kCollapsedChipCount)
                                  .toList();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final t in visible)
                                ActionChip(
                                  label: Text(
                                    t['name'] as String,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  onPressed: () =>
                                      _openBrowseByTag(t['name'] as String),
                                ),
                            ],
                          ),
                          if (namedTags.length > _kCollapsedChipCount)
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                onPressed: () => setState(
                                  () => _tagsExpanded = !_tagsExpanded,
                                ),
                                child: Text(
                                  _tagsExpanded
                                      ? l10n.mediaDetailChipsShowLess
                                      : l10n.mediaDetailChipsShowMore,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (description != null && description.isNotEmpty) ...[
                  Text(l10n.mediaSynopsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  AnilistMarkdown(
                    description,
                    style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildStudios(colorScheme, l10n),

                _buildStreamingLinks(colorScheme, l10n),

                _buildRelations(context, colorScheme),

                _buildRecommendations(context, colorScheme),

                _buildReviews(colorScheme, l10n),

                _buildForumThreads(context, colorScheme, l10n),

                _buildScoreDistribution(colorScheme, l10n),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    ),
    );
  }

  Widget _buildAiringCard(Map<String, dynamic> next, ColorScheme cs, AppLocalizations l10n) {
    final episode = next['episode'] as int?;
    final timeUntil = next['timeUntilAiring'] as int?;
    if (episode == null || timeUntil == null) return const SizedBox.shrink();

    final days = timeUntil ~/ 86400;
    final hours = (timeUntil % 86400) ~/ 3600;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(Icons.schedule, color: cs.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            l10n.mediaNextEp(episode, days, hours),
            style: TextStyle(fontWeight: FontWeight.w600, color: cs.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildStudios(ColorScheme cs, AppLocalizations l10n) {
    final studios = media['studios'] as Map<String, dynamic>?;
    final nodes = (studios?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(l10n.mediaStudio, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
          Text(
            nodes.map((s) => s['name']).join(', '),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamingLinks(ColorScheme cs, AppLocalizations l10n) {
    final isDark = cs.brightness == Brightness.dark;
    final links = (media['externalLinks'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final streaming = (media['streamingEpisodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    if (links.isEmpty && streaming.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mediaWhere, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: links.where((l) => l['url'] != null).map((link) {
            final color = link['color'] as String?;
            Color? siteColor;
            if (color != null && color.startsWith('#')) {
              siteColor = Color(int.parse('FF${color.substring(1)}', radix: 16));
            }

            Color labelColor;
            if (siteColor != null) {
              final luminance = siteColor.computeLuminance();
              if (isDark && luminance < 0.4) {
                // API a veces devuelve negro u oscuro (p. ej. Twitter) → ilegible en fondo oscuro.
                labelColor = cs.primary;
              } else if (!isDark && luminance > 0.6) {
                labelColor = HSLColor.fromColor(siteColor)
                    .withLightness(0.3)
                    .toColor();
              } else {
                labelColor = siteColor;
              }
            } else {
              labelColor = cs.primary;
            }

            return ActionChip(
              avatar: link['icon'] != null
                  ? ColorFiltered(
                      colorFilter: isDark
                          ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                          : ColorFilter.mode(
                              cs.onSurface.withAlpha(200), BlendMode.srcIn),
                      child: CachedNetworkImage(
                        imageUrl: link['icon'] as String,
                        width: 18,
                        height: 18,
                        errorWidget: (_, _, _) => Icon(Icons.link, size: 16, color: labelColor),
                      ),
                    )
                  : Icon(Icons.link, size: 16, color: labelColor),
              label: Text(
                link['site'] as String? ?? 'Link',
                style: TextStyle(fontSize: 12, color: labelColor),
              ),
              onPressed: () => launchUrl(Uri.parse(link['url'] as String)),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRelations(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final relations = media['relations'] as Map<String, dynamic>?;
    final edges = (relations?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (edges.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mediaRelated, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: edges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final edge = edges[i];
              final node = edge['node'] as Map<String, dynamic>;
              final relTitle = node['title'] as Map<String, dynamic>? ?? {};
              final relCover = node['coverImage'] as Map<String, dynamic>? ?? {};
              final relType = (edge['relationType'] as String?) ?? '';
              final relName = (relTitle['english'] as String?) ??
                  (relTitle['romaji'] as String?) ?? '';
              final relPoster = relCover['large'] as String?;
              final relId = node['id'] as int?;
              final nodeType = node['type'] as String?;

              return GestureDetector(
                onTap: () {
                  if (relId != null) {
                    final relKind = nodeType == 'MANGA' ? MediaKind.manga : MediaKind.anime;
                    context.push('/media/$relId?kind=${relKind.code}');
                  }
                },
                child: SizedBox(
                  width: 95,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: relPoster != null
                            ? CachedNetworkImage(
                                imageUrl: relPoster,
                                width: 85,
                                height: 115,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 85,
                                height: 115,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.image),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        relType.replaceAll('_', ' '),
                        style: TextStyle(fontSize: 9, color: cs.primary, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        relName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRecommendations(BuildContext context, ColorScheme cs) {
    final l10n = AppLocalizations.of(context)!;
    final recs = media['recommendations'] as Map<String, dynamic>?;
    final nodes = (recs?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final validRecs = nodes
        .where((n) => n['mediaRecommendation'] != null)
        .map((n) => n['mediaRecommendation'] as Map<String, dynamic>)
        .toList();
    if (validRecs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mediaRecommendations, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        SizedBox(
          height: 155,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: validRecs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final rec = validRecs[i];
              final recTitle = rec['title'] as Map<String, dynamic>? ?? {};
              final recCover = rec['coverImage'] as Map<String, dynamic>? ?? {};
              final recName = (recTitle['english'] as String?) ??
                  (recTitle['romaji'] as String?) ?? '';
              final recPoster = recCover['large'] as String?;
              final recId = rec['id'] as int?;
              final recType = rec['type'] as String?;

              return GestureDetector(
                onTap: () {
                  if (recId != null) {
                    final recKind = recType == 'MANGA' ? MediaKind.manga : MediaKind.anime;
                    context.push('/media/$recId?kind=${recKind.code}');
                  }
                },
                child: SizedBox(
                  width: 90,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: recPoster != null
                            ? CachedNetworkImage(
                                imageUrl: recPoster,
                                width: 85,
                                height: 115,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 85,
                                height: 115,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.image),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildReviews(ColorScheme cs, AppLocalizations l10n) {
    final reviews = media['reviews'] as Map<String, dynamic>?;
    final nodes = (reviews?['nodes'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (nodes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mediaReviews, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        ...nodes.map((review) {
          final user = review['user'] as Map<String, dynamic>? ?? {};
          final avatar = user['avatar'] as Map<String, dynamic>? ?? {};
          final reviewScore = review['score'] as int?;
          final reviewId = review['id'] as int?;

          return GestureDetector(
            onTap: reviewId != null
                ? () => context.push('/review/$reviewId', extra: review)
                : null,
            child: GlassCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: avatar['medium'] != null
                            ? CachedNetworkImageProvider(avatar['medium'] as String)
                            : null,
                        child: avatar['medium'] == null
                            ? const Icon(Icons.person, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          user['name'] as String? ?? l10n.mediaAnonymous,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      if (reviewScore != null) ...[
                        Icon(Icons.star, size: 14, color: Colors.amber.shade600),
                        const SizedBox(width: 2),
                        Text('$reviewScore/100', style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    review['summary'] as String? ?? '',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.4),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.thumb_up_alt_outlined, size: 13, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${review['rating'] ?? 0}/${review['ratingAmount'] ?? 0}',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                      const Spacer(),
                      Text(
                        l10n.readMore,
                        style: TextStyle(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                      Icon(Icons.arrow_forward_ios, size: 11, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildForumThreads(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final mediaId = media['id'] as int?;
    if (mediaId == null) return const SizedBox.shrink();
    return Consumer(
      builder: (context, ref, _) {
        final threadsAsync = ref.watch(anilistMediaThreadsProvider(mediaId));
        return threadsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (e, st) => const SizedBox.shrink(),
          data: (threads) {
            if (threads.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.forumDiscussions,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 8),
                ...threads.take(3).map((t) => _ForumThreadTile(thread: t, cs: cs)),
                if (threads.length >= 3)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text(l10n.forumViewAll,
                          style: const TextStyle(fontSize: 12)),
                      onPressed: () => context.push(
                        '/forum/media/$mediaId',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScoreDistribution(ColorScheme cs, AppLocalizations l10n) {
    final scoreDist = (media['stats']?['scoreDistribution'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (scoreDist.isEmpty) return const SizedBox.shrink();

    final maxAmount = scoreDist.fold<int>(0, (m, s) {
      final a = s['amount'] as int? ?? 0;
      return a > m ? a : m;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mediaScoreDistribution, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: scoreDist.map((s) {
              final scoreVal = s['score'] as int? ?? 0;
              final amount = s['amount'] as int? ?? 0;
              final fraction = maxAmount > 0 ? amount / maxAmount : 0.0;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$amount', style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Container(
                    width: 18,
                    height: 60 * fraction + 4,
                    decoration: BoxDecoration(
                      color: cs.primary.withAlpha((150 + 105 * fraction).round()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('$scoreVal', style: const TextStyle(fontSize: 10)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatDate(Map<String, dynamic>? date) {
    if (date == null) return '';
    final y = date['year'];
    final m = date['month'];
    final d = date['day'];
    if (y == null) return '';
    if (m == null) return '$y';
    if (d == null) return '$m/$y';
    return '$d/$m/$y';
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

}

String _formatMediaStatus(String raw, bool isStatus, AppLocalizations l10n) {
  if (!isStatus) {
    // format codes → pretty label
    return switch (raw) {
      'TV' => 'TV',
      'TV_SHORT' => 'TV Short',
      'MOVIE' => 'Movie',
      'SPECIAL' => 'Special',
      'OVA' => 'OVA',
      'ONA' => 'ONA',
      'MUSIC' => 'Music',
      'MANGA' => 'Manga',
      'NOVEL' => 'Novel',
      'ONE_SHOT' => 'One Shot',
      _ => raw,
    };
  }
  return switch (raw) {
    'FINISHED' => l10n.mediaStatusFinished,
    'RELEASING' => l10n.mediaStatusReleasing,
    'NOT_YET_RELEASED' => l10n.mediaStatusNotYetReleased,
    'CANCELLED' => l10n.mediaStatusCancelled,
    'HIATUS' => l10n.mediaStatusHiatus,
    _ => raw,
  };
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.icon, this.color, this.value, this.label);
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _MediaFavoriteToggle extends ConsumerStatefulWidget {
  const _MediaFavoriteToggle({required this.media});

  final Map<String, dynamic> media;

  @override
  ConsumerState<_MediaFavoriteToggle> createState() =>
      _MediaFavoriteToggleState();
}

class _MediaFavoriteToggleState extends ConsumerState<_MediaFavoriteToggle> {
  bool _busy = false;

  int get _mediaId => (widget.media['id'] as num).toInt();

  String get _mediaType =>
      ((widget.media['type'] as String?) ?? 'ANIME').toUpperCase();

  bool _apiFavourite() => widget.media['isFavourite'] as bool? ?? false;

  bool _localFavourite(List<Map<String, dynamic>> local) {
    return local.any((e) {
      final id = (e['id'] as num?)?.toInt() ?? 0;
      final t = (e['type'] as String? ?? 'ANIME').toUpperCase();
      return id == _mediaId && t == _mediaType;
    });
  }

  bool _combinedFavourite() {
    ref.watch(favoriteAnilistMediaProvider);
    final local = ref.read(favoriteAnilistMediaProvider);
    return _apiFavourite() || _localFavourite(local);
  }

  Future<void> _onPressed() async {
    final l10n = AppLocalizations.of(context)!;
    final token = ref.read(anilistTokenProvider).valueOrNull;
    final favNotifier = ref.read(favoriteAnilistMediaProvider.notifier);
    final local = ref.read(favoriteAnilistMediaProvider);
    final serverFav = _apiFavourite();
    final localHas = _localFavourite(local);
    final combined = serverFav || localHas;

    if (!combined) {
      if (token == null) {
        await favNotifier.toggleLocalFavorite(widget.media);
        return;
      }
      setState(() => _busy = true);
      try {
        final gql = ref.read(anilistGraphqlProvider);
        await gql.toggleFavouriteMedia(
          mediaId: _mediaId,
          mediaType: _mediaType,
          token: token,
        );
        await favNotifier.removeFavorite(_mediaId, _mediaType);
        ref.invalidate(anilistMediaDetailProvider(_mediaId));
        ref.invalidate(anilistProfileProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage('$e'))),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (serverFav && token != null) {
      setState(() => _busy = true);
      try {
        final gql = ref.read(anilistGraphqlProvider);
        await gql.toggleFavouriteMedia(
          mediaId: _mediaId,
          mediaType: _mediaType,
          token: token,
        );
        await favNotifier.removeFavorite(_mediaId, _mediaType);
        ref.invalidate(anilistMediaDetailProvider(_mediaId));
        ref.invalidate(anilistProfileProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage('$e'))),
          );
        }
      } finally {
        if (mounted) setState(() => _busy = false);
      }
      return;
    }

    if (localHas) {
      await favNotifier.toggleLocalFavorite(widget.media);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isFav = _combinedFavourite();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Tooltip(
        message:
            isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
        child: IconButton.filledTonal(
          onPressed: _busy ? null : _onPressed,
          icon: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isFav
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFav ? Colors.redAccent : null,
                ),
        ),
      ),
    );
  }
}

class _AddToLibraryButton extends ConsumerStatefulWidget {
  const _AddToLibraryButton({required this.media, required this.kind});
  final Map<String, dynamic> media;
  final MediaKind kind;

  @override
  ConsumerState<_AddToLibraryButton> createState() => _AddToLibraryButtonState();
}

class _AddToLibraryButtonState extends ConsumerState<_AddToLibraryButton> {
  LibraryEntry? _existing;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _checkExisting();
  }

  Future<void> _checkExisting() async {
    final db = ref.read(databaseProvider);
    final mediaId = widget.media['id'];
    if (mediaId == null) {
      setState(() => _loaded = true);
      return;
    }
    final entry = await db.getLibraryEntryByKindAndExternalId(
      widget.kind.code,
      mediaId.toString(),
    );
    if (mounted) setState(() { _existing = entry; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = _existing != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: _loaded
          ? FilledButton.icon(
              icon: Icon(isEdit ? Icons.edit : Icons.add),
              label: Text(isEdit ? l10n.editLibraryEntry : l10n.addToLibrary),
              onPressed: () async {
                final saved = await showAddToLibrarySheet(
                  context: context,
                  ref: ref,
                  item: widget.media,
                  kind: widget.kind,
                  existingEntry: _existing,
                );
                if (!context.mounted || !saved) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(isEdit ? l10n.entryUpdated : l10n.addedToLibrary)),
                );
                _checkExisting();
              },
            )
          : const SizedBox.shrink(),
    );
  }
}

class _ForumThreadTile extends StatelessWidget {
  const _ForumThreadTile({required this.thread, required this.cs});

  final Map<String, dynamic> thread;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final id = thread['id'] as int?;
    final title = thread['title'] as String? ?? '';
    final replyCount = thread['replyCount'] as int? ?? 0;
    final viewCount = thread['viewCount'] as int? ?? 0;
    final createdAt = thread['createdAt'] as int?;
    final user = thread['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;

    String timeAgo = '';
    if (createdAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) {
        timeAgo = '${diff.inDays ~/ 365}a';
      } else if (diff.inDays > 30) {
        timeAgo = '${diff.inDays ~/ 30}mo';
      } else if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h';
      } else {
        timeAgo = '${diff.inMinutes}min';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id == null
            ? null
            : () => context.push('/forum/thread/$id',
                extra: thread),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (avatar != null)
                  ClipOval(
                    child: Image.network(avatar,
                        width: 16, height: 16, fit: BoxFit.cover),
                  ),
                if (avatar != null) const SizedBox(width: 4),
                Text(userName,
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('· $timeAgo',
                      style: TextStyle(
                          fontSize: 11, color: cs.onSurfaceVariant)),
                ],
                const Spacer(),
                Icon(Icons.comment_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$replyCount',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Icon(Icons.visibility_outlined,
                    size: 13, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$viewCount',
                    style: TextStyle(
                        fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
