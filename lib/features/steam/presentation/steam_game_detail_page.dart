import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/steam/data/datasources/steam_api_datasource.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/m3_detail.dart';

/// Detail page for one Steam app: header, playtime, achievements list, and
/// an "Add to my library" action that resolves the matching IGDB game.
class SteamGameDetailPage extends ConsumerWidget {
  const SteamGameDetailPage({super.key, required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gamesAsync = ref.watch(steamOwnedGamesProvider);
    final achievementsAsync =
        ref.watch(steamGameAchievementsProvider(appId));

    final game = gamesAsync.maybeWhen(
      data: (list) => list.firstWhere(
        (g) => ((g['appid'] as num?)?.toInt() ?? 0) == appId,
        orElse: () => <String, dynamic>{},
      ),
      orElse: () => <String, dynamic>{},
    );

    final name = (game['name'] as String?) ?? 'App $appId';
    final playtimeMin = (game['playtime_forever'] as num?)?.toInt() ?? 0;
    final hours = playtimeMin / 60.0;
    final lastPlayedTs =
        (game['rtime_last_played'] as num?)?.toInt() ?? 0;
    final lastPlayed = lastPlayedTs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastPlayedTs * 1000)
        : null;

    return Scaffold(
        appBar: AppBar(title: Text(name)),
        body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, kGlassBottomNavContentHeight + 24),
        children: [
          AspectRatio(
            aspectRatio: 460 / 215,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                SteamApiDatasource.headerUrl(appId),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SteamMediaCarousel(appId: appId),
          const SizedBox(height: 16),
          _StatTile(
            icon: Icons.timelapse_rounded,
            label: l10n.steamPlaytime,
            value: l10n.steamHoursPlayed(hours.toStringAsFixed(1)),
          ),
          if (lastPlayed != null) ...[
            const SizedBox(height: 6),
            _StatTile(
              icon: Icons.history_rounded,
              label: l10n.steamLastPlayed,
              value: _formatDate(lastPlayed),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SteamFavoriteButton(appId: appId, name: name),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_to_photos_rounded),
                  label: Text(l10n.steamAddToLibrary),
                  onPressed: () => _addToLibrary(context, ref, name),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SteamGameInfoCard(appId: appId),
          const SizedBox(height: 12),
          _SteamFriendsCard(appId: appId),
          const SizedBox(height: 24),
          achievementsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text(l10n.errorWithMessage(e)),
            data: (res) {
              if (res.total == 0) {
                return Text(l10n.steamNoAchievements);
              }
              return _AchievementsSummaryCard(
                appId: appId,
                unlocked: res.unlocked,
                total: res.total,
              );
            },
          ),
          const SizedBox(height: 12),
          _SteamReviewsCard(appId: appId),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: Text(l10n.steamViewOnStore),
            onPressed: () => _launchSteamStore(appId),
          ),
        ],
      ),
    );
  }

  Future<void> _addToLibrary(
    BuildContext context,
    WidgetRef ref,
    String name,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, dynamic>? igdbGame;
    try {
      final igdb = ref.read(igdbApiProvider);
      final igdbId = await igdb.findGameIdBySteamAppId(appId, gameName: name);
      if (igdbId != null) {
        igdbGame = await igdb.fetchGameDetail(igdbId);
      }
    } catch (_) {}

    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

    if (igdbGame == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.steamNoIgdbMatch(name))),
      );
      return;
    }

    if (!context.mounted) return;
    final ok = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: igdbGame,
      kind: MediaKind.game,
    );
    if (ok && context.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.addedToLibrary)),
      );
    }
  }

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static Future<void> _launchSteamStore(int appId) async {
    final uri = Uri.parse('https://store.steampowered.com/app/$appId/');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: cs.onSurfaceVariant),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

// ─── Media carousel (screenshots + video thumbnails) ─────────────────────────

