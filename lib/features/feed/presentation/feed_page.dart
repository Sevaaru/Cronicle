import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/feed/presentation/activity_feed_widgets.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/games_home_feed_view.dart';
import 'package:cronicle/features/trakt/presentation/trakt_home_feed_view.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

enum _FeedFilter {
  anime,
  manga,
  movie,
  tv,
  game;

  IconData get icon => switch (this) {
        _FeedFilter.anime => Icons.animation_rounded,
        _FeedFilter.manga => Icons.menu_book_rounded,
        _FeedFilter.movie => Icons.movie_rounded,
        _FeedFilter.tv => Icons.tv_rounded,
        _FeedFilter.game => Icons.sports_esports_rounded,
      };
}

String _filterLabel(_FeedFilter f, AppLocalizations l10n) => switch (f) {
      _FeedFilter.anime => l10n.filterAnime,
      _FeedFilter.manga => l10n.filterManga,
      _FeedFilter.movie => l10n.filterMovies,
      _FeedFilter.tv => l10n.filterTv,
      _FeedFilter.game => l10n.filterGames,
    };

enum _AnimeMangaBrowseTab {
  activity,
  seasonal,
  topRated,
  upcoming,
  recentlyReleased,
}

const _anilistBrowseCategories = [
  'seasonal',
  'top_rated',
  'upcoming',
  'recently_released',
];

String _browseCategoryApiKey(_AnimeMangaBrowseTab tab) => switch (tab) {
      _AnimeMangaBrowseTab.activity => '',
      _AnimeMangaBrowseTab.seasonal => 'seasonal',
      _AnimeMangaBrowseTab.topRated => 'top_rated',
      _AnimeMangaBrowseTab.upcoming => 'upcoming',
      _AnimeMangaBrowseTab.recentlyReleased => 'recently_released',
    };

String _browseTabLabel(_AnimeMangaBrowseTab tab, AppLocalizations l10n) =>
    switch (tab) {
      _AnimeMangaBrowseTab.activity => l10n.feedBrowseActivity,
      _AnimeMangaBrowseTab.seasonal => l10n.feedBrowseSeasonal,
      _AnimeMangaBrowseTab.topRated => l10n.feedBrowseTopRated,
      _AnimeMangaBrowseTab.upcoming => l10n.feedBrowseUpcoming,
      _AnimeMangaBrowseTab.recentlyReleased =>
        l10n.feedBrowseRecentlyReleased,
    };

const List<_AnimeMangaBrowseTab> _animeBrowseTabs = [
  _AnimeMangaBrowseTab.activity,
  _AnimeMangaBrowseTab.seasonal,
  _AnimeMangaBrowseTab.topRated,
  _AnimeMangaBrowseTab.upcoming,
  _AnimeMangaBrowseTab.recentlyReleased,
];

/// Manga no tiene temporadas en Anilist como el anime; se omite Â«De temporadaÂ».
const List<_AnimeMangaBrowseTab> _mangaBrowseTabs = [
  _AnimeMangaBrowseTab.activity,
  _AnimeMangaBrowseTab.topRated,
  _AnimeMangaBrowseTab.upcoming,
  _AnimeMangaBrowseTab.recentlyReleased,
];

