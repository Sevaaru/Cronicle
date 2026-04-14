import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:drift/drift.dart' as drift;

enum _SearchFilter {
  all,
  anime,
  manga,
  movie,
  tv,
  game;

  String get label => switch (this) {
        _SearchFilter.all => 'Todo',
        _SearchFilter.anime => 'Anime',
        _SearchFilter.manga => 'Manga',
        _SearchFilter.movie => 'Películas',
        _SearchFilter.tv => 'Series',
        _SearchFilter.game => 'Juegos',
      };

  IconData get icon => switch (this) {
        _SearchFilter.all => Icons.search_rounded,
        _SearchFilter.anime => Icons.animation_rounded,
        _SearchFilter.manga => Icons.menu_book_rounded,
        _SearchFilter.movie => Icons.movie_rounded,
        _SearchFilter.tv => Icons.tv_rounded,
        _SearchFilter.game => Icons.sports_esports_rounded,
      };
}

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  _SearchFilter _filter = _SearchFilter.all;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _addToLibrary(Map<String, dynamic> item, MediaKind kind) async {
    final db = ref.read(databaseProvider);
    final title = item['title'] as Map<String, dynamic>? ?? {};
    final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};

    await db.upsertLibraryEntry(
      LibraryEntriesCompanion(
        kind: drift.Value(kind.code),
        externalId: drift.Value(item['id'].toString()),
        title: drift.Value(
          (title['english'] as String?) ??
              (title['romaji'] as String?) ??
              (item['name'] as String?) ??
              'Unknown',
        ),
        posterUrl: drift.Value(coverImage['large'] as String?),
        status: const drift.Value('planning'),
        totalEpisodes: drift.Value(
          (item['episodes'] as int?) ?? (item['chapters'] as int?),
        ),
        updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Añadido a la biblioteca')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Búsqueda')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Buscar...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (v) => setState(() => _query = v),
                    onSubmitted: (v) => setState(() => _query = v),
                    textInputAction: TextInputAction.search,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: _SearchFilter.values.length,
              itemBuilder: (context, i) {
                final f = _SearchFilter.values[i];
                final selected = _filter == f;
                return FilterChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 16),
                      const SizedBox(width: 4),
                      Text(f.label),
                    ],
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _query.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 56,
                            color: colorScheme.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          'Escribe para buscar',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _SearchResultsList(
                    query: _query,
                    filter: _filter,
                    onAdd: _addToLibrary,
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({
    required this.query,
    required this.filter,
    required this.onAdd,
  });

  final String query;
  final _SearchFilter filter;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Determine what to search based on filter
    final sections = <_ResultSection>[];

    if (filter == _SearchFilter.all || filter == _SearchFilter.anime) {
      sections.add(_ResultSection('Anime', MediaKind.anime,
          ref.watch(anilistSearchProvider(query, 'ANIME'))));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.manga) {
      sections.add(_ResultSection('Manga', MediaKind.manga,
          ref.watch(anilistSearchProvider(query, 'MANGA'))));
    }
    // Movie, TV, Game: stubs for now (no API connected yet)
    if (filter == _SearchFilter.movie) {
      sections.add(_ResultSection.placeholder('Películas', MediaKind.movie));
    }
    if (filter == _SearchFilter.tv) {
      sections.add(_ResultSection.placeholder('Series', MediaKind.tv));
    }
    if (filter == _SearchFilter.game) {
      sections.add(_ResultSection.placeholder('Juegos', MediaKind.game));
    }

    if (sections.isEmpty) {
      return const Center(child: Text('Selecciona un filtro'));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: sections.map((section) {
        if (section.isPlaceholder) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Column(
                children: [
                  Text(
                    section.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Próximamente — conecta TMDB / IGDB',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return section.results!.when(
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(
              children: [
                Text(section.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15)),
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Error en ${section.title}: $e'),
          ),
          data: (list) {
            if (list.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (filter == _SearchFilter.all) ...[
                  const SizedBox(height: 12),
                  Text(section.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                ],
                ...list.map((item) => _ResultCard(
                      item: item,
                      kind: section.kind,
                      onAdd: onAdd,
                    )),
              ],
            );
          },
        );
      }).toList(),
    );
  }
}

class _ResultSection {
  _ResultSection(this.title, this.kind, this.results) : isPlaceholder = false;
  _ResultSection.placeholder(this.title, this.kind)
      : results = null,
        isPlaceholder = true;

  final String title;
  final MediaKind kind;
  final AsyncValue<List<Map<String, dynamic>>>? results;
  final bool isPlaceholder;
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.item,
    required this.kind,
    required this.onAdd,
  });

  final Map<String, dynamic> item;
  final MediaKind kind;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final title = item['title'] as Map<String, dynamic>? ?? {};
    final coverImage = item['coverImage'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        (item['name'] as String?) ??
        '';
    final poster = coverImage['large'] as String?;
    final episodes = item['episodes'] as int?;
    final chapters = item['chapters'] as int?;
    final score = item['averageScore'] as int?;
    final genres =
        (item['genres'] as List?)?.cast<String>().take(3).join(', ');
    final format = item['format'] as String?;

    final bool isManga = kind == MediaKind.manga;
    final countLabel = isManga
        ? (chapters != null ? '$chapters cap' : null)
        : (episodes != null ? '$episodes ep' : null);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onAdd(item, kind),
        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(left: Radius.circular(20)),
              child: poster != null
                  ? CachedNetworkImage(
                      imageUrl: poster,
                      width: 75,
                      height: 105,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 75,
                      height: 105,
                      color: colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.image_not_supported),
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
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (format != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              format,
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onTertiaryContainer,
                              ),
                            ),
                          ),
                        if (format != null) const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            kind.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (genres != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        genres,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (countLabel != null) ...[
                          Icon(
                            isManga ? Icons.menu_book : Icons.tv,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Text(countLabel,
                              style: const TextStyle(fontSize: 11)),
                          const SizedBox(width: 10),
                        ],
                        if (score != null) ...[
                          Icon(Icons.star,
                              size: 13, color: Colors.amber.shade600),
                          const SizedBox(width: 3),
                          Text('$score%',
                              style: const TextStyle(fontSize: 11)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: IconButton(
                icon:
                    Icon(Icons.add_circle_outline, color: colorScheme.primary),
                onPressed: () => onAdd(item, kind),
                tooltip: 'Añadir a biblioteca',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
