import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/core/widget/home_widget_bridge.dart';
import 'package:cronicle/features/achievements/presentation/achievements_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/domain/book_progress_calculator.dart';
import 'package:cronicle/features/library/presentation/anilist_sync_service.dart';
import 'package:cronicle/features/library/presentation/anime_library_airing_refresh.dart';
import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/library/presentation/trakt_sync_service.dart';
import 'package:cronicle/features/trakt/data/trakt_library_remote_sync.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/features/settings/presentation/library_kind_layout_notifier.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/completion_rating_dialog.dart';
import 'package:cronicle/shared/widgets/eva_style.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/signal_style.dart';

const _statusKeys = [
  null,
  'CURRENT',
  'PLANNING',
  'COMPLETED',
  'PLAYED',
  'PAUSED',
  'DROPPED',
  'REPEATING',
];

const _statusMenuValueAll = '';

String _statusLabel(String? key, AppLocalizations l10n) => switch (key) {
  null => l10n.statusAll,
  'CURRENT' => l10n.statusCurrent,
  'PLANNING' => l10n.statusPlanning,
  'COMPLETED' => l10n.statusCompleted,
  'PLAYED' => l10n.statusPlayedGame,
  'PAUSED' => l10n.statusPaused,
  'DROPPED' => l10n.statusDropped,
  'REPEATING' => l10n.statusRepeating,
  _ => key,
};

IconData _statusIcon(String? key) => switch (key) {
  null => Icons.list_alt_rounded,
  'CURRENT' => Icons.play_arrow_rounded,
  'PLANNING' => Icons.bookmark_add_outlined,
  'COMPLETED' => Icons.check_circle_outline,
  'PLAYED' => Icons.done_all_rounded,
  'PAUSED' => Icons.pause_circle_outline,
  'DROPPED' => Icons.cancel_outlined,
  'REPEATING' => Icons.replay_rounded,
  _ => Icons.list_alt_rounded,
};

String _currentStatusLabel(
  String status,
  MediaKind? kind,
  AppLocalizations l10n,
) {
  final upper = status.toUpperCase();
  if (upper == 'CURRENT') {
    if (kind == MediaKind.manga) return l10n.statusCurrentManga;
    if (kind == MediaKind.anime) return l10n.statusCurrentAnime;
    return l10n.statusCurrent;
  }
  return switch (upper) {
    'PLANNING' => l10n.statusPlanning,
    'COMPLETED' => l10n.statusCompleted,
    'PLAYED' => l10n.statusPlayedGame,
    'DROPPED' => l10n.statusDropped,
    'PAUSED' => l10n.statusPaused,
    'REPEATING' => l10n.statusRepeating,
    _ => status,
  };
}

bool _libraryEntryHasDetailPage(LibraryEntry entry) {
  if (entry.externalId.isEmpty) return false;
  final kind = MediaKind.fromCode(entry.kind);
  if (kind == MediaKind.anime || kind == MediaKind.manga) return true;
  if (kind == MediaKind.book) return true;
  if (kind == MediaKind.game) return int.tryParse(entry.externalId) != null;
  if (kind == MediaKind.movie || kind == MediaKind.tv) {
    return int.tryParse(entry.externalId) != null;
  }
  return false;
}

void _openLibraryEntryDetail(BuildContext context, LibraryEntry entry) {
  final kind = MediaKind.fromCode(entry.kind);
  if (kind == MediaKind.game) {
    // Prefer the Steam detail view when this entry was added from Steam
    if (entry.steamAppId != null) {
      context.push('/profile/steam/game/${entry.steamAppId}');
      return;
    }
    final id = int.tryParse(entry.externalId);
    if (id != null) context.push('/game/$id');
    return;
  }
  if (kind == MediaKind.movie) {
    final id = int.tryParse(entry.externalId);
    if (id != null) context.push('/trakt-movie/$id');
    return;
  }
  if (kind == MediaKind.tv) {
    final id = int.tryParse(entry.externalId);
    if (id != null) context.push('/trakt-show/$id');
    return;
  }
  if (kind == MediaKind.book) {
    context.push('/book/${entry.externalId}');
    return;
  }
  context.push('/media/${entry.externalId}?kind=${entry.kind}');
}

enum _SortField {
  updatedAt(Icons.update, 'updatedAt'),
  title(Icons.sort_by_alpha, 'title'),
  score(Icons.star_outline, 'score'),
  progress(Icons.trending_up, 'progress');

  const _SortField(this.icon, this.dbKey);
  final IconData icon;
  final String dbKey;
}

String _sortLabel(_SortField f, AppLocalizations l10n) => switch (f) {
  _SortField.updatedAt => l10n.sortRecent,
  _SortField.title => l10n.sortName,
  _SortField.score => l10n.sortScore,
  _SortField.progress => l10n.sortProgress,
};

/// Returns a small "behind N" or "next ep in Xd Yh" label for an airing
/// anime entry, or null when not applicable.
({String text, bool behind})? _animeAiringLabel(
  LibraryEntry entry,
  AppLocalizations l10n,
) {
  if (MediaKind.fromCode(entry.kind) != MediaKind.anime) return null;
  final behind = AnimeAiringProgress.episodesBehind(
    mediaKindCode: entry.kind,
    animeMediaStatus: entry.animeMediaStatus,
    releasedEpisodes: entry.releasedEpisodes,
    progress: entry.progress,
  );
  if (behind != null) {
    return (text: l10n.libraryAnimeAiringBehind(behind), behind: true);
  }
  if (!AnimeAiringProgress.isAnimeCaughtUpWithAiring(
    mediaKindCode: entry.kind,
    animeMediaStatus: entry.animeMediaStatus,
    releasedEpisodes: entry.releasedEpisodes,
    progress: entry.progress,
  )) {
    return null;
  }
  final secs = AnimeAiringProgress.secondsUntilNextEpisodeAiring(
    entry.nextEpisodeAirsAt,
  );
  if (secs == null) return null;
  final days = secs ~/ 86400;
  final hours = days == 0 ? (secs + 3599) ~/ 3600 : (secs % 86400) ~/ 3600;
  final ep = AnimeAiringProgress.nextEpisodeLabelNumber(
    mediaKindCode: entry.kind,
    releasedEpisodes: entry.releasedEpisodes,
  );
  if (ep == null) return null;
  return (text: l10n.mediaNextEp(ep, days, hours), behind: false);
}

