import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/books/presentation/books_home_feed_view.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/games_home_feed_view.dart';
import 'package:cronicle/features/trakt/presentation/trakt_home_feed_view.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/features/feed/presentation/summary_feed_view.dart';

enum _FeedFilter {
  summary,
  anime,
  manga,
  movie,
  tv,
  game,
  book;

  IconData get icon => switch (this) {
        _FeedFilter.summary => Icons.auto_awesome_rounded,
        _FeedFilter.anime => Icons.animation_rounded,
        _FeedFilter.manga => Icons.menu_book_rounded,
        _FeedFilter.movie => Icons.movie_rounded,
        _FeedFilter.tv => Icons.tv_rounded,
        _FeedFilter.game => Icons.sports_esports_rounded,
        _FeedFilter.book => Icons.auto_stories_rounded,
      };
}

String _filterLabel(_FeedFilter f, AppLocalizations l10n) => switch (f) {
      _FeedFilter.summary => l10n.feedSummary,
      _FeedFilter.anime => l10n.filterAnime,
      _FeedFilter.manga => l10n.filterManga,
      _FeedFilter.movie => l10n.filterMovies,
      _FeedFilter.tv => l10n.filterTv,
      _FeedFilter.game => l10n.filterGames,
      _FeedFilter.book => l10n.filterBooks,
    };

enum _AnimeMangaBrowseTab {
  seasonal,
  trending,
  topRated,
  upcoming,
  recentlyReleased,
}

const _anilistBrowseCategories = [
  'seasonal',
  'trending',
  'top_rated',
  'upcoming',
  'recently_released',
];

/// Categorías de browse para manga (sin «de temporada»; la primera es tendencias).
const _mangaBrowseCategories = [
  'trending',
  'top_rated',
  'upcoming',
  'recently_released',
];

String _browseCategoryApiKey(_AnimeMangaBrowseTab tab) => switch (tab) {
      _AnimeMangaBrowseTab.seasonal => 'seasonal',
      _AnimeMangaBrowseTab.trending => 'trending',
      _AnimeMangaBrowseTab.topRated => 'top_rated',
      _AnimeMangaBrowseTab.upcoming => 'upcoming',
      _AnimeMangaBrowseTab.recentlyReleased => 'recently_released',
    };

String _browseTabLabel(_AnimeMangaBrowseTab tab, AppLocalizations l10n) =>
    switch (tab) {
      _AnimeMangaBrowseTab.seasonal => l10n.feedBrowseSeasonal,
      _AnimeMangaBrowseTab.trending => l10n.feedBrowseTrending,
      _AnimeMangaBrowseTab.topRated => l10n.feedBrowseTopRated,
      _AnimeMangaBrowseTab.upcoming => l10n.feedBrowseUpcoming,
      _AnimeMangaBrowseTab.recentlyReleased =>
        l10n.feedBrowseRecentlyReleased,
    };

const List<_AnimeMangaBrowseTab> _animeBrowseTabs = [
  _AnimeMangaBrowseTab.trending,
  _AnimeMangaBrowseTab.seasonal,
  _AnimeMangaBrowseTab.topRated,
  _AnimeMangaBrowseTab.upcoming,
  _AnimeMangaBrowseTab.recentlyReleased,
];

