import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/library/presentation/library_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/add_to_library_sheet.dart';
import 'package:cronicle/shared/widgets/browse_result_card.dart';


class TraktFeedSection {
  TraktFeedSection._();
  static const trending = 'trending';
  static const popular = 'popular';
  static const anticipated = 'anticipated';
  static const played = 'played';
  static const watched = 'watched';
  static const collected = 'collected';
  static const watching = 'watching';

  static const allMovie = [trending, played, anticipated, watched, collected, popular];
  static const allShow = [trending, watching, anticipated, watched, collected, popular];
}

String traktSectionTitle(AppLocalizations l10n, MediaKind kind, String slug) =>
    switch (slug) {
      TraktFeedSection.trending => l10n.traktSectionTrending,
      TraktFeedSection.popular => l10n.traktSectionPopular,
      TraktFeedSection.anticipated => kind == MediaKind.movie
          ? l10n.traktSectionAnticipatedMovies
          : l10n.traktSectionAnticipatedShows,
      TraktFeedSection.played => l10n.traktSectionMostPlayed,
      TraktFeedSection.watched => l10n.traktSectionMostWatched,
      TraktFeedSection.collected => l10n.traktSectionMostCollected,
      TraktFeedSection.watching => l10n.traktSectionWatchingNow,
      _ => slug,
    };


List<Map<String, dynamic>> _movieSection(TraktMoviesHomeData d, String slug) =>
    switch (slug) {
      TraktFeedSection.trending => d.trending,
      TraktFeedSection.popular => d.popular,
      TraktFeedSection.anticipated => d.anticipated,
      TraktFeedSection.played => d.played,
      TraktFeedSection.watched => d.watched,
      TraktFeedSection.collected => d.collected,
      _ => const [],
    };

List<Map<String, dynamic>> _showSection(TraktShowsHomeData d, String slug) =>
    switch (slug) {
      TraktFeedSection.trending => d.trending,
      TraktFeedSection.popular => d.popular,
      TraktFeedSection.anticipated => d.anticipated,
      TraktFeedSection.watched => d.watched,
      TraktFeedSection.collected => d.collected,
      TraktFeedSection.watching => d.watching,
      _ => const [],
    };


class TraktHomeSectionListPage extends ConsumerWidget {
  const TraktHomeSectionListPage({
    super.key,
    required this.kind,
    required this.slug,
  });

  final MediaKind kind;
  final String slug;

  Future<void> _addToLibrary(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> item,
  ) async {
    final db = ref.read(databaseProvider);
    final id = item['id']?.toString() ?? '';
    final existing = await db.getLibraryEntryByKindAndExternalId(
      kind.code,
      id,
    );
    if (!context.mounted) return;
    final added = await showAddToLibrarySheet(
      context: context,
      ref: ref,
      item: item,
      kind: kind,
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
    final title = traktSectionTitle(l10n, kind, slug);

    final libraryEntries =
        ref.watch(libraryByKindProvider(kind)).valueOrNull ?? [];
    final libraryIds = {
      for (final e in libraryEntries) e.externalId: true,
    };

    if (kind == MediaKind.movie) {
      return _buildMovies(context, ref, l10n, title, libraryIds);
    }
    return _buildShows(context, ref, l10n, title, libraryIds);
  }

  Widget _buildMovies(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String title,
    Map<String, bool> libraryIds,
  ) {
    final async = ref.watch(traktMoviesHomeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          final items = _movieSection(data, slug);
          if (items.isEmpty) {
            return Center(child: Text(l10n.profileLibraryEmpty));
          }
          return _buildList(context, ref, items, libraryIds);
        },
      ),
    );
  }

  Widget _buildShows(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String title,
    Map<String, bool> libraryIds,
  ) {
    final async = ref.watch(traktShowsHomeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$e', textAlign: TextAlign.center),
          ),
        ),
        data: (data) {
          final items = _showSection(data, slug);
          if (items.isEmpty) {
            return Center(child: Text(l10n.profileLibraryEmpty));
          }
          return _buildList(context, ref, items, libraryIds);
        },
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
    Map<String, bool> libraryIds,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final item = items[i];
        final id = item['id']?.toString() ?? '';
        final inLib = libraryIds.containsKey(id);
        return BrowseResultCard(
          item: item,
          kind: kind,
          inLibrary: inLib,
          onAdd: (it, k) => _addToLibrary(context, ref, it),
        );
      },
    );
  }
}
