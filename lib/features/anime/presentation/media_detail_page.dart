import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';

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
          child: _MediaHeroHeader(
            name: name,
            romajiTitle: romajiTitle,
            nativeTitle: nativeTitle,
            banner: banner,
            poster: poster,
            format: format,
            status: status,
            isAdult: isAdult,
            l10n: l10n,
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
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(22),
                    ),
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

                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mediaInfo,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.2,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 22,
                        runSpacing: 8,
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

                if (media['nextAiringEpisode'] != null)
                  _buildAiringCard(media['nextAiringEpisode'] as Map<String, dynamic>, colorScheme, l10n),

                if (genres.isNotEmpty) ...[
                  _SectionHeader(label: l10n.mediaGenresSection),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in (_genresExpanded ||
                              genres.length <= _kCollapsedChipCount)
                          ? genres
                          : genres.take(_kCollapsedChipCount))
                        _M3PillChip(
                          label: g,
                          bg: colorScheme.secondaryContainer,
                          fg: colorScheme.onSecondaryContainer,
                          onTap: () => _openBrowseByGenre(g),
                        ),
                      if (genres.length > _kCollapsedChipCount)
                        _M3PillChip(
                          label: _genresExpanded
                              ? l10n.mediaDetailChipsShowLess
                              : l10n.mediaDetailChipsShowMore,
                          bg: colorScheme.surfaceContainerHigh,
                          fg: colorScheme.onSurface,
                          icon: _genresExpanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          onTap: () => setState(
                            () => _genresExpanded = !_genresExpanded,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                if (browseTags.isNotEmpty) ...[
                  _SectionHeader(label: l10n.mediaTagsSection),
                  const SizedBox(height: 8),
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
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final t in visible)
                            _M3PillChip(
                              label: t['name'] as String,
                              bg: colorScheme.surfaceContainerHigh,
                              fg: colorScheme.onSurface,
                              onTap: () =>
                                  _openBrowseByTag(t['name'] as String),
                            ),
                          if (namedTags.length > _kCollapsedChipCount)
                            _M3PillChip(
                              label: _tagsExpanded
                                  ? l10n.mediaDetailChipsShowLess
                                  : l10n.mediaDetailChipsShowMore,
                              bg: colorScheme.tertiaryContainer,
                              fg: colorScheme.onTertiaryContainer,
                              icon: _tagsExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              onTap: () => setState(
                                () => _tagsExpanded = !_tagsExpanded,
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
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

                _buildCharacters(context, colorScheme, l10n),

                _buildStaff(context, colorScheme, l10n),

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

    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.primaryContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: cs.onPrimaryContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.mediaNextEp(episode, days, hours),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
                fontSize: 13,
                letterSpacing: 0.1,
              ),
            ),
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

  Widget _buildCharacters(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final container = media['characters'] as Map<String, dynamic>?;
    final edges = (container?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (edges.isEmpty) return const SizedBox.shrink();
    final mediaId = media['id'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.mediaCharacters,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            if (mediaId != null)
              TextButton(
                onPressed: () => context.push('/media/$mediaId/characters'),
                child: Text(l10n.mediaViewAll,
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 175,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: edges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final edge = edges[i];
              final node = edge['node'] as Map<String, dynamic>? ?? {};
              final cId = node['id'] as int?;
              final cName = (node['name'] as Map?)?['full'] as String? ?? '';
              final cImg = (node['image'] as Map?)?['large'] as String?;
              final role = edge['role'] as String?;
              final vas = (edge['voiceActors'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
              final firstVa = vas.isNotEmpty ? vas.first : null;

              return SizedBox(
                width: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: cId == null ? null : () => context.push('/character/$cId'),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: cImg != null
                            ? CachedNetworkImage(
                                imageUrl: cImg,
                                width: 90,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 90,
                                height: 110,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.person),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    if (role != null)
                      Text(
                        _formatCharacterRole(role, l10n),
                        style: TextStyle(fontSize: 9, color: cs.primary, fontWeight: FontWeight.w600),
                      ),
                    if (firstVa != null) ...[
                      const SizedBox(height: 2),
                      InkWell(
                        onTap: () {
                          final id = firstVa['id'] as int?;
                          if (id != null) context.push('/staff/$id');
                        },
                        child: Text(
                          (firstVa['name'] as Map?)?['full'] as String? ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildStaff(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final container = media['staff'] as Map<String, dynamic>?;
    final edges = (container?['edges'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
    if (edges.isEmpty) return const SizedBox.shrink();
    final mediaId = media['id'] as int?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(l10n.mediaStaff,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const Spacer(),
            if (mediaId != null)
              TextButton(
                onPressed: () => context.push('/media/$mediaId/staff'),
                child: Text(l10n.mediaViewAll,
                    style: const TextStyle(fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 165,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: edges.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final edge = edges[i];
              final node = edge['node'] as Map<String, dynamic>? ?? {};
              final sId = node['id'] as int?;
              final sName = (node['name'] as Map?)?['full'] as String? ?? '';
              final sImg = (node['image'] as Map?)?['large'] as String?;
              final role = edge['role'] as String?;

              return SizedBox(
                width: 100,
                child: GestureDetector(
                  onTap: sId == null ? null : () => context.push('/staff/$sId'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: sImg != null
                            ? CachedNetworkImage(
                                imageUrl: sImg,
                                width: 90,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 90,
                                height: 110,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.person),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (role != null)
                        Text(
                          role,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
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
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(20),
              ),
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
        Container(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(22),
          ),
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

String _formatCharacterRole(String role, AppLocalizations l10n) {
  return switch (role) {
    'MAIN' => l10n.characterRoleMain,
    'SUPPORTING' => l10n.characterRoleSupporting,
    'BACKGROUND' => l10n.characterRoleBackground,
    _ => role,
  };
}

String _formatMediaStatus(String raw, bool isStatus, AppLocalizations l10n) {
  if (!isStatus) {
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

    final cs = Theme.of(context).colorScheme;
    final bg = isFav
        ? cs.errorContainer.withAlpha(220)
        : cs.surfaceContainerHigh;
    final fg = isFav ? cs.onErrorContainer : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message:
            isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(isFav ? 18 : 14),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _busy ? null : _onPressed,
              child: SizedBox(
                width: 52,
                height: 52,
                child: Center(
                  child: _busy
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: fg,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          transitionBuilder: (c, a) =>
                              ScaleTransition(scale: a, child: c),
                          child: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(isFav),
                            color: fg,
                            size: 24,
                          ),
                        ),
                ),
              ),
            ),
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
    final cs = Theme.of(context).colorScheme;
    final isEdit = _existing != null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: _loaded
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: 52,
              decoration: BoxDecoration(
                color: isEdit
                    ? cs.tertiaryContainer
                    : cs.primary,
                borderRadius: BorderRadius.circular(isEdit ? 16 : 18),
                boxShadow: isEdit
                    ? null
                    : [
                        BoxShadow(
                          color: cs.primary.withAlpha(60),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(isEdit ? 16 : 18),
                  onTap: () async {
                    final saved = await showAddToLibrarySheet(
                      context: context,
                      ref: ref,
                      item: widget.media,
                      kind: widget.kind,
                      existingEntry: _existing,
                    );
                    if (!context.mounted || !saved) return;
                    if (!isEdit) {
                      final cover = widget.media['coverImage']
                              as Map<String, dynamic>? ??
                          const {};
                      final coverUrl = (cover['extraLarge'] as String?) ??
                          (cover['large'] as String?);
                      playLibraryInsertAnimation(
                        sourceContext: context,
                        imageUrl: coverUrl,
                      );
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit
                            ? l10n.entryUpdated
                            : l10n.addedToLibrary),
                      ),
                    );
                    _checkExisting();
                  },
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isEdit
                              ? Icons.edit_rounded
                              : Icons.add_rounded,
                          color: isEdit
                              ? cs.onTertiaryContainer
                              : cs.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isEdit
                              ? l10n.editLibraryEntry
                              : l10n.addToLibrary,
                          style: TextStyle(
                            color: isEdit
                                ? cs.onTertiaryContainer
                                : cs.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox(
              height: 52,
            ),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: id == null
            ? null
            : () => context.push('/forum/thread/$id',
                extra: thread),
        child: Padding(
          padding: const EdgeInsets.all(14),
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
      ),
    );
  }
}

/// Hero header for the media detail page.
///
/// Replaces the old positioned-stack layout. Shows banner with a soft scrim,
/// a poster overlapping into the surface area, and a column of titles +
/// inline tag chips so the right-hand side never has empty wasted space.
class _MediaHeroHeader extends StatelessWidget {
  const _MediaHeroHeader({
    required this.name,
    required this.romajiTitle,
    required this.nativeTitle,
    required this.banner,
    required this.poster,
    required this.format,
    required this.status,
    required this.isAdult,
    required this.l10n,
  });

  final String name;
  final String? romajiTitle;
  final String? nativeTitle;
  final String? banner;
  final String? poster;
  final String? format;
  final String? status;
  final bool isAdult;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bannerHeight = 180.0;
    const posterHeight = 150.0;
    const posterWidth = 100.0;
    const overlap = 60.0;
    // Total height: banner stops at bannerHeight; poster bottom sits at
    // bannerHeight - overlap + posterHeight. Add a small bottom buffer so
    // the chip wrap has breathing room before the action row.
    const totalHeight = bannerHeight - overlap + posterHeight + 8;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Banner.
          GestureDetector(
            onTap: banner != null
                ? () => showFullscreenImage(context, banner!)
                : null,
            child: Container(
              height: bannerHeight,
              width: double.infinity,
              decoration: BoxDecoration(
                image: banner != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(banner!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: banner == null ? cs.surfaceContainerHighest : null,
              ),
              foregroundDecoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withAlpha(30),
                    Colors.transparent,
                    Colors.black.withAlpha(120),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
          // Back button.
          Positioned(
            left: 4,
            top: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withAlpha(70),
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
          ),
          // Poster overlapping into surface.
          Positioned(
            left: 16,
            top: bannerHeight - overlap,
            child: poster != null
                ? GestureDetector(
                    onTap: () => showFullscreenImage(context, poster!),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: cs.surface, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(70),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: CachedNetworkImage(
                          imageUrl: poster!,
                          width: posterWidth,
                          height: posterHeight,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  )
                : Container(
                    width: posterWidth,
                    height: posterHeight,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: cs.surface, width: 3),
                    ),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
          // Title column to the right of poster, anchored to align roughly
          // with the bottom half of the poster so the banner top reads clean.
          Positioned(
            left: 16 + posterWidth + 14,
            right: 16,
            top: bannerHeight + 4,
            bottom: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _MarqueeText(
                  text: name,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.2,
                    color: cs.onSurface,
                  ),
                ),
                if (romajiTitle != null && romajiTitle != name) ...[
                  const SizedBox(height: 2),
                  Text(
                    romajiTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                if (nativeTitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    nativeTitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurfaceVariant.withAlpha(200),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    if (format != null)
                      _PillTag(
                        _formatMediaStatus(format!, false, l10n),
                        bg: cs.tertiaryContainer,
                        fg: cs.onTertiaryContainer,
                      ),
                    if (status != null)
                      _PillTag(
                        _formatMediaStatus(status!, true, l10n),
                        bg: cs.secondaryContainer,
                        fg: cs.onSecondaryContainer,
                      ),
                    if (isAdult)
                      _PillTag(
                        '18+',
                        bg: cs.errorContainer,
                        fg: cs.onErrorContainer,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// M3 expressive pill tag (rounded 999) used inside the hero header.
class _PillTag extends StatelessWidget {
  const _PillTag(this.text, {required this.bg, required this.fg});
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: fg,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Text that scrolls horizontally Hollywood-marquee-style when it overflows
/// its available width. When the text fits, it renders as a static [Text].
class _MarqueeText extends StatefulWidget {
  const _MarqueeText({
    required this.text,
    required this.style,
    // ignore: unused_element_parameter
    this.gap = 48,
    // ignore: unused_element_parameter
    this.pixelsPerSecond = 30,
    // ignore: unused_element_parameter
    this.startDelay = const Duration(seconds: 2),
  });

  final String text;
  final TextStyle style;
  final double gap;
  final double pixelsPerSecond;
  final Duration startDelay;

  @override
  State<_MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<_MarqueeText>
    with SingleTickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  Ticker? _ticker;
  Duration _last = Duration.zero;
  double _offset = 0;
  bool _started = false;
  bool _userInteracting = false;
  double _cycleWidth = 0;

  @override
  void dispose() {
    _ticker?.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _ensureTicker(double cycleWidth) {
    _cycleWidth = cycleWidth;
    _ticker ??= createTicker((elapsed) {
      if (_userInteracting) {
        // Sync offset with user-driven scroll so auto-scroll resumes from
        // wherever the user left it.
        if (_scroll.hasClients) {
          _offset = _scroll.offset % _cycleWidth;
          if (_offset < 0) _offset += _cycleWidth;
        }
        _last = elapsed;
        return;
      }
      if (!_started) {
        if (elapsed >= widget.startDelay) {
          _started = true;
          _last = elapsed;
        }
        return;
      }
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      _offset += widget.pixelsPerSecond * dt;
      if (_offset >= _cycleWidth) {
        _offset -= _cycleWidth;
      }
      if (_scroll.hasClients) {
        _scroll.jumpTo(_offset);
      }
    });
    if (!_ticker!.isActive) _ticker!.start();
  }

  double _measureText(double maxWidth) {
    final tp = TextPainter(
      text: TextSpan(text: widget.text, style: widget.style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);
    return tp.size.width;
  }

  bool _onScrollNotification(ScrollNotification n) {
    if (n is ScrollStartNotification &&
        n.dragDetails != null) {
      _userInteracting = true;
      _started = true; // skip initial delay after interaction
    } else if (n is ScrollEndNotification) {
      // Keep paused briefly after user releases so it doesn't snap back.
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        _userInteracting = false;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureText(maxWidth);
        // Tolerance: only marquee when clearly overflowing.
        if (textWidth <= maxWidth + 0.5) {
          // Stop ticker if a previous overflowing text shrank.
          _ticker?.stop();
          _started = false;
          _offset = 0;
          return Text(
            widget.text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: widget.style,
          );
        }

        final cycleWidth = textWidth + widget.gap;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _ensureTicker(cycleWidth);
        });

        return SizedBox(
          height: (widget.style.fontSize ?? 14) * (widget.style.height ?? 1.2),
          child: ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (rect) {
              return LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: const [0, 0.04, 0.96, 1],
                colors: const [
                  Colors.transparent,
                  Colors.black,
                  Colors.black,
                  Colors.transparent,
                ],
              ).createShader(rect);
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScrollNotification,
              child: ListView.builder(
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemBuilder: (_, _) {
                  return Padding(
                    padding: EdgeInsets.only(right: widget.gap),
                    child: Text(
                      widget.text,
                      maxLines: 1,
                      softWrap: false,
                      style: widget.style,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// M3 expressive section header (used for Genres / Tags / etc).
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13.5,
            letterSpacing: 0.2,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Tappable expressive M3 pill chip (used for genres, tags, "show more").
class _M3PillChip extends StatelessWidget {
  const _M3PillChip({
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.onTap,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: icon != null ? 12 : 14,
            vertical: 7,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: fg),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: fg,
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
