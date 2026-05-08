import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/steam/data/datasources/steam_api_datasource.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
import 'package:cronicle/shared/widgets/library_snackbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cronicle/shared/widgets/game_view_toggle.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/m3_detail.dart';

/// Detail page for one Steam app: header, playtime, achievements list, and
/// an "Add to my library" action that resolves the matching IGDB game.
class SteamGameDetailPage extends ConsumerStatefulWidget {
  const SteamGameDetailPage({super.key, required this.appId});

  final int appId;

  @override
  ConsumerState<SteamGameDetailPage> createState() =>
      _SteamGameDetailPageState();

  static String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  static Future<void> _launchSteamStore(int appId) async {
    final uri = Uri.parse('https://store.steampowered.com/app/$appId/');
    if (await canLaunchUrl(uri))
      await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SteamGameDetailPageState extends ConsumerState<SteamGameDetailPage> {
  /// The IGDB externalId resolved for this Steam game, once known.
  /// Set immediately from the library entry (if already in library) or after
  /// the first IGDB lookup triggered by "Add to library".
  String? _igdbExternalId;

  /// Whether the IGDB lookup is currently running (shows spinner on the add
  /// button instead of opening a separate loading dialog).
  bool _addLoading = false;

  final _addBtnKey = GlobalKey();

  int get appId => widget.appId;

  LibraryEntry? _findExistingEntry(List<LibraryEntry> entries) {
    // Primary: match by steamAppId stored in the DB (fastest, most accurate)
    final bySteam = entries.cast<LibraryEntry?>().firstWhere(
          (e) => e?.steamAppId == appId,
          orElse: () => null,
        );
    if (bySteam != null) {
      // Keep _igdbExternalId in sync so the IGDB toggle appears immediately
      if (_igdbExternalId == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _igdbExternalId = bySteam.externalId);
        });
      }
      return bySteam;
    }
    // Fallback: match by cached IGDB id (covers the moment between "just added"
    // and the stream emitting the updated list with steamAppId set)
    if (_igdbExternalId != null) {
      return entries.cast<LibraryEntry?>().firstWhere(
            (e) => e?.externalId == _igdbExternalId,
            orElse: () => null,
          );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final gamesAsync = ref.watch(steamOwnedGamesProvider);
    final achievementsAsync = ref.watch(steamGameAchievementsProvider(appId));

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
    final lastPlayedTs = (game['rtime_last_played'] as num?)?.toInt() ?? 0;
    final lastPlayed = lastPlayedTs > 0
        ? DateTime.fromMillisecondsSinceEpoch(lastPlayedTs * 1000)
        : null;

    // Check if the game is already in the library
    final gameEntries =
        ref.watch(libraryByKindProvider(MediaKind.game)).valueOrNull ?? [];
    final existing = _findExistingEntry(gameEntries);
    final inLibrary = existing != null;

    final igdbId = _igdbExternalId != null
        ? int.tryParse(_igdbExternalId!)
        : null;

    return Scaffold(
          appBar: AppBar(title: Text(name)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, kGlassBottomNavContentHeight + 24),
            children: [
              // Steam / IGDB view toggle — visible once the IGDB id is known
              if (igdbId != null) ...[
                GameViewToggle(
                  currentIsSteam: true,
                  onSteam: null, // already on Steam view
                  onIgdb: () => context.push('/game/$igdbId'),
                ),
                const SizedBox(height: 12),
              ],
              AspectRatio(
                aspectRatio: 460 / 215,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    SteamApiDatasource.headerUrl(appId),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      color: cs.surfaceContainerHighest,
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
                  value: SteamGameDetailPage._formatDate(lastPlayed),
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
                      key: _addBtnKey,
                      icon: _addLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Icon(inLibrary
                              ? Icons.edit_rounded
                              : Icons.add_to_photos_rounded),
                      label: Text(inLibrary
                          ? l10n.editLibraryEntry
                          : l10n.steamAddToLibrary),
                      onPressed: _addLoading
                          ? null
                          : () => _addToLibrary(
                              context, name, playtimeMin, existing),
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
                onPressed: () => SteamGameDetailPage._launchSteamStore(appId),
              ),
            ],
          ),
    );
  }

  Future<void> _addToLibrary(
    BuildContext context,
    String name,
    int playtimeMin,
    LibraryEntry? existing,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);

    if (mounted) setState(() => _addLoading = true);

    Map<String, dynamic>? igdbGame;
    try {
      final igdb = ref.read(igdbApiProvider);
      final igdbId = await igdb.findGameIdBySteamAppId(appId, gameName: name);
      if (igdbId != null) {
        final raw = await igdb.fetchGameDetail(igdbId);
        if (raw != null) {
          igdbGame = IgdbApiDatasource.normalize(raw);
          if (mounted) {
            setState(() => _igdbExternalId = igdbId.toString());
          }
        }
      }
    } catch (_) {}

    if (mounted) setState(() => _addLoading = false);
    if (!context.mounted) return;

    if (igdbGame == null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.steamNoIgdbMatch(name))),
      );
      return;
    }

    // Re-check existing entry by IGDB id now that we have it
    LibraryEntry? resolvedExisting = existing;
    if (resolvedExisting == null && _igdbExternalId != null) {
      final db = ref.read(databaseProvider);
      resolvedExisting = await db.getLibraryEntryByKindAndExternalId(
        MediaKind.game.code,
        _igdbExternalId!,
      );
    }
    final wasEdit = resolvedExisting != null;

    if (!context.mounted) return;
    final ok = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: igdbGame,
      kind: MediaKind.game,
      existingEntry: resolvedExisting,
      initialProgress: (!wasEdit && playtimeMin > 0)
          ? (playtimeMin / 60).round()
          : null,
      useRootNavigator: false,
      steamAppId: appId,
    );

    if (!context.mounted) return;
    if (!ok) return;

    if (!wasEdit) {
      final btnCtx = _addBtnKey.currentContext;
      if (btnCtx != null) {
        playLibraryInsertAnimation(
          sourceContext: btnCtx,
          imageUrl: SteamApiDatasource.capsuleUrl(appId),
          startWidth: 80,
          startHeight: 60,
        );
      }
    }
    showLibrarySnackbar(context, wasEdit: wasEdit);
  }
}

