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
import 'package:cronicle/shared/widgets/glass_card.dart';

const _statusFilters = [
  (null, 'Todo', Icons.list_alt_rounded),
  ('CURRENT', 'Viendo', Icons.play_arrow_rounded),
  ('PLANNING', 'Planeado', Icons.bookmark_add_outlined),
  ('COMPLETED', 'Completado', Icons.check_circle_outline),
  ('PAUSED', 'Pausado', Icons.pause_circle_outline),
  ('DROPPED', 'Abandonado', Icons.cancel_outlined),
  ('REPEATING', 'Repitiendo', Icons.replay_rounded),
];

enum _SortField {
  updatedAt('Última actualización', Icons.update),
  title('Nombre', Icons.sort_by_alpha),
  score('Puntuación', Icons.star_outline),
  progress('Progreso', Icons.trending_up);

  const _SortField(this.label, this.icon);
  final String label;
  final IconData icon;
}

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  MediaKind? _selectedKind; // null = all
  String? _selectedStatus;
  _SortField _sortField = _SortField.updatedAt;
  bool _sortAsc = false;
  bool _statusInitialized = false;
  bool _syncChecked = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Inicializar status con el default de ajustes (una sola vez)
    if (!_statusInitialized) {
      final defaultFilter = ref.read(defaultLibraryFilterProvider);
      _selectedStatus = defaultFilter;
      _statusInitialized = true;
    }

    // Comprobar sincronización con Anilist al entrar
    _checkAnilistSync();

    final listAsync = ref.watch(libraryFilteredProvider(_selectedKind, _selectedStatus));

    return Scaffold(
      appBar: AppBar(title: const Text('Biblioteca')),
      body: Column(
        children: [
          // Media kind chips
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _KindChip(
                  label: 'Todo',
                  icon: Icons.grid_view_rounded,
                  selected: _selectedKind == null,
                  onTap: () => setState(() => _selectedKind = null),
                  cs: cs,
                ),
                const SizedBox(width: 6),
                for (final kind in MediaKind.values) ...[
                  _KindChip(
                    label: kind.label,
                    icon: _kindIcon(kind),
                    selected: _selectedKind == kind,
                    onTap: () => setState(() => _selectedKind = kind),
                    cs: cs,
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Status filters
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _statusFilters.map((f) {
                final selected = _selectedStatus == f.$1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    selected: selected,
                    label: Text(f.$2, style: const TextStyle(fontSize: 11)),
                    avatar: Icon(f.$3, size: 14),
                    onSelected: (_) => setState(() => _selectedStatus = f.$1),
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          // Sort bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.sort, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, _) => const SizedBox(width: 4),
                      itemCount: _SortField.values.length,
                      itemBuilder: (context, i) {
                        final field = _SortField.values[i];
                        final selected = _sortField == field;
                        return FilterChip(
                          selected: selected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(field.icon, size: 12),
                              const SizedBox(width: 3),
                              Text(field.label, style: const TextStyle(fontSize: 10)),
                              if (selected) ...[
                                const SizedBox(width: 2),
                                Icon(
                                  _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                                  size: 11,
                                ),
                              ],
                            ],
                          ),
                          onSelected: (_) {
                            setState(() {
                              if (_sortField == field) {
                                _sortAsc = !_sortAsc;
                              } else {
                                _sortField = field;
                                _sortAsc = field == _SortField.title;
                              }
                            });
                          },
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // List
          Expanded(
            child: listAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (entries) {
                if (entries.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inbox_rounded, size: 48,
                            color: cs.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text('Sin resultados',
                            style: TextStyle(color: cs.onSurfaceVariant)),
                        const SizedBox(height: 4),
                        Text(
                          _selectedStatus != null
                              ? 'No hay títulos con este estado'
                              : 'Busca y añade contenido',
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant.withAlpha(150)),
                        ),
                      ],
                    ),
                  );
                }
                final sorted = _sortEntries(entries);
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: sorted.length,
                  itemBuilder: (context, i) =>
                      _EntryCard(entry: sorted[i], ref: ref),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<LibraryEntry> _sortEntries(List<LibraryEntry> entries) {
    final list = [...entries];
    list.sort((a, b) {
      int cmp;
      switch (_sortField) {
        case _SortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _SortField.score:
          cmp = (a.score ?? 0).compareTo(b.score ?? 0);
        case _SortField.progress:
          cmp = (a.progress ?? 0).compareTo(b.progress ?? 0);
        case _SortField.updatedAt:
          cmp = a.updatedAt.compareTo(b.updatedAt);
      }
      return _sortAsc ? cmp : -cmp;
    });
    return list;
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
        ref.invalidate(libraryFilteredProvider(_selectedKind, _selectedStatus));
      }
    });
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.cs,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      onSelected: (_) => onTap(),
      showCheckmark: false,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.ref});

  final LibraryEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                            _statusLabel(entry.status),
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
                    if (kind != _selectedKindForCard) ...[
                      const SizedBox(height: 3),
                      Text(kind.label,
                          style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant.withAlpha(150))),
                    ],
                  ],
                ),
              ),
            ),
            if (showProgressButton)
              _IncrementButton(entry: entry, ref: ref),
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error.withAlpha(150)),
              onPressed: () => ref.read(databaseProvider).deleteLibraryEntry(entry.id),
            ),
          ],
        ),
      ),
    );
  }

  MediaKind? get _selectedKindForCard => null;

  String _statusLabel(String status) => switch (status.toUpperCase()) {
        'CURRENT' => 'Viendo',
        'PLANNING' => 'Planeado',
        'COMPLETED' => 'Completado',
        'DROPPED' => 'Abandonado',
        'PAUSED' => 'Pausado',
        'REPEATING' => 'Repitiendo',
        _ => status,
      };

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

class _IncrementButton extends StatefulWidget {
  const _IncrementButton({required this.entry, required this.ref});
  final LibraryEntry entry;
  final WidgetRef ref;

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

      // Sync con Anilist si es anime/manga
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
      tooltip: atMax ? 'Completado' : '+1 capítulo/episodio',
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
