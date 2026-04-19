import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/books/presentation/books_home_feed_view.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

/// Full list page for a book category (`/books/section/:slug`).
class BooksHomeSectionListPage extends ConsumerWidget {
  const BooksHomeSectionListPage({super.key, required this.slug});

  final String slug;

  Future<void> _addToLibrary(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final db = ref.read(databaseProvider);
    final workKey = item['workKey'] as String? ?? '';
    final existing = await db.getLibraryEntryByKindAndExternalId(
      MediaKind.book.code,
      workKey,
    );
    if (!context.mounted) return;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: MediaKind.book,
      existingEntry: existing,
    );
    if (!context.mounted || !added) return;
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.addedToLibrary)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final title = booksHomeSectionTitle(l10n, slug);
    final valid = BookFeedSection.isValid(slug);

    AsyncValue<List<Map<String, dynamic>>>? async;
    if (valid) {
      if (slug == BookFeedSection.trending) {
        async = ref.watch(bookTrendingProvider);
      } else {
        async = ref.watch(bookSubjectProvider(slug));
      }
    }

    final libraryEntries =
        ref.watch(libraryByKindProvider(MediaKind.book)).valueOrNull ?? [];
    final libraryIds = {
      for (final e in libraryEntries) e.externalId: true,
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: !valid
          ? Center(child: Text(l10n.profileLibraryEmpty))
          : async!.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('$e', textAlign: TextAlign.center),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.profileLibraryEmpty));
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final workKey = item['workKey'] as String? ?? '';
                    final inLib = libraryIds.containsKey(workKey);
                    return BrowseResultCard(
                      item: item,
                      kind: MediaKind.book,
                      inLibrary: inLib,
                      onAdd: (it, k) =>
                          _addToLibrary(context, ref, it),
                    );
                  },
                );
              },
            ),
    );
  }
}
