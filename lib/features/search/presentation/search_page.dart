import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/settings/presentation/search_filter_layout_notifier.dart';
import 'package:cronicle/features/search/presentation/search_category_browse_hub.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';
import 'package:cronicle/l10n/app_localizations.dart';

enum _SearchFilter {
  all,
  anime,
  manga,
  movie,
  tv,
  game,
  book;

  IconData get icon => switch (this) {
        _SearchFilter.all => Icons.search_rounded,
        _SearchFilter.anime => Icons.animation_rounded,
        _SearchFilter.manga => Icons.menu_book_rounded,
        _SearchFilter.movie => Icons.movie_rounded,
        _SearchFilter.tv => Icons.tv_rounded,
        _SearchFilter.game => Icons.sports_esports_rounded,
        _SearchFilter.book => Icons.auto_stories_rounded,
      };
}

String _searchFilterLabel(_SearchFilter f, AppLocalizations l10n) => switch (f) {
  _SearchFilter.all => l10n.filterAll,
  _SearchFilter.anime => l10n.filterAnime,
  _SearchFilter.manga => l10n.filterManga,
  _SearchFilter.movie => l10n.filterMovies,
  _SearchFilter.tv => l10n.filterTv,
  _SearchFilter.game => l10n.filterGames,
  _SearchFilter.book => l10n.filterBooks,
};

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchCtrl = TextEditingController();
  Timer? _searchDebounce;
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

  Future<bool> _addToLibrary(Map<String, dynamic> item, MediaKind kind) async {
    final db = ref.read(databaseProvider);
    final externalId = kind == MediaKind.book
        ? (item['workKey'] as String? ?? item['id'].toString())
        : item['id'].toString();
    final existing = await db.getLibraryEntryByKindAndExternalId(
      kind.code, externalId,
    );
    if (!mounted) return false;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
      existingEntry: existing,
    );
    if (!mounted || !added) return added;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToLibrary)),
    );
    return added;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final searchLayout = ref.watch(searchFilterLayoutProvider);
    final visibleFilters = _SearchFilter.values
        .where((f) => searchLayout.isVisible(f.name))
        .toList();

    if (!visibleFilters.contains(_filter)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _filter = visibleFilters.first);
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.searchTitle, style: pageTitleStyle()),
      ),
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
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: visibleFilters.length,
              itemBuilder: (context, i) {
                final f = visibleFilters[i];
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
                  return _PopularContent(filter: _filter);
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
                  onPickCategory: (f) => setState(() => _filter = f),
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
  const _PopularContent({required this.filter});
  final _SearchFilter filter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (filter == _SearchFilter.all) {
      return const _SearchIdleAllPlaceholder();
    }

    final hubMode = switch (filter) {
      _SearchFilter.anime => SearchBrowseCategoryMode.anime,
      _SearchFilter.manga => SearchBrowseCategoryMode.manga,
      _SearchFilter.movie => SearchBrowseCategoryMode.movie,
      _SearchFilter.tv => SearchBrowseCategoryMode.tv,
      _SearchFilter.game => SearchBrowseCategoryMode.game,
      _SearchFilter.book => SearchBrowseCategoryMode.book,
      _SearchFilter.all => null,
    };
    if (hubMode != null) {
      return SearchCategoryBrowseHub(mode: hubMode);
    }

    return const SizedBox.shrink();
  }
}

