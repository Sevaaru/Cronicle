import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/remote_network_image.dart';

/// Home feed de pelÃ­culas o series usando datos de Trakt.tv.
class TraktHomeFeedView extends ConsumerWidget {
  const TraktHomeFeedView({super.key, required this.kind});

  final MediaKind kind;

  bool get _isMovie => kind == MediaKind.movie;

  Future<void> _onRefresh(WidgetRef ref) async {
    if (_isMovie) {
      ref.invalidate(traktMoviesHomeProvider);
      await ref.read(traktMoviesHomeProvider.future);
    } else {
      ref.invalidate(traktShowsHomeProvider);
      await ref.read(traktShowsHomeProvider.future);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (EnvConfig.traktClientId.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.traktNotConfiguredHint,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    if (_isMovie) {
      final async = ref.watch(traktMoviesHomeProvider);
      return RefreshIndicator(
        onRefresh: () => _onRefresh(ref),
        child: async.when(
          loading: () => _MovieSkeletons(l10n: l10n),
          error: (e, _) => _errorBox(
            context,
            e,
            l10n,
            () => ref.invalidate(traktMoviesHomeProvider),
          ),
          data: (d) => ScrollConfiguration(
            behavior: const _NoStretchScrollBehavior(),
            child: _MoviesFeed(data: d, l10n: l10n),
          ),
        ),
      );
    }

    final async = ref.watch(traktShowsHomeProvider);
    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: async.when(
        loading: () => _ShowSkeletons(l10n: l10n),
        error: (e, _) => _errorBox(
          context,
          e,
          l10n,
          () => ref.invalidate(traktShowsHomeProvider),
        ),
        data: (d) => ScrollConfiguration(
          behavior: const _NoStretchScrollBehavior(),
          child: _ShowsFeed(data: d, l10n: l10n),
        ),
      ),
    );
  }

  static Widget _errorBox(
    BuildContext context,
    Object e,
    AppLocalizations l10n,
    VoidCallback onRetry,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: cs.error),
            const SizedBox(height: 12),
            Text(
              e.toString(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: onRetry,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Movies feed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MoviesFeed extends StatelessWidget {
  const _MoviesFeed({required this.data, required this.l10n});

  final TraktMoviesHomeData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (data.trending.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.traktSectionTrending,
            slug: 'trending',
            items: data.trending,
            kind: MediaKind.movie,
            cardWidth: 126,
            cardHeight: 172,
            icon: Icons.local_fire_department_rounded,
            accent: cs.primary,
          ),
        if (data.played.isNotEmpty)
          _HeroSection(
            title: l10n.traktSectionMostPlayed,
            slug: 'played',
            items: data.played,
            kind: MediaKind.movie,
            accent: Colors.amber.shade600,
            icon: Icons.emoji_events_rounded,
          ),
        if (data.anticipated.isNotEmpty)
          _RankedListSection(
            title: l10n.traktSectionAnticipatedMovies,
            slug: 'anticipated',
            items: data.anticipated,
            kind: MediaKind.movie,
            icon: Icons.rocket_launch_rounded,
            accent: cs.tertiary,
          ),
        if (data.watched.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.traktSectionMostWatched,
            slug: 'watched',
            items: data.watched,
            kind: MediaKind.movie,
            cardWidth: 108,
            cardHeight: 148,
            icon: Icons.visibility_rounded,
            accent: const Color(0xFF2563EB),
          ),
        if (data.collected.isNotEmpty)
          _SpotlightRowsSection(
            title: l10n.traktSectionMostCollected,
            slug: 'collected',
            items: data.collected,
            kind: MediaKind.movie,
            accent: const Color(0xFF7C3AED),
            icon: Icons.bookmark_rounded,
          ),
        if (data.popular.isNotEmpty)
          _MoodBandSection(
            title: l10n.traktSectionPopular,
            slug: 'popular',
            items: data.popular,
            kind: MediaKind.movie,
            accent: const Color(0xFFF59E0B),
            darkBg: const Color(0xFF1A1208),
            icon: Icons.star_rounded,
          ),
      ],
    );
  }
}

// â”€â”€â”€ Shows feed â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ShowsFeed extends StatelessWidget {
  const _ShowsFeed({required this.data, required this.l10n});

