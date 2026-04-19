import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/profile/presentation/profile_stats_shared.dart';
import 'package:cronicle/features/profile/presentation/profile_trakt_extras_provider.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

/// Estadísticas detalladas (Anilist, Trakt, juegos locales) fuera del perfil principal.
class PersonalStatsPage extends ConsumerWidget {
  const PersonalStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final profileAsync = ref.watch(anilistProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profilePersonalStatsTitle)),
      body: tokenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorLoadingProfile)),
        data: (token) {
          if (token == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.profileConnectHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            );
          }
          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.errorWithMessage(e.toString()))),
            data: (profile) {
              if (profile == null) {
                return Center(child: Text(l10n.profileConnectHint));
              }
              return _PersonalStatsBody(profile: profile);
            },
          );
        },
      ),
    );
  }
}

class _PersonalStatsBody extends ConsumerWidget {
  const _PersonalStatsBody({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final traktSessionAsync = ref.watch(traktSessionProvider);

    final stats = profile['statistics'] as Map<String, dynamic>? ?? {};
    final animeStats = stats['anime'] as Map<String, dynamic>? ?? {};
    final mangaStats = stats['manga'] as Map<String, dynamic>? ?? {};

    final animeCount = animeStats['count'] as int? ?? 0;
    final episodesWatched = animeStats['episodesWatched'] as int? ?? 0;
    final minutesWatched = animeStats['minutesWatched'] as int? ?? 0;
    final animeMean = (animeStats['meanScore'] as num?)?.toDouble() ?? 0;

    final mangaCount = mangaStats['count'] as int? ?? 0;
    final chaptersRead = mangaStats['chaptersRead'] as int? ?? 0;
    final volumesRead = mangaStats['volumesRead'] as int? ?? 0;
    final mangaMean = (mangaStats['meanScore'] as num?)?.toDouble() ?? 0;

    final animeGenres = (animeStats['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final mangaGenres = (mangaStats['genres'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final animeStatuses = (animeStats['statuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final mangaStatuses = (mangaStats['statuses'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    final daysWatched = (minutesWatched / 60 / 24).toStringAsFixed(1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      children: [
        ProfileStatsSectionHeader(l10n.sectionAnime, Icons.animation_rounded, cs.primary),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('$animeCount', l10n.statTitles, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('$episodesWatched', l10n.statEpisodes, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('${daysWatched}d', l10n.statDaysWatching, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat(animeMean.toStringAsFixed(1), l10n.statMeanScore, loose: true),
                      ),
                    ),
                  ],
                ),
              ),
              if (animeStatuses.isNotEmpty) ...[
                const Divider(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: animeStatuses.map((s) {
                    final status =
                        translateAnilistProfileStatus(s['status'] as String? ?? '', l10n);
                    final count = s['count'] as int? ?? 0;
                    return Chip(
                      label: Text('$status: $count', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        if (animeGenres.isNotEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.sectionTopGenresAnime,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...animeGenres.map((g) => ProfileStatsGenreBar(
                      genre: g['genre'] as String? ?? '',
                      count: g['count'] as int? ?? 0,
                      maxCount: (animeGenres.first['count'] as int?) ?? 1,
                      color: cs.primary,
                    )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        ProfileStatsSectionHeader(l10n.sectionManga, Icons.menu_book_rounded, Colors.deepPurple),
        const SizedBox(height: 8),
        GlassCard(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('$mangaCount', l10n.statTitles, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('$chaptersRead', l10n.statChapters, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat('$volumesRead', l10n.statVolumes, loose: true),
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ProfileStatsBigStat(mangaMean.toStringAsFixed(1), l10n.statMeanScore, loose: true),
                      ),
                    ),
                  ],
                ),
              ),
              if (mangaStatuses.isNotEmpty) ...[
                const Divider(height: 24),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: mangaStatuses.map((s) {
                    final status =
                        translateAnilistProfileStatus(s['status'] as String? ?? '', l10n);
                    final count = s['count'] as int? ?? 0;
                    return Chip(
                      label: Text('$status: $count', style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
        if (mangaGenres.isNotEmpty) ...[
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.sectionTopGenresManga,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                ...mangaGenres.map((g) => ProfileStatsGenreBar(
                      genre: g['genre'] as String? ?? '',
                      count: g['count'] as int? ?? 0,
                      maxCount: (mangaGenres.first['count'] as int?) ?? 1,
                      color: Colors.deepPurple,
                    )),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        ref.watch(profileTraktExtrasProvider).when(
              loading: () {
                final connected = traktSessionAsync.maybeWhen(
                  data: (s) => s.connected,
                  orElse: () => false,
                );
                if (!connected) return const SizedBox.shrink();
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              error: (e, st) => const SizedBox.shrink(),
              data: (extras) {
                if (extras == null) return const SizedBox.shrink();
                final st = extras.stats;
                final traktLocalFavs = ref.watch(favoriteTraktTitlesProvider);
                final favMovies = traktLocalFavs
                    .where((e) => (e['trakt_type'] as String?) != 'show')
                    .toList();
                final favShows =
                    traktLocalFavs.where((e) => (e['trakt_type'] as String?) == 'show').toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ProfileStatsSectionHeader(
                        l10n.profileSectionTrakt, Icons.movie_filter_rounded, Colors.teal.shade400),
                    const SizedBox(height: 10),
                    ProfileTraktStatsPanel(
                      stats: st,
                      accent: Colors.teal.shade400,
                    ),
                    if (favMovies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ProfileStatsSectionHeader(
                          l10n.sectionFavTraktMovies, Icons.favorite_rounded, Colors.teal.shade400),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 8),
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: favMovies.length,
                          itemBuilder: (context, i) => ProfileTraktFavCard(
                            media: favMovies[i],
                            isShow: false,
                          ),
                        ),
                      ),
                    ],
                    if (favShows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ProfileStatsSectionHeader(
                          l10n.sectionFavTraktShows, Icons.favorite_rounded, Colors.teal.shade400),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.only(right: 8),
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemCount: favShows.length,
                          itemBuilder: (context, i) => ProfileTraktFavCard(
                            media: favShows[i],
                            isShow: true,
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),

        const SizedBox(height: 20),
        ProfileStatsSectionHeader(
            l10n.sectionProfileLocalGames, Icons.sports_esports_rounded, Colors.redAccent.shade400),
        const SizedBox(height: 8),
        StreamBuilder<List<LibraryEntry>>(
          stream: ref.watch(databaseProvider).watchAllLibrary(),
          builder: (context, snap) {
            final entries = snap.data ?? [];
            final games = entries
                .where((e) => MediaKind.fromCode(e.kind) == MediaKind.game)
                .toList();
            if (games.isEmpty) {
              return GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.profileLocalGamesEmpty,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              );
            }
            var totalHours = 0;
            final byStatus = <String, int>{};
            for (final e in games) {
              totalHours += e.progress ?? 0;
              final st = (e.status).toUpperCase();
              byStatus[st] = (byStatus[st] ?? 0) + 1;
            }
            final statusKeys = byStatus.keys.toList()..sort();

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: ProfileStatsBigStat(
                              '${games.length}',
                              l10n.statTitles,
                              loose: true,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ProfileStatsBigStat(
                              '$totalHours',
                              l10n.profileLocalGamesHoursTotal,
                              loose: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusKeys.isNotEmpty) ...[
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: statusKeys.map((k) {
                        final label = libraryEntryStatusLabel(l10n, k, MediaKind.game);
                        return Chip(
                          label: Text('$label: ${byStatus[k]}',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        ProfileStatsSectionHeader(
            l10n.filterBooks, Icons.auto_stories_rounded, const Color(0xFFAB47BC)),
        const SizedBox(height: 8),
        StreamBuilder<List<LibraryEntry>>(
          stream: ref.watch(databaseProvider).watchAllLibrary(),
          builder: (context, snap) {
            final entries = snap.data ?? [];
            final books = entries
                .where((e) => MediaKind.fromCode(e.kind) == MediaKind.book)
                .toList();
            if (books.isEmpty) {
              return GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.profileLibraryEmpty,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
                  ),
                ),
              );
            }
            var totalPages = 0;
            final byStatus = <String, int>{};
            for (final e in books) {
              totalPages += e.progress ?? 0;
              final st = (e.status).toUpperCase();
              byStatus[st] = (byStatus[st] ?? 0) + 1;
            }
            final statusKeys = byStatus.keys.toList()..sort();

            return GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: ProfileStatsBigStat(
                              '${books.length}',
                              l10n.statTitles,
                              loose: true,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: ProfileStatsBigStat(
                              '$totalPages',
                              l10n.addToListPagesRead,
                              loose: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusKeys.isNotEmpty) ...[
                    const Divider(height: 24),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: statusKeys.map((k) {
                        final label = libraryEntryStatusLabel(l10n, k, MediaKind.book);
                        return Chip(
                          label: Text('$label: ${byStatus[k]}',
                              style: const TextStyle(fontSize: 11)),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
