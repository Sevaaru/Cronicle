import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

enum _SearchFilter {
  all,
  anime,
  manga,
  movie,
  tv,
  game;

  IconData get icon => switch (this) {
        _SearchFilter.all => Icons.search_rounded,
        _SearchFilter.anime => Icons.animation_rounded,
        _SearchFilter.manga => Icons.menu_book_rounded,
        _SearchFilter.movie => Icons.movie_rounded,
        _SearchFilter.tv => Icons.tv_rounded,
        _SearchFilter.game => Icons.sports_esports_rounded,
      };
}

String _searchFilterLabel(_SearchFilter f, AppLocalizations l10n) => switch (f) {
  _SearchFilter.all => l10n.filterAll,
  _SearchFilter.anime => l10n.filterAnime,
  _SearchFilter.manga => l10n.filterManga,
  _SearchFilter.movie => l10n.filterMovies,
  _SearchFilter.tv => l10n.filterTv,
  _SearchFilter.game => l10n.filterGames,
};

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchTitle)),
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
                      hintText: l10n.searchHint,
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
                      Text(_searchFilterLabel(f, l10n)),
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
                ? _PopularContent(filter: _filter, onAdd: _addToLibrary)
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

class _PopularContent extends ConsumerWidget {
  const _PopularContent({required this.filter, required this.onAdd});
  final _SearchFilter filter;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (filter == _SearchFilter.movie ||
        filter == _SearchFilter.tv ||
        filter == _SearchFilter.game) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(filter.icon, size: 48, color: cs.onSurfaceVariant.withAlpha(80)),
            const SizedBox(height: 12),
            Text(l10n.searchComingSoon(_searchFilterLabel(filter, l10n)),
                style: TextStyle(color: cs.onSurfaceVariant)),
          ],
        ),
      );
    }

    final showAnime = filter == _SearchFilter.all || filter == _SearchFilter.anime;
    final showManga = filter == _SearchFilter.all || filter == _SearchFilter.manga;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        if (showAnime) ...[
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: cs.primary),
              const SizedBox(width: 6),
              Text(l10n.searchTrendingAnime,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: cs.primary)),
            ],
          ),
          const SizedBox(height: 8),
          _PopularGrid(type: 'ANIME', kind: MediaKind.anime, onAdd: onAdd),
          const SizedBox(height: 16),
        ],
        if (showManga) ...[
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: Colors.deepPurple),
              const SizedBox(width: 6),
              Text(l10n.searchTrendingManga,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.deepPurple)),
            ],
          ),
          const SizedBox(height: 8),
          _PopularGrid(type: 'MANGA', kind: MediaKind.manga, onAdd: onAdd),
        ],
      ],
    );
  }
}

class _PopularGrid extends ConsumerWidget {
  const _PopularGrid({required this.type, required this.kind, required this.onAdd});
  final String type;
  final MediaKind kind;
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(anilistPopularProvider(type));
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return popularAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(l10n.errorWithMessage(e), style: TextStyle(color: cs.error)),
      ),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 195,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              final title = item['title'] as Map<String, dynamic>? ?? {};
              final cover = (item['coverImage'] as Map?)?['large'] as String?;
              final name = (title['english'] as String?) ??
                  (title['romaji'] as String?) ?? '';
              final score = item['averageScore'] as int?;
              final id = item['id'] as int?;

              return GestureDetector(
                onTap: id != null
                    ? () => context.push('/media/$id?kind=${kind.code}')
                    : null,
                child: SizedBox(
                  width: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: cover != null
                            ? CachedNetworkImage(
                                imageUrl: cover,
                                width: 110,
                                height: 150,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 110,
                                height: 150,
                                color: cs.surfaceContainerHighest,
                                child: const Icon(Icons.image),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                      if (score != null)
                        Row(
                          children: [
                            Icon(Icons.star, size: 11, color: Colors.amber.shade600),
                            const SizedBox(width: 2),
                            Text('$score%',
                                style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
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
    final l10n = AppLocalizations.of(context)!;
    final sections = <_ResultSection>[];

    if (filter == _SearchFilter.all || filter == _SearchFilter.anime) {
      sections.add(_ResultSection(l10n.filterAnime, MediaKind.anime,
          ref.watch(anilistSearchProvider(query, 'ANIME'))));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.manga) {
      sections.add(_ResultSection(l10n.filterManga, MediaKind.manga,
          ref.watch(anilistSearchProvider(query, 'MANGA'))));
    }
    if (filter == _SearchFilter.movie) {
      sections.add(_ResultSection.placeholder(l10n.filterMovies, MediaKind.movie));
    }
    if (filter == _SearchFilter.tv) {
      sections.add(_ResultSection.placeholder(l10n.filterTv, MediaKind.tv));
    }
    if (filter == _SearchFilter.game) {
      sections.add(_ResultSection.placeholder(l10n.filterGames, MediaKind.game));
    }

    if (sections.isEmpty) {
      return Center(child: Text(l10n.searchSelectFilter));
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
                    l10n.searchComingSoonApi,
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
            child: Text(l10n.searchErrorIn(section.title, e)),
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
    final l10n = AppLocalizations.of(context)!;
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

    final itemId = item['id'] as int?;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (itemId != null) {
            context.push('/media/$itemId?kind=${kind.code}');
          }
        },
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
                            mediaKindLabel(kind, AppLocalizations.of(context)!),
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
                tooltip: l10n.addToLibrary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