List<_AnimeMangaBrowseTab> _browseTabsFor(_FeedFilter filter) =>
    filter == _FeedFilter.manga ? _mangaBrowseTabs : _animeBrowseTabs;

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  _FeedFilter _filter = _FeedFilter.anime;
  bool _filterInitialized = false;
  _AnimeMangaBrowseTab _animeMangaBrowseTab = _AnimeMangaBrowseTab.activity;

  void _invalidateFeed() {
    switch (_filter) {
      case _FeedFilter.anime:
        ref.invalidate(anilistFeedByTypeProvider('ANIME_LIST'));
        for (final c in _anilistBrowseCategories) {
          ref.invalidate(anilistBrowseMediaProvider('ANIME', c));
        }
      case _FeedFilter.manga:
        ref.invalidate(anilistFeedByTypeProvider('MANGA_LIST'));
        for (final c in _anilistBrowseCategories) {
          if (c == 'seasonal') continue;
          ref.invalidate(anilistBrowseMediaProvider('MANGA', c));
        }
      case _FeedFilter.game:
        ref.invalidate(igdbPopularProvider);
        ref.invalidate(igdbGamesHomeFeedProvider);
      case _FeedFilter.movie:
        ref.invalidate(traktMoviesHomeProvider);
      case _FeedFilter.tv:
        ref.invalidate(traktShowsHomeProvider);
    }
  }

  void _loadMore() {
    switch (_filter) {
      case _FeedFilter.anime:
        ref.read(anilistFeedByTypeProvider('ANIME_LIST').notifier).loadMore();
      case _FeedFilter.manga:
        ref.read(anilistFeedByTypeProvider('MANGA_LIST').notifier).loadMore();
      default:
        break;
    }
  }

  bool get _showAnimeMangaBrowseRail =>
      _filter == _FeedFilter.anime || _filter == _FeedFilter.manga;

  bool get _showAnilistBrowseGrid =>
      _showAnimeMangaBrowseRail &&
      _animeMangaBrowseTab != _AnimeMangaBrowseTab.activity;

  Future<void> _addToLibrary(Map<String, dynamic> item, MediaKind kind) async {
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
    );
    if (!mounted || !added) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToLibrary)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final feedLayout = ref.watch(feedFilterLayoutProvider);
    ref.listen<FeedFilterLayoutState>(feedFilterLayoutProvider, (prev, next) {
      if (!next.visibleIdSet.contains(_filter.name)) {
        final id = next.firstVisibleId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _filter = _FeedFilter.values.byName(id));
          }
        });
      }
    });

    if (!_filterInitialized) {
      final defaultTab = ref.read(defaultFeedTabProvider);
      final layout0 = ref.read(feedFilterLayoutProvider);
      _filter = _FeedFilter.values.firstWhere(
        (f) => f.name == defaultTab,
        orElse: () => _FeedFilter.anime,
      );
      if (!layout0.visibleIdSet.contains(_filter.name)) {
        _filter = _FeedFilter.values.byName(layout0.firstVisibleId);
      }
      _filterInitialized = true;
    }

    final feedFilterChips = feedLayout.visibleOrderedIds
        .map((id) => _FeedFilter.values.byName(id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const ProfileAvatarButton(),
        titleSpacing: 0,
        title: Text(l10n.feedTitle, style: pageTitleStyle()),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unread =
                  ref.watch(anilistUnreadNotificationCountProvider);
              return unread.when(
                data: (count) => IconButton(
                  tooltip: l10n.notificationsTitle,
                  onPressed: () => context.push('/notifications'),
                  icon: Badge(
                    isLabelVisible: count > 0,
                    label: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(fontSize: 10),
                    ),
                    child: const Icon(Icons.notifications_outlined),
                  ),
                ),
                loading: () => IconButton(
                  tooltip: l10n.notificationsTitle,
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
                error: (_, _) => IconButton(
                  tooltip: l10n.notificationsTitle,
                  onPressed: () => context.push('/notifications'),
                  icon: const Icon(Icons.notifications_outlined),
                ),
              );
            },
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
              itemCount: feedFilterChips.length,
              itemBuilder: (context, i) {
                final f = feedFilterChips[i];
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
                  onSelected: (_) {
                    setState(() {
                      final prev = _filter;
                      _filter = f;
                      if (prev != f &&
                          (f == _FeedFilter.anime || f == _FeedFilter.manga)) {
                        _animeMangaBrowseTab = _AnimeMangaBrowseTab.activity;
                      }
                    });
                  },
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          if (_showAnimeMangaBrowseRail) ...[
            const SizedBox(height: 4),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemCount: _browseTabsFor(_filter).length,
                itemBuilder: (context, i) {
                  final tab = _browseTabsFor(_filter)[i];
                  final selected = _animeMangaBrowseTab == tab;
                  return FilterChip(
                    selected: selected,
                    label: Text(
                      _browseTabLabel(tab, l10n),
                      style: const TextStyle(fontSize: 12),
                    ),
                    onSelected: (_) =>
                        setState(() => _animeMangaBrowseTab = tab),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: _filter == _FeedFilter.game
                ? const GamesHomeFeedView()
                : _filter == _FeedFilter.movie
                    ? const TraktHomeFeedView(kind: MediaKind.movie)
                    : _filter == _FeedFilter.tv
                        ? const TraktHomeFeedView(kind: MediaKind.tv)
                        : _showAnilistBrowseGrid
                            ? _AnimeMangaBrowseList(
                                mediaType: _filter == _FeedFilter.anime
                                    ? 'ANIME'
                                    : 'MANGA',
                                category:
                                    _browseCategoryApiKey(_animeMangaBrowseTab),
                                kind: _filter == _FeedFilter.anime
                                    ? MediaKind.anime
                                    : MediaKind.manga,
                                onRefresh: _invalidateFeed,
                                onAdd: _addToLibrary,
                                l10n: l10n,
                              )
                            : ActivityFeedList(
                                feedAsync: _filter == _FeedFilter.anime
                                    ? ref.watch(anilistFeedByTypeProvider('ANIME_LIST'))
                                    : ref.watch(anilistFeedByTypeProvider('MANGA_LIST')),
                                onRefresh: _invalidateFeed,
                                onLoadMore: _loadMore,
                                hasMore: () {
                                  try {
                                    final type = _filter == _FeedFilter.anime
                                        ? 'ANIME_LIST'
                                        : 'MANGA_LIST';
                                    return ref
                                        .read(anilistFeedByTypeProvider(type).notifier)
                                        .hasMore;
                                  } catch (_) {
                                    return false;
                                  }
                                },
                                feedIsFollowing: false,
                                feedScopeHeader: null,
                                l10n: l10n,
                              ),
          ),
        ],
      ),
    );
  }
}