// ─── Stat tile ───────────────────────────────────────────────────────────────

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

    return activityAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (activity) {
        if (activity.friendListPrivate || activity.totalChecked == 0) {
          return const SizedBox.shrink();
        }
        final friends = activity.friendsWhoOwn;
        if (friends.isEmpty) return const SizedBox.shrink();

        const kMax = 5;
        return Card.filled(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.group_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.steamFriendsActivity,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      l10n.steamFriendsOwnThis(friends.length),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...friends.take(kMax).map((f) {
                  final steamId = f['steamid'] as String? ?? '';
                  return _FriendPlaytimeRow(
                    friend: f,
                    playtimeMinutes: activity.playtimeByFriendId[steamId],
                  );
                }),
                if (friends.length > kMax)
                  TextButton(
                    onPressed: () =>
                        _showAllFriends(context, friends, activity, l10n),
                    child: Text('+${friends.length - kMax} more'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAllFriends(
    BuildContext context,
    List<Map<String, dynamic>> friends,
    SteamFriendsActivity activity,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scroll) => Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurfaceVariant
                      .withAlpha(60),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(l10n.steamFriendsActivity,
                  style: Theme.of(ctx).textTheme.titleMedium),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: friends.length,
                itemBuilder: (ctx, i) {
                  final f = friends[i];
                  final steamId = f['steamid'] as String? ?? '';
                  return _FriendPlaytimeRow(
                    friend: f,
                    playtimeMinutes: activity.playtimeByFriendId[steamId],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendPlaytimeRow extends StatelessWidget {
  const _FriendPlaytimeRow({
    required this.friend,
    this.playtimeMinutes,
  });

  final Map<String, dynamic> friend;
  final int? playtimeMinutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final avatarUrl =
        (friend['avatarmedium'] as String?) ?? (friend['avatar'] as String?);
    final name = (friend['personaname'] as String?) ?? '?';
    final profileUrl = friend['profileurl'] as String?;
    final hasProfile = profileUrl != null && profileUrl.isNotEmpty;

    final playtimeText = playtimeMinutes != null
        ? l10n.steamHoursPlayed((playtimeMinutes! / 60).toStringAsFixed(1))
        : '—';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: hasProfile
          ? () => launchUrl(Uri.parse(profileUrl),
              mode: LaunchMode.externalApplication)
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?')
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(name,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ),
            Text(
              playtimeText,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            if (hasProfile) ...[
              const SizedBox(width: 4),
              Icon(Icons.open_in_new_rounded,
                  size: 13, color: cs.onSurfaceVariant),
            ],
          ],
        ),
      ),
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

enum _AchievementFilter { all, unlocked, locked }

class SteamAchievementsPage extends ConsumerStatefulWidget {
  const SteamAchievementsPage({super.key, required this.appId});

  final int appId;

  @override
  ConsumerState<SteamAchievementsPage> createState() =>
      _SteamAchievementsPageState();
}

class _SteamAchievementsPageState extends ConsumerState<SteamAchievementsPage> {
  _AchievementFilter _filter = _AchievementFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEs = Localizations.localeOf(context).languageCode == 'es';
    final achievementsAsync =
        ref.watch(steamGameAchievementsProvider(widget.appId));

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

          final visible = switch (_filter) {
            _AchievementFilter.all => res.achievements,
            _AchievementFilter.unlocked =>
              res.achievements.where((a) => a.achieved).toList(),
            _AchievementFilter.locked =>
              res.achievements.where((a) => !a.achieved).toList(),
          };

          final cs = Theme.of(context).colorScheme;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.steamAchievementsProgress(
                                res.unlocked, res.total),
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                        Text(
                          '${(res.total > 0 ? res.unlocked / res.total * 100 : 0).round()}%',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(color: cs.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: res.total > 0 ? res.unlocked / res.total : 0,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Filter chips row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in _AchievementFilter.values) ...[
                            _AchievFilterChip(
                              label: switch (f) {
                                _AchievementFilter.all =>
                                  isEs ? 'Todos' : 'All',
                                _AchievementFilter.unlocked =>
                                  isEs ? 'Desbloqueados' : 'Unlocked',
                                _AchievementFilter.locked =>
                                  isEs ? 'Bloqueados' : 'Locked',
                              },
                              icon: switch (f) {
                                _AchievementFilter.all =>
                                  Icons.list_alt_rounded,
                                _AchievementFilter.unlocked =>
                                  Icons.lock_open_rounded,
                                _AchievementFilter.locked =>
                                  Icons.lock_outline_rounded,
                              },
                              selected: _filter == f,
                              onTap: () => setState(() => _filter = f),
                            ),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.fromLTRB(
                      16, 8, 16, kGlassBottomNavContentHeight + 24),
                  itemCount: visible.length,
                  itemBuilder: (context, i) =>
                      _AchievementCard(achievement: visible[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Achievement filter chip ──────────────────────────────────────────────────

class _AchievFilterChip extends StatelessWidget {
  const _AchievFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primaryContainer : cs.surfaceContainerHigh;
    final fg = selected ? cs.onPrimaryContainer : cs.onSurfaceVariant;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Achievement card ─────────────────────────────────────────────────────────

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});

  final SteamAchievement achievement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unlocked = achievement.achieved;
    final iconUrl = unlocked
        ? achievement.iconUrl
        : (achievement.iconGrayUrl ?? achievement.iconUrl);
    final name = achievement.displayName.isNotEmpty
        ? achievement.displayName
        : achievement.apiName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: unlocked
            ? (isDark
                ? cs.primaryContainer.withAlpha(60)
                : cs.primaryContainer.withAlpha(40))
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: ColorFiltered(
                  colorFilter: unlocked
                      ? const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply)
                      : const ColorFilter.matrix([
                          0.213, 0.715, 0.072, 0, 0, //
                          0.213, 0.715, 0.072, 0, 0,
                          0.213, 0.715, 0.072, 0, 0,
                          0, 0, 0, 0.7, 0,
                        ]),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: iconUrl != null && iconUrl.isNotEmpty
                        ? Image.network(
                            iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              color: cs.surfaceContainerHighest,
                              child: Icon(Icons.emoji_events_outlined,
                                  color: cs.onSurfaceVariant),
                            ),
                          )
                        : Container(
                            color: cs.surfaceContainerHighest,
                            child: Icon(Icons.emoji_events_outlined,
                                color: cs.onSurfaceVariant),
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: unlocked
                                ? cs.onSurface
                                : cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    if (!(achievement.hidden && !unlocked) &&
                        achievement.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        achievement.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ] else if (achievement.hidden && !unlocked) ...[
                      const SizedBox(height: 2),
                      Text(
                        l10n.steamAchievementHidden,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ],
                    if (unlocked && achievement.unlockTime != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded,
                              size: 12, color: Colors.green.shade400),
                          const SizedBox(width: 4),
                          Text(
                            l10n.steamAchievementUnlockedOn(
                              SteamGameDetailPage._formatDate(
                                  achievement.unlockTime!),
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.green.shade400),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Badge
              Icon(
                unlocked
                    ? Icons.emoji_events_rounded
                    : Icons.lock_outline_rounded,
                size: 22,
                color: unlocked
                    ? Colors.amber.shade400
                    : cs.onSurfaceVariant.withAlpha(120),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