enum _ViewMode { list, grid }

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  MediaKind? _selectedKind;
  String? _selectedStatus;
  _SortField _sortField = _SortField.updatedAt;
  bool _sortAsc = false;
  _ViewMode _viewMode = _ViewMode.list;
  bool _statusInitialized = false;
  bool _syncChecked = false;
  bool _remoteSyncing = false;

  final _scrollController = ScrollController();

  // Entry ids that already played their entrance wipe for the current
  // filter combination, so scrolling back or reordering never replays it.
  final _revealed = <int>{};

  void _updateFilters(VoidCallback change) {
    setState(() {
      change();
      _revealed.clear();
    });
  }

  ({bool play, Duration delay}) _revealFor(int entryId, int index) => (
    play: _revealed.add(entryId),
    delay: Duration(milliseconds: index < 10 ? index * 45 : 0),
  );

  LibraryPageParams get _params => LibraryPageParams(
    kindCode: _selectedKind?.code,
    status: _selectedStatus,
    orderBy: _sortField.dbKey,
    ascending: _sortAsc,
  );

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(refreshAnimeLibraryAiringMetadata(ref));
      unawaited(_silentRemoteMerge());
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    if (cur >= max - 300) {
      try {
        final notifier = ref.read(paginatedLibraryProvider(_params).notifier);
        if (notifier.hasMore && !notifier.isLoadingMore) {
          notifier.loadMore();
        }
      } catch (_) {}
    }
  }

  /// Smoothly scrolls to the top of the library list/grid after a progress
  /// increment. Pressing "+" promotes the entry to the top of the
  /// "recently updated" sort, so we follow it visually instead of leaving
  /// the user staring at the now-empty slot below.
  void _scrollToTopAfterProgress() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels <= 0.5) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _openEditSheet(BuildContext context, LibraryEntry entry) async {
    final kind = MediaKind.fromCode(entry.kind);
    final item = <String, dynamic>{
      'id': int.tryParse(entry.externalId) ?? entry.externalId,
      'title': {'english': entry.title, 'romaji': entry.title},
      'coverImage': {'large': entry.posterUrl},
      if (kind == MediaKind.manga)
        'chapters': entry.totalEpisodes
      else if (kind == MediaKind.book)
        'pages': entry.totalEpisodes
      else
        'episodes': entry.totalEpisodes,
      if (kind == MediaKind.anime) 'status': entry.animeMediaStatus,
    };

    final saved = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
      existingEntry: entry,
    );

    if (saved && mounted) {
      ref.invalidate(paginatedLibraryProvider(_params));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (!_statusInitialized) {
      final defaultFilter = ref.read(defaultLibraryFilterProvider);
      _selectedStatus = defaultFilter == 'ALL' ? null : defaultFilter;
      _statusInitialized = true;
    }

    _checkAnilistSync();

    final kindLayout = ref.watch(libraryKindLayoutProvider);
    ref.listen<LibraryKindLayoutState>(libraryKindLayoutProvider, (prev, next) {
      if (_selectedKind == null) {
        if (!next.isVisible('all')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedKind = next.firstVisibleKind);
          });
        }
      } else if (!next.isVisible(_selectedKind!.name)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _selectedKind = next.isVisible('all')
                ? null
                : next.firstVisibleKind;
          });
        });
      }
    });

    final visibleKindSlots = kindLayout.slots.where((s) => s.visible).toList();
    final pageAccent = _selectedKind == null
        ? kSignalRed
        : _kindColor(_selectedKind!, cs);

    final listAsync = ref.watch(paginatedLibraryProvider(_params));
    bool hasMore;
    try {
      hasMore = ref.read(paginatedLibraryProvider(_params).notifier).hasMore;
    } catch (_) {
      hasMore = false;
    }

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.libraryTitle, style: pageTitleStyle()),
        actions: [
          if (_remoteSyncing)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _SyncIndicatorPill(label: l10n.syncLoading, cs: cs),
            ),
          IconButton(
            icon: const Icon(Icons.search_rounded),
            tooltip: l10n.searchTitle,
            onPressed: () => _openLibrarySearchPage(context),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: visibleKindSlots.length,
              itemBuilder: (context, i) {
                final s = visibleKindSlots[i];
                if (s.id == 'all') {
                  return _SignalKindTab(
                    index: i + 1,
                    label: l10n.filterAll,
                    icon: Icons.grid_view_rounded,
                    accent: kSignalRed,
                    selected: _selectedKind == null,
                    onTap: () => _updateFilters(() => _selectedKind = null),
                  );
                }
                final kind = MediaKind.values.byName(s.id);
                return _SignalKindTab(
                  index: i + 1,
                  label: mediaKindLabel(kind, l10n),
                  icon: _kindIcon(kind),
                  accent: _kindColor(kind, cs),
                  selected: _selectedKind == kind,
                  onTap: () => _updateFilters(() => _selectedKind = kind),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: SizedBox(
              height: 36,
              child: Row(
                children: [
                  _StatusDropdown(
                    value: _selectedStatus,
                    label: _statusLabel(_selectedStatus, l10n),
                    icon: _statusIcon(_selectedStatus),
                    cs: cs,
                    onChanged: (v) => _updateFilters(() => _selectedStatus = v),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 1,
                    height: 22,
                    color: cs.outlineVariant.withAlpha(80),
                  ),
                  const SizedBox(width: 8),
                  _SortDropdown(
                    field: _sortField,
                    ascending: _sortAsc,
                    cs: cs,
                    onSelected: (field) {
                      _updateFilters(() {
                        if (_sortField == field) {
                          _sortAsc = !_sortAsc;
                        } else {
                          _sortField = field;
                          _sortAsc = field == _SortField.title;
                        }
                      });
                    },
                  ),
                  const Spacer(),
                  _ViewModeToggle(
                    mode: _viewMode,
                    onChanged: (m) => _updateFilters(() => _viewMode = m),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _LibraryBackdrop(
              accent: pageAccent,
              child: listAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
                data: (entries) {
                  if (entries.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: _pullToRefresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        SignalOutlineText(
                                          '00',
                                          fontSize: 76,
                                          color: pageAccent,
                                          strokeWidth: 1.4,
                                          letterSpacing: 2,
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          width: 10,
                                          height: 22,
                                          margin: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          color: kSignalRed,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.libraryNoResults,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface,
                                          ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _selectedStatus != null
                                          ? l10n.libraryNoStatusResults
                                          : l10n.librarySearchAndAdd,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: _pullToRefresh,
                    child: _viewMode == _ViewMode.list
                        ? ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: EdgeInsets.fromLTRB(
                              16,
                              4,
                              16,
                              MediaQuery.paddingOf(context).bottom,
                            ),
                            addAutomaticKeepAlives: false,
                            itemCount: entries.length + (hasMore ? 1 : 0),
                            itemBuilder: (context, i) {
                              if (i >= entries.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return _EntryCard(
                                key: ValueKey(entries[i].id),
                                entry: entries[i],
                                index: i + 1,
                                reveal: _revealFor(entries[i].id, i),
                                ref: ref,
                                selectedKind: _selectedKind,
                                onEdit: () =>
                                    _openEditSheet(context, entries[i]),
                                onProgressUpdated: () {
                                  ref.invalidate(
                                    paginatedLibraryProvider(_params),
                                  );
                                  _scrollToTopAfterProgress();
                                },
                              );
                            },
                          )
                        : _LibraryMasonryGrid(
                            entries: entries,
                            hasMore: hasMore,
                            scrollController: _scrollController,
                            ref: ref,
                            revealFor: _revealFor,
                            onEdit: (e) => _openEditSheet(context, e),
                            onProgressUpdated: () {
                              ref.invalidate(paginatedLibraryProvider(_params));
                              _scrollToTopAfterProgress();
                            },
                          ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openLibrarySearchPage(BuildContext context) async {
    final db = ref.read(databaseProvider);
    final all = await db.getAllLibraryEntries();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => _LibrarySearchPage(
          entries: all,
          onEdit: (entry) => _openEditSheet(context, entry),
        ),
      ),
    );
  }

  Future<void> _pullToRefresh() async {
    // User-initiated refresh: forces remote sync (delta if available) and
    // refreshes paginated query so any new/updated entries appear.
    await _silentRemoteMerge();
    if (!mounted) return;
    ref.invalidate(paginatedLibraryProvider(_params));
  }

  Future<void> _silentRemoteMerge() async {
    if (mounted) setState(() => _remoteSyncing = true);
    final db = ref.read(databaseProvider);
    var changed = false;
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final auth = ref.read(anilistAuthProvider);
      await mergeAnilistLibraryIntoLocalIfSignedIn(
        graphql: graphql,
        db: db,
        auth: auth,
        prefs: ref.read(sharedPreferencesProvider),
        force: true,
      );
      changed = true;
    } catch (_) {}
    try {
      final traktAuth = ref.read(traktAuthProvider);
      final traktApi = ref.read(traktApiProvider);
      await mergeTraktLibraryIntoLocalIfSignedIn(
        api: traktApi,
        db: db,
        getValidAccessToken: () => traktAuth.getValidAccessToken(),
      );
      changed = true;
    } catch (_) {}
    if (mounted) setState(() => _remoteSyncing = false);
    if (changed && mounted) {
      ref.invalidate(paginatedLibraryProvider);
    }
  }

  void _checkAnilistSync() {
    if (_syncChecked) return;
    _syncChecked = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final token = await ref.read(anilistTokenProvider.future);
      if (token == null || !mounted) return;

      final db = ref.read(databaseProvider);
      final synced = await db.getKeyValue('anilist_library_synced');
      if (synced != null) return;

      await db.setKeyValue('anilist_library_synced', 'true');

      if (!mounted) return;
      final graphql = ref.read(anilistGraphqlProvider);
      final didSync = await showAnilistSyncDialog(
        context: context,
        graphql: graphql,
        db: db,
        token: token,
        prefs: ref.read(sharedPreferencesProvider),
      );

      if (didSync && mounted) {
        ref.invalidate(paginatedLibraryProvider(_params));
      }
    });
  }
}

class _StatusDropdown extends StatelessWidget {
  const _StatusDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.cs,
    required this.onChanged,
  });
  final String? value;
  final String label;
  final IconData icon;
  final ColorScheme cs;
  final ValueChanged<String?> onChanged;

  String _menuValueForKey(String? key) => key ?? _statusMenuValueAll;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    final fg = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;
    // The clipped Material wraps the button so its ink stays inside the bevel.
    return Material(
      color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
      shape: signalChamfer(
        8,
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : cs.outlineVariant.withAlpha(80),
          width: 0.8,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<String>(
        initialValue: _menuValueForKey(value),
        onSelected: (v) => onChanged(v == _statusMenuValueAll ? null : v),
        shape: signalChamfer(12),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        child: Padding(
          // Match FilterChip metrics: 8h / 6v + avatar(16) + label(13).
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  letterSpacing: 0.1,
                  color: selected ? cs.onSecondaryContainer : cs.onSurface,
                ),
              ),
              Icon(Icons.arrow_drop_down_rounded, size: 18, color: fg),
            ],
          ),
        ),
        itemBuilder: (ctx) {
          final l10n = AppLocalizations.of(ctx)!;
          return _statusKeys.map((key) {
            final menuValue = _menuValueForKey(key);
            final isSelected = key == value;
            return PopupMenuItem<String>(
              value: menuValue,
              height: 48,
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? cs.tertiaryContainer
                          : cs.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _statusIcon(key),
                      size: 18,
                      color: isSelected
                          ? cs.onTertiaryContainer
                          : cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _statusLabel(key, l10n),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected ? cs.onSurface : cs.onSurface,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(Icons.check_rounded, size: 18, color: cs.tertiary),
                ],
              ),
            );
          }).toList();
        },
      ),
    );
  }
}

