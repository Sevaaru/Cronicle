import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/feed/presentation/activity_feed_widgets.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/social/presentation/social_steam_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/feed_activity.dart';

/// Sealed-like union for an entry rendered in the unified social feed.
abstract class SocialFeedEntry {
  const SocialFeedEntry();
  DateTime get sortKey;
}

class _AnilistEntry extends SocialFeedEntry {
  const _AnilistEntry(this.activity);
  final FeedActivity activity;
  @override
  DateTime get sortKey => activity.createdAt;
}

class _SteamFriendEntry extends SocialFeedEntry {
  const _SteamFriendEntry(this.item);
  final SteamFriendActivityItem item;
  @override
  DateTime get sortKey => item.timestamp;
}

class _SteamNewsEntry extends SocialFeedEntry {
  const _SteamNewsEntry(this.item);
  final SteamNewsFeedItem item;
  @override
  DateTime get sortKey => item.publishedAt;
}

/// Unified feed merging AniList activities with Steam friend-played and
/// Steam news. Sorted by date desc; preserves pull-to-refresh, compose
/// card, infinite scroll (anilist) and inline error/empty states.
class SocialUnifiedFeed extends ConsumerStatefulWidget {
  const SocialUnifiedFeed({
    super.key,
    required this.header,
    required this.isFollowing,
    required this.includeAnilist,
    required this.includeSteamFriends,
    required this.includeSteamNews,
    required this.activityTypeApi,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
  });

  final Widget header;
  final bool isFollowing;
  final bool includeAnilist;
  final bool includeSteamFriends;
  final bool includeSteamNews;
  final String? activityTypeApi;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final bool Function() hasMore;

  @override
  ConsumerState<SocialUnifiedFeed> createState() =>
      _SocialUnifiedFeedState();
}

