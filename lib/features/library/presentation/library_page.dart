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

class LibraryPage extends ConsumerStatefulWidget {
  const LibraryPage({super.key});

  @override
  ConsumerState<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends ConsumerState<LibraryPage> {
  MediaKind? _selectedKind; // null = all
  String? _selectedStatus;
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
          const SizedBox(height: 6),

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
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                  itemCount: entries.length,
                  itemBuilder: (context, i) =>
                      _EntryCard(entry: entries[i], ref: ref),
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
      await showAnilistSyncDialog(
        context: context,
        graphql: graphql,
        db: db,
        token: token,
      );
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
            IconButton(
              icon: Icon(Icons.delete_outline, size: 20, color: cs.error.withAlpha(150)),
              onPressed: () => ref.read(databaseProvider).deleteLibraryEntry(entry.id),
            ),
          ],
        ),
      ),
    );
  }

  // Placeholder — no aplica filtro visual extra en la card
  MediaKind? get _selectedKindForCard => null;

  String _statusLabel(String status) => switch (status) {
        'CURRENT' => 'Viendo',
        'PLANNING' => 'Planeado',
        'COMPLETED' => 'Completado',
        'DROPPED' => 'Abandonado',
        'PAUSED' => 'Pausado',
        'REPEATING' => 'Repitiendo',
        _ => status,
      };

  Color _statusColor(String status, ColorScheme cs) => switch (status) {
        'CURRENT' => cs.primaryContainer,
        'COMPLETED' => Colors.green.withAlpha(50),
        'PLANNING' => cs.tertiaryContainer,
        'DROPPED' => cs.errorContainer,
        'PAUSED' => cs.surfaceContainerHighest,
        'REPEATING' => Colors.deepPurple.withAlpha(50),
        _ => cs.surfaceContainerHighest,
      };
}

IconData _kindIcon(MediaKind kind) => switch (kind) {
      MediaKind.anime => Icons.animation_rounded,
      MediaKind.manga => Icons.menu_book_rounded,
      MediaKind.movie => Icons.movie_rounded,
      MediaKind.tv => Icons.tv_rounded,
      MediaKind.game => Icons.sports_esports_rounded,
    };