class _SearchIdleAllPlaceholder extends StatelessWidget {
  const _SearchIdleAllPlaceholder();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.manage_search_rounded,
                size: 56,
                color: cs.primary.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 20),
              Text(
                l10n.searchIdleAllTitle,
                textAlign: TextAlign.center,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.searchIdleAllBody,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const int _kSearchAllPreviewPerSection = 5;

class _SearchResultsList extends ConsumerWidget {
  const _SearchResultsList({
    required this.query,
    required this.filter,
    required this.onAdd,
    required this.onPickCategory,
  });

  final String query;
  final _SearchFilter filter;
  final Future<bool> Function(Map<String, dynamic>, MediaKind) onAdd;
  final void Function(_SearchFilter category) onPickCategory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sections = <_ResultSection>[];

    final libraryEntries = ref.watch(libraryAllProvider()).valueOrNull ?? [];
    final libraryIds = {
      for (final e in libraryEntries) '${e.kind}:${e.externalId}': true,
    };

    if (filter == _SearchFilter.all || filter == _SearchFilter.anime) {
      sections.add(_ResultSection(
        l10n.filterAnime,
        MediaKind.anime,
        ref.watch(anilistSearchProvider(query, 'ANIME')),
        _SearchFilter.anime,
      ));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.manga) {
      sections.add(_ResultSection(
        l10n.filterManga,
        MediaKind.manga,
        ref.watch(anilistSearchProvider(query, 'MANGA')),
        _SearchFilter.manga,
      ));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.movie) {
      sections.add(_ResultSection(
        l10n.filterMovies,
        MediaKind.movie,
        ref.watch(traktSearchMoviesProvider(query)),
        _SearchFilter.movie,
      ));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.tv) {
      sections.add(_ResultSection(
        l10n.filterTv,
        MediaKind.tv,
        ref.watch(traktSearchShowsProvider(query)),
        _SearchFilter.tv,
      ));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.game) {
      sections.add(_ResultSection(
        l10n.filterGames,
        MediaKind.game,
        ref.watch(igdbSearchProvider(query)),
        _SearchFilter.game,
      ));
    }
    if (filter == _SearchFilter.all || filter == _SearchFilter.book) {
      sections.add(_ResultSection(
        l10n.filterBooks,
        MediaKind.book,
        ref.watch(bookSearchProvider(query)),
        _SearchFilter.book,
      ));
    }

    if (sections.isEmpty) {
      return Center(child: Text(l10n.searchSelectFilter));
    }

    final layout = ref.watch(searchFilterLayoutProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: sections.map((section) {
        return section.results.when(
          loading: () =>
              _SearchSectionLoadingPlaceholder(title: section.title),
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
            final isAll = filter == _SearchFilter.all;
            final preview = isAll
                ? list.take(_kSearchAllPreviewPerSection).toList()
                : list;
            final hasMoreInAll =
                isAll && list.length > _kSearchAllPreviewPerSection;
            final canOpenCategoryTab =
                layout.isVisible(section.targetFilter.name);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isAll) ...[
                  const SizedBox(height: 12),
                  Text(section.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 8),
                ],
                ...preview.map((item) {
                  final id = item['id']?.toString() ?? '';
                  final inLib = libraryIds.containsKey('${section.kind.code}:$id');
                  return BrowseResultCard(
                    item: item,
                    kind: section.kind,
                    inLibrary: inLib,
                    onAdd: onAdd,
                  );
                }),
                if (hasMoreInAll && canOpenCategoryTab) ...[
                  const SizedBox(height: 10),
                  _SearchShowMoreMaterialCta(
                    label: l10n.searchShowMoreInCategory(section.title),
                    onTap: () => onPickCategory(section.targetFilter),
                  ),
                ],
              ],
            );
          },
        );
      }).toList(),
    );
  }
}

class _SearchShowMoreMaterialCta extends StatelessWidget {
  const _SearchShowMoreMaterialCta({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

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
              Icon(
                Icons.layers_outlined,
                size: 22,
                color: cs.primary,
              ),
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

class _ResultSection {
  _ResultSection(this.title, this.kind, this.results, this.targetFilter);

  final String title;
  final MediaKind kind;
  final AsyncValue<List<Map<String, dynamic>>> results;
  final _SearchFilter targetFilter;
}

class _SearchSectionLoadingPlaceholder extends StatelessWidget {
  const _SearchSectionLoadingPlaceholder({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 64,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