class _SocialUnifiedFeedState extends ConsumerState<SocialUnifiedFeed> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore {
    try {
      return widget.hasMore();
    } catch (_) {
      return false;
    }
  }

  void _onScroll() {
    if (!widget.includeAnilist) return;
    if (!_hasMore) return;
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 300) widget.onLoadMore();
  }

  void _fireRefresh() => widget.onRefresh();

  /// Build the merged & sorted list of entries.
  List<SocialFeedEntry> _mergeEntries({
    required List<FeedActivity> anilist,
    required List<SteamFriendActivityItem> friends,
    required List<SteamNewsFeedItem> news,
  }) {
    final entries = <SocialFeedEntry>[];
    if (widget.includeAnilist) {
      for (final a in anilist) {
        entries.add(_AnilistEntry(a));
      }
    }
    if (widget.includeSteamFriends) {
      for (final f in friends) {
        entries.add(_SteamFriendEntry(f));
      }
    }
    if (widget.includeSteamNews) {
      for (final n in news) {
        entries.add(_SteamNewsEntry(n));
      }
    }
    entries.sort((a, b) => b.sortKey.compareTo(a.sortKey));
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    // AniList feed (only if enabled). When following+no token we render
    // a small inline banner instead of blocking the whole feed, so the
    // user can still see Steam content.
    AsyncValue<List<FeedActivity>> anilistAsync =
        const AsyncData<List<FeedActivity>>([]);
    bool anilistNeedsLogin = false;
    bool anilistLoading = false;
    Object? anilistError;
    if (widget.includeAnilist) {
      final tokenAsync = ref.watch(anilistTokenProvider);
      final hasTokenInfo = tokenAsync.hasValue;
      final hasToken = tokenAsync.valueOrNull != null;
      if (widget.isFollowing && hasTokenInfo && !hasToken) {
        anilistNeedsLogin = true;
      } else {
        final feedProv = anilistSocialFeedProvider(
            widget.activityTypeApi, widget.isFollowing);
        anilistAsync = ref.watch(feedProv);
        anilistLoading = anilistAsync.isLoading && !anilistAsync.hasValue;
        anilistError = anilistAsync.hasError && !anilistAsync.hasValue
            ? anilistAsync.error
            : null;
      }
    }

    // Steam asyncs.
    final friendsAsync = widget.includeSteamFriends
        ? ref.watch(steamFriendsRecentActivityProvider)
        : const AsyncData<List<SteamFriendActivityItem>>([]);
    final newsAsync = widget.includeSteamNews
        ? ref.watch(steamOwnedGamesNewsProvider)
        : const AsyncData<List<SteamNewsFeedItem>>([]);

    // Visible activity lists (best-effort, treat error/loading as empty).
    final hideText = ref.watch(hideTextActivitiesProvider);
    final anilistRaw = anilistAsync.valueOrNull ?? const <FeedActivity>[];
    final anilistList = hideText
        ? anilistRaw.where((a) => !a.isTextActivity).toList()
        : anilistRaw;
    final friendsList =
        friendsAsync.valueOrNull ?? const <SteamFriendActivityItem>[];
    final newsList =
        newsAsync.valueOrNull ?? const <SteamNewsFeedItem>[];

    final entries = _mergeEntries(
      anilist: anilistList,
      friends: friendsList,
      news: newsList,
    );

    final hasMore = widget.includeAnilist && _hasMore;
    final showCompose = widget.includeAnilist;
    final showSteamLoading =
        (friendsAsync.isLoading && !friendsAsync.hasValue) ||
            (newsAsync.isLoading && !newsAsync.hasValue);
    final isInitialLoading = anilistLoading || showSteamLoading;
    final isRefreshingOverlay =
        widget.includeAnilist && anilistAsync.isLoading && anilistAsync.hasValue;

    final listPadding = const EdgeInsets.fromLTRB(16, 0, 16, 100);

    Widget content;
    if (isInitialLoading && entries.isEmpty && !anilistNeedsLogin) {
      content = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: [
          widget.header,
          const SizedBox(height: 80),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    } else if (anilistError != null && entries.isEmpty) {
      final isRate = anilistError is AnilistRateLimitException;
      final retry = isRate
          ? (anilistError as AnilistRateLimitException).retryAfterSeconds
          : null;
      final msg = isRate
          ? (retry != null && retry > 0
              ? l10n.errorAnilistRateLimitWithSeconds(retry)
              : l10n.errorAnilistRateLimit)
          : l10n.errorNetwork;
      content = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: [
          widget.header,
          const SizedBox(height: 60),
          Icon(isRate ? Icons.hourglass_top_rounded : Icons.wifi_off,
              size: 48, color: cs.error),
          const SizedBox(height: 12),
          Center(child: Text(msg)),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: _fireRefresh,
              child: Text(l10n.feedRetry),
            ),
          ),
        ],
      );
    } else if (widget.includeSteamFriends &&
        !widget.includeAnilist &&
        friendsAsync.hasError &&
        entries.isEmpty) {
      // Steam-only mode + the provider failed: surface the actual reason
      // so the user understands instead of seeing a blank "feed empty".
      final err = friendsAsync.error;
      final msg = err is StateError
          ? switch (err.message) {
              'steam_not_connected' =>
                'No hay sesi\u00f3n de Steam activa. Conecta Steam en Ajustes.',
              'steam_friends_empty' =>
                'Steam devolvi\u00f3 0 amigos. Verifica que tu lista de amigos est\u00e9 marcada como p\u00fablica en la privacidad de tu perfil de Steam.',
              _ => 'Steam: ${err.message}',
            }
          : 'Steam: ${err.toString()}';
      content = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: [
          widget.header,
          const SizedBox(height: 40),
          Icon(Icons.error_outline_rounded, size: 48, color: cs.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(msg, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          Center(
            child: FilledButton(
              onPressed: () {
                // ignore: unused_result
                ref.refresh(steamFriendsRecentActivityProvider);
              },
              child: Text(l10n.feedRetry),
            ),
          ),
        ],
      );
    } else {
      // Header → compose → optional anilist-needs-login banner →
      // entries → optional load-more spinner → optional empty hint.
      final children = <Widget>[];
      children.add(widget.header);
      if (anilistNeedsLogin) {
        children.add(_AnilistLoginBanner(l10n: l10n, cs: cs));
      } else if (showCompose) {
        children.add(ComposeCard(onPosted: _fireRefresh));
      }
      if (entries.isEmpty) {
        children.add(const SizedBox(height: 28));
        children.add(Center(
          child: Text(l10n.feedEmpty,
              style: TextStyle(color: cs.onSurfaceVariant)),
        ));
        children.add(const SizedBox(height: 14));
        children.add(Center(
          child: FilledButton.tonalIcon(
            onPressed: _fireRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(l10n.feedRetry),
          ),
        ));
      } else {
        for (final e in entries) {
          children.add(RepaintBoundary(child: _entryWidget(e, l10n, cs)));
        }
        if (hasMore) {
          children.add(const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
                child: CircularProgressIndicator(strokeWidth: 2)),
          ));
        }
      }
      content = ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: listPadding,
        children: children,
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        widget.onRefresh();
        // Also refresh Steam providers.
        // ignore: unused_result
        ref.refresh(steamFriendsRecentActivityProvider);
        // ignore: unused_result
        ref.refresh(steamOwnedGamesNewsProvider);
      },
      child: Stack(
        children: [
          Positioned.fill(child: content),
          if (isRefreshingOverlay)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2,
                backgroundColor:
                    cs.surfaceContainerHighest.withAlpha(120),
              ),
            ),
        ],
      ),
    );
  }

  Widget _entryWidget(
      SocialFeedEntry e, AppLocalizations l10n, ColorScheme cs) {
    if (e is _AnilistEntry) {
      return ActivityCard(activity: e.activity);
    }
    if (e is _SteamFriendEntry) {
      return _SteamFriendCard(item: e.item, l10n: l10n);
    }
    if (e is _SteamNewsEntry) {
      return _SteamNewsCard(item: e.item, l10n: l10n);
    }
    return const SizedBox.shrink();
  }
}

