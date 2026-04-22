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
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';

const _statusKeys = [null, 'CURRENT', 'PLANNING', 'COMPLETED', 'PAUSED', 'DROPPED', 'REPEATING'];

const _statusMenuValueAll = '';

String _statusLabel(String? key, AppLocalizations l10n) => switch (key) {
  null => l10n.statusAll,
  'CURRENT' => l10n.statusCurrent,
  'PLANNING' => l10n.statusPlanning,
  'COMPLETED' => l10n.statusCompleted,
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
  'PAUSED' => Icons.pause_circle_outline,
  'DROPPED' => Icons.cancel_outlined,
  'REPEATING' => Icons.replay_rounded,
  _ => Icons.list_alt_rounded,
};

String _currentStatusLabel(String status, MediaKind? kind, AppLocalizations l10n) {
  final upper = status.toUpperCase();
  if (upper == 'CURRENT') {
    if (kind == MediaKind.manga) return l10n.statusCurrentManga;
    if (kind == MediaKind.anime) return l10n.statusCurrentAnime;
    return l10n.statusCurrent;
  }
  return switch (upper) {
    'PLANNING' => l10n.statusPlanning,
    'COMPLETED' => l10n.statusCompleted,
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

  Future<void> _openEditSheet(BuildContext context, LibraryEntry entry) async {
    final kind = MediaKind.fromCode(entry.kind);
    final item = <String, dynamic>{
      'id': int.tryParse(entry.externalId) ?? entry.externalId,
      'title': {'english': entry.title, 'romaji': entry.title},
      'coverImage': {'large': entry.posterUrl},
      if (kind == MediaKind.manga) 'chapters': entry.totalEpisodes
      else if (kind == MediaKind.book) 'pages': entry.totalEpisodes
      else 'episodes': entry.totalEpisodes,
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
      _selectedStatus = defaultFilter;
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
            _selectedKind =
                next.isVisible('all') ? null : next.firstVisibleKind;
          });
        });
      }
    });

    final visibleKindSlots = kindLayout.slots.where((s) => s.visible).toList();

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
              padding: const EdgeInsets.only(right: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.syncLoading,
                    style: TextStyle(
                      fontSize: 11,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _LibrarySearchFab(
          onTap: () => _openLibrarySearchPage(context),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 4),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemCount: visibleKindSlots.length,
              itemBuilder: (context, i) {
                final s = visibleKindSlots[i];
                if (s.id == 'all') {
                  return _buildChip(
                    label: l10n.filterAll,
                    icon: Icons.grid_view_rounded,
                    selected: _selectedKind == null,
                    onTap: () => setState(() => _selectedKind = null),
                  );
                }
                final kind = MediaKind.values.byName(s.id);
                return _buildChip(
                  label: mediaKindLabel(kind, l10n),
                  icon: _kindIcon(kind),
                  selected: _selectedKind == kind,
                  onTap: () => setState(() => _selectedKind = kind),
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
                    onChanged: (v) => setState(() => _selectedStatus = v),
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
                      setState(() {
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
                    onChanged: (m) => setState(() => _viewMode = m),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          Expanded(
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
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 84,
                                    height: 84,
                                    decoration: BoxDecoration(
                                      color: cs.secondaryContainer.withAlpha(120),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.collections_bookmark_rounded,
                                      size: 40,
                                      color: cs.onSecondaryContainer,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
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
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                          addAutomaticKeepAlives: false,
                          itemCount: entries.length + (hasMore ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= entries.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                              );
                            }
                            return _EntryCard(
                              key: ValueKey(entries[i].id),
                              entry: entries[i],
                              ref: ref,
                              selectedKind: _selectedKind,
                              onEdit: () => _openEditSheet(context, entries[i]),
                              onProgressUpdated: () {
                                ref.invalidate(paginatedLibraryProvider(_params));
                              },
                            );
                          },
                        )
                      : _LibraryMasonryGrid(
                          entries: entries,
                          hasMore: hasMore,
                          scrollController: _scrollController,
                          ref: ref,
                          onEdit: (e) => _openEditSheet(context, e),
                          onProgressUpdated: () {
                            ref.invalidate(paginatedLibraryProvider(_params));
                          },
                        ),
                );
              },
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
    return PopupMenuButton<String>(
      initialValue: _menuValueForKey(value),
      onSelected: (v) => onChanged(
        v == _statusMenuValueAll ? null : v,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      child: Material(
        color: selected ? cs.secondaryContainer : cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: selected
                ? Colors.transparent
                : cs.outlineVariant.withAlpha(80),
            width: 0.8,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: null, // PopupMenuButton handles the tap.
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
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.1,
                    color: selected ? cs.onSecondaryContainer : cs.onSurface,
                  ),
                ),
                Icon(
                  Icons.arrow_drop_down_rounded,
                  size: 18,
                  color: fg,
                ),
              ],
            ),
          ),
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
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.w500,
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
    );
  }
}