class _SteamMediaCarousel extends ConsumerWidget {
  const _SteamMediaCarousel({required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(steamAppDetailsProvider(appId));

    return detailsAsync.maybeWhen(
      data: (data) {
        if (data == null) return const SizedBox.shrink();

        // Build the screenshot URL list separately for the gallery viewer.
        final screenshotUrls = <String>[];
        final screenshots = data['screenshots'] as List? ?? [];
        for (final s in screenshots) {
          if (s is! Map) continue;
          final url = (s['path_full'] as String?) ?? (s['path_thumbnail'] as String?);
          if (url != null) screenshotUrls.add(url);
        }

        // Combined display list: videos first, then screenshots.
        final items = <_MediaItem>[];

        final movies = data['movies'] as List? ?? [];
        for (final m in movies) {
          if (m is! Map) continue;
          final thumb = m['thumbnail'] as String?;
          final mp4 = (m['mp4'] as Map?)?['max'] as String? ??
              (m['mp4'] as Map?)?['480'] as String?;
          final webm = (m['webm'] as Map?)?['max'] as String? ??
              (m['webm'] as Map?)?['480'] as String?;
          final url = mp4 ?? webm;
          if (thumb != null && url != null) {
            items.add(_MediaItem(thumbnailUrl: thumb, videoUrl: url));
          }
        }

        var screenshotIdx = 0;
        for (final url in screenshotUrls) {
          items.add(_MediaItem(thumbnailUrl: url, imageIndex: screenshotIdx));
          screenshotIdx++;
        }

        if (items.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final item = items[i];
              return GestureDetector(
                onTap: item.videoUrl != null
                    ? () async {
                        final uri = Uri.parse(item.videoUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri,
                              mode: LaunchMode.externalApplication);
                        }
                      }
                    : item.imageIndex != null && screenshotUrls.isNotEmpty
                        ? () => showFullscreenGallery(
                              context,
                              screenshotUrls,
                              initialIndex: item.imageIndex!,
                            )
                        : null,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.thumbnailUrl,
                        height: 130,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(
                          width: 200,
                          height: 130,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                        errorWidget: (_, _, _) => Container(
                          width: 200,
                          height: 130,
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                        ),
                      ),
                      if (item.videoUrl != null)
                        Positioned.fill(
                          child: Container(
                            color: Colors.black38,
                            child: const Center(
                              child: Icon(Icons.play_circle_outline_rounded,
                                  size: 40, color: Colors.white),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MediaItem {
  const _MediaItem({required this.thumbnailUrl, this.videoUrl, this.imageIndex});
  final String thumbnailUrl;
  final String? videoUrl;
  /// Index into the screenshots-only URL list; null for video items.
  final int? imageIndex;
}

// ─── Favourite button ─────────────────────────────────────────────────────────

class _SteamFavoriteButton extends ConsumerWidget {
  const _SteamFavoriteButton({required this.appId, required this.name});

  final int appId;
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final favs = ref.watch(favoriteGamesProvider);
    final isFav =
        favs.any((e) => (e['steam_appid'] as num?)?.toInt() == appId);

    return M3FavoriteIconButton(
      isFavorite: isFav,
      tooltip: isFav ? l10n.tooltipRemoveFavorite : l10n.tooltipAddFavorite,
      onPressed: () => ref
          .read(favoriteGamesProvider.notifier)
          .toggleSteamFavorite(
            appId,
            name,
            SteamApiDatasource.capsuleUrl(appId),
          ),
    );
  }
}

// ─── Game info card (Steam Store API) ────────────────────────────────────────

class _SteamGameInfoCard extends ConsumerWidget {
  const _SteamGameInfoCard({required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detailsAsync = ref.watch(steamAppDetailsProvider(appId));
    final playersAsync = ref.watch(steamCurrentPlayersProvider(appId));
    final cs = Theme.of(context).colorScheme;

    final shortDesc = detailsAsync.maybeWhen(
      data: (d) => d?['short_description'] as String?,
      orElse: () => null,
    );
    final metacritic = detailsAsync.maybeWhen(
      data: (d) => (d?['metacritic'] as Map<String, dynamic>?)?['score'] as int?,
      orElse: () => null,
    );
    final developers = detailsAsync.maybeWhen(
      data: (d) {
        final devs = d?['developers'] as List?;
        return devs?.map((e) => e.toString()).join(', ');
      },
      orElse: () => null,
    );
    final currentPlayers = playersAsync.maybeWhen(
      data: (c) => c,
      orElse: () => null,
    );

    // Nothing to show yet
    if (detailsAsync.isLoading && playersAsync.isLoading) {
      return const SizedBox.shrink();
    }
    if (shortDesc == null && metacritic == null && currentPlayers == null &&
        developers == null) {
      return const SizedBox.shrink();
    }

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.steamAbout,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (shortDesc != null && shortDesc.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                shortDesc,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (developers != null && developers.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                developers,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (metacritic != null || currentPlayers != null) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (metacritic != null)
                    _InfoChip(
                      icon: Icons.star_rounded,
                      label: '${l10n.steamMetacritic}: $metacritic',
                      color: metacritic >= 75
                          ? Colors.green.shade400
                          : metacritic >= 50
                              ? Colors.orange.shade400
                              : cs.error,
                    ),
                  if (currentPlayers != null)
                    _InfoChip(
                      icon: Icons.people_rounded,
                      label: l10n.steamCurrentPlayers(
                          _formatNumber(currentPlayers)),
                      color: cs.primary,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }
}

// ─── Friends activity card ────────────────────────────────────────────────────

class _SteamFriendsCard extends ConsumerWidget {
  const _SteamFriendsCard({required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activityAsync = ref.watch(steamFriendsWithGameProvider(appId));
    final cs = Theme.of(context).colorScheme;

    return activityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (activity) {
        if (activity.friendListPrivate || activity.totalChecked == 0) {
          return const SizedBox.shrink();
        }
        final friends = activity.friendsWhoOwn;
        return Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_rounded,
                        size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.steamFriendsActivity,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  friends.isEmpty
                      ? l10n.steamFriendsNoneOwn
                      : l10n.steamFriendsOwnThis(friends.length),
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (friends.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: friends.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final f = friends[i];
                        final avatarUrl = (f['avatarmedium'] as String?) ??
                            (f['avatar'] as String?);
                        final name =
                            (f['personaname'] as String?) ?? '?';
                        return Tooltip(
                          message: name,
                          child: CircleAvatar(
                            radius: 21,
                            backgroundImage: avatarUrl != null
                                ? NetworkImage(avatarUrl)
                                : null,
                            child: avatarUrl == null
                                ? Text(name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?')
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── User reviews card ────────────────────────────────────────────────────────

class _SteamReviewsCard extends ConsumerWidget {
  const _SteamReviewsCard({required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reviewsAsync = ref.watch(steamUserReviewsProvider(appId));
    final cs = Theme.of(context).colorScheme;

    return reviewsAsync.maybeWhen(
      data: (data) {
        if (data == null) return const SizedBox.shrink();
        final summary = data['query_summary'] as Map?;
        if (summary == null) return const SizedBox.shrink();

        final reviewScoreDesc = summary['review_score_desc'] as String? ?? '';
        final reviewScore = (summary['review_score'] as num?)?.toInt() ?? 0;
        final totalPositive = (summary['total_positive'] as num?)?.toInt() ?? 0;
        final totalReviews = (summary['total_reviews'] as num?)?.toInt() ?? 0;

        if (totalReviews == 0) return const SizedBox.shrink();

        final positivePercent =
            (totalPositive / totalReviews * 100).round();

        final scoreColor = reviewScore >= 9
            ? Colors.green
            : reviewScore >= 7
                ? Colors.green.shade400
                : reviewScore >= 5
                    ? Colors.orange
                    : reviewScore >= 3
                        ? Colors.deepOrange
                        : cs.error;

        final reviews = (data['reviews'] as List? ?? [])
            .whereType<Map>()
            .where((r) => ((r['review'] as String?) ?? '').trim().isNotEmpty)
            .take(5)
            .toList();

        return Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.steamUserReviews,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: scoreColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border:
                            Border.all(color: scoreColor.withAlpha(80)),
                      ),
                      child: Text(
                        reviewScoreDesc,
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: scoreColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.steamReviewsStats(
                            positivePercent, _formatNumber(totalReviews)),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
                if (reviews.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  for (final r in reviews) ...[
                    const SizedBox(height: 10),
                    _ReviewRow(review: r),
                  ],
                ],
              ],
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  static String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({required this.review});

  final Map review;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final votedUp = review['voted_up'] as bool? ?? false;
    final reviewText = (review['review'] as String? ?? '').trim();
    final playtimeMin =
        (review['author'] as Map?)?['playtime_at_review'] as num?;
    final hours = playtimeMin != null
        ? (playtimeMin / 60).toStringAsFixed(0)
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          votedUp
              ? Icons.thumb_up_rounded
              : Icons.thumb_down_rounded,
          size: 16,
          color: votedUp ? Colors.green : cs.error,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reviewText,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              if (hours != null) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.steamHoursPlayed(hours),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withAlpha(150),
                      ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Achievements summary card ────────────────────────────────────────────────

class _AchievementsSummaryCard extends StatelessWidget {
  const _AchievementsSummaryCard({
    required this.appId,
    required this.unlocked,
    required this.total,
  });

  final int appId;
  final int unlocked;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final progress = total > 0 ? unlocked / total : 0.0;
    return Card.filled(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/profile/steam/game/$appId/achievements'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    l10n.steamAchievements,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    l10n.steamAchievementsProgress(unlocked, total),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded,
                      color: cs.onSurfaceVariant, size: 20),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Achievements full-screen page ───────────────────────────────────────────

class SteamAchievementsPage extends ConsumerWidget {
  const SteamAchievementsPage({super.key, required this.appId});

  final int appId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final achievementsAsync =
        ref.watch(steamGameAchievementsProvider(appId));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.steamAchievements)),
      body: achievementsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (res) {
          if (res.total == 0) {
            return Center(child: Text(l10n.steamNoAchievements));
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.steamAchievementsProgress(
                              res.unlocked, res.total),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: res.total > 0 ? res.unlocked / res.total : 0,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: res.achievements.length,
                  itemBuilder: (context, i) =>
                      _AchievementRow(achievement: res.achievements[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Achievement row ──────────────────────────────────────────────────────────

class _AchievementRow extends StatelessWidget {
  const _AchievementRow({required this.achievement});

  final SteamAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final iconUrl = achievement.achieved
        ? achievement.iconUrl
        : (achievement.iconGrayUrl ?? achievement.iconUrl);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: 40,
              height: 40,
              child: iconUrl != null && iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          Container(color: cs.surfaceContainerHighest),
                    )
                  : Container(color: cs.surfaceContainerHighest),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.displayName.isNotEmpty
                      ? achievement.displayName
                      : achievement.apiName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if ((achievement.hidden && !achievement.achieved) == false &&
                    achievement.description.isNotEmpty)
                  Text(
                    achievement.description,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  )
                else if (achievement.hidden && !achievement.achieved)
                  Text(
                    l10n.steamAchievementHidden,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                if (achievement.achieved && achievement.unlockTime != null)
                  Text(
                    l10n.steamAchievementUnlockedOn(
                      SteamGameDetailPage._formatDate(achievement.unlockTime!),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade400,
                        ),
                  ),
              ],
            ),
          ),
          Icon(
            achievement.achieved
                ? Icons.emoji_events_rounded
                : Icons.lock_outline_rounded,
            color: achievement.achieved
                ? Colors.amber.shade400
                : cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}
