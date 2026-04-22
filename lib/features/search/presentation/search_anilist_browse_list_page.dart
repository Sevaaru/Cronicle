import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

const _anilistBrowseCategoryKeys = <String>{
  'seasonal',
  'trending',
  'top_rated',
  'upcoming',
  'recently_released',
  'popularity',
  'start_date',
};

bool isValidAnilistBrowseCategory(String category) =>
    _anilistBrowseCategoryKeys.contains(category);

String searchAnilistBrowseTitle(AppLocalizations l10n, String category) =>
    switch (category) {
      'seasonal' => l10n.feedBrowseSeasonal,
      'trending' => l10n.feedBrowseTrending,
      'top_rated' => l10n.feedBrowseTopRated,
      'upcoming' => l10n.feedBrowseUpcoming,
      'recently_released' => l10n.feedBrowseRecentlyReleased,
      'popularity' => l10n.searchBrowsePopularityAllTime,
      'start_date' => l10n.searchBrowseByStartDate,
      _ => category,
    };

class SearchAnilistBrowseListPage extends ConsumerStatefulWidget {
  const SearchAnilistBrowseListPage({
    super.key,
    required this.mediaType,
    required this.category,
  });

  final String mediaType;
  final String category;

  @override
  ConsumerState<SearchAnilistBrowseListPage> createState() =>
      _SearchAnilistBrowseListPageState();
}

class _SearchAnilistBrowseListPageState
    extends ConsumerState<SearchAnilistBrowseListPage> {
  final _scrollController = ScrollController();
  var _libraryIds = <String, bool>{};

  MediaKind get _kind =>
      widget.mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;

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
    final n = ref.read(anilistBrowseMediaProvider(
      widget.mediaType,
      widget.category,
    ).notifier);
    if (!n.hasMore) return;
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      n.loadMore();
    }
  }

  Future<bool> _addToLibrary(Map<String, dynamic> item, MediaKind k) async {
    final db = ref.read(databaseProvider);
    final existing = await db.getLibraryEntryByKindAndExternalId(
      k.code,
      item['id'].toString(),
    );
    if (!mounted) return false;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: k,
      existingEntry: existing,
    );
    return added;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final libraryEntries =
        ref.watch(libraryByKindProvider(_kind)).valueOrNull ?? [];
    _libraryIds = {
      for (final e in libraryEntries) '${e.kind}:${e.externalId}': true,
    };
    final async = ref.watch(
      anilistBrowseMediaProvider(widget.mediaType, widget.category),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final hasMore = ref
        .read(anilistBrowseMediaProvider(
                widget.mediaType, widget.category)
            .notifier)
        .hasMore;
    final title = searchAnilistBrowseTitle(l10n, widget.category);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: Text(title),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off, size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(l10n.errorNetwork),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    ref.invalidate(
                      anilistBrowseMediaProvider(
                        widget.mediaType,
                        widget.category,
                      ),
                    );
                  },
                  child: Text(l10n.feedRetry),
                ),
              ],
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(child: Text(l10n.feedBrowseEmpty));
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(
                anilistBrowseMediaProvider(
                  widget.mediaType,
                  widget.category,
                ),
              );
              await ref.read(
                anilistBrowseMediaProvider(
                  widget.mediaType,
                  widget.category,
                ).future,
              );
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              itemCount: list.length + (hasMore ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= list.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                }
                final item = list[i];
                final id = item['id']?.toString() ?? '';
                final inLib = _libraryIds.containsKey('${_kind.code}:$id');
                return BrowseResultCard(
                  item: item,
                  kind: _kind,
                  inLibrary: inLib,
                  onAdd: _addToLibrary,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
