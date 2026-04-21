import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

String translateAnilistProfileStatus(String status, AppLocalizations l10n) =>
    switch (status) {
      'CURRENT' => l10n.statusCurrentAnime,
      'PLANNING' => l10n.statusPlanning,
      'COMPLETED' => l10n.statusCompleted,
      'DROPPED' => l10n.statusDropped,
      'PAUSED' => l10n.statusPaused,
      'REPEATING' => l10n.statusRepeating,
      _ => status,
    };

String libraryEntryStatusLabel(
  AppLocalizations l10n,
  String key,
  MediaKind kind,
) {
  return switch (key) {
    'CURRENT' => switch (kind) {
        MediaKind.manga => l10n.statusCurrentManga,
        MediaKind.game => l10n.statusCurrentGame,
        MediaKind.book => l10n.statusCurrentBook,
        _ => l10n.statusCurrentAnime,
      },
    'PLANNING' => l10n.statusPlanning,
    'COMPLETED' => l10n.statusCompleted,
    'DROPPED' => l10n.statusDropped,
    'PAUSED' => l10n.statusPaused,
    'REPEATING' => switch (kind) {
        MediaKind.game => l10n.statusReplayingGame,
        MediaKind.book => l10n.statusRereadingBook,
        _ => l10n.statusRepeating,
      },
    _ => key,
  };
}

int traktProfileStatInt(Map<String, dynamic> stats, String bucket, String field) {
  final b = stats[bucket];
  if (b is! Map) return 0;
  final v = b[field];
  if (v is num) return v.round();
  return int.tryParse('$v') ?? 0;
}

Map<String, dynamic> traktStatsSubMap(Map<String, dynamic> stats, String bucket) {
  final b = stats[bucket];
  if (b is! Map) return {};
  return Map<String, dynamic>.from(b);
}

int traktSubMapInt(Map<String, dynamic>? sub, String field) {
  if (sub == null) return 0;
  final v = sub[field];
  if (v is num) return v.round();
  return int.tryParse('$v') ?? 0;
}

String traktHoursFromMinutesLabel(int minutes) {
  if (minutes <= 0) return '0';
  final h = minutes / 60.0;
  return h >= 100 ? h.round().toString() : h.toStringAsFixed(1);
}

