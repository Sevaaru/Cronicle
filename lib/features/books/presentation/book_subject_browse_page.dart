import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

class BookSubjectBrowsePage extends ConsumerStatefulWidget {
  const BookSubjectBrowsePage({
    super.key,
    required this.subject,
    this.initialSortKey = 'popularity',
  });

  final String subject;
  final String initialSortKey;

  @override
  ConsumerState<BookSubjectBrowsePage> createState() =>
      _BookSubjectBrowsePageState();
}

class _BookSubjectBrowsePageState
    extends ConsumerState<BookSubjectBrowsePage> {
  late String _sortKey;

  @override
  void initState() {
    super.initState();
    _sortKey = _normalizeSort(widget.initialSortKey);
  }

  String _normalizeSort(String s) {
    if (s == 'score' || s == 'name') return s;
    return 'popularity';
  }

  List<Map<String, dynamic>> _sort(List<Map<String, dynamic>> items) {
    final sorted = List<Map<String, dynamic>>.from(items);
    switch (_sortKey) {
      case 'score':
        sorted.sort((a, b) {
          final sa = (a['averageScore'] as int?) ?? 0;
          final sb = (b['averageScore'] as int?) ?? 0;
          return sb.compareTo(sa);
        });
      case 'name':
        sorted.sort((a, b) {
          final na = ((a['title'] as Map?)?['english'] as String?) ?? '';
          final nb = ((b['title'] as Map?)?['english'] as String?) ?? '';
          return na.toLowerCase().compareTo(nb.toLowerCase());
        });
      default: // popularity — keep API order (already sorted by relevance)
        break;
    }
    return sorted;
  }

  Future<bool> _addToLibrary(Map<String, dynamic> item, MediaKind k) async {
    final db = ref.read(databaseProvider);
    final workKey = item['workKey'] as String? ?? item['id'].toString();
    final existing = await db.getLibraryEntryByKindAndExternalId(
      MediaKind.book.code,
      workKey,
    );
    if (!mounted) return false;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: MediaKind.book,
      existingEntry: existing,
    );
    return added;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final libraryEntries =
        ref.watch(libraryByKindProvider(MediaKind.book)).valueOrNull ?? [];
    final libraryIds = {
      for (final e in libraryEntries) e.externalId: true,
    };

    final browse = ref.watch(bookSubjectBrowseProvider(widget.subject));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.subject[0].toUpperCase() + widget.subject.substring(1),
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
              },
            ),
          ),
          Expanded(
            child: browse.when(
              loading: () => ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                children: List.generate(
                  8,
                  (_) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                                width: 100,
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
              ),
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
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(
                            bookSubjectBrowseProvider(widget.subject)),
                        child: Text(l10n.feedRetry),
                      ),
                    ],
                  ),
                ),
              ),
              data: (list) {
                final sorted = _sort(list);
                if (sorted.isEmpty) {
                  return Center(child: Text(l10n.feedBrowseEmpty));
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(
                        bookSubjectBrowseProvider(widget.subject));
                    await ref.read(
                        bookSubjectBrowseProvider(widget.subject).future);
                  },
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: sorted.length,
                    itemBuilder: (context, i) {
                      final item = sorted[i];
                      final workKey =
                          item['workKey'] as String? ?? '';
                      return BrowseResultCard(
                        item: item,
                        kind: MediaKind.book,
                        inLibrary:
                            libraryIds.containsKey(workKey),
                        onAdd: _addToLibrary,
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