  final TraktShowsHomeData data;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.only(bottom: 40),
      children: [
        if (data.trending.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.traktSectionTrending,
            slug: 'trending',
            items: data.trending,
            kind: MediaKind.tv,
            cardWidth: 126,
            cardHeight: 172,
            icon: Icons.local_fire_department_rounded,
            accent: cs.primary,
          ),
        if (data.watching.isNotEmpty)
          _SpotlightRowsSection(
            title: l10n.traktSectionWatchingNow,
            slug: 'watching',
            items: data.watching,
            kind: MediaKind.tv,
            accent: const Color(0xFF16A34A),
            icon: Icons.play_circle_rounded,
          ),
        if (data.anticipated.isNotEmpty)
          _RankedListSection(
            title: l10n.traktSectionAnticipatedShows,
            slug: 'anticipated',
            items: data.anticipated,
            kind: MediaKind.tv,
            icon: Icons.rocket_launch_rounded,
            accent: cs.tertiary,
          ),
        if (data.watched.isNotEmpty)
          _ScoreCarouselSection(
            title: l10n.traktSectionMostWatched,
            slug: 'watched',
            items: data.watched,
            kind: MediaKind.tv,
            cardWidth: 108,
            cardHeight: 148,
            icon: Icons.visibility_rounded,
            accent: const Color(0xFF0891B2),
          ),
        if (data.collected.isNotEmpty)
          _MoodBandSection(
            title: l10n.traktSectionMostCollected,
            slug: 'collected',
            items: data.collected,
            kind: MediaKind.tv,
            accent: const Color(0xFF14B8A6),
            darkBg: const Color(0xFF041412),
            icon: Icons.bookmark_rounded,
          ),
        if (data.popular.isNotEmpty)
          _HeroSection(
            title: l10n.traktSectionPopular,
            slug: 'popular',
            items: data.popular,
            kind: MediaKind.tv,
            accent: Colors.amber.shade600,
            icon: Icons.star_rounded,
          ),
      ],
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// HELPERS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

String? _coverUrl(Map<String, dynamic> item) =>
    (item['coverImage'] as Map?)?['large'] as String?;

String _itemTitle(Map<String, dynamic> item) =>
    ((item['title'] as Map?)?['english'] as String?) ?? '';

int? _itemScore(Map<String, dynamic> item) => item['averageScore'] as int?;

Color _scoreColor(int s) {
  if (s >= 80) return const Color(0xFF22C55E);
  if (s >= 60) return const Color(0xFFF59E0B);
  return const Color(0xFF94A3B8);
}

String _route(MediaKind kind, int id) =>
    kind == MediaKind.movie ? '/trakt-movie/$id' : '/trakt-show/$id';

String _formatVotes(int v) {
  if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
  return '$v';
}

// â”€â”€â”€ Section header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.slug,
    this.kind,
    this.accent,
    this.icon,
    this.onDark = false,
  });

  final String title;
  final String? slug;
  final MediaKind? kind;
  final Color? accent;
  final IconData? icon;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = accent ?? cs.primary;
    final textColor = onDark ? Colors.white : cs.onSurface;
    final chevronColor = onDark ? Colors.white60 : cs.onSurfaceVariant;

    final canNavigate = slug != null && kind != null;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: canNavigate
          ? () {
              final kindStr = kind == MediaKind.movie ? 'movie' : 'show';
              context.push('/trakt-section/$kindStr/$slug');
            }
          : null,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: textColor,
              ),
            ),
          ),
          if (canNavigate)
            Icon(Icons.chevron_right_rounded, size: 20, color: chevronColor),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Skeleton helper â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

Widget _skel(BuildContext ctx,
    {required double w, required double h, double r = 8, Color? color}) {
  final cs = Theme.of(ctx).colorScheme;
  return Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: color ?? cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(r),
    ),
  );
}