/// Kind tab: index + icon + uppercase label; the accent wipes in on select.
class _SignalKindTab extends StatelessWidget {
  const _SignalKindTab({
    required this.index,
    required this.label,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final String label;
  final IconData icon;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SignalSelectable(
      selected: selected,
      accent: accent,
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 0, 12, 0),
      builder: (fg) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            signalIndex(index),
            style: signalFont(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: fg.withAlpha(170),
            ),
          ),
          const SizedBox(width: 6),
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 5),
          Text(
            label.toUpperCase(),
            style: signalFont(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thin vertical grid lines behind the library list, tinted with the
/// selected kind; the tint cross-fades when the tab changes.
class _LibraryBackdrop extends StatelessWidget {
  const _LibraryBackdrop({required this.accent, required this.child});

  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(end: accent.withAlpha(26)),
            duration: const Duration(milliseconds: 300),
            builder: (_, color, _) => SignalGridBackdrop(color: color!),
          ),
        ),
        child,
      ],
    );
  }
}

/// Thin progress line with a bright head tick.
class _SignalProgressLine extends StatelessWidget {
  const _SignalProgressLine({
    required this.fraction,
    required this.color,
    required this.track,
  });

  final double fraction;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 3,
      width: double.infinity,
      child: CustomPaint(painter: _ProgressLinePainter(fraction, color, track)),
    );
  }
}

class _ProgressLinePainter extends CustomPainter {
  _ProgressLinePainter(this.fraction, this.color, this.track);

  final double fraction;
  final Color color;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = track);
    final w = size.width * fraction;
    if (w <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, size.height),
      Paint()..color = color,
    );
    if (fraction < 1) {
      canvas.drawRect(
        Rect.fromLTWH(math.max(0, w - 4), 0, 4, size.height),
        Paint()..color = Colors.white.withAlpha(220),
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressLinePainter old) =>
      old.fraction != fraction || old.color != color || old.track != track;
}

