import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/trakt/presentation/trakt_detail_widgets.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/m3_detail.dart';

class TraktMovieDetailPage extends ConsumerWidget {
  const TraktMovieDetailPage({super.key, required this.traktId});

  final int traktId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(traktMovieDetailProvider(traktId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (item) {
          if (item == null) {
            return Center(child: Text(l10n.libraryNoResults));
          }
          return _TraktMovieDetailBody(item: item);
        },
      ),
    );
  }
}

class _TraktMovieDetailBody extends ConsumerWidget {
  const _TraktMovieDetailBody({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final titleMap = item['title'] as Map<String, dynamic>? ?? {};
    final name = (titleMap['english'] as String?) ?? '';
    final original = item['original_title'] as String?;
    final poster =
        (item['coverImage'] as Map?)?['extraLarge'] as String? ??
            (item['coverImage'] as Map?)?['large'] as String?;
    final fanart = item['fanart'] as String?;
    final overview = item['overview'] as String?;
    final year = item['year'];
    final runtime = item['runtime'] as int?;
    final genres = (item['genres'] as List?)?.cast<String>() ?? [];
    final subgenres = (item['subgenres'] as List?)?.cast<String>() ?? [];
    final score = item['averageScore'] as int?;
    final votes = item['votes'] as int?;
    final certification = item['certification'] as String?;
    final traktStatus = item['trakt_status'] as String?;
    final tagline = item['tagline'] as String?;
    final country = item['country'] as String?;
    final language = item['language'] as String?;
    final released = item['released'] as String?;

    final subtitleParts = <String>[];
    if (year != null) subtitleParts.add('$year');
    if (runtime != null) subtitleParts.add('$runtime min');
    final heroLines = <String>[];
    if (subtitleParts.isNotEmpty) heroLines.add(subtitleParts.join(' · '));
    if (tagline != null && tagline.isNotEmpty) heroLines.add(tagline);

    final heroPills = <Widget>[
      if (certification != null && certification.isNotEmpty)
        TraktTag(certification, cs.errorContainer, cs.onErrorContainer),
      if (traktStatus != null && traktStatus.isNotEmpty)
        TraktTag(
          traktFormatApiStatus(traktStatus),
          cs.secondaryContainer,
          cs.onSecondaryContainer,
        ),
      ...genres.take(4).map(
            (g) => TraktTag(
              traktFormatGenreLabel(g),
              cs.tertiaryContainer,
              cs.onTertiaryContainer,
            ),
          ),
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TraktDetailHeroHeader(
            title: name,
            subtitleLines: heroLines,
            pills: heroPills,
            poster: poster,
            fanart: fanart ?? poster,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                TraktAddToLibraryRow(item: item, kind: MediaKind.movie),
                const SizedBox(height: 12),
                if (score != null || (votes != null && votes > 0))
                  M3SurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (score != null)
                          TraktStatColumn(
                            Icons.star,
                            Colors.amber.shade600,
                            '$score%',
                            l10n.statMeanScore,
                          ),
                        if (votes != null && votes > 0)
                          TraktStatColumn(
                            Icons.how_to_vote_outlined,
                            cs.primary,
                            traktFormatVoteCount(votes),
                            l10n.traktDetailVotes,
                          ),
                      ],
                    ),
                  ),
                M3SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      M3SectionHeader(label: l10n.mediaInfo),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 24,
                        runSpacing: 6,
                        children: [
                          if (year != null) TraktInfoPill(l10n.traktDetailYear, '$year'),
                          if (runtime != null) TraktInfoPill(l10n.mediaDuration, '$runtime min'),
                          if (country != null && country.isNotEmpty)
                            TraktInfoPill(l10n.traktDetailCountry, country.toUpperCase()),
                          if (language != null && language.isNotEmpty)
                            TraktInfoPill(l10n.traktDetailLanguage, language.toUpperCase()),
                          if (released != null && released.toString().isNotEmpty)
                            TraktInfoPill(l10n.mediaStart, traktFormatDate(context, released)),
                          if (original != null && original.isNotEmpty && original != name)
                            TraktInfoPill(l10n.traktDetailOriginalTitle, original),
                        ],
                      ),
                    ],
                  ),
                ),
                if (subgenres.isNotEmpty) ...[
                  M3SectionHeader(label: l10n.traktDetailSubgenres),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: subgenres
                        .map(
                          (g) => M3PillChip(
                            label: traktFormatGenreLabel(g),
                            bg: cs.surfaceContainerHigh,
                            fg: cs.onSurface,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (overview != null && overview.isNotEmpty) ...[
                  M3SectionHeader(label: l10n.mediaSynopsis),
                  const SizedBox(height: 10),
                  Text(
                    overview,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: cs.onSurfaceVariant,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                ...traktExternalLinkChips(context, l10n, item, isMovie: true),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
