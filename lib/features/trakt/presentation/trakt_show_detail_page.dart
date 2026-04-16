import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/trakt/presentation/trakt_detail_widgets.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class TraktShowDetailPage extends ConsumerWidget {
  const TraktShowDetailPage({super.key, required this.traktId});

  final int traktId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(traktShowDetailProvider(traktId));

    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (item) {
          if (item == null) {
            return Center(child: Text(l10n.libraryNoResults));
          }
          return _TraktShowDetailBody(traktId: traktId, item: item);
        },
      ),
    );
  }
}

class _TraktShowDetailBody extends ConsumerWidget {
  const _TraktShowDetailBody({required this.traktId, required this.item});

  final int traktId;
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
    final eps = item['episodes'] as int?;
    final epRuntime = item['episode_runtime'] as int?;
    final network = item['network'] as String?;
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
    if (eps != null) subtitleParts.add('$eps ep');
    if (network != null && network.isNotEmpty) subtitleParts.add(network);
    final lines = <String>[];
    if (subtitleParts.isNotEmpty) lines.add(subtitleParts.join(' · '));
    if (tagline != null && tagline.isNotEmpty) lines.add(tagline);
    final heroSubtitle = lines.join('\n');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TraktDetailHeroHeader(
            title: name,
            subtitle: heroSubtitle.isEmpty ? null : heroSubtitle,
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
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (certification != null && certification.isNotEmpty)
                      TraktTag(certification, cs.errorContainer, cs.onErrorContainer),
                    if (traktStatus != null && traktStatus.isNotEmpty)
                      TraktTag(
                        traktFormatApiStatus(traktStatus),
                        cs.secondaryContainer,
                        cs.onSecondaryContainer,
                      ),
                    ...genres.take(6).map(
                          (g) => TraktTag(
                            traktFormatGenreLabel(g),
                            cs.tertiaryContainer,
                            cs.onTertiaryContainer,
                          ),
                        ),
                  ],
                ),
                const SizedBox(height: 12),
                TraktAddToLibraryRow(item: item, kind: MediaKind.tv),
                const SizedBox(height: 12),
                TraktTvEpisodeProgressCard(traktId: traktId, item: item),
                if (score != null || (votes != null && votes > 0))
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
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
                GlassCard(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mediaInfo,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 24,
                        runSpacing: 6,
                        children: [
                          if (year != null) TraktInfoPill(l10n.traktDetailYear, '$year'),
                          if (eps != null) TraktInfoPill(l10n.mediaEpisodes, '$eps'),
                          if (epRuntime != null)
                            TraktInfoPill(l10n.mediaDuration, '$epRuntime min/ep'),
                          if (network != null && network.isNotEmpty)
                            TraktInfoPill(l10n.traktDetailNetwork, network),
                          if (country != null && country.isNotEmpty)
                            TraktInfoPill(l10n.traktDetailCountry, country.toUpperCase()),
                          if (language != null && language.isNotEmpty)
                            TraktInfoPill(l10n.traktDetailLanguage, language.toUpperCase()),
                          if (released != null && released.toString().isNotEmpty)
                            TraktInfoPill(l10n.mediaStart, released.toString()),
                          if (original != null && original.isNotEmpty && original != name)
                            TraktInfoPill(l10n.traktDetailOriginalTitle, original),
                        ],
                      ),
                    ],
                  ),
                ),
                if (subgenres.isNotEmpty) ...[
                  Text(
                    l10n.traktDetailSubgenres,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: subgenres
                        .map(
                          (g) => TraktTag(
                            traktFormatGenreLabel(g),
                            cs.surfaceContainerHighest,
                            cs.onSurfaceVariant,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                ],
                if (overview != null && overview.isNotEmpty) ...[
                  Text(
                    l10n.mediaSynopsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    overview,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                ...traktExternalLinkChips(context, l10n, item, isMovie: false),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
