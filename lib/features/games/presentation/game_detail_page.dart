import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbApiDatasource, IgdbWebUnsupportedException;
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

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
          return _GameDetailContent(game: game);
        },
      ),
    );
  }
}

class _GameDetailContent extends StatelessWidget {
  const _GameDetailContent({required this.game});

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
    final storyline = game['storyline'] as String?;
    final score = game['averageScore'] as int?;
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
                  _AddToLibraryButton(game: game),
                  const SizedBox(height: 12),

                  if (score != null)
                    GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatColumn(Icons.star, Colors.amber.shade600,
                              '$score%', l10n.gameDetailRating),
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

                  if (storyline != null) ...[
                    Text(l10n.gameDetailStoryline,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Text(storyline,
                          style: TextStyle(
                              fontSize: 13, color: cs.onSurfaceVariant)),
                    ),
                  ],

                  if (screenshots != null && screenshots.isNotEmpty) ...[
                    Text('Screenshots',
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
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: Icon(inLibrary ? Icons.edit : Icons.add),
            label: Text(inLibrary ? l10n.editLibraryEntry : l10n.addToLibrary),
            style: FilledButton.styleFrom(
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
          ),
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
  const _StatColumn(this.icon, this.iconColor, this.value, this.label);
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
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
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