/// Manga: sin «De temporada»; se abre en tendencias (evita seasonal vacío).
const List<_AnimeMangaBrowseTab> _mangaBrowseTabs = [
  _AnimeMangaBrowseTab.trending,
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

class _FeedPageState extends ConsumerState<FeedPage>
    with TickerProviderStateMixin {
  _FeedFilter _filter = _FeedFilter.anime;
  bool _filterInitialized = false;
  _AnimeMangaBrowseTab _animeMangaBrowseTab = _AnimeMangaBrowseTab.trending;
  TabController? _browseTabController;

  void _invalidateFeed() {
    switch (_filter) {
      case _FeedFilter.summary:
        // Summary refreshes inside its own RefreshIndicator.
        break;
      case _FeedFilter.anime:
        ref.invalidate(anilistFeedByTypeProvider('ANIME_LIST'));
        final cat = _browseCategoryApiKey(_animeMangaBrowseTab);
        ref.invalidate(anilistBrowseMediaProvider('ANIME', cat));
      case _FeedFilter.manga:
        ref.invalidate(anilistFeedByTypeProvider('MANGA_LIST'));
        final cat = _browseCategoryApiKey(_animeMangaBrowseTab);
        ref.invalidate(anilistBrowseMediaProvider('MANGA', cat));
      case _FeedFilter.game:
        ref.invalidate(igdbPopularProvider);
        ref.invalidate(igdbGamesHomeFeedProvider);
      case _FeedFilter.movie:
        ref.invalidate(traktMoviesHomeProvider);
      case _FeedFilter.tv:
        ref.invalidate(traktShowsHomeProvider);
      case _FeedFilter.book:
        ref.invalidate(bookTrendingProvider);
    }
  }

  bool get _showAnimeMangaBrowseRail =>
      _filter == _FeedFilter.anime || _filter == _FeedFilter.manga;

  void _ensureBrowseTabController() {
    final tabs = _browseTabsFor(_filter);
    final neededLength = tabs.length;
    if (_browseTabController != null &&
        _browseTabController!.length == neededLength) {
      return;
    }
    _browseTabController?.removeListener(_onBrowseTabSwipe);
    _browseTabController?.dispose();
    final initialIndex = tabs.indexOf(_animeMangaBrowseTab).clamp(0, neededLength - 1);
    _browseTabController = TabController(
      length: neededLength,
      initialIndex: initialIndex,
      vsync: this,
    );
    _browseTabController!.addListener(_onBrowseTabSwipe);
  }

  void _onBrowseTabSwipe() {
    if (_browseTabController == null) return;
    final tabs = _browseTabsFor(_filter);
    final idx = _browseTabController!.index;
    if (idx >= 0 && idx < tabs.length && tabs[idx] != _animeMangaBrowseTab) {
      setState(() => _animeMangaBrowseTab = tabs[idx]);
    }
  }

  @override
  void dispose() {
    _browseTabController?.removeListener(_onBrowseTabSwipe);
    _browseTabController?.dispose();
    super.dispose();
  }

  Future<void> _addToLibrary(Map<String, dynamic> item, MediaKind kind) async {
    final db = ref.read(databaseProvider);
    final externalId = kind == MediaKind.book
        ? (item['workKey'] as String? ?? item['id'].toString())
        : item['id'].toString();
    final existing = await db.getLibraryEntryByKindAndExternalId(
      kind.code, externalId,
    );
    if (!mounted) return;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
      existingEntry: existing,
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
      if (_filter != _FeedFilter.summary &&
          !next.visibleIdSet.contains(_filter.name)) {
        final id = next.firstVisibleId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => _filter = _FeedFilter.values.byName(id));
          }
        });
      }
    });

    if (!_filterInitialized) {
      _filter = _FeedFilter.summary;
      _animeMangaBrowseTab = _AnimeMangaBrowseTab.trending;
      _filterInitialized = true;
    }

    final feedFilterChips = <_FeedFilter>[
      _FeedFilter.summary,
      ...feedLayout.visibleOrderedIds
          .map((id) => _FeedFilter.values.byName(id)),
    ];

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.feedTitle, style: pageTitleStyle()),
        actionsPadding: const EdgeInsets.only(right: 12),
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
                        _animeMangaBrowseTab = _AnimeMangaBrowseTab.trending;
                        // Force controller rebuild for new filter
                        _browseTabController?.removeListener(_onBrowseTabSwipe);
                        _browseTabController?.dispose();
                        _browseTabController = null;
                      }
                      if (f != _FeedFilter.anime && f != _FeedFilter.manga) {
                        _browseTabController?.removeListener(_onBrowseTabSwipe);
                        _browseTabController?.dispose();
                        _browseTabController = null;
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
            Builder(builder: (_) {
              _ensureBrowseTabController();
              final tabs = _browseTabsFor(_filter);
              return AnimatedBuilder(
                animation: _browseTabController!.animation!,
                builder: (context, _) {
                  final animValue = _browseTabController!.animation!.value;
                  return SizedBox(
                    height: 40,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemCount: tabs.length,
                      itemBuilder: (context, i) {
                        final tab = tabs[i];
                        // Progressive selection: 1.0 = fully selected, 0.0 = unselected.
                        final diff = (animValue - i).abs();
                        final t = (1.0 - diff).clamp(0.0, 1.0);
                        final cs = Theme.of(context).colorScheme;
                        final selectedBg = cs.secondaryContainer;
                        final unselectedBg = cs.surfaceContainerHighest;
                        final bg = Color.lerp(unselectedBg, selectedBg, t)!;
                        final selectedFg = cs.onSecondaryContainer;
                        final unselectedFg = cs.onSurfaceVariant;
                        final fg = Color.lerp(unselectedFg, selectedFg, t)!;
                        return GestureDetector(
                          onTap: () {
                            final idx = tabs.indexOf(tab);
                            setState(() => _animeMangaBrowseTab = tab);
                            if (_browseTabController != null && idx >= 0) {
                              _browseTabController!.animateTo(idx);
                            }
                          },
                          child: Chip(
                            label: Text(
                              _browseTabLabel(tab, l10n),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: t > 0.5
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                color: fg,
                              ),
                            ),
                            backgroundColor: bg,
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }),
          ],
          const SizedBox(height: 6),
          Expanded(
            child: _filter == _FeedFilter.summary
                ? SummaryFeedView(
                    onRefresh: _invalidateFeed,
                    onSwitchCategory: (cat) {
                      setState(() {
                        _filter = _FeedFilter.values.byName(cat);
                        if (cat == 'anime' || cat == 'manga') {
                          _animeMangaBrowseTab = _AnimeMangaBrowseTab.trending;
                          _browseTabController?.removeListener(_onBrowseTabSwipe);
                          _browseTabController?.dispose();
                          _browseTabController = null;
                        }
                      });
                    },
                  )
                : _filter == _FeedFilter.game
                ? const GamesHomeFeedView()
                : _filter == _FeedFilter.book
                    ? const BooksHomeFeedView()
                    : _filter == _FeedFilter.movie
                    ? const TraktHomeFeedView(kind: MediaKind.movie)
                    : _filter == _FeedFilter.tv
                        ? const TraktHomeFeedView(kind: MediaKind.tv)
                        : Builder(builder: (_) {
                            _ensureBrowseTabController();
                            final tabs = _browseTabsFor(_filter);
                            final mediaType = _filter == _FeedFilter.anime
                                ? 'ANIME'
                                : 'MANGA';
                            final kind = _filter == _FeedFilter.anime
                                ? MediaKind.anime
                                : MediaKind.manga;
                            return TabBarView(
                              controller: _browseTabController,
                              children: tabs.map((tab) {
                                return _AnimeMangaBrowseList(
                                  mediaType: mediaType,
                                  category: _browseCategoryApiKey(tab),
                                  kind: kind,
                                  onRefresh: _invalidateFeed,
                                  onAdd: _addToLibrary,
                                  l10n: l10n,
                                );
                              }).toList(),
                            );
                          }),
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

class _AnimeMangaBrowseListState extends ConsumerState<_AnimeMangaBrowseList>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  var _libraryIds = <String, bool>{};

  @override
  bool get wantKeepAlive => true;

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
    super.build(context);
    final libraryEntries = ref.watch(libraryByKindProvider(widget.kind)).valueOrNull ?? [];
    _libraryIds = {
      for (final e in libraryEntries) '${e.kind}:${e.externalId}': true,
    };
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
              final item = list[i];
              final id = item['id']?.toString() ?? '';
              final inLib = _libraryIds.containsKey('${widget.kind.code}:$id');
              return BrowseResultCard(
                item: item,
                kind: widget.kind,
                inLibrary: inLib,
                onAdd: widget.onAdd,
              );
            },
          ),
        );
      },
    );
  }
}
