import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/anilist_sync_service.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

const _statusKeys = [null, 'CURRENT', 'PLANNING', 'COMPLETED', 'PAUSED', 'DROPPED', 'REPEATING'];

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
  bool _statusInitialized = false;
  bool _syncChecked = false;

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
      else 'episodes': entry.totalEpisodes,
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

    final listAsync = ref.watch(paginatedLibraryProvider(_params));
    bool hasMore;
    try {
      hasMore = ref.read(paginatedLibraryProvider(_params).notifier).hasMore;
    } catch (_) {
      hasMore = false;
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.libraryTitle)),
      body: Column(
        children: [
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: MediaKind.values.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _buildChip(
                    label: l10n.filterAll,
                    icon: Icons.grid_view_rounded,
                    selected: _selectedKind == null,
                    onTap: () => setState(() => _selectedKind = null),
                  );
                }
                final kind = MediaKind.values[i - 1];
                return _buildChip(
                  label: mediaKindLabel(kind, l10n),
                  icon: _kindIcon(kind),
                  selected: _selectedKind == kind,
                  onTap: () => setState(() => _selectedKind = kind),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Status dropdown + Sort chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                // Status dropdown
                _StatusDropdown(
                  value: _selectedStatus,
                  label: _statusLabel(_selectedStatus, l10n),
                  icon: _statusIcon(_selectedStatus),
                  cs: cs,
                  onChanged: (v) => setState(() => _selectedStatus = v),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 1, height: 24,
                  color: cs.outlineVariant.withAlpha(60),
                ),
                const SizedBox(width: 8),
                // Sort chips
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, _) => const SizedBox(width: 6),
                      itemCount: _SortField.values.length,
                      itemBuilder: (context, i) {
                        final field = _SortField.values[i];
                        final selected = _sortField == field;
                        return _buildChip(
                          label: _sortLabel(field, l10n),
                          icon: field.icon,
                          selected: selected,
                          trailing: selected
                              ? Icon(
                                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 12,
                                )
                              : null,
                          onTap: () {
                            setState(() {
                              if (_sortField == field) {
                                _sortAsc = !_sortAsc;
                              } else {
                                _sortField = field;
                                _sortAsc = field == _SortField.title;
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // List
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 48,
                            color: cs.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(l10n.libraryNoResults,
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedStatus != null
                              ? l10n.libraryNoStatusResults
                              : l10n.librarySearchAndAdd,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withAlpha(150)),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                );
              },
            ),
          ),
        ],
      ),
    );
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
      );

      if (didSync && mounted) {
        ref.invalidate(paginatedLibraryProvider(_params));
      }
    });
  }
}