// ===========================================================================
// List entry — NERV console row: scan-lined poster with targeting brackets,
// heavy serif title, plain status readout, progress readout
// with a bar gauge, and a full-height action rail behind a hazard strip.
// ===========================================================================

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.index,
    required this.reveal,
    required this.ref,
    required this.onEdit,
    required this.onProgressUpdated,
    this.selectedKind,
  });

  static const _posterWidth = 76.0;
  static const _minHeight = 112.0;

  final LibraryEntry entry;
  final int index;
  final ({bool play, Duration delay}) reveal;
  final WidgetRef ref;
  final VoidCallback onEdit;
  final VoidCallback onProgressUpdated;
  final MediaKind? selectedKind;

  String? _progressText(AppLocalizations l10n, MediaKind kind) {
    if (kind == MediaKind.book) {
      final label = BookProgressCalculator.getShortProgressLabel(entry, l10n);
      return label.isEmpty ? null : label;
    }
    final label = AnimeAiringProgress.watchedProgressLabel(
      progress: entry.progress,
      totalEpisodes: entry.totalEpisodes,
      releasedEpisodes: entry.releasedEpisodes,
      mediaKindCode: entry.kind,
    );
    return label == '0' ? null : label;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final brightness = theme.brightness;
    final l10n = AppLocalizations.of(context)!;
    final kind = MediaKind.fromCode(entry.kind);
    final canNavigate = _libraryEntryHasDetailPage(entry);
    final status = entry.status.toUpperCase();
    final showProgressButton =
        (kind == MediaKind.anime ||
            kind == MediaKind.manga ||
            kind == MediaKind.book ||
            (kind == MediaKind.tv &&
                entry.totalEpisodes != null &&
                entry.totalEpisodes! > 0)) &&
        status == 'CURRENT';

    final accent = _kindColor(kind, cs);
    final orange = nervOrange(brightness);
    final statusColor = evaStatusColor(status, brightness);
    final panel = _LibraryEntryCardSurface.surfaceColor(context, accent);
    final progress = _progressText(l10n, kind);
    final fraction = _progressFraction(entry, kind);
    final airing = _animeAiringLabel(entry, l10n);

    final header = Row(
      children: [
        Text(
          signalIndex(index),
          style: signalFont(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: orange,
          ),
        ),
        if (selectedKind == null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '// ${mediaKindLabel(kind, l10n).toUpperCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: signalFont(
                fontSize: 9.5,
                letterSpacing: 1.4,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );

    final meta = Row(
      children: [
        Flexible(
          child: Text(
            _currentStatusLabel(entry.status, kind, l10n).toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: signalFont(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: statusColor,
            ),
          ),
        ),
        if (airing != null) ...[
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              airing.text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: signalFont(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ],
        if (entry.repeatCount > 0) ...[
          const SizedBox(width: 8),
          _RepeatCountChip(
            count: entry.repeatCount,
            color: evaStatusColor('REPEATING', brightness),
          ),
        ],
      ],
    );

    final card = _LibraryEntryCardSurface(
      color: panel,
      onTap: canNavigate ? () => _openLibraryEntryDetail(context, entry) : null,
      onLongPress: onEdit,
      child: IntrinsicHeight(
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _minHeight),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Fixed height keeps IntrinsicHeight from measuring the image,
              // whose infinite width/height reports an infinite intrinsic.
              SizedBox(
                width: _posterWidth,
                height: _minHeight,
                child: _EvaPoster(
                  entry: entry,
                  kind: kind,
                  accent: accent,
                  bracket: orange,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      header,
                      const SizedBox(height: 6),
                      Text(
                        entry.title.toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: evaTitleFont(fontSize: 15, color: cs.onSurface),
                      ),
                      const SizedBox(height: 5),
                      meta,
                      const Spacer(),
                      if (progress != null || fraction != null) ...[
                        const SizedBox(height: 6),
                        EvaGaugeRow(
                          progress: progress,
                          fraction: fraction,
                          accent: accent,
                          readout: orange,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: 60,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (showProgressButton) ...[
                      Expanded(
                        child: _IncrementButton(
                          entry: entry,
                          ref: ref,
                          onUpdated: onProgressUpdated,
                          accent: accent,
                          rail: true,
                        ),
                      ),
                      DecoratedBox(
                        decoration: evaRailFade(
                          cs.outlineVariant.withAlpha(90),
                        ),
                        child: const SizedBox(height: 1),
                      ),
                    ],
                    Expanded(
                      child: Ink(
                        decoration: evaRailFade(
                          brightness == Brightness.dark
                              ? cs.surfaceContainerHighest.withAlpha(150)
                              : cs.surfaceContainerHigh,
                        ),
                        child: InkWell(
                          onTap: onEdit,
                          child: Center(
                            child: Icon(
                              Icons.edit_sharp,
                              size: 28,
                              color: cs.onSurfaceVariant,
                            ),
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
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SignalAutoReveal(
        play: reveal.play,
        delay: reveal.delay,
        color: accent,
        shape: _LibraryEntryCardSurface.shape,
        child: card,
      ),
    );
  }
}

/// Borderless panel shared by the list rows, tinted toward the kind colour.
class _LibraryEntryCardSurface extends StatelessWidget {
  const _LibraryEntryCardSurface({
    required this.child,
    required this.color,
    required this.onTap,
    required this.onLongPress,
  });

  static final shape = signalChamfer(14, radius: 8, bevelBottomLeft: false);

  final Widget child;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;

  /// Card fill: base surface tinted very subtly toward the kind colour
  /// (stronger in light mode to compensate for the brighter base).
  static Color surfaceColor(BuildContext context, Color kindColor) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? cs.surfaceContainerLow : cs.surface;
    return Color.alphaBlend(kindColor.withAlpha(isDark ? 6 : 8), base);
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, onLongPress: onLongPress, child: child),
    );
  }
}

/// Poster with CRT scanlines, corner targeting brackets and the score hexagon.
class _EvaPoster extends StatelessWidget {
  const _EvaPoster({
    required this.entry,
    required this.kind,
    required this.accent,
    required this.bracket,
  });

  final LibraryEntry entry;
  final MediaKind kind;
  final Color accent;
  final Color bracket;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: accent.withAlpha(40),
          child: Center(child: Icon(_kindIcon(kind), color: accent)),
        ),
        if (entry.posterUrl != null && entry.posterUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: entry.posterUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 160,
            memCacheHeight: 240,
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        if (entry.score != null && entry.score! > 0)
          Positioned(
            left: 6,
            bottom: 6,
            child: _EvaScoreHex(score: entry.score!, stroke: bracket),
          ),
      ],
    );
  }
}

class _EvaScoreHex extends ConsumerWidget {
  const _EvaScoreHex({required this.score, required this.stroke});

  final int score;
  final Color stroke;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoring = ref.watch(scoringSystemSettingProvider);
    final v = scoring.fromStoredScore(score);
    final text = switch (scoring) {
      ScoringSystem.point10Decimal => v.toStringAsFixed(1),
      ScoringSystem.point3 => scoring.formatScore(v),
      _ => '${v.round()}',
    };
    return EvaHexBadge(text: text, stroke: stroke);
  }
}

/// Square-cut user score tag shown over poster art.
class _ScoreTag extends ConsumerWidget {
  const _ScoreTag({required this.score});

  final int? score;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scoring = ref.watch(scoringSystemSettingProvider);
    final scoreText = scoring.formatScore(scoring.fromStoredScore(score));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: ShapeDecoration(
        color: Colors.black.withAlpha(150),
        shape: signalChamfer(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 11, color: Colors.amber.shade400),
          const SizedBox(width: 2),
          Text(
            scoreText,
            style: signalFont(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepeatCountChip extends StatelessWidget {
  const _RepeatCountChip({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Tooltip(
      message: l10n.addToListRepeatSummary(count),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.replay_rounded, size: 11, color: color),
          const SizedBox(width: 2),
          Text(
            '×$count',
            style: signalFont(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncrementButton extends StatefulWidget {
  const _IncrementButton({
    required this.entry,
    required this.ref,
    required this.onUpdated,
    required this.accent,
    this.overlayWhite = false,
    this.rail = false,
  });
  final LibraryEntry entry;
  final WidgetRef ref;
  final VoidCallback onUpdated;
  final Color accent;

  /// Fills its parent (list action rail) with a flash instead of a burst.
  final bool rail;

  /// When true (used over poster art), forces a white icon and a translucent
  /// dark background so the button stays legible regardless of the image.
  final bool overlayWhite;

  @override
  State<_IncrementButton> createState() => _IncrementButtonState();
}

class _IncrementButtonState extends State<_IncrementButton>
    with TickerProviderStateMixin {
  bool _busy = false;

  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  );
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );
  late final AnimationController _floater = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.82), weight: 30),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.82,
        end: 1.18,
      ).chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 1.18,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 35,
    ),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    _ripple.dispose();
    _floater.dispose();
    super.dispose();
  }

  Future<void> _increment() async {
    if (_busy) return;
    HapticFeedback.lightImpact();
    // Fire visual animations immediately for snappy feedback.
    _pop
      ..reset()
      ..forward();
    _ripple
      ..reset()
      ..forward();
    _floater
      ..reset()
      ..forward();
    setState(() => _busy = true);
    try {
      final db = widget.ref.read(databaseProvider);
      final kind = MediaKind.fromCode(widget.entry.kind);
      // Snapshot whether this increment is the one that completes the entry.
      // We compute it from the in-memory entry BEFORE the increment so we
      // can fire the rating dialog right after the DB write.
      final wasCompleted = widget.entry.status.toUpperCase() == 'COMPLETED';
      final willComplete = !wasCompleted && _willCompleteWithIncrement(kind);

      if (kind == MediaKind.book) {
        await db.incrementBookProgress(widget.entry.id);
      } else {
        await db.incrementProgress(widget.entry.id);
      }
      try {
        await widget.ref
            .read(achievementsProvider.notifier)
            .bumpProgressIncrement();
      } catch (_) {}
      unawaited(HomeWidgetBridge.refresh());
      widget.onUpdated();
      if (kind == MediaKind.anime || kind == MediaKind.manga) {
        _syncProgressToAnilist();
      } else if (kind == MediaKind.tv) {
        final tid = int.tryParse(widget.entry.externalId);
        if (tid != null) {
          unawaited(
            syncTraktEntryFromLocalDatabase(widget.ref, MediaKind.tv, tid),
          );
        }
      }

      // Just finished it — prompt the user to optionally drop a score and
      // a personal note. Re-fetch the freshly-updated entry so the dialog
      // sees the new status/progress.
      if (willComplete && mounted) {
        final updated =
            await db.getLibraryEntryById(widget.entry.id) ?? widget.entry;
        if (!mounted) return;
        await showCompletionRatingDialog(
          context: context,
          ref: widget.ref,
          entry: updated,
        );
        // Reflect any score/notes change in the list.
        widget.onUpdated();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// True when the next +1 will push the entry to its known final progress
  /// and therefore mark it as COMPLETED in the local DB. Mirrors the logic
  /// inside [AppDatabase.incrementProgress] / [incrementBookProgress].
  bool _willCompleteWithIncrement(MediaKind kind) {
    final entry = widget.entry;
    if (kind == MediaKind.book) {
      final mode = (entry.bookTrackingMode ?? 'pages').toLowerCase();
      if (mode == 'chapters') {
        final total =
            entry.userTotalChaptersOverride ?? entry.totalChaptersFromApi;
        if (total == null || total <= 0) return false;
        final next = (entry.currentChapter ?? 0) + 1;
        return next >= total;
      }
      final total = mode == 'percentage'
          ? 100
          : entry.userTotalPagesOverride ??
                entry.totalPagesFromApi ??
                entry.totalEpisodes;
      if (total == null || total <= 0) return false;
      final next = (entry.progress ?? 0) + 1;
      return next >= total;
    }
    final total = entry.totalEpisodes;
    if (total == null || total <= 0) return false;
    final next = (entry.progress ?? 0) + 1;
    return next >= total;
  }

  void _syncProgressToAnilist() async {
    try {
      final token = await widget.ref.read(anilistTokenProvider.future);
      if (token == null) return;
      final mediaId = int.tryParse(widget.entry.externalId);
      if (mediaId == null) return;
      final newProgress = (widget.entry.progress ?? 0) + 1;
      final total = widget.entry.totalEpisodes;
      final completed = total != null && total > 0 && newProgress >= total;
      final saved = completed
          ? await widget.ref
                .read(databaseProvider)
                .getLibraryEntryById(widget.entry.id)
          : null;
      final graphql = widget.ref.read(anilistGraphqlProvider);
      await graphql.saveMediaListEntry(
        mediaId: mediaId,
        token: token,
        progress: newProgress,
        status: completed ? 'COMPLETED' : null,
        repeat: saved?.repeatCount,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final kind = MediaKind.fromCode(widget.entry.kind);
    final atMax = kind == MediaKind.book
        ? (() {
            final mode = BookProgressCalculator.getTrackingMode(widget.entry);
            final cap = BookProgressCalculator.getIncrementCap(widget.entry);
            if (cap == null) return false;
            final current = mode == BookTrackingMode.chapters
                ? (widget.entry.currentChapter ?? 0)
                : (widget.entry.progress ?? 0);
            return current >= cap;
          })()
        : () {
            final cap = AnimeAiringProgress.animeEpisodeProgressCap(
              mediaKindCode: widget.entry.kind,
              totalEpisodes: widget.entry.totalEpisodes,
              releasedEpisodes: widget.entry.releasedEpisodes,
            );
            if (cap != null) {
              return (widget.entry.progress ?? 0) >= cap;
            }
            return widget.entry.totalEpisodes != null &&
                (widget.entry.progress ?? 0) >= widget.entry.totalEpisodes!;
          }();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bg;
    final Color fg;
    if (widget.overlayWhite) {
      // Over poster art: glass-like dark chip with a white icon.
      bg = atMax ? Colors.black.withAlpha(110) : Colors.black.withAlpha(140);
      fg = atMax ? Colors.white.withAlpha(180) : Colors.white;
    } else {
      bg = atMax
          ? cs.surfaceContainerHighest.withAlpha(isDark ? 140 : 200)
          : widget.accent.withAlpha(isDark ? 70 : 60);
      fg = atMax ? cs.onSurfaceVariant.withAlpha(160) : widget.accent;
    }

    if (widget.rail) {
      return Tooltip(
        message: atMax ? l10n.tooltipCompleted : l10n.tooltipIncrementProgress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Ink(
              decoration: evaRailFade(bg),
              child: InkWell(
                onTap: atMax ? null : _increment,
                child: Center(
                  child: ScaleTransition(
                    scale: _scale,
                    child: _busy
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: fg,
                            ),
                          )
                        : atMax
                        ? Icon(Icons.check_sharp, size: 34, color: fg)
                        : EvaPlusIcon(color: fg, size: 32),
                  ),
                ),
              ),
            ),
            IgnorePointer(
              child: AnimatedBuilder(
                animation: Listenable.merge([_ripple, _floater]),
                builder: (_, _) {
                  final flash = _ripple.value;
                  final float = _floater.value;
                  if ((flash == 0 && float == 0) || atMax) {
                    return const SizedBox.shrink();
                  }
                  final opacity =
                      (1 -
                              Curves.easeIn.transform(
                                math.max(0, (float - 0.4) / 0.6),
                              ))
                          .clamp(0.0, 1.0);
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      DecoratedBox(
                        decoration: evaRailFade(
                          widget.accent.withAlpha(
                            ((1 - flash) * 110).round().clamp(0, 255),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment(
                          0,
                          -0.35 - 0.55 * Curves.easeOutCubic.transform(float),
                        ),
                        child: Opacity(
                          opacity: opacity,
                          child: Text(
                            '+1',
                            style: signalFont(
                              color: fg,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      );
    }

    return Tooltip(
      message: atMax ? l10n.tooltipCompleted : l10n.tooltipIncrementProgress,
      child: SizedBox(
        // Slightly oversized hit-box to host the burst overlay outside the
        // button without clipping; the visible chip stays 38x38.
        width: 38,
        height: 38,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Expanding ripple burst behind the button.
            AnimatedBuilder(
              animation: _ripple,
              builder: (_, _) {
                if (_ripple.value == 0 || atMax) {
                  return const SizedBox.shrink();
                }
                final t = _ripple.value;
                final size = 38 + 46 * Curves.easeOutCubic.transform(t);
                return IgnorePointer(
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.accent.withAlpha(
                        ((1 - t) * 80).round().clamp(0, 255),
                      ),
                    ),
                  ),
                );
              },
            ),
            // Floating "+1" badge that drifts upward and fades out.
            AnimatedBuilder(
              animation: _floater,
              builder: (_, _) {
                if (_floater.value == 0 || atMax) {
                  return const SizedBox.shrink();
                }
                final t = _floater.value;
                final dy = -28 * Curves.easeOutCubic.transform(t);
                final opacity =
                    (1 - Curves.easeIn.transform(math.max(0, (t - 0.4) / 0.6)))
                        .clamp(0.0, 1.0);
                return Positioned(
                  top: -4,
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Opacity(
                      opacity: opacity,
                      child: Text(
                        '+1',
                        style: signalFont(
                          color: widget.accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          shadows: const [
                            Shadow(
                              color: Color(0x33000000),
                              blurRadius: 4,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            // The actual button, scale-animated on tap.
            ScaleTransition(
              scale: _scale,
              child: Material(
                color: bg,
                shape: signalChamfer(8),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: atMax ? null : _increment,
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(
                      child: _busy
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: fg,
                              ),
                            )
                          : Icon(
                              atMax ? Icons.check_rounded : Icons.add_rounded,
                              size: 20,
                              color: fg,
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Returns 0..1 progress for the entry, or null when no meaningful total exists.
double? _progressFraction(LibraryEntry entry, MediaKind kind) {
  final progress = entry.progress ?? 0;
  if (kind == MediaKind.book) {
    final cap = BookProgressCalculator.getIncrementCap(entry);
    if (cap == null || cap <= 0) return null;
    final mode = BookProgressCalculator.getTrackingMode(entry);
    final current = mode == BookTrackingMode.chapters
        ? (entry.currentChapter ?? 0)
        : progress;
    return (current / cap).clamp(0.0, 1.0);
  }
  final total = entry.totalEpisodes;
  if (total == null || total <= 0) return null;
  return (progress / total).clamp(0.0, 1.0);
}

IconData _kindIcon(MediaKind kind) => switch (kind) {
  MediaKind.anime => Icons.animation_rounded,
  MediaKind.manga => Icons.menu_book_rounded,
  MediaKind.movie => Icons.movie_rounded,
  MediaKind.tv => Icons.tv_rounded,
  MediaKind.game => Icons.sports_esports_rounded,
  MediaKind.book => Icons.auto_stories_rounded,
};

/// Per-media-kind accent color used to tint the library card surface, the
/// progress bar, and the increment button so each type reads at a glance.
Color _kindColor(MediaKind kind, ColorScheme cs) => switch (kind) {
  MediaKind.anime => const Color(0xFF7C4DFF), // violeta
  MediaKind.manga => const Color(0xFFEC407A), // rosa
  MediaKind.movie => const Color(0xFFFF7043), // naranja
  MediaKind.tv => const Color(0xFF26A69A), // teal
  MediaKind.game => const Color(0xFF42A5F5), // azul
  MediaKind.book => const Color(0xFFAB47BC), // púrpura
};

// ===========================================================================
// Sort dropdown — combines all sort fields into a single popup menu and shows
// the current direction (asc/desc) as a trailing arrow. Tapping the same
// field again toggles direction.
// ===========================================================================
class _SortDropdown extends StatelessWidget {
  const _SortDropdown({
    required this.field,
    required this.ascending,
    required this.cs,
    required this.onSelected,
  });

  final _SortField field;
  final bool ascending;
  final ColorScheme cs;
  final ValueChanged<_SortField> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final fg = cs.onSurface;

    return Material(
      color: cs.surfaceContainerHigh,
      shape: signalChamfer(
        8,
        side: BorderSide(color: cs.outlineVariant.withAlpha(80), width: 0.8),
      ),
      clipBehavior: Clip.antiAlias,
      child: PopupMenuButton<_SortField>(
        initialValue: field,
        onSelected: onSelected,
        shape: signalChamfer(12),
        position: PopupMenuPosition.under,
        offset: const Offset(0, 6),
        tooltip: l10n.sortRecent,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(field.icon, size: 16, color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(
                _sortLabel(field, l10n),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                  color: fg,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                ascending
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 14,
                color: cs.onSurfaceVariant,
              ),
              Icon(
                Icons.arrow_drop_down_rounded,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
        itemBuilder: (ctx) => _SortField.values.map((f) {
          final isSelected = f == field;
          return PopupMenuItem<_SortField>(
            value: f,
            height: 44,
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? cs.tertiaryContainer
                        : cs.surfaceContainerHighest,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    f.icon,
                    size: 16,
                    color: isSelected
                        ? cs.onTertiaryContainer
                        : cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _sortLabel(f, l10n),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: cs.onSurface,
                  ),
                ),
                const Spacer(),
                if (isSelected)
                  Icon(
                    ascending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 16,
                    color: cs.tertiary,
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ===========================================================================
// View mode toggle — single squircle icon button that switches between the
// classic list and the Pinterest-style masonry grid.
// ===========================================================================
class _ViewModeToggle extends StatelessWidget {
  const _ViewModeToggle({required this.mode, required this.onChanged});

  final _ViewMode mode;
  final ValueChanged<_ViewMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isGrid = mode == _ViewMode.grid;

    return Tooltip(
      message: isGrid ? 'Vista lista' : 'Vista mosaico',
      child: Material(
        color: cs.surfaceContainerHigh,
        shape: signalChamfer(
          8,
          side: BorderSide(color: cs.outlineVariant.withAlpha(80), width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => onChanged(isGrid ? _ViewMode.list : _ViewMode.grid),
          child: SizedBox(
            width: 36,
            height: 36,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.85, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                isGrid ? Icons.view_agenda_outlined : Icons.dashboard_rounded,
                key: ValueKey(isGrid),
                size: 20,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Pinterest-style masonry grid. Uses 2 columns and assigns each entry to the
// shorter column, with deterministic varied poster aspect ratios derived from
// the entry id so it reads as dynamic but stable between rebuilds.
// ===========================================================================
class _LibraryMasonryGrid extends StatelessWidget {
  const _LibraryMasonryGrid({
    required this.entries,
    required this.hasMore,
    required this.scrollController,
    required this.ref,
    required this.revealFor,
    required this.onEdit,
    required this.onProgressUpdated,
  });

  final List<LibraryEntry> entries;
  final bool hasMore;
  final ScrollController scrollController;
  final WidgetRef ref;
  final ({bool play, Duration delay}) Function(int entryId, int index)
  revealFor;
  final ValueChanged<LibraryEntry> onEdit;
  final VoidCallback onProgressUpdated;

  static const _columns = 2;
  static const _gap = 10.0;

  /// Stable per-entry aspect ratio for the poster tile (height / width).
  /// Slight variation gives the masonry its "Pinterest" rhythm.
  double _ratioFor(LibraryEntry e) {
    final h = e.id.hashCode & 0x7fffffff;
    const ratios = [1.45, 1.55, 1.62, 1.4, 1.5, 1.7, 1.35];
    return ratios[h % ratios.length];
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 16.0;
        final available = constraints.maxWidth - horizontalPadding * 2;
        final tileWidth = (available - _gap * (_columns - 1)) / _columns;

        // Distribute into the two shortest columns, remembering list order.
        final columns = List.generate(_columns, (_) => <(int, LibraryEntry)>[]);
        final heights = List.filled(_columns, 0.0);
        for (var n = 0; n < entries.length; n++) {
          final e = entries[n];
          var shortest = 0;
          for (var i = 1; i < _columns; i++) {
            if (heights[i] < heights[shortest]) shortest = i;
          }
          columns[shortest].add((n, e));
          heights[shortest] += tileWidth * _ratioFor(e) + _gap;
        }

        return CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                MediaQuery.paddingOf(context).bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var c = 0; c < _columns; c++) ...[
                      if (c > 0) const SizedBox(width: _gap),
                      Expanded(
                        child: Column(
                          children: [
                            for (final (n, e) in columns[c]) ...[
                              _GridEntryTile(
                                key: ValueKey(e.id),
                                entry: e,
                                index: n + 1,
                                // The grid builds every tile up front, so
                                // only the first screen plays the wipe.
                                reveal: n < 12
                                    ? revealFor(e.id, n)
                                    : (play: false, delay: Duration.zero),
                                ratio: _ratioFor(e),
                                ref: ref,
                                onEdit: () => onEdit(e),
                                onProgressUpdated: onProgressUpdated,
                              ),
                              const SizedBox(height: _gap),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (hasMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _GridEntryTile extends StatelessWidget {
  const _GridEntryTile({
    super.key,
    required this.entry,
    required this.index,
    required this.reveal,
    required this.ratio,
    required this.ref,
    required this.onEdit,
    required this.onProgressUpdated,
  });

  static final shape = signalChamfer(16, radius: 8);

  final LibraryEntry entry;
  final int index;
  final ({bool play, Duration delay}) reveal;
  final double ratio;
  final WidgetRef ref;
  final VoidCallback onEdit;
  final VoidCallback onProgressUpdated;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final kind = MediaKind.fromCode(entry.kind);
    final accent = _kindColor(kind, cs);
    final canNavigate = _libraryEntryHasDetailPage(entry);
    final progress = _progressFraction(entry, kind);
    final l10n = AppLocalizations.of(context)!;
    final airing = _animeAiringLabel(entry, l10n);
    final showIncrement =
        (kind == MediaKind.anime ||
            kind == MediaKind.manga ||
            kind == MediaKind.book ||
            (kind == MediaKind.tv &&
                entry.totalEpisodes != null &&
                entry.totalEpisodes! > 0)) &&
        entry.status == 'CURRENT';

    return AspectRatio(
      aspectRatio: 1 / ratio,
      child: SignalAutoReveal(
        play: reveal.play,
        delay: reveal.delay,
        color: accent,
        shape: shape,
        child: Material(
          color: cs.surfaceContainerHighest,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: canNavigate
                ? () => _openLibraryEntryDetail(context, entry)
                : null,
            onLongPress: onEdit,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Poster fills the tile.
                if (entry.posterUrl != null)
                  CachedNetworkImage(
                    imageUrl: entry.posterUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 360,
                    memCacheHeight: 540,
                    placeholder: (_, _) =>
                        ColoredBox(color: accent.withAlpha(30)),
                    errorWidget: (_, _, _) => ColoredBox(
                      color: accent.withAlpha(40),
                      child: Center(
                        child: Icon(_kindIcon(kind), color: accent),
                      ),
                    ),
                  )
                else
                  ColoredBox(
                    color: accent.withAlpha(40),
                    child: Center(
                      child: Icon(_kindIcon(kind), color: accent, size: 36),
                    ),
                  ),

                // Bottom gradient + title for legibility.
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(10, 28, 10, 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(170),
                        ],
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          margin: const EdgeInsets.only(top: 2, right: 6),
                          color: accent,
                        ),
                        Expanded(
                          child: Text(
                            entry.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top-left hollow index + kind icon.
                Positioned(
                  top: 6,
                  left: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SignalOutlineText(
                        signalIndex(index),
                        fontSize: 24,
                        color: Colors.white.withAlpha(230),
                        strokeWidth: 1.1,
                        letterSpacing: 0.5,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: ShapeDecoration(
                          color: accent,
                          shape: signalChamfer(4),
                        ),
                        child: Icon(
                          _kindIcon(kind),
                          size: 11,
                          color: signalOnColor(accent),
                        ),
                      ),
                    ],
                  ),
                ),

                // User score chip — top-right by default. If the airing badge
                // is also visible (also top-right), the score is pushed below
                // it so they stack instead of overlapping.
                if (entry.score != null && entry.score! > 0)
                  Positioned(
                    top: airing != null ? 36 : 8,
                    right: 8,
                    child: _ScoreTag(score: entry.score),
                  ),

                // Top-right next-episode airing badge for currently airing
                // anime. Shows either "Ep N • Xd Yh" or "N atrasados".
                if (airing != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: ShapeDecoration(
                        color: airing.behind
                            ? cs.tertiaryContainer.withAlpha(235)
                            : cs.primaryContainer.withAlpha(235),
                        shape: signalChamfer(5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            airing.behind
                                ? Icons.notifications_active_rounded
                                : Icons.schedule_rounded,
                            size: 11,
                            color: airing.behind
                                ? cs.onTertiaryContainer
                                : cs.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            airing.text,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                              color: airing.behind
                                  ? cs.onTertiaryContainer
                                  : cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bottom-right increment button when applicable. Forced to a
                // white-on-translucent style so it stays visible regardless of
                // the underlying poster colors.
                if (showIncrement)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _IncrementButton(
                      entry: entry,
                      ref: ref,
                      onUpdated: onProgressUpdated,
                      accent: accent,
                      overlayWhite: true,
                    ),
                  ),

                // Bottom progress bar.
                if (progress != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _SignalProgressLine(
                      fraction: progress,
                      color: accent,
                      track: Colors.white.withAlpha(50),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LibrarySearchPage extends StatefulWidget {
  const _LibrarySearchPage({required this.entries, required this.onEdit});

  final List<LibraryEntry> entries;
  final Future<void> Function(LibraryEntry entry) onEdit;

  @override
  State<_LibrarySearchPage> createState() => _LibrarySearchPageState();
}

class _LibrarySearchPageState extends State<_LibrarySearchPage> {
  final _controller = TextEditingController();
  String _query = '';
  GoRouter? _goRouter;
  final _expanded = <MediaKind>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final router = GoRouter.of(context);
    if (_goRouter != router) {
      _goRouter?.routerDelegate.removeListener(_onGoRouterChange);
      _goRouter = router;
      router.routerDelegate.addListener(_onGoRouterChange);
    }
  }

  void _onGoRouterChange() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _goRouter?.routerDelegate.removeListener(_onGoRouterChange);
    _controller.dispose();
    super.dispose();
  }

  List<LibraryEntry> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return [];
    return widget.entries
        .where((e) => e.title.toLowerCase().contains(q))
        .toList()
      ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final filtered = _filtered;

    final byKind = <MediaKind, List<LibraryEntry>>{};
    for (final e in filtered) {
      final kind = MediaKind.fromCode(e.kind);
      byKind.putIfAbsent(kind, () => []).add(e);
    }

    const kPreview = 5;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.librarySearchTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: SearchBar(
              controller: _controller,
              autoFocus: true,
              onChanged: (v) => setState(() {
                _query = v;
                _expanded.clear();
              }),
              hintText: l10n.librarySearchHint,
              leading: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.search_rounded),
              ),
              trailing: _query.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() {
                            _query = '';
                            _expanded.clear();
                          });
                        },
                      ),
                    ]
                  : null,
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(cs.surfaceContainerHigh),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              ),
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: _query.trim().isEmpty
                ? Center(
                    child: Text(
                      l10n.librarySearchPrompt,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      l10n.libraryNoResults,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                      12,
                      0,
                      12,
                      kGlassBottomNavContentHeight + 24,
                    ),
                    children: [
                      ...MediaKind.values.where(byKind.containsKey).expand((
                        kind,
                      ) {
                        final items = byKind[kind]!;
                        final isExpanded = _expanded.contains(kind);
                        final preview = isExpanded
                            ? items
                            : items.take(kPreview).toList();
                        final hasMore = items.length > kPreview && !isExpanded;
                        final kindLabel = mediaKindLabel(kind, l10n);
                        return [
                          const SizedBox(height: 12),
                          _SearchSectionHeader(
                            icon: _kindIcon(kind),
                            title: kindLabel,
                          ),
                          const SizedBox(height: 6),
                          ...preview.map(
                            (e) => _SearchEntryTile(
                              entry: e,
                              onEdit: () => widget.onEdit(e),
                            ),
                          ),
                          if (hasMore) ...[
                            const SizedBox(height: 4),
                            _LibraryShowMoreCta(
                              label: l10n.searchShowMoreInCategory(kindLabel),
                              onTap: () => setState(() => _expanded.add(kind)),
                            ),
                          ],
                          const SizedBox(height: 4),
                        ];
                      }),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  const _SearchSectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: cs.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

class _SearchEntryTile extends StatelessWidget {
  const _SearchEntryTile({required this.entry, required this.onEdit});

  final LibraryEntry entry;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final kind = MediaKind.fromCode(entry.kind);
    final canNavigate = _libraryEntryHasDetailPage(entry);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: cs.surfaceContainerHigh,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: cs.outlineVariant.withAlpha(60), width: 0.6),
        ),
        child: ListTile(
          onTap: canNavigate
              ? () => _openLibraryEntryDetail(context, entry)
              : null,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: entry.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: entry.posterUrl!,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 40,
                    height: 56,
                    color: cs.surfaceContainerHighest,
                    child: Icon(
                      _kindIcon(kind),
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
          ),
          title: Text(
            entry.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${mediaKindLabel(kind, l10n)} · ${_currentStatusLabel(entry.status, kind, l10n)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: onEdit,
          ),
        ),
      ),
    );
  }
}

/// A modern Material 3 expressive pill that signals an in-flight library
/// sync. Uses a soft `primaryContainer` surface, a small wavy circular
/// progress indicator (M3 expressive, `year2023: false`) and a subtly
/// breathing animation so it doesn't feel like a static spinner.
class _LibraryShowMoreCta extends StatelessWidget {
  const _LibraryShowMoreCta({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.layers_outlined, size: 22, color: cs.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.15,
                    height: 1.25,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 26,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SyncIndicatorPill extends StatefulWidget {
  const _SyncIndicatorPill({required this.label, required this.cs});

  final String label;
  final ColorScheme cs;

  @override
  State<_SyncIndicatorPill> createState() => _SyncIndicatorPillState();
}

class _SyncIndicatorPillState extends State<_SyncIndicatorPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breathe;

  @override
  void initState() {
    super.initState();
    _breathe = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breathe.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    return AnimatedBuilder(
      animation: _breathe,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_breathe.value);
        final bg = Color.lerp(
          cs.primaryContainer.withAlpha(180),
          cs.primaryContainer,
          t,
        )!;
        return Container(
          padding: const EdgeInsets.fromLTRB(8, 5, 12, 5),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  // ignore: deprecated_member_use
                  year2023: false,
                  strokeWidth: 2.4,
                  strokeCap: StrokeCap.round,
                  color: cs.onPrimaryContainer,
                  backgroundColor: cs.onPrimaryContainer.withAlpha(40),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: cs.onPrimaryContainer,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LibrarySearchFab extends StatelessWidget {
  const _LibrarySearchFab({required this.onTap});
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton(
      onPressed: onTap,
      backgroundColor: cs.primaryContainer,
      foregroundColor: cs.onPrimaryContainer,
      elevation: 3,
      highlightElevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: const Icon(Icons.search_rounded, size: 26),
    );
  }
}
