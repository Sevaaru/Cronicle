import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

enum _FeedFilter {
  following,
  all,
  anime,
  manga,
  movie,
  tv,
  game;

  IconData get icon => switch (this) {
        _FeedFilter.following => Icons.people_rounded,
        _FeedFilter.all => Icons.public_rounded,
        _FeedFilter.anime => Icons.animation_rounded,
        _FeedFilter.manga => Icons.menu_book_rounded,
        _FeedFilter.movie => Icons.movie_rounded,
        _FeedFilter.tv => Icons.tv_rounded,
        _FeedFilter.game => Icons.sports_esports_rounded,
      };
}

String _filterLabel(_FeedFilter f, AppLocalizations l10n) => switch (f) {
      _FeedFilter.following => l10n.filterFollowing,
      _FeedFilter.all => l10n.filterGlobal,
      _FeedFilter.anime => l10n.filterAnime,
      _FeedFilter.manga => l10n.filterManga,
      _FeedFilter.movie => l10n.filterMovies,
      _FeedFilter.tv => l10n.filterTv,
      _FeedFilter.game => l10n.filterGames,
    };

String _timeAgo(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return l10n.timeWeeks((diff.inDays / 7).floor());
}

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  _FeedFilter _filter = _FeedFilter.all;
  bool _filterInitialized = false;

  AsyncValue<List<FeedActivity>> _getFilteredFeed() {
    return switch (_filter) {
      _FeedFilter.following => ref.watch(anilistFeedFollowingProvider),
      _FeedFilter.all => ref.watch(anilistFeedProvider),
      _FeedFilter.anime =>
        ref.watch(anilistFeedByTypeProvider('ANIME_LIST')),
      _FeedFilter.manga =>
        ref.watch(anilistFeedByTypeProvider('MANGA_LIST')),
      _ => const AsyncData([]),
    };
  }

  void _invalidateFeed() {
    switch (_filter) {
      case _FeedFilter.following:
        ref.invalidate(anilistFeedFollowingProvider);
      case _FeedFilter.all:
        ref.invalidate(anilistFeedProvider);
      case _FeedFilter.anime:
        ref.invalidate(anilistFeedByTypeProvider('ANIME_LIST'));
      case _FeedFilter.manga:
        ref.invalidate(anilistFeedByTypeProvider('MANGA_LIST'));
      default:
        break;
    }
  }

  void _loadMore() {
    switch (_filter) {
      case _FeedFilter.following:
        ref.read(anilistFeedFollowingProvider.notifier).loadMore();
      case _FeedFilter.all:
        ref.read(anilistFeedProvider.notifier).loadMore();
      case _FeedFilter.anime:
        ref.read(anilistFeedByTypeProvider('ANIME_LIST').notifier).loadMore();
      case _FeedFilter.manga:
        ref.read(anilistFeedByTypeProvider('MANGA_LIST').notifier).loadMore();
      default:
        break;
    }
  }

  bool get _isPlaceholderFilter =>
      _filter == _FeedFilter.movie ||
      _filter == _FeedFilter.tv ||
      _filter == _FeedFilter.game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    if (!_filterInitialized) {
      final defaultTab = ref.read(defaultFeedTabProvider);
      _filter = _FeedFilter.values.firstWhere(
        (f) => f.name == defaultTab,
        orElse: () => _FeedFilter.all,
      );
      _filterInitialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.feedTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _invalidateFeed,
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: _FeedFilter.values.length,
              itemBuilder: (context, i) {
                final f = _FeedFilter.values[i];
                final selected = _filter == f;
                return FilterChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 15),
                      const SizedBox(width: 4),
                      Text(_filterLabel(f, l10n), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _isPlaceholderFilter
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_filter.icon, size: 48,
                            color: colorScheme.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          l10n.feedComingSoon(_filterLabel(_filter, l10n)),
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _filter == _FeedFilter.following
                    ? _FollowingFeedGuard(
                        onRefresh: _invalidateFeed,
                        onLoadMore: _loadMore,
                        filter: _filter,
                        l10n: l10n,
                      )
                    : _FeedList(
                        feedAsync: _getFilteredFeed(),
                        onRefresh: _invalidateFeed,
                        onLoadMore: _loadMore,
                        filter: _filter,
                        l10n: l10n,
                      ),
          ),
        ],
      ),
    );
  }
}

class _FollowingFeedGuard extends ConsumerWidget {
  const _FollowingFeedGuard({
    required this.onRefresh,
    required this.onLoadMore,
    required this.filter,
    required this.l10n,
  });
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final _FeedFilter filter;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(anilistTokenProvider);

    return tokenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.errorVerifyingSession)),
      data: (token) {
        if (token == null) {
          final cs = Theme.of(context).colorScheme;
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded, size: 56,
                      color: cs.onSurfaceVariant.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(
                    l10n.loginRequiredFollowing,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.login, size: 18),
                    label: Text(l10n.goToSettings),
                    onPressed: () => context.go('/settings'),
                  ),
                ],
              ),
            ),
          );
        }
        return _FeedList(
          feedAsync: ref.watch(anilistFeedFollowingProvider),
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          filter: filter,
          l10n: l10n,
        );
      },
    );
  }
}