// ---------------------------------------------------------------------------
// Status dropdown
// ---------------------------------------------------------------------------
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

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String?>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface)),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (ctx) {
        final l10n = AppLocalizations.of(ctx)!;
        return _statusKeys.map((key) {
          final isSelected = key == value;
          return PopupMenuItem<String?>(
            value: key,
            child: Row(
              children: [
                Icon(_statusIcon(key), size: 18,
                    color: isSelected ? cs.primary : cs.onSurfaceVariant),
                const SizedBox(width: 10),
                Text(_statusLabel(key, l10n),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected ? cs.primary : cs.onSurface,
                    )),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_rounded, size: 18, color: cs.primary),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Chip builder
// ---------------------------------------------------------------------------
Widget _buildChip({
  required String label,
  required IconData icon,
  required bool selected,
  required VoidCallback onTap,
  Widget? trailing,
}) {
  return FilterChip(
    selected: selected,
    label: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        if (trailing != null) ...[
          const SizedBox(width: 3),
          trailing,
        ],
      ],
    ),
    onSelected: (_) => onTap(),
    showCheckmark: false,
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
  );
}

// ---------------------------------------------------------------------------
// Entry card
// ---------------------------------------------------------------------------
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
    final canNavigate = entry.externalId.isNotEmpty &&
        (kind == MediaKind.anime || kind == MediaKind.manga);
    final showProgressButton =
        (kind == MediaKind.anime || kind == MediaKind.manga) &&
        entry.status == 'CURRENT';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: canNavigate
            ? () => context.push('/media/${entry.externalId}?kind=${entry.kind}')
            : null,
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: entry.posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: entry.posterUrl!,
                      width: 65,
                      height: 90,
                      fit: BoxFit.cover,
                      memCacheWidth: 130,
                    )
                  : Container(
                      width: 65,
                      height: 90,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(entry.status, cs),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _currentStatusLabel(entry.status, kind, l10n),
                            style: TextStyle(fontSize: 10, color: cs.onPrimaryContainer),
                          ),
                        ),
                        if (entry.score != null && entry.score! > 0) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.star, size: 12, color: Colors.amber.shade600),
                          const SizedBox(width: 2),
                          Text('${entry.score}',
                              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                        ],
                        if (entry.progress != null) ...[
                          const SizedBox(width: 6),
                          Text(
                            entry.totalEpisodes != null
                                ? '${entry.progress}/${entry.totalEpisodes}'
                                : '${entry.progress}',
                            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                          ),
                        ],
                      ],
                    ),
                    if (selectedKind == null) ...[
                      const SizedBox(height: 3),
                      Text(mediaKindLabel(kind, l10n),
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withAlpha(150))),
                    ],
                  ],
                ),
              ),
            ),
            if (showProgressButton)
              _IncrementButton(entry: entry, ref: ref, onUpdated: onProgressUpdated),
            IconButton(
              icon: Icon(Icons.edit_outlined, size: 20, color: cs.onSurfaceVariant),
              onPressed: onEdit,
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status, ColorScheme cs) => switch (status.toUpperCase()) {
        'CURRENT' => cs.primaryContainer,
        'COMPLETED' => Colors.green.withAlpha(50),
        'PLANNING' => cs.tertiaryContainer,
        'DROPPED' => cs.errorContainer,
        'PAUSED' => cs.surfaceContainerHighest,
        'REPEATING' => Colors.deepPurple.withAlpha(50),
        _ => cs.surfaceContainerHighest,
      };
}

// ---------------------------------------------------------------------------
// Increment button
// ---------------------------------------------------------------------------
class _IncrementButton extends StatefulWidget {
  const _IncrementButton({required this.entry, required this.ref, required this.onUpdated});
  final LibraryEntry entry;
  final WidgetRef ref;
  final VoidCallback onUpdated;

  @override
  State<_IncrementButton> createState() => _IncrementButtonState();
}

class _IncrementButtonState extends State<_IncrementButton> {
  bool _busy = false;

  Future<void> _increment() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final db = widget.ref.read(databaseProvider);
      await db.incrementProgress(widget.entry.id);
      widget.onUpdated();
      final kind = MediaKind.fromCode(widget.entry.kind);
      if (kind == MediaKind.anime || kind == MediaKind.manga) {
        _syncProgressToAnilist();
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
      final graphql = widget.ref.read(anilistGraphqlProvider);
      await graphql.saveMediaListEntry(
        mediaId: mediaId,
        token: token,
        progress: newProgress,
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final atMax = widget.entry.totalEpisodes != null &&
        (widget.entry.progress ?? 0) >= widget.entry.totalEpisodes!;

    return IconButton(
      icon: _busy
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: cs.primary),
            )
          : Icon(
              Icons.add_circle_outline,
              size: 22,
              color: atMax ? cs.onSurfaceVariant.withAlpha(80) : cs.primary,
            ),
      tooltip: atMax ? l10n.tooltipCompleted : l10n.tooltipIncrementProgress,
      onPressed: atMax ? null : _increment,
    );
  }
}

IconData _kindIcon(MediaKind kind) => switch (kind) {
      MediaKind.anime => Icons.animation_rounded,
      MediaKind.manga => Icons.menu_book_rounded,
      MediaKind.movie => Icons.movie_rounded,
      MediaKind.tv => Icons.tv_rounded,
      MediaKind.game => Icons.sports_esports_rounded,
    };
