import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbApiDatasource, IgdbWebUnsupportedException;
import 'package:cronicle/features/games/data/datasources/opencritic_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/opencritic_providers.dart';
import 'package:cronicle/features/games/presentation/igdb_detail_helpers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

typedef _GameDetailLinkRow = ({
  String label,
  String url,
  bool igdbPage,
  int? websiteCategory,
  int? externalCategory,
});

Future<void> _launchGameLink(
  BuildContext context,
  AppLocalizations l10n,
  String? href,
) async {
  final resolved = IgdbApiDatasource.absoluteHttpUrl(href);
  if (resolved == null) return;
  final uri = Uri.tryParse(resolved);
  if (uri == null) return;
  try {
    final ok =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(resolved))),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage('$e'))),
      );
    }
  }
}

class GameDetailPage extends ConsumerWidget {
  const GameDetailPage({super.key, required this.gameId});

  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(igdbGameDetailProvider(gameId));

    return Scaffold(
      body: detailAsync.when(
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
        data: (game) {
          if (game == null) {
            return Center(child: Text(l10n.gameDetailNoData));
          }
          return _GameDetailContent(gameId: gameId, game: game);
        },
      ),
    );
  }
}

class _GameDetailContent extends StatelessWidget {
  const _GameDetailContent({required this.gameId, required this.game});