class _AnilistLoginBanner extends StatelessWidget {
  const _AnilistLoginBanner({required this.l10n, required this.cs});
  final AppLocalizations l10n;
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withAlpha(80)),
      ),
      child: Row(
        children: [
          Icon(Icons.people_outline_rounded,
              size: 20, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.loginRequiredFollowing,
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: () => context.go('/settings'),
            icon: const Icon(Icons.login, size: 16),
            label: Text(l10n.goToSettings,
                style: const TextStyle(fontSize: 12)),
            style: FilledButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Steam tiles styled as cards (match ActivityCard chrome) ──────────────────

class _SteamCardShell extends StatelessWidget {
  const _SteamCardShell({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(22),
      ),
      child: child,
    );
  }
}

class _SteamSourceChip extends StatelessWidget {
  const _SteamSourceChip({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1B2838).withAlpha(40),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports_esports_rounded,
              size: 12, color: Color(0xFF66C0F4)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SteamFriendCard extends StatelessWidget {
  const _SteamFriendCard({required this.item, required this.l10n});
  final SteamFriendActivityItem item;
  final AppLocalizations l10n;

  String _playtimeLabel() {
    final mins = item.playtimeForever;
    if (mins <= 0) return '';
    if (mins < 60) return l10n.steamFriendPlayedMinutes(mins);
    final hours = (mins / 60).toStringAsFixed(mins >= 600 ? 0 : 1);
    return l10n.steamFriendPlayedHours(hours);
  }

  /// Headline shown under the persona name describing the activity.
  String _action() {
    switch (item.kind) {
      case SteamFriendActivityKind.played:
        return '${l10n.steamFriendPlayedAction} ${item.gameName}';
      case SteamFriendActivityKind.purchased:
        return l10n.steamFriendAddedGames(item.newGamesCount);
      case SteamFriendActivityKind.achievement:
        return l10n.steamFriendUnlockedIn(item.gameName);
    }
  }

  void _onTap(BuildContext context) {
    // Purchase summaries don't point to a specific game — fall back to
    // the friend's Steam profile when present.
    if (item.kind == SteamFriendActivityKind.purchased) {
      // No deep link target; tap is a no-op.
      return;
    }
    if (item.appId > 0) {
      context.push('/profile/steam/game/${item.appId}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final timeLabel = activityTimeAgo(item.timestamp, l10n);

    return _SteamCardShell(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _onTap(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: avatar + persona / action / time + STEAM chip.
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: item.avatarUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.avatarUrl!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _SteamAvatarFallback(cs: cs),
                        )
                      : _SteamAvatarFallback(cs: cs),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.personaName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _action(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          fontSize: 10,
                          color: cs.onSurfaceVariant.withAlpha(180),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _SteamSourceChip(label: 'STEAM'),
              ],
            ),
            const SizedBox(height: 12),
            // Body — varies per kind.
            _buildBody(cs),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(ColorScheme cs) {
    switch (item.kind) {
      case SteamFriendActivityKind.played:
        return _gameRow(cs, subtitle: _playtimeLabel());
      case SteamFriendActivityKind.achievement:
        return _achievementRow(cs);
      case SteamFriendActivityKind.purchased:
        return _purchasesRow(cs);
    }
  }

  Widget _gameThumb(ColorScheme cs, {double height = 56}) {
    // Steam header.jpg is 460x215 (~2.14:1). Render the thumb wide so the
    // capsule looks correct instead of cropped to a square low-quality icon.
    final width = height * 2;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: item.gameIconUrl != null
          ? CachedNetworkImage(
              imageUrl: item.gameIconUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: width,
                height: height,
                color: cs.surfaceContainerHigh,
                child: Icon(Icons.videogame_asset_rounded,
                    size: 26, color: cs.onSurfaceVariant),
              ),
            )
          : Container(
              width: width,
              height: height,
              color: cs.surfaceContainerHigh,
              child: Icon(Icons.videogame_asset_rounded,
                  size: 26, color: cs.onSurfaceVariant),
            ),
    );
  }

  Widget _gameRow(ColorScheme cs, {String subtitle = ''}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _gameThumb(cs),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.gameName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded,
            size: 20, color: cs.onSurfaceVariant),
      ],
    );
  }

  Widget _achievementRow(ColorScheme cs) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFFFB300).withAlpha(40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFFFFB300).withAlpha(140),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 24,
            color: Color(0xFFFFB300),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.achievementName ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                item.gameName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
              if ((item.achievementDescription ?? '').isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.achievementDescription!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant.withAlpha(200),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _purchasesRow(ColorScheme cs) {
    final names = item.newGameNames;
    final preview = names.isEmpty
        ? ''
        : (names.length <= 2 ? names.join(', ') : '${names.take(2).join(', ')}…');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF66C0F4).withAlpha(40),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF66C0F4).withAlpha(140),
              width: 1,
            ),
          ),
          child: const Icon(
            Icons.shopping_bag_rounded,
            size: 22,
            color: Color(0xFF66C0F4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.steamFriendAddedGamesTitle(item.newGamesCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  preview,
                  maxLines: 2,
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
      ],
    );
  }
}

