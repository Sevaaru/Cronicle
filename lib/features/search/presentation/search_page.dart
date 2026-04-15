import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';
import 'package:cronicle/l10n/app_localizations.dart';

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
  Timer? _searchDebounce;
  /// Query passed to Anilist/IGDB providers (updated after debounce or submit).
  String _committedSearchQuery = '';
  _SearchFilter _filter = _SearchFilter.all;

  void _onSearchTextChanged() {
    _searchDebounce?.cancel();
    final text = _searchCtrl.text;
    if (text.trim().isEmpty) {
      setState(() => _committedSearchQuery = '');
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      setState(() => _committedSearchQuery = _searchCtrl.text.trim());
    });
    setState(() {});
  }

  void _flushSearchNow() {
    _searchDebounce?.cancel();
    setState(() => _committedSearchQuery = _searchCtrl.text.trim());
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
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
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchDebounce?.cancel();
                                _searchCtrl.clear();
                                setState(() => _committedSearchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (_) => _onSearchTextChanged(),
                    onSubmitted: (_) => _flushSearchNow(),
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
            child: Builder(
              builder: (context) {
                final draft = _searchCtrl.text.trim();
                final hasDraft = draft.isNotEmpty;
                final debouncePending = _searchDebounce?.isActive ?? false;
                if (!hasDraft) {
                  return _PopularContent(filter: _filter, onAdd: _addToLibrary);
                }
                if (debouncePending) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                return _SearchResultsList(
                  query: _committedSearchQuery,
                  filter: _filter,
                  onAdd: _addToLibrary,
                );
              },
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

    if (filter == _SearchFilter.movie || filter == _SearchFilter.tv) {
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

    if (filter == _SearchFilter.game) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        children: [
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: Colors.teal),
              const SizedBox(width: 6),
              Text(l10n.searchTrendingGames,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          _IgdbPopularGrid(onAdd: onAdd),
        ],
      );
    }

    final showAnime = filter == _SearchFilter.all || filter == _SearchFilter.anime;
    final showManga = filter == _SearchFilter.all || filter == _SearchFilter.manga;
    final showGames = filter == _SearchFilter.all;

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
          const SizedBox(height: 16),
        ],
        if (showGames) ...[
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 18, color: Colors.teal),
              const SizedBox(width: 6),
              Text(l10n.searchTrendingGames,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.teal)),
            ],
          ),
          const SizedBox(height: 8),
          _IgdbPopularGrid(onAdd: onAdd),
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

class _IgdbPopularGrid extends ConsumerWidget {
  const _IgdbPopularGrid({required this.onAdd});
  final Future<void> Function(Map<String, dynamic>, MediaKind) onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popularAsync = ref.watch(igdbPopularProvider);
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return popularAsync.when(
      loading: () => const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          e is IgdbWebUnsupportedException
              ? l10n.igdbWebNotSupported
              : l10n.errorWithMessage(e),
          style: TextStyle(color: cs.error),
        ),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              l10n.libraryNoResults,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          );
        }
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
              final name = (title['english'] as String?) ?? '';
              final score = item['averageScore'] as int?;
              final id = item['id'] as int?;

              return GestureDetector(
                onTap: id != null ? () => context.push('/game/$id') : null,
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
                                child: const Icon(Icons.sports_esports),
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
    if (filter == _SearchFilter.all || filter == _SearchFilter.game) {
      sections.add(_ResultSection(l10n.filterGames, MediaKind.game,
          ref.watch(igdbSearchProvider(query))));
    }
    if (filter == _SearchFilter.movie) {
      sections.add(_ResultSection.placeholder(l10n.filterMovies, MediaKind.movie));
    }
    if (filter == _SearchFilter.tv) {
      sections.add(_ResultSection.placeholder(l10n.filterTv, MediaKind.tv));
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
            child: Text(
              l10n.searchErrorIn(
                section.title,
                e is IgdbWebUnsupportedException
                    ? l10n.igdbWebNotSupported
                    : e,
              ),
            ),
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
                ...list.map((item) => BrowseResultCard(
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