Widget _buildChip({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
  Widget? trailing,
}) {
  return Builder(
    builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return FilterChip(
        selected: selected,
        onSelected: (_) => onTap(),
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
        ),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              IconTheme(
                data: IconThemeData(
                  size: 14,
                  color: selected ? cs.onSecondaryContainer : cs.onSurfaceVariant,
                ),
                child: trailing,
              ),
            ],
          ],
        ),
        labelStyle: TextStyle(
          color: selected ? cs.onSecondaryContainer : cs.onSurface,
        ),
        selectedColor: cs.secondaryContainer,
        backgroundColor: cs.surfaceContainerHigh,
        side: BorderSide(
          color: selected
              ? Colors.transparent
              : cs.outlineVariant.withAlpha(80),
          width: 0.8,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );
    },
  );
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    super.key,
    required this.entry,
    required this.ref,
    required this.onEdit,
    required this.onProgressUpdated,
    this.selectedKind,
  });

  final LibraryEntry entry;
  final WidgetRef ref;
  final VoidCallback onEdit;
  final VoidCallback onProgressUpdated;
  final MediaKind? selectedKind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final kind = MediaKind.fromCode(entry.kind);
    final canNavigate = _libraryEntryHasDetailPage(entry);
    final showProgressButton =
        (kind == MediaKind.anime ||
            kind == MediaKind.manga ||
            kind == MediaKind.book ||
            (kind == MediaKind.tv &&
                entry.totalEpisodes != null &&
                entry.totalEpisodes! > 0)) &&
        entry.status == 'CURRENT';
    final bookProgressLabel = kind == MediaKind.book
        ? BookProgressCalculator.getShortProgressLabel(entry, l10n)
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: _LibraryEntryCardSurface(
        kind: kind,
        onTap: canNavigate ? () => _openLibraryEntryDetail(context, entry) : null,
        onLongPress: onEdit,
        progressFraction: _progressFraction(entry, kind),
        progressColor: _kindColor(kind, cs),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Edge-to-edge poster: fills the full card height, no margin.
              SizedBox(
                width: 64,
                child: entry.posterUrl != null
                    ? CachedNetworkImage(
                        imageUrl: entry.posterUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 160,
                      )
                    : ColoredBox(
                        color: _kindColor(kind, cs).withAlpha(40),
                        child: Center(
                          child: Icon(
                            _kindIcon(kind),
                            color: _kindColor(kind, cs),
                          ),
                        ),
                      ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          height: 1.25,
                          letterSpacing: 0.1,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _EntryMetaLine(
                        entry: entry,
                        kind: kind,
                        cs: cs,
                        l10n: l10n,
                        bookProgressLabel: bookProgressLabel,
                        statusColor: _statusColor(entry.status, cs),
                        statusForeground: _statusForegroundColor(entry.status, cs),
                        kindColor: _kindColor(kind, cs),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 8, 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showProgressButton) ...[
                      _IncrementButton(
                        entry: entry,
                        ref: ref,
                        onUpdated: onProgressUpdated,
                        accent: _kindColor(kind, cs),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _SquircleIconButton(
                      icon: Icons.edit_outlined,
                      tone: _SquircleTone.neutral,
                      onTap: onEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) => switch (status.toUpperCase()) {
        'CURRENT' => cs.primary,
        'COMPLETED' => cs.tertiary,
        'PLANNING' => cs.secondary,
        'DROPPED' => cs.error,
        'PAUSED' => cs.outline,
        'REPEATING' => cs.tertiary,
        _ => cs.outline,
      };

  Color _statusForegroundColor(String status, ColorScheme cs) =>
      switch (status.toUpperCase()) {
        'CURRENT' => cs.primary,
        'COMPLETED' => cs.tertiary,
        'PLANNING' => cs.secondary,
        'DROPPED' => cs.error,
        'PAUSED' => cs.onSurfaceVariant,
        'REPEATING' => cs.tertiary,
        _ => cs.onSurfaceVariant,
      };
}

/// Outlined M3 surface used by every library card. Tinted softly toward the
/// media kind color so anime / manga / movies / etc. read at a glance, with
/// an ultra-thin progress bar pinned to the bottom edge.
class _LibraryEntryCardSurface extends StatelessWidget {
  const _LibraryEntryCardSurface({
    required this.child,
    required this.kind,
    required this.onTap,
    required this.onLongPress,
    required this.progressFraction,
    required this.progressColor,
  });

  final Widget child;
  final MediaKind kind;
  final VoidCallback? onTap;
  final VoidCallback onLongPress;
  final double? progressFraction;
  final Color progressColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? cs.surfaceContainerLow : cs.surface;
    // Tint the card surface very subtly toward the kind color. Stronger in
    // light mode to compensate for the brighter base, softer in dark mode.
    final tinted = Color.alphaBlend(
      progressColor.withAlpha(isDark ? 6 : 8),
      base,
    );

    return Material(
      color: tinted,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          children: [
            child,
            if (progressFraction != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SizedBox(
                  height: 3,
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    backgroundColor: progressColor.withAlpha(40),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _SquircleTone { primary, neutral }

/// M3-style action button with squircle shape (rounded rectangle, not a full
/// circle). Used for both the increment (+) and edit pencil so the trailing
/// pair feels like a coherent toolbar instead of two floating circles.
class _SquircleIconButton extends StatelessWidget {
  const _SquircleIconButton({
    required this.icon,
    required this.onTap,
    this.tone = _SquircleTone.neutral,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final _SquircleTone tone;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disabled = onTap == null;

    final Color bg;
    final Color fg;
    if (tone == _SquircleTone.primary && !disabled) {
      bg = cs.primary.withAlpha(isDark ? 60 : 50);
      fg = cs.primary;
    } else if (disabled) {
      bg = cs.surfaceContainerHighest.withAlpha(isDark ? 120 : 180);
      fg = cs.onSurfaceVariant.withAlpha(120);
    } else {
      // Make the edit button clearly visible against the tinted card surface
      // in both light and dark mode by using a higher-contrast container.
      bg = isDark
          ? cs.surfaceContainerHighest
          : cs.secondaryContainer.withAlpha(150);
      fg = isDark ? cs.onSurface : cs.onSecondaryContainer;
    }

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Center(
            child: Icon(icon, size: 20, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Single sleek metadata line: status dot + label + progress + score.
class _EntryMetaLine extends StatelessWidget {
  const _EntryMetaLine({
    required this.entry,
    required this.kind,
    required this.cs,
    required this.l10n,
    required this.bookProgressLabel,
    required this.statusColor,
    required this.statusForeground,
    required this.kindColor,
  });

  final LibraryEntry entry;
  final MediaKind kind;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final String? bookProgressLabel;
  final Color statusColor;
  final Color statusForeground;
  final Color kindColor;

  String? _progressText() {
    if (kind == MediaKind.book &&
        bookProgressLabel != null &&
        bookProgressLabel!.isNotEmpty) {
      return bookProgressLabel;
    }
    if (entry.progress != null) {
      final epTotal = AnimeAiringProgress.displayEpisodeTotal(
        mediaKindCode: entry.kind,
        totalEpisodes: entry.totalEpisodes,
        releasedEpisodes: entry.releasedEpisodes,
      );
      if (epTotal != null) return '${entry.progress}/$epTotal';
      if (entry.totalEpisodes != null) {
        return '${entry.progress}/${entry.totalEpisodes}';
      }
      if ((entry.progress ?? 0) > 0) return '${entry.progress}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressText();
    final statusLabel = _currentStatusLabel(entry.status, kind, l10n);
    final hasScore = entry.score != null && entry.score! > 0;

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: kindColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            progress != null ? '$statusLabel  ·  $progress' : statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),
        ),
        if (hasScore) ...[
          const SizedBox(width: 8),
          Icon(Icons.star_rounded, size: 13, color: Colors.amber.shade600),
          const SizedBox(width: 2),
          Consumer(
            builder: (context, ref, _) {
              final scoring = ref.watch(scoringSystemSettingProvider);
              return Text(
                scoring.formatScore(scoring.fromStoredScore(entry.score)),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ],
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
  });
  final LibraryEntry entry;
  final WidgetRef ref;
  final VoidCallback onUpdated;
  final Color accent;
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
      tween: Tween(begin: 0.82, end: 1.18)
          .chain(CurveTween(curve: Curves.easeOutBack)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(begin: 1.18, end: 1.0)
          .chain(CurveTween(curve: Curves.easeOutCubic)),
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
      if (kind == MediaKind.book) {
        await db.incrementBookProgress(widget.entry.id);
      } else {
        await db.incrementProgress(widget.entry.id);
      }
      widget.onUpdated();
      if (kind == MediaKind.anime || kind == MediaKind.manga) {
        _syncProgressToAnilist();
      } else if (kind == MediaKind.tv) {
        final tid = int.tryParse(widget.entry.externalId);
        if (tid != null) {
          unawaited(syncTraktEntryFromLocalDatabase(widget.ref, MediaKind.tv, tid));
        }
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _syncProgressToAnilist() async {
    try {
      final token = await widget.ref.read(anilistTokenProvider.future);
      if (token == null) return;
      final mediaId = int.tryParse(widget.entry.externalId);
      if (mediaId == null) return;
      final newProgress = (widget.entry.progress ?? 0) + 1;
      final total = widget.entry.totalEpisodes;
      final completed =
          total != null && total > 0 && newProgress >= total;
      final graphql = widget.ref.read(anilistGraphqlProvider);
      await graphql.saveMediaListEntry(
        mediaId: mediaId,
        token: token,
        progress: newProgress,
        status: completed ? 'COMPLETED' : null,
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
      bg = atMax
          ? Colors.black.withAlpha(110)
          : Colors.black.withAlpha(140);
      fg = atMax ? Colors.white.withAlpha(180) : Colors.white;
    } else {
      bg = atMax
          ? cs.surfaceContainerHighest.withAlpha(isDark ? 140 : 200)
          : widget.accent.withAlpha(isDark ? 70 : 60);
      fg = atMax
          ? cs.onSurfaceVariant.withAlpha(160)
          : widget.accent;
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
                        style: TextStyle(
                          color: widget.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                              atMax
                                  ? Icons.check_rounded
                                  : Icons.add_rounded,
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
      MediaKind.tv    => const Color(0xFF26A69A), // teal
      MediaKind.game  => const Color(0xFF42A5F5), // azul
      MediaKind.book  => const Color(0xFFAB47BC), // púrpura
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

    return PopupMenuButton<_SortField>(
      initialValue: field,
      onSelected: onSelected,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      tooltip: l10n.sortRecent,
      child: Material(
        color: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: cs.outlineVariant.withAlpha(80),
            width: 0.8,
          ),
        ),
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
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: cs.outlineVariant.withAlpha(80),
            width: 0.8,
          ),
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
                isGrid
                    ? Icons.view_agenda_outlined
                    : Icons.dashboard_rounded,
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
    required this.onEdit,
    required this.onProgressUpdated,
  });

  final List<LibraryEntry> entries;
  final bool hasMore;
  final ScrollController scrollController;
  final WidgetRef ref;
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

        // Distribute into the two shortest columns.
        final columns = List.generate(_columns, (_) => <LibraryEntry>[]);
        final heights = List.filled(_columns, 0.0);
        for (final e in entries) {
          var shortest = 0;
          for (var i = 1; i < _columns; i++) {
            if (heights[i] < heights[shortest]) shortest = i;
          }
          columns[shortest].add(e);
          heights[shortest] += tileWidth * _ratioFor(e) + _gap;
        }

        return CustomScrollView(
          controller: scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                horizontalPadding,
                4,
                horizontalPadding,
                20,
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
                            for (final e in columns[c]) ...[
                              _GridEntryTile(
                                key: ValueKey(e.id),
                                entry: e,
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
    required this.ratio,
    required this.ref,
    required this.onEdit,
    required this.onProgressUpdated,
  });

  final LibraryEntry entry;
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
      child: Material(
        color: cs.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
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
              ),

              // Top-left kind dot.
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(110),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _kindIcon(kind),
                    size: 12,
                    color: Colors.white,
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
                  child: SizedBox(
                    height: 3,
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white.withAlpha(50),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibrarySearchPage extends StatefulWidget {
  const _LibrarySearchPage({
    required this.entries,
    required this.onEdit,
  });

  final List<LibraryEntry> entries;
  final Future<void> Function(LibraryEntry entry) onEdit;

  @override
  State<_LibrarySearchPage> createState() => _LibrarySearchPageState();
}

class _LibrarySearchPageState extends State<_LibrarySearchPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
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

    const bottomSafePad = 20.0;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.librarySearchTitle)),
      body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: SearchBar(
            controller: _controller,
            autoFocus: true,
            onChanged: (v) => setState(() => _query = v),
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
                        setState(() => _query = '');
                      },
                    ),
                  ]
                : null,
            elevation: WidgetStatePropertyAll(0),
            backgroundColor: WidgetStatePropertyAll(
              cs.surfaceContainerHigh,
            ),
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
                      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomSafePad),
                      children: [
                        _SearchSectionHeader(
                          icon: Icons.public_rounded,
                          title: l10n.librarySearchGlobalResults,
                        ),
                        const SizedBox(height: 6),
                        ...filtered.map((e) => _SearchEntryTile(
                              entry: e,
                              onEdit: () => widget.onEdit(e),
                            )),
                        const SizedBox(height: 12),
                        ...MediaKind.values.where(byKind.containsKey).map((kind) {
                          final items = byKind[kind]!;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SearchSectionHeader(
                                icon: _kindIcon(kind),
                                title: mediaKindLabel(kind, l10n),
                              ),
                              const SizedBox(height: 6),
                              ...items.map((e) => _SearchEntryTile(
                                    entry: e,
                                    onEdit: () => widget.onEdit(e),
                                  )),
                              const SizedBox(height: 10),
                            ],
                          );
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
  const _SearchEntryTile({
    required this.entry,
    required this.onEdit,
  });

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
          side: BorderSide(
            color: cs.outlineVariant.withAlpha(60),
            width: 0.6,
          ),
        ),
        child: ListTile(
          onTap: canNavigate ? () => _openLibraryEntryDetail(context, entry) : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                    child: Icon(_kindIcon(kind), size: 18, color: cs.onSurfaceVariant),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canNavigate)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded, size: 20),
                  onPressed: () => _openLibraryEntryDetail(context, entry),
                ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 20),
                onPressed: onEdit,
              ),
            ],
          ),
        ),
      ),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Icon(Icons.search_rounded, size: 26),
    );
  }
}