class ProfileStatsSectionHeader extends StatelessWidget {
  const ProfileStatsSectionHeader(this.title, this.icon, this.color, {super.key});
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class ProfileStatsBigStat extends StatelessWidget {
  const ProfileStatsBigStat(this.value, this.label, {super.key, this.loose = false});
  final String value;
  final String label;
  final bool loose;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gap = loose ? 8.0 : 4.0;
    final vSize = loose ? 22.0 : 18.0;
    final lSize = loose ? 11.5 : 10.0;
    return Padding(
      padding: loose ? const EdgeInsets.symmetric(horizontal: 6, vertical: 8) : EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: vSize, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          SizedBox(height: gap),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(
              fontSize: lSize,
              height: 1.25,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileTraktStatsPanel extends StatelessWidget {
  const ProfileTraktStatsPanel({
    super.key,
    required this.stats,
    required this.accent,
  });

  final Map<String, dynamic> stats;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final ratingsRoot = stats['ratings'];
    int ratingsTotal = 0;
    if (ratingsRoot is Map) {
      final t = ratingsRoot['total'];
      if (t is num) ratingsTotal = t.round();
    }

    final seasons = traktStatsSubMap(stats, 'seasons');
    final network = traktStatsSubMap(stats, 'network');

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TraktBucketBlock(
            title: l10n.profileTraktSubMovies,
            accent: accent,
            cs: cs,
            tiles: _tilesForMediaBucket(
              context,
              traktStatsSubMap(stats, 'movies'),
              l10n,
            ),
          ),
          SizedBox(height: 22, child: Center(child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)))),
          _TraktBucketBlock(
            title: l10n.profileTraktSubShows,
            accent: accent,
            cs: cs,
            tiles: _tilesForMediaBucket(
              context,
              traktStatsSubMap(stats, 'shows'),
              l10n,
            ),
          ),
          SizedBox(height: 22, child: Center(child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)))),
          _TraktBucketBlock(
            title: l10n.profileTraktSubEpisodes,
            accent: accent,
            cs: cs,
            tiles: _tilesForEpisodesBucket(
              context,
              traktStatsSubMap(stats, 'episodes'),
              l10n,
            ),
          ),
          if (_seasonsHasData(seasons)) ...[
            SizedBox(height: 22, child: Center(child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)))),
            _TraktBucketBlock(
              title: l10n.profileTraktSubSeasons,
              accent: accent,
              cs: cs,
              tiles: [
                _TraktMetricTile(
                  value: '${traktSubMapInt(seasons, 'ratings')}',
                  label: l10n.statTraktRatings,
                  cs: cs,
                ),
                _TraktMetricTile(
                  value: '${traktSubMapInt(seasons, 'comments')}',
                  label: l10n.statTraktComments,
                  cs: cs,
                ),
              ],
            ),
          ],
          if (_networkHasData(network)) ...[
            SizedBox(height: 22, child: Center(child: Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.35)))),
            _TraktBucketBlock(
              title: l10n.profileTraktSubNetwork,
              accent: accent,
              cs: cs,
              tiles: [
                _TraktMetricTile(
                  value: '${traktSubMapInt(network, 'friends')}',
                  label: l10n.statTraktFriends,
                  cs: cs,
                ),
                _TraktMetricTile(
                  value: '${traktSubMapInt(network, 'followers')}',
                  label: l10n.statTraktFollowers,
                  cs: cs,
                ),
                _TraktMetricTile(
                  value: '${traktSubMapInt(network, 'following')}',
                  label: l10n.statTraktFollowing,
                  cs: cs,
                ),
              ],
            ),
          ],
          if (ratingsTotal > 0) ...[
            const SizedBox(height: 14),
            Text(
              '${l10n.profileTraktRatingsTotal}: $ratingsTotal',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  bool _seasonsHasData(Map<String, dynamic> s) =>
      traktSubMapInt(s, 'ratings') > 0 || traktSubMapInt(s, 'comments') > 0;

  bool _networkHasData(Map<String, dynamic> n) =>
      traktSubMapInt(n, 'friends') > 0 ||
      traktSubMapInt(n, 'followers') > 0 ||
      traktSubMapInt(n, 'following') > 0;

  List<Widget> _tilesForMediaBucket(
    BuildContext context,
    Map<String, dynamic> b,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    final mins = traktSubMapInt(b, 'minutes');
    return [
      _TraktMetricTile(value: '${traktSubMapInt(b, 'plays')}', label: l10n.statTraktPlays, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'watched')}', label: l10n.statTraktWatched, cs: cs),
      _TraktMetricTile(
        value: traktHoursFromMinutesLabel(mins),
        label: l10n.statTraktWatchTimeHrs,
        cs: cs,
      ),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'collected')}', label: l10n.statTraktCollected, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'ratings')}', label: l10n.statTraktRatings, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'comments')}', label: l10n.statTraktComments, cs: cs),
    ];
  }

  List<Widget> _tilesForEpisodesBucket(
    BuildContext context,
    Map<String, dynamic> b,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    final mins = traktSubMapInt(b, 'minutes');
    return [
      _TraktMetricTile(value: '${traktSubMapInt(b, 'plays')}', label: l10n.statTraktPlays, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'watched')}', label: l10n.statTraktWatched, cs: cs),
      _TraktMetricTile(
        value: traktHoursFromMinutesLabel(mins),
        label: l10n.statTraktWatchTimeHrs,
        cs: cs,
      ),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'collected')}', label: l10n.statTraktCollected, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'ratings')}', label: l10n.statTraktRatings, cs: cs),
      _TraktMetricTile(value: '${traktSubMapInt(b, 'comments')}', label: l10n.statTraktComments, cs: cs),
    ];
  }
}

class _TraktBucketBlock extends StatelessWidget {
  const _TraktBucketBlock({
    required this.title,
    required this.accent,
    required this.cs,
    required this.tiles,
  });

  final String title;
  final Color accent;
  final ColorScheme cs;
  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final gap = 12.0;
            final w = (c.maxWidth - gap) / 2;
            return Wrap(
              spacing: gap,
              runSpacing: 14,
              children: tiles
                  .map((e) => SizedBox(width: w, child: e))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _TraktMetricTile extends StatelessWidget {
  const _TraktMetricTile({
    required this.value,
    required this.label,
    required this.cs,
  });

  final String value;
  final String label;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileStatsGenreBar extends StatelessWidget {
  const ProfileStatsGenreBar({
    super.key,
    required this.genre,
    required this.count,
    required this.maxCount,
    required this.color,
  });
  final String genre;
  final int count;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(genre, style: TextStyle(fontSize: 12, color: cs.onSurface)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color.withAlpha(180)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('$count',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class ProfileTraktFavCard extends StatelessWidget {
  const ProfileTraktFavCard({super.key, required this.media, required this.isShow});
  final Map<String, dynamic> media;
  final bool isShow;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';
    final cover = (media['coverImage'] as Map?)?['large'] as String?;
    final id = (media['id'] as num?)?.toInt();

    return GestureDetector(
      onTap: id != null
          ? () => isShow
              ? context.push('/trakt-show/$id')
              : context.push('/trakt-movie/$id')
          : null,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 130,
                      color: cs.surfaceContainerHighest,
                      child: Icon(isShow ? Icons.tv_rounded : Icons.movie_rounded),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