  final int gameId;
  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final title = game['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ?? '';
    final coverImage = game['coverImage'] as Map<String, dynamic>? ?? {};
    final poster = (coverImage['extraLarge'] as String?) ??
        (coverImage['large'] as String?);
    final summary = game['summary'] as String?;
    final score = game['averageScore'] as int?;
    final criticScore = game['aggregatedRating'] as int?;
    final criticReviewCount = game['aggregatedRatingCount'] as int?;
    final userRatingCount = game['totalRatingCount'] as int?;
    final format = game['format'] as String?;
    final genres = (game['genres'] as List?)?.cast<String>() ?? [];

    final screenshots = game['screenshots'] as List?;
    final artworks = game['artworks'] as List?;
    final bannerSource = artworks?.isNotEmpty == true
        ? artworks!.first
        : (screenshots?.isNotEmpty == true ? screenshots!.first : null);
    final bannerImageId =
        (bannerSource as Map<String, dynamic>?)?['image_id'] as String?;
    final banner = bannerImageId != null
        ? IgdbApiDatasource.screenshotUrl(bannerImageId)
        : null;

    final companies = game['involved_companies'] as List?;
    final developers = companies
        ?.where((c) => (c as Map<String, dynamic>)['developer'] == true)
        .map((c) =>
            ((c as Map<String, dynamic>)['company']
                as Map<String, dynamic>?)?['name'] as String? ??
            '')
        .where((n) => n.isNotEmpty)
        .toList();
    final publishers = companies
        ?.where((c) => (c as Map<String, dynamic>)['publisher'] == true)
        .map((c) =>
            ((c as Map<String, dynamic>)['company']
                as Map<String, dynamic>?)?['name'] as String? ??
            '')
        .where((n) => n.isNotEmpty)
        .toList();

    final gameModes = (game['game_modes'] as List?)
        ?.map((m) => (m as Map<String, dynamic>)['name'] as String? ?? '')
        .where((m) => m.isNotEmpty)
        .toList();
    final themes = (game['themes'] as List?)
        ?.map((t) => (t as Map<String, dynamic>)['name'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    final releaseDateEpoch = game['first_release_date'] as int?;
    final releaseDate = releaseDateEpoch != null
        ? DateTime.fromMillisecondsSinceEpoch(releaseDateEpoch * 1000)
        : null;

    final similarGames = game['similar_games'] as List?;
    final igdbPageUrl = game['igdb_page_url'] as String?;
    final websites = (game['websites'] as List?) ?? const [];
    final externalGames = (game['external_games'] as List?) ?? const [];
    final ttb = game['time_to_beat'] as Map<String, dynamic>?;
    final reviews = (game['igdb_reviews'] as List?) ?? const [];

    final linkRows = <_GameDetailLinkRow>[];
    final seenLinkUrls = <String>{};
    void addLinkRow(
      String label,
      String? href, {
      bool igdbPage = false,
      int? websiteCategory,
      int? externalCategory,
    }) {
      final u = IgdbApiDatasource.absoluteHttpUrl(href);
      if (u == null) return;
      final key = u.toLowerCase();
      if (seenLinkUrls.contains(key)) return;
      seenLinkUrls.add(key);
      linkRows.add((
        label: label,
        url: u,
        igdbPage: igdbPage,
        websiteCategory: websiteCategory,
        externalCategory: externalCategory,
      ));
    }

    addLinkRow(l10n.gameDetailOpenIgdb, igdbPageUrl, igdbPage: true);
    for (final w in websites) {
      final m = w as Map<String, dynamic>;
      final wc = m['category'] as int?;
      final href = IgdbApiDatasource.absoluteHttpUrl(m['url'] as String?);
      if (href == null) continue;
      addLinkRow(
        gameDetailWebsiteChipLabel(wc, href, l10n),
        href,
        websiteCategory: wc,
      );
    }
    for (final e in externalGames) {
      final m = e as Map<String, dynamic>;
      final href = externalStoreLaunchUrl(m);
      if (href == null) continue;
      addLinkRow(
        gameDetailExternalGameChipLabel(m, href, l10n),
        href,
        externalCategory: m['category'] as int?,
      );
    }
    final hasLinkSection = linkRows.isNotEmpty;

    final ttbHastily = readTimeToBeatSeconds(ttb, 'hastily', 'hastly');
    final ttbNormal = readTimeToBeatSeconds(ttb, 'normally', 'normal');
    final ttbComplete = readTimeToBeatSeconds(ttb, 'completely', 'complete');
    final hasTtb = ttbHastily != null ||
        ttbNormal != null ||
        ttbComplete != null;

    const bannerHeight = 200.0;
    const posterHeight = 140.0;
    const posterWidth = 95.0;
    const overlapAmount = 50.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness:
            (banner != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness:
            (banner != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                SizedBox(
                  height: bannerHeight + posterHeight - overlapAmount + 10,
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: banner != null
                            ? () => showFullscreenImage(context, banner)
                            : null,
                        child: Container(
                          height: bannerHeight,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            image: banner != null
                                ? DecorationImage(
                                    image:
                                        CachedNetworkImageProvider(banner),
                                    fit: BoxFit.cover,
                                    colorFilter: ColorFilter.mode(
                                        Colors.black.withAlpha(60),
                                        BlendMode.darken),
                                  )
                                : null,
                            color: banner == null
                                ? cs.surfaceContainerHighest
                                : null,
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back,
                                      color: Colors.white),
                                  style: IconButton.styleFrom(
                                      backgroundColor: Colors.black26),
                                  onPressed: () =>
                                      Navigator.of(context).maybePop(),
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
                                onTap: () =>
                                    showFullscreenImage(context, poster),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: cs.surface, width: 3),
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
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: cs.surface.withAlpha(210),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    name,
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (format != null)
                        _Tag(format, cs.tertiaryContainer,
                            cs.onTertiaryContainer),
                      ...genres.take(4).map((g) => _Tag(
                          g, cs.secondaryContainer, cs.onSecondaryContainer)),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _GameFavoriteButton(game: game),
                      const SizedBox(width: 8),
                      Expanded(child: _AddToLibraryButton(game: game)),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (hasLinkSection) ...[
                    Text(l10n.gameDetailLinksSection,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    _ExpandableGameLinkChips(
                      rows: linkRows,
                      l10n: l10n,
                      isDark: isDark,
                      colorScheme: cs,
                      onOpenUrl: (url) => _launchGameLink(context, l10n, url),
                    ),
                    const SizedBox(height: 12),
                  ],

                  if (hasTtb) ...[
                    Text(l10n.gameDetailTimeToBeatSection,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          if (ttbHastily != null)
                            _KeyValueRow(
                              l10n.gameDetailTtbHastily,
                              formatIgdbPlaytimeSeconds(ttbHastily, l10n),
                            ),
                          if (ttbNormal != null)
                            _KeyValueRow(
                              l10n.gameDetailTtbNormal,
                              formatIgdbPlaytimeSeconds(ttbNormal, l10n),
                            ),
                          if (ttbComplete != null)
                            _KeyValueRow(
                              l10n.gameDetailTtbComplete,
                              formatIgdbPlaytimeSeconds(ttbComplete, l10n),
                            ),
                        ],
                      ),
                    ),
                  ],

                  Text(l10n.gameDetailReviewsSection,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  if (reviews.isEmpty)
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        l10n.gameDetailNoReviews,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final raw in reviews)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: GlassCard(
                                padding: const EdgeInsets.all(14),
                                child: _IgdbReviewTile(
                                  review: raw as Map<String, dynamic>,
                                  l10n: l10n,
                                  cs: cs,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                  if (EnvConfig.openCriticRapidApiKey.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _OpenCriticSection(gameId: gameId),
                  ],

                  if (score != null ||
                      criticScore != null ||
                      releaseDate != null)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Wrap(
                        spacing: 20,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceAround,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (score != null)
                            _StatColumn(
                              Icons.star,
                              Colors.amber.shade600,
                              '$score%',
                              l10n.gameDetailStatUserScore,
                              footnote: userRatingCount != null &&
                                      userRatingCount > 0
                                  ? l10n.gameDetailStatRatingsCount(
                                      userRatingCount,
                                    )
                                  : null,
                            ),
                          if (criticScore != null)
                            _StatColumn(
                              Icons.newspaper_outlined,
                              Colors.deepOrange.shade400,
                              '$criticScore%',
                              l10n.gameDetailStatCriticScore,
                              footnote: criticReviewCount != null &&
                                      criticReviewCount > 0
                                  ? l10n.gameDetailStatCriticReviewsCount(
                                      criticReviewCount,
                                    )
                                  : null,
                            ),
                          if (releaseDate != null)
                            _StatColumn(
                              Icons.calendar_today,
                              Colors.teal,
                              '${releaseDate.year}',
                              l10n.gameDetailReleaseDate,
                            ),
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
                          Text(l10n.mediaInfo,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 24,
                            runSpacing: 6,
                            children: [
                              if (developers != null &&
                                  developers.isNotEmpty)
                                _InfoPill(l10n.gameDetailDeveloper,
                                    developers.join(', ')),
                              if (publishers != null &&
                                  publishers.isNotEmpty)
                                _InfoPill(l10n.gameDetailPublisher,
                                    publishers.join(', ')),
                              if (releaseDate != null)
                                _InfoPill(l10n.gameDetailReleaseDate,
                                    '${releaseDate.day}/${releaseDate.month}/${releaseDate.year}'),
                              if (gameModes != null &&
                                  gameModes.isNotEmpty)
                                _InfoPill(l10n.gameDetailModes,
                                    gameModes.join(', ')),
                              if (themes != null && themes.isNotEmpty)
                                _InfoPill(l10n.gameDetailThemes,
                                    themes.take(3).join(', ')),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (summary != null) ...[
                    Text(l10n.gameDetailSynopsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(summary,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                  ],

                  if (screenshots != null && screenshots.isNotEmpty) ...[
                    Text(l10n.gameDetailScreenshots,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 8),
                        itemCount: screenshots.length,
                        itemBuilder: (context, i) {
                          final imgId =
                              (screenshots[i] as Map<String, dynamic>)['image_id']
                                  as String?;
                          if (imgId == null) return const SizedBox.shrink();
                          final url = IgdbApiDatasource.screenshotUrl(imgId);
                          return GestureDetector(
                            onTap: () =>
                                showFullscreenImage(context, url),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: CachedNetworkImage(
                                imageUrl: url,
                                height: 120,
                                width: 213,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  if (similarGames != null &&
                      similarGames.isNotEmpty) ...[
                    Text(l10n.gameDetailSimilarGames,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 180,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        separatorBuilder: (_, _) =>
                            const SizedBox(width: 10),
                        itemCount: similarGames.length,
                        itemBuilder: (context, i) {
                          final sg =
                              similarGames[i] as Map<String, dynamic>;
                          final sgName = sg['name'] as String? ?? '';
                          final sgCover =
                              sg['cover'] as Map<String, dynamic>?;
                          final sgImgId =
                              sgCover?['image_id'] as String?;
                          final sgCoverUrl = sgImgId != null
                              ? IgdbApiDatasource.coverUrl(sgImgId)
                              : null;
                          final sgId = sg['id'] as int?;

                          return GestureDetector(
                            onTap: sgId != null
                                ? () => context.push('/game/$sgId')
                                : null,
                            child: SizedBox(
                              width: 100,
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    child: sgCoverUrl != null
                                        ? CachedNetworkImage(
                                            imageUrl: sgCoverUrl,
                                            width: 100,
                                            height: 140,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            width: 100,
                                            height: 140,
                                            color: cs
                                                .surfaceContainerHighest,
                                            child: const Icon(
                                                Icons.sports_esports),
                                          ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sgName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
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

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _igdbReviewExcerpt(String text) {
  final t = text.trim();
  if (t.length <= 320) return t;
  return '${t.substring(0, 320)}…';
}

class _OpenCriticSection extends ConsumerWidget {
  const _OpenCriticSection({required this.gameId});

  final int gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(openCriticGameInsightsProvider(gameId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.gameDetailOpenCriticSection,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: 6),
        async.when(
          loading: () => GlassCard(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '…',
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          error: (_, _) => GlassCard(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(bottom: 12),
            child: Text(
              l10n.gameDetailOpenCriticNoMatch,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          data: (insights) {
            if (insights == null) {
              return GlassCard(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.gameDetailOpenCriticNoMatch,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _OpenCriticInsightsBody(
                insights: insights,
                l10n: l10n,
                cs: cs,
                onOpenUrl: (u) => _launchGameLink(context, l10n, u),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _OpenCriticInsightsBody extends StatelessWidget {
  const _OpenCriticInsightsBody({
    required this.insights,
    required this.l10n,
    required this.cs,
    required this.onOpenUrl,
  });

  final OpenCriticGameInsights insights;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final scoreLabel =
        insights.topCriticScore != null ? '${insights.topCriticScore}' : '—';
    final meta = l10n.gameDetailOpenCriticMeta(
      scoreLabel,
      insights.numReviews,
    );
    final page = insights.pageUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(14),
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                meta,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              if (page != null && page.isNotEmpty) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => onOpenUrl(page),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: Text(l10n.gameDetailOpenCriticOpenSite),
                ),
              ],
            ],
          ),
        ),
        if (insights.reviews.isEmpty && insights.numReviews == 0)
          GlassCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              l10n.gameDetailOpenCriticNoMatch,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          )
        else if (insights.reviews.isNotEmpty) ...[
          for (final r in insights.reviews)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: _OpenCriticReviewTile(
                  review: r,
                  l10n: l10n,
                  cs: cs,
                  onOpenUrl: onOpenUrl,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _OpenCriticReviewTile extends StatelessWidget {
  const _OpenCriticReviewTile({
    required this.review,
    required this.l10n,
    required this.cs,
    required this.onOpenUrl,
  });

  final OpenCriticCriticReview review;
  final AppLocalizations l10n;
  final ColorScheme cs;
  final void Function(String url) onOpenUrl;

  @override
  Widget build(BuildContext context) {
    final excerpt = _igdbReviewExcerpt(stripSimpleHtml(review.snippet));
    final by = review.authorName;
    final sub = StringBuffer(review.outletName);
    if (review.score != null) {
      sub.write(' · ${review.score}');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          review.headline,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        const SizedBox(height: 2),
        Text(
          sub.toString(),
          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
        ),
        if (by != null && by.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            l10n.gameDetailReviewBy(by),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
        if (excerpt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            excerpt,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
        if (review.reviewUrl != null && review.reviewUrl!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onOpenUrl(review.reviewUrl!),
              icon: const Icon(Icons.article_outlined, size: 18),
              label: Text(l10n.gameDetailOpenCriticReadReview),
            ),
          ),
        ],
      ],
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _IgdbReviewTile extends StatelessWidget {
  const _IgdbReviewTile({
    required this.review,
    required this.l10n,
    required this.cs,
  });

  final Map<String, dynamic> review;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext _) {
    final titleRaw = review['title'] as String?;
    final title = (titleRaw != null && titleRaw.trim().isNotEmpty)
        ? titleRaw.trim()
        : l10n.gameDetailReviewUntitled;
    final user = review['user'] as Map<String, dynamic>?;
    final by = user?['username'] as String? ?? '';
    final rawContent = review['content'] as String? ?? '';
    final excerpt = _igdbReviewExcerpt(stripSimpleHtml(rawContent));

    final scoreVal = review['score'];
    int? score;
    if (scoreVal is int) {
      score = scoreVal;
    } else if (scoreVal is num) {
      score = scoreVal.toInt();
    }

    DateTime? reviewDate;
    final created = review['created_at'];
    if (created is int) {
      reviewDate = DateTime.fromMillisecondsSinceEpoch(created * 1000);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            if (score != null)
              Text(
                '$score',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: cs.primary,
                ),
              ),
          ],
        ),
        if (by.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            l10n.gameDetailReviewBy(by),
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
        if (reviewDate != null) ...[
          const SizedBox(height: 2),
          Text(
            '${reviewDate.day}/${reviewDate.month}/${reviewDate.year}',
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
        if (excerpt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            excerpt,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class _ExpandableGameLinkChips extends StatefulWidget {
  const _ExpandableGameLinkChips({
    required this.rows,
    required this.l10n,
    required this.isDark,
    required this.colorScheme,
    required this.onOpenUrl,
  });

  final List<_GameDetailLinkRow> rows;
  final AppLocalizations l10n;
  final bool isDark;
  final ColorScheme colorScheme;
  final void Function(String url) onOpenUrl;

  @override
  State<_ExpandableGameLinkChips> createState() =>
      _ExpandableGameLinkChipsState();
}

class _ExpandableGameLinkChipsState extends State<_ExpandableGameLinkChips> {
  static const int _maxCollapsed = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final rows = widget.rows;
    final cs = widget.colorScheme;
    final l10n = widget.l10n;
    final isDark = widget.isDark;

    final showAll = _expanded || rows.length <= _maxCollapsed;
    final visible =
        showAll ? rows : rows.take(_maxCollapsed).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: visible.map((row) => _buildChip(row, cs, l10n, isDark)).toList(),
        ),
        if (rows.length > _maxCollapsed) ...[
          const SizedBox(height: 6),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded
                  ? l10n.gameDetailLinksShowLess
                  : l10n.gameDetailLinksShowMore(rows.length - _maxCollapsed),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(
    _GameDetailLinkRow row,
    ColorScheme cs,
    AppLocalizations l10n,
    bool isDark,
  ) {
    final icon = gameDetailLinkIcon(
      url: row.url,
      isIgdbPage: row.igdbPage,
      websiteCategory: row.websiteCategory,
      externalCategory: row.externalCategory,
    );
    final accent = gameDetailLinkAccentColor(
      url: row.url,
      isIgdbPage: row.igdbPage,
      websiteCategory: row.websiteCategory,
      externalCategory: row.externalCategory,
    );
    var labelColor = cs.primary;
    if (accent != null) {
      final lum = accent.computeLuminance();
      if (!isDark && lum > 0.55) {
        labelColor =
            HSLColor.fromColor(accent).withLightness(0.32).toColor();
      } else {
        labelColor = accent;
      }
    }
    return Tooltip(
      message: '${row.label}\n${row.url}',
      child: ActionChip(
        avatar: Icon(icon, size: 16, color: labelColor),
        label: Text(
          gameDetailLinkChipTitle(row.label),
          style: TextStyle(fontSize: 12, color: labelColor),
        ),
        onPressed: () => widget.onOpenUrl(row.url),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class _GameFavoriteButton extends ConsumerWidget {
  const _GameFavoriteButton({required this.game});
  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final id = (game['id'] as num?)?.toInt() ?? 0;
    final list = ref.watch(favoriteGamesProvider);
    final isFav =
        id != 0 && list.any((e) => (e['id'] as num?)?.toInt() == id);

    return Tooltip(
      message: isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
      child: IconButton.filledTonal(
        style: IconButton.styleFrom(
          fixedSize: const Size(48, 48),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: id == 0
            ? null
            : () => ref
                .read(favoriteGamesProvider.notifier)
                .toggleFavorite(game),
        icon: Icon(
          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          color: isFav ? Colors.redAccent : null,
        ),
      ),
    );
  }
}

class _AddToLibraryButton extends ConsumerWidget {
  const _AddToLibraryButton({required this.game});
  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final db = ref.watch(databaseProvider);
    final gameId = game['id']?.toString() ?? '';

    return StreamBuilder<LibraryEntry?>(
      stream: db
          .watchLibraryByKind(MediaKind.game.code)
          .map((list) => list.cast<LibraryEntry?>().firstWhere(
                (e) => e?.externalId == gameId,
                orElse: () => null,
              )),
      builder: (context, snap) {
        final existing = snap.data;
        final inLibrary = existing != null;
        return FilledButton.icon(
          icon: Icon(inLibrary ? Icons.edit : Icons.add),
          label: Text(inLibrary ? l10n.editLibraryEntry : l10n.addToLibrary),
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            backgroundColor: inLibrary ? cs.secondaryContainer : null,
            foregroundColor: inLibrary ? cs.onSecondaryContainer : null,
          ),
          onPressed: () async {
            final added = await showAddToLibrarySheet(
              context: context,
              ref: ref,
              item: game,
              kind: MediaKind.game,
              existingEntry: existing,
            );
            if (context.mounted && added) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(inLibrary
                        ? l10n.entryUpdated
                        : l10n.addedToLibrary)),
              );
            }
          },
        );
      },
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.text, this.bg, this.fg);
  final String text;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(text,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(
    this.icon,
    this.iconColor,
    this.value,
    this.label, {
    this.footnote,
  });
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
        Text(label,
            style: TextStyle(
                fontSize: 10,
                color: cs.onSurfaceVariant)),
        if (footnote != null) ...[
          const SizedBox(height: 2),
          Text(
            footnote!,
            style: TextStyle(fontSize: 9, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
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
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant)),
        const SizedBox(height: 1),
        Text(value, style: const TextStyle(fontSize: 13)),
      ],
    );
  }
}
