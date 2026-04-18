import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart'
    show IgdbWebUnsupportedException;
import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/games/presentation/games_review_home_card.dart';
import 'package:cronicle/features/games/presentation/games_section_titles.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';

/// Pantalla completa para una categoría del home IGDB (`/games/section/:slug`).
class GamesHomeSectionListPage extends ConsumerWidget {
  const GamesHomeSectionListPage({super.key, required this.slug});

  final String slug;

  static bool _isReviews(String slug) =>
      slug == GamesFeedSection.reviewsRecent ||
      slug == GamesFeedSection.reviewsCritics;

  static String? _releaseDateLabel(BuildContext context, Map<String, dynamic> item) {
    final ts = item['first_release_date'];
    if (ts == null) return null;
    final sec = ts is int ? ts : ts is num ? ts.toInt() : int.tryParse('$ts');
    if (sec == null || sec <= 0) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(sec * 1000, isUtc: true)
        .toLocal();
    final locale = Localizations.localeOf(context).toString();
    return DateFormat.yMMMd(locale).format(dt);
  }

  Future<void> _addToLibrary(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
    MediaKind kind,
  ) async {
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
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
    final title = gamesHomeSectionTitle(l10n, slug);
    final valid = GamesFeedSection.isValid(slug);
    final async = valid ? ref.watch(igdbGamesSectionListProvider(slug)) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: !valid
          ? Center(child: Text(l10n.gamesHomeNoItems))
          : async!.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    e is IgdbWebUnsupportedException
                        ? l10n.igdbWebNotSupported
                        : l10n.errorWithMessage(e),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(child: Text(l10n.gamesHomeNoItems));
                }
                if (_isReviews(slug)) {
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    itemCount: items.length,
                    itemBuilder: (context, i) =>
                        GamesReviewHomeCard(review: items[i]),
                  );
                }
                final showDate = slug == GamesFeedSection.comingSoon;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final id = item['id'];
                    final dateLine =
                        showDate ? _releaseDateLabel(context, item) : null;
                    return BrowseResultCard(
                      key: ValueKey('section-$slug-$id'),
                      item: item,
                      kind: MediaKind.game,
                      releaseDateLine: dateLine,
                      onAdd: (it, k) => _addToLibrary(context, ref, it, k),
                    );
                  },
                );
              },
            ),
    );
  }
}
