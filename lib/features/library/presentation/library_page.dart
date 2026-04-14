import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class LibraryPage extends ConsumerWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final tabs = [
      (l10n.navAnime, MediaKind.anime, Icons.animation_rounded),
      (l10n.navManga, MediaKind.manga, Icons.menu_book_rounded),
      (l10n.navMovies, MediaKind.movie, Icons.movie_rounded),
      (l10n.navTv, MediaKind.tv, Icons.tv_rounded),
      (l10n.navGames, MediaKind.game, Icons.sports_esports_rounded),
    ];

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navLibrary),
          bottom: TabBar(
            isScrollable: false,
            tabs: tabs.map((t) => Tab(icon: Icon(t.$3), text: t.$1)).toList(),
          ),
        ),
        body: TabBarView(
          children: tabs
              .map((t) => _MediaList(kind: t.$2))
              .toList(),
        ),
      ),
    );
  }
}

class _MediaList extends ConsumerWidget {
  const _MediaList({required this.kind});

  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(libraryByKindProvider(kind));
    final colorScheme = Theme.of(context).colorScheme;

    return listAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (entries) {
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inbox_rounded,
                    size: 48, color: colorScheme.onSurfaceVariant),
                const SizedBox(height: 12),
                Text(
                  'Tu lista está vacía',
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Busca y añade contenido desde las pestañas',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          itemCount: entries.length,
          itemBuilder: (context, i) =>
              _EntryCard(entry: entries[i], ref: ref),
        );
      },
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({required this.entry, required this.ref});

  final LibraryEntry entry;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: entry.posterUrl != null
                ? CachedNetworkImage(
                    imageUrl: entry.posterUrl!,
                    width: 70,
                    height: 95,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 70,
                    height: 95,
                    color: colorScheme.surfaceContainerHighest,
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
                  Text(
                    entry.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          entry.status,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      if (entry.progress != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          entry.totalEpisodes != null
                              ? '${entry.progress}/${entry.totalEpisodes}'
                              : '${entry.progress}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () {
              ref.read(databaseProvider).deleteLibraryEntry(entry.id);
            },
          ),
        ],
      ),
    );
  }
}