class _AnimeMangaBrowseList extends ConsumerStatefulWidget {
  const _AnimeMangaBrowseList({
    required this.mediaType,
    required this.category,
    required this.kind,
    required this.onRefresh,
    required this.onAdd,
    required this.l10n,
  });

  final String mediaType;
  final String category;
  final MediaKind kind;
  final VoidCallback onRefresh;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;
  final AppLocalizations l10n;

  @override
  ConsumerState<_AnimeMangaBrowseList> createState() =>
      _AnimeMangaBrowseListState();
}

class _AnimeMangaBrowseListState extends ConsumerState<_AnimeMangaBrowseList> {
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

  void _onScroll() {
    final n = ref.read(anilistBrowseMediaProvider(
      widget.mediaType,
      widget.category,
    ).notifier);
    if (!n.hasMore) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      n.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(
      anilistBrowseMediaProvider(widget.mediaType, widget.category),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final hasMore = ref
        .read(anilistBrowseMediaProvider(widget.mediaType, widget.category)
            .notifier)
        .hasMore;

    return async.when(
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
              onPressed: () {
                ref.invalidate(
                  anilistBrowseMediaProvider(widget.mediaType, widget.category),
                );
                widget.onRefresh();
              },
              child: Text(widget.l10n.feedRetry),
            ),
          ],
        ),
      ),
      data: (list) {
        if (list.isEmpty) {
          return Center(child: Text(widget.l10n.feedBrowseEmpty));
        }
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(
              anilistBrowseMediaProvider(widget.mediaType, widget.category),
            );
            widget.onRefresh();
            await ref.read(
              anilistBrowseMediaProvider(widget.mediaType, widget.category)
                  .future,
            );
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: list.length + (hasMore ? 1 : 0),
            itemBuilder: (_, i) {
              if (i >= list.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return BrowseResultCard(
                item: list[i],
                kind: widget.kind,
                onAdd: widget.onAdd,
              );
            },
          ),
        );
      },
    );
  }
}
