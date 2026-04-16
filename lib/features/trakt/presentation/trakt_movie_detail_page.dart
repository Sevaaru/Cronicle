import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';

class TraktMovieDetailPage extends ConsumerWidget {
  const TraktMovieDetailPage({super.key, required this.traktId});

  final int traktId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(traktMovieDetailProvider(traktId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (item) {
          if (item == null) {
            return Center(child: Text(l10n.libraryNoResults));
          }
          final titleMap = item['title'] as Map<String, dynamic>? ?? {};
          final name = (titleMap['english'] as String?) ?? '';
          final poster =
              (item['coverImage'] as Map?)?['extraLarge'] as String? ??
                  (item['coverImage'] as Map?)?['large'] as String?;
          final overview = item['overview'] as String?;
          final year = item['year'];
          final genres = (item['genres'] as List?)?.cast<String>().join(', ');

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (poster != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: CachedNetworkImage(
                        imageUrl: poster,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (year != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$year',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (genres != null && genres.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    genres,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                if (overview != null && overview.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    overview,
                    style: const TextStyle(fontSize: 14, height: 1.35),
                  ),
                ],
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.library_add_check_rounded),
                  label: Text(l10n.addToListTitle),
                  onPressed: () async {
                    final added = await showAddToLibrarySheet(
                      context: context,
                      ref: ref,
                      item: item,
                      kind: MediaKind.movie,
                    );
                    if (!context.mounted || !added) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.addedToLibrary)),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