class _FeedList extends ConsumerStatefulWidget {
  const _FeedList({
    required this.feedAsync,
    required this.onRefresh,
    required this.onLoadMore,
    required this.filter,
    required this.l10n,
  });

  final AsyncValue<List<FeedActivity>> feedAsync;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final _FeedFilter filter;
  final AppLocalizations l10n;

  @override
  ConsumerState<_FeedList> createState() => _FeedListState();
}

class _FeedListState extends ConsumerState<_FeedList> {
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
      return switch (widget.filter) {
        _FeedFilter.following =>
          ref.read(anilistFeedFollowingProvider.notifier).hasMore,
        _FeedFilter.all => ref.read(anilistFeedProvider.notifier).hasMore,
        _FeedFilter.anime =>
          ref.read(anilistFeedByTypeProvider('ANIME_LIST').notifier).hasMore,
        _FeedFilter.manga =>
          ref.read(anilistFeedByTypeProvider('MANGA_LIST').notifier).hasMore,
        _ => false,
      };
    } catch (_) {
      return false;
    }
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 300) {
      widget.onLoadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMore = _hasMore;

    return widget.feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(widget.l10n.errorNetwork),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: widget.onRefresh,
              child: Text(widget.l10n.feedRetry),
            ),
          ],
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(child: Text(widget.l10n.feedEmpty));
        }
        return RefreshIndicator(
          onRefresh: () async => widget.onRefresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: activities.length + (hasMore ? 1 : 0),
            itemBuilder: (context, i) {
              if (i >= activities.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return _ActivityCard(activity: activities[i]);
            },
          ),
        );
      },
    );
  }
}

class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({required this.activity});

  final FeedActivity activity;

  IconData _sourceIcon(MediaKind kind) => switch (kind) {
        MediaKind.anime => Icons.animation_rounded,
        MediaKind.manga => Icons.menu_book_rounded,
        MediaKind.movie => Icons.movie_rounded,
        MediaKind.tv => Icons.tv_rounded,
        MediaKind.game => Icons.sports_esports_rounded,
      };

  Color _sourceColor(MediaKind kind, ColorScheme cs) => switch (kind) {
        MediaKind.anime => cs.primary,
        MediaKind.manga => Colors.deepPurple,
        MediaKind.movie => Colors.amber.shade700,
        MediaKind.tv => Colors.teal,
        MediaKind.game => Colors.redAccent,
      };

  Future<void> _handleLike(BuildContext context, WidgetRef ref) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return;
    }
    final graphql = ref.read(anilistGraphqlProvider);
    final actId = int.tryParse(activity.id);
    if (actId == null) return;

    final isLiked = await graphql.toggleLike(actId, token);
    final updated = activity.copyWith(
      isLiked: isLiked,
      likeCount: isLiked
          ? activity.likeCount + 1
          : (activity.likeCount - 1).clamp(0, 999999),
    );

    try { ref.read(anilistFeedProvider.notifier).updateActivity(updated); } catch (_) {}
    try { ref.read(anilistFeedByTypeProvider('ANIME_LIST').notifier).updateActivity(updated); } catch (_) {}
    try { ref.read(anilistFeedByTypeProvider('MANGA_LIST').notifier).updateActivity(updated); } catch (_) {}
    try { ref.read(anilistFeedFollowingProvider.notifier).updateActivity(updated); } catch (_) {}
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (activity.mediaId != null) {
                context.push('/media/${activity.mediaId}?kind=${activity.source.code}');
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: activity.userId != null
                      ? () => context.push('/user/${activity.userId}')
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    backgroundImage: activity.userAvatarUrl != null
                        ? CachedNetworkImageProvider(activity.userAvatarUrl!)
                        : null,
                    child: activity.userAvatarUrl == null
                        ? Text(
                            activity.userName.isNotEmpty
                                ? activity.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: activity.userId != null
                                  ? () => context.push('/user/${activity.userId}')
                                  : null,
                              child: Text(
                                activity.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _sourceIcon(activity.source),
                            size: 13,
                            color: _sourceColor(activity.source, colorScheme),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _timeAgo(activity.createdAt, l10n),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      RichText(
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface,
                          ),
                          children: [
                            TextSpan(
                              text: activity.action,
                              style: TextStyle(color: colorScheme.onSurfaceVariant),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(
                              text: activity.mediaTitle,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (activity.mediaPosterUrl != null) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: activity.mediaPosterUrl!,
                      width: 45,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const SizedBox(width: 42),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => _handleLike(context, ref),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        activity.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: activity.isLiked ? Colors.red.shade400 : colorScheme.onSurfaceVariant,
                      ),
                      if (activity.likeCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('${activity.likeCount}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context.push('/activity/${activity.id}/replies'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 15, color: colorScheme.onSurfaceVariant),
                      if (activity.replyCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('${activity.replyCount}',
                            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
