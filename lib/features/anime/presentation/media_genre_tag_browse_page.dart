import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

class MediaGenreTagBrowsePage extends ConsumerStatefulWidget {
  const MediaGenreTagBrowsePage({
    super.key,
    required this.kind,
    this.genre,
    this.tag,
    required this.initialSortKey,
  });

  final MediaKind kind;
  final String? genre;
  final String? tag;
  final String initialSortKey;

  @override
  ConsumerState<MediaGenreTagBrowsePage> createState() =>
      _MediaGenreTagBrowsePageState();
}

class _MediaGenreTagBrowsePageState
    extends ConsumerState<MediaGenreTagBrowsePage> {
  late String _sortKey;
  late final ScrollController _scrollController;

  String get _mediaType => widget.kind == MediaKind.manga ? 'MANGA' : 'ANIME';

  String get _genrePart => widget.genre ?? '';
  String get _tagPart => widget.tag ?? '';

  @override
  void initState() {
    super.initState();
    _sortKey = _normalizeSort(widget.initialSortKey);
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  String _normalizeSort(String s) {
    if (s == 'score' || s == 'name') return s;
    return 'popularity';
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 360) return;
    ref
        .read(anilistGenreTagBrowseProvider(
          _mediaType,
          _sortKey,
          _genrePart,
          _tagPart,
        ).notifier)
        .loadMore();
  }

  Future<void> _addToLibrary(Map<String, dynamic> item, MediaKind k) async {
    await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: k,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final browse = ref.watch(
      anilistGenreTagBrowseProvider(
        _mediaType,
        _sortKey,
        _genrePart,
        _tagPart,
      ),
    );

    final titleLabel =
        widget.genre ?? widget.tag ?? l10n.mediaBrowseInvalidParams;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titleLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SegmentedButton<String>(
              style: SegmentedButton.styleFrom(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              segments: [
                ButtonSegment<String>(
                  value: 'score',
                  label: Text(l10n.mediaBrowseSortScore,
                      style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'popularity',
                  label: Text(l10n.mediaBrowseSortPopularity,
                      style: const TextStyle(fontSize: 12)),
                ),
                ButtonSegment<String>(
                  value: 'name',
                  label: Text(l10n.mediaBrowseSortName,
                      style: const TextStyle(fontSize: 12)),
                ),
              ],
              selected: {_sortKey},
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                final next = s.first;
                if (next == _sortKey) return;
                setState(() => _sortKey = next);
                if (_scrollController.hasClients) {
                  _scrollController.jumpTo(0);
                }
              },
            ),
          ),
          Expanded(
            child: browse.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.wifi_off, size: 48, color: cs.error),
                      const SizedBox(height: 12),
                      Text(l10n.errorNetwork,
                          textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('$e',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12, color: cs.onSurfaceVariant)),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.invalidate(anilistGenreTagBrowseProvider(
                            _mediaType,
                            _sortKey,
                            _genrePart,
                            _tagPart,
                          ));
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
                final hasMore = ref
                    .read(anilistGenreTagBrowseProvider(
                      _mediaType,
                      _sortKey,
                      _genrePart,
                      _tagPart,
                    ).notifier)
                    .hasMore;
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(anilistGenreTagBrowseProvider(
                      _mediaType,
                      _sortKey,
                      _genrePart,
                      _tagPart,
                    ));
                    await ref.read(anilistGenreTagBrowseProvider(
                      _mediaType,
                      _sortKey,
                      _genrePart,
                      _tagPart,
                    ).future);
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: list.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i < list.length) {
                        return BrowseResultCard(
                          item: list[i],
                          kind: widget.kind,
                          onAdd: _addToLibrary,
                        );
                      }
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        ),
                      );
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
}