// â”€â”€â”€ Poster placeholder â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _PosterPlaceholder extends StatelessWidget {
  const _PosterPlaceholder({
    required this.width,
    required this.height,
    this.radius = 8,
    this.isShow = false,
  });

  final double width;
  final double height;
  final double radius;
  final bool isShow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        isShow ? Icons.tv_rounded : Icons.movie_rounded,
        size: width * 0.35,
        color: cs.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
  }
}

// â”€â”€â”€ Score badge â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, this.small = false});

  final int score;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 5 : 6,
        vertical: small ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: _scoreColor(score),
        borderRadius: BorderRadius.circular(small ? 5 : 6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$score',
        style: TextStyle(
          color: Colors.white,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SECTION WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

// â”€â”€â”€ 1. Score Carousel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ScoreCarouselSection extends StatelessWidget {
  const _ScoreCarouselSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.kind,
    required this.cardWidth,
    required this.cardHeight,
    this.icon,
    this.accent,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final double cardWidth;
  final double cardHeight;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(10).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SectionHeader(title: title, slug: slug, kind: kind, icon: icon, accent: accent),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: slice.length,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) => _ScoreCarouselCard(
                item: slice[i],
                kind: kind,
                width: cardWidth,
                height: cardHeight,
                accent: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreCarouselCard extends StatelessWidget {
  const _ScoreCarouselCard({
    required this.item,
    required this.kind,
    required this.width,
    required this.height,
    this.accent,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final double width;
  final double height;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;

    return GestureDetector(
      onTap: id != null ? () => context.push(_route(kind, id)) : null,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: url != null
                      ? RemoteNetworkImage(
                          imageUrl: url,
                          width: width,
                          height: height,
                          fit: BoxFit.cover,
                        )
                      : _PosterPlaceholder(
                          width: width,
                          height: height,
                          radius: 10,
                          isShow: kind == MediaKind.tv,
                        ),
                ),
                if (score != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _ScoreBadge(score: score),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.25,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 2. Ranked List â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _RankedListSection extends StatelessWidget {
  const _RankedListSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.kind,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(6).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, kind: kind, icon: icon, accent: accent),
          const SizedBox(height: 10),
          ...List.generate(
            slice.length,
            (i) => _RankedRow(item: slice[i], rank: i + 1, kind: kind),
          ),
        ],
      ),
    );
  }
}

class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.item,
    required this.rank,
    required this.kind,
  });

  final Map<String, dynamic> item;
  final int rank;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final id = item['id'] as int?;
    final year = item['year'] as int?;
    final cert = item['certification'] as String?;
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres = genresList != null && genresList.isNotEmpty
        ? genresList.take(2).join(' Â· ')
        : null;
    final votes = item['votes'] as int?;
    final network = item['network'] as String?;

    final subtitle = genres ??
        [?network, if (year != null) '$year']
            .join(' Â· ')
            .nullIfEmpty;

    final badge = cert ?? (year != null ? '$year' : null);

    return GestureDetector(
      onTap: id != null ? () => context.push(_route(kind, id)) : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              child: Text(
                '$rank',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: rank <= 3
                      ? cs.primary
                      : cs.onSurfaceVariant.withValues(alpha: 0.45),
                  letterSpacing: -1,
                ),
              ),
            ),
            const SizedBox(width: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? RemoteNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(
                      width: 48,
                      height: 64,
                      radius: 7,
                      isShow: kind == MediaKind.tv,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (votes != null && votes > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.thumb_up_rounded,
                            size: 11, color: Colors.orange.shade400),
                        const SizedBox(width: 3),
                        Text(
                          _formatVotes(votes),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ] else if (badge != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      badge,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 3. Hero Section â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.kind,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hero = items.first;
    final rest = items.skip(1).take(5).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, kind: kind, icon: icon, accent: accent),
          const SizedBox(height: 12),
          _HeroCard(item: hero, kind: kind, accent: accent),
          if (rest.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: rest.length,
                padding: EdgeInsets.zero,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = rest[i];
                  final id = it['id'] as int?;
                  final url = _coverUrl(it);
                  final score = _itemScore(it);
                  return GestureDetector(
                    onTap: id != null
                        ? () => ctx.push(_route(kind, id))
                        : null,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: url != null
                              ? RemoteNetworkImage(
                                  imageUrl: url,
                                  width: 70,
                                  height: 96,
                                  fit: BoxFit.cover,
                                )
                              : _PosterPlaceholder(
                                  width: 70,
                                  height: 96,
                                  radius: 8,
                                  isShow: kind == MediaKind.tv,
                                ),
                        ),
                        if (score != null)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: _ScoreBadge(score: score, small: true),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.item,
    required this.kind,
    required this.accent,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres = genresList != null && genresList.isNotEmpty
        ? genresList.take(2).join(' Â· ')
        : '';
    final year = item['year'] as int?;
    final cert = item['certification'] as String?;
    final meta = [if (year != null) '$year', ?cert].join('  ');

    return GestureDetector(
      onTap: id != null ? () => context.push(_route(kind, id)) : null,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: url != null
                  ? RemoteNetworkImage(
                      imageUrl: url,
                      width: 88,
                      height: 120,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(
                      width: 88,
                      height: 120,
                      radius: 0,
                      isShow: kind == MediaKind.tv,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (score != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Icon(Icons.star_rounded, size: 15, color: accent),
                          const SizedBox(width: 4),
                          Text(
                            '$score',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: accent,
                              height: 1,
                            ),
                          ),
                          Text(
                            '/100',
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 5),
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (genres.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        genres,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (meta.isNotEmpty)
                      Text(
                        meta,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 4. Mood Band â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _MoodBandSection extends StatelessWidget {
  const _MoodBandSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.kind,
    required this.accent,
    required this.darkBg,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final Color accent;
  final Color darkBg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(8).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: _SectionHeader(
                title: title,
                slug: slug,
                kind: kind,
                icon: icon,
                accent: accent,
                onDark: true,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: slice.length,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, i) {
                  final it = slice[i];
                  final url = _coverUrl(it);
                  final id = it['id'] as int?;
                  return GestureDetector(
                    onTap:
                        id != null ? () => ctx.push(_route(kind, id)) : null,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url != null
                          ? RemoteNetworkImage(
                              imageUrl: url,
                              width: 108,
                              height: 148,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 108,
                              height: 148,
                              color: accent.withValues(alpha: 0.15),
                              child: Icon(
                                kind == MediaKind.tv
                                    ? Icons.tv_rounded
                                    : Icons.movie_rounded,
                                color: Colors.white24,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ 5. Spotlight Rows â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _SpotlightRowsSection extends StatelessWidget {
  const _SpotlightRowsSection({
    required this.title,
    required this.slug,
    required this.items,
    required this.kind,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String slug;
  final List<Map<String, dynamic>> items;
  final MediaKind kind;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final slice = items.take(5).toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(title: title, slug: slug, kind: kind, icon: icon, accent: accent),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: accent.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(slice.length, (i) {
                final isLast = i == slice.length - 1;
                return Column(
                  children: [
                    _SpotlightRow(item: slice[i], kind: kind, accent: accent),
                    if (!isLast)
                      Divider(
                        height: 1,
                        color: accent.withValues(alpha: 0.15),
                        indent: 72,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightRow extends StatelessWidget {
  const _SpotlightRow({
    required this.item,
    required this.kind,
    required this.accent,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final url = _coverUrl(item);
    final name = _itemTitle(item);
    final score = _itemScore(item);
    final id = item['id'] as int?;
    final genresList = (item['genres'] as List?)?.cast<String>();
    final genres = genresList != null && genresList.isNotEmpty
        ? genresList.take(2).join(' Â· ')
        : null;
    final year = item['year'] as int?;
    final network = item['network'] as String?;
    final subtitle = genres ??
        [?network, if (year != null) '$year']
            .join(' Â· ')
            .nullIfEmpty;

    return GestureDetector(
      onTap: id != null ? () => context.push(_route(kind, id)) : null,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: url != null
                  ? RemoteNetworkImage(
                      imageUrl: url,
                      width: 48,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : _PosterPlaceholder(
                      width: 48,
                      height: 64,
                      radius: 7,
                      isShow: kind == MediaKind.tv,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (score != null) ...[
              const SizedBox(width: 8),
              _ScoreBadge(score: score),
            ],
          ],
        ),
      ),
    );
  }
}

// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
// SKELETON WIDGETS
// â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

class _MovieSkeletons extends StatelessWidget {
  const _MovieSkeletons({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _ScoreCarouselSkeleton(cardWidth: 126, cardHeight: 172),
          _HeroSkeleton(),
          _RankedListSkeleton(),
          _ScoreCarouselSkeleton(cardWidth: 108, cardHeight: 148),
          _SpotlightRowsSkeleton(),
          _MoodBandSkeleton(
            accent: Color(0xFFF59E0B),
            darkBg: Color(0xFF1A1208),
          ),
        ],
      ),
    );
  }
}

class _ShowSkeletons extends StatelessWidget {
  const _ShowSkeletons({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          _ScoreCarouselSkeleton(cardWidth: 126, cardHeight: 172),
          _SpotlightRowsSkeleton(),
          _RankedListSkeleton(),
          _ScoreCarouselSkeleton(cardWidth: 108, cardHeight: 148),
          _MoodBandSkeleton(
            accent: Color(0xFF14B8A6),
            darkBg: Color(0xFF041412),
          ),
          _HeroSkeleton(),
        ],
      ),
    );
  }
}

class _ScoreCarouselSkeleton extends StatelessWidget {
  const _ScoreCarouselSkeleton({
    required this.cardWidth,
    required this.cardHeight,
  });

  final double cardWidth;
  final double cardHeight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                _skel(context, w: 18, h: 18, r: 4),
                const SizedBox(width: 8),
                _skel(context, w: 140, h: 16, r: 6),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: cardHeight + 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (ctx, _) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _skel(ctx, w: cardWidth, h: cardHeight, r: 10),
                  const SizedBox(height: 5),
                  _skel(ctx, w: cardWidth * 0.75, h: 10, r: 4),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankedListSkeleton extends StatelessWidget {
  const _RankedListSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 140, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 10),
          ...List.generate(
            5,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _skel(context, w: 30, h: 24, r: 4),
                  const SizedBox(width: 10),
                  _skel(context, w: 48, h: 64, r: 7),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _skel(context, w: double.infinity, h: 13, r: 4),
                        const SizedBox(height: 5),
                        _skel(context, w: 90, h: 11, r: 4),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 130, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 12),
          _skel(context, w: double.infinity, h: 120, r: 14),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              padding: EdgeInsets.zero,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (ctx, _) => _skel(ctx, w: 70, h: 96, r: 8),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBandSkeleton extends StatelessWidget {
  const _MoodBandSkeleton({required this.accent, required this.darkBg});

  final Color accent;
  final Color darkBg;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: darkBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
              child: Row(
                children: [
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 120,
                    height: 16,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 4,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (ctx, _) => Container(
                  width: 108,
                  height: 148,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
        ),
      ),
    );
  }
}

class _SpotlightRowsSkeleton extends StatelessWidget {
  const _SpotlightRowsSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _skel(context, w: 18, h: 18, r: 4),
              const SizedBox(width: 8),
              _skel(context, w: 140, h: 16, r: 6),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: cs.surfaceContainerHighest),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: List.generate(4, (i) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          _skel(context, w: 48, h: 64, r: 7),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _skel(context,
                                    w: double.infinity, h: 13, r: 4),
                                const SizedBox(height: 5),
                                _skel(context, w: 90, h: 11, r: 4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (i < 3)
                      Divider(
                        height: 1,
                        color: cs.surfaceContainerHighest,
                      ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// â”€â”€â”€ Scroll behavior (suppress stretch on web) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _NoStretchScrollBehavior extends MaterialScrollBehavior {
  const _NoStretchScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

// â”€â”€â”€ String extension â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

extension _StringNullIfEmpty on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