class _SteamAvatarFallback extends StatelessWidget {
  const _SteamAvatarFallback({required this.cs});
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        color: cs.surfaceContainerHigh,
        child: Icon(Icons.person, size: 20, color: cs.onSurfaceVariant),
      );
}

class _SteamNewsCard extends StatelessWidget {
  const _SteamNewsCard({required this.item, required this.l10n});
  final SteamNewsFeedItem item;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cleaned = item.contents
        .replaceAll(RegExp(r'\[[^\]]+\]'), '')
        .replaceAll(RegExp(r'\{[^}]+\}'), '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();
    return _SteamCardShell(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (item.appId > 0) {
            context.push('/profile/steam/game/${item.appId}');
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.gameIconUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.gameIconUrl!,
                          width: 76,
                          height: 36,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              _NewsIconFallback(cs: cs),
                        )
                      : _NewsIconFallback(cs: cs),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.gameName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activityTimeAgo(item.publishedAt, l10n),
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const _SteamSourceChip(label: 'STEAM'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
                height: 1.25,
              ),
            ),
            if (cleaned.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                cleaned,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NewsIconFallback extends StatelessWidget {
  const _NewsIconFallback({required this.cs});
  final ColorScheme cs;
  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        color: cs.surfaceContainerHigh,
        child: Icon(Icons.videogame_asset_rounded,
            size: 18, color: cs.onSurfaceVariant),
      );
}
