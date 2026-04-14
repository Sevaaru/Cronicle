import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(anilistProfileProvider);
    final tokenAsync = ref.watch(anilistTokenProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: tokenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorLoadingProfile)),
        data: (token) {
          if (token == null) {
            return _NotLoggedIn();
          }
          return profileAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (profile) {
              if (profile == null) return _NotLoggedIn();
              return _ProfileContent(profile: profile);
            },
          );
        },
      ),
    );
  }
}

class _NotLoggedIn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final libraryStream = ref.watch(databaseProvider).watchAllLibrary();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      children: [
        GlassCard(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: cs.surfaceContainerHighest,
                child: Icon(Icons.person_outline, size: 40, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              Text(l10n.profileLocalUser,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text(l10n.profileConnectHint,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.profileLocalLibrary, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        StreamBuilder<List<dynamic>>(
          stream: libraryStream,
          builder: (context, snap) {
            final entries = snap.data ?? [];
            final counts = <MediaKind, int>{};
            for (final e in entries) {
              final kind = MediaKind.fromCode(e.kind as int);
              counts[kind] = (counts[kind] ?? 0) + 1;
            }
            if (entries.isEmpty) {
              return GlassCard(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(l10n.profileLibraryEmpty,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),
              );
            }
            return GlassCard(
              child: Column(
                children: [
                  _StatRow(Icons.collections_bookmark, 'Total',
                      '${entries.length}', cs.primary),
                  for (final kind in MediaKind.values)
                    if ((counts[kind] ?? 0) > 0)
                      _StatRow(_kindIcon(kind), mediaKindLabel(kind, l10n),
                          '${counts[kind]}', _kindColor(kind, cs)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ProfileContent extends StatelessWidget {
  const _ProfileContent({required this.profile});
  final Map<String, dynamic> profile;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final name = profile['name'] as String? ?? '';
    final avatar = (profile['avatar'] as Map?)?['large'] as String?;
    final banner = profile['bannerImage'] as String?;
    final about = profile['about'] as String?;
    final siteUrl = profile['siteUrl'] as String?;

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

    final favs = profile['favourites'] as Map<String, dynamic>? ?? {};
    final favAnime = (favs['anime'] as Map?)?['nodes'] as List? ?? [];
    final favManga = (favs['manga'] as Map?)?['nodes'] as List? ?? [];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      image: banner != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(banner),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                  Colors.black.withAlpha(80), BlendMode.darken),
                            )
                          : null,
                      color: banner == null ? cs.primaryContainer : null,
                    ),
                  ),
                  Positioned(
                    left: 16, right: 16, top: 105,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: cs.surface, width: 4),
                          ),
                          child: CircleAvatar(
                            radius: 38,
                            backgroundImage:
                                avatar != null ? CachedNetworkImageProvider(avatar) : null,
                            child: avatar == null
                                ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 28))
                                : null,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cs.surface.withAlpha(200),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(name,
                                      style: const TextStyle(
                                          fontSize: 20, fontWeight: FontWeight.w700)),
                                ),
                                if (siteUrl != null)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8, top: 2),
                                    child: Text('anilist.co',
                                        style: TextStyle(
                                            fontSize: 12, color: cs.onSurfaceVariant)),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 46),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList.list(
            children: [
              if (about != null && about.isNotEmpty) ...[
                GlassCard(
                  child: Text(about,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
                ),
                const SizedBox(height: 12),
              ],

              // Anime stats
              _SectionHeader(l10n.sectionAnime, Icons.animation_rounded, cs.primary),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BigStat('$animeCount', l10n.statTitles),
                        _BigStat('$episodesWatched', l10n.statEpisodes),
                        _BigStat('${daysWatched}d', l10n.statDaysWatching),
                        _BigStat(animeMean.toStringAsFixed(1), l10n.statMeanScore),
                      ],
                    ),
                    if (animeStatuses.isNotEmpty) ...[
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: animeStatuses.map((s) {
                          final status = _translateStatus(s['status'] as String? ?? '', l10n);
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
                      ...animeGenres.map((g) => _GenreBar(
                            genre: g['genre'] as String? ?? '',
                            count: g['count'] as int? ?? 0,
                            maxCount: (animeGenres.first['count'] as int?) ?? 1,
                            color: cs.primary,
                          )),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Manga stats
              _SectionHeader(l10n.sectionManga, Icons.menu_book_rounded, Colors.deepPurple),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BigStat('$mangaCount', l10n.statTitles),
                        _BigStat('$chaptersRead', l10n.statChapters),
                        _BigStat('$volumesRead', l10n.statVolumes),
                        _BigStat(mangaMean.toStringAsFixed(1), l10n.statMeanScore),
                      ],
                    ),
                    if (mangaStatuses.isNotEmpty) ...[
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: mangaStatuses.map((s) {
                          final status = _translateStatus(s['status'] as String? ?? '', l10n);
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
                      ...mangaGenres.map((g) => _GenreBar(
                            genre: g['genre'] as String? ?? '',
                            count: g['count'] as int? ?? 0,
                            maxCount: (mangaGenres.first['count'] as int?) ?? 1,
                            color: Colors.deepPurple,
                          )),
                    ],
                  ),
                ),
              ],

              // Favoritos
              if (favAnime.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(l10n.sectionFavAnime, Icons.favorite_rounded, Colors.red.shade400),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemCount: favAnime.length,
                    itemBuilder: (context, i) {
                      final media = favAnime[i] as Map<String, dynamic>;
                      return _FavCard(media: media, kind: MediaKind.anime);
                    },
                  ),
                ),
              ],
              if (favManga.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeader(l10n.sectionFavManga, Icons.favorite_rounded, Colors.red.shade400),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemCount: favManga.length,
                    itemBuilder: (context, i) {
                      final media = favManga[i] as Map<String, dynamic>;
                      return _FavCard(media: media, kind: MediaKind.manga);
                    },
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Connected accounts
              _SectionHeader(l10n.sectionConnectedAccounts, Icons.link_rounded, cs.tertiary),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    const Text('Anilist',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(name,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.circle_outlined, color: cs.onSurfaceVariant.withAlpha(100), size: 20),
                    const SizedBox(width: 8),
                    Text('Letterboxd',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withAlpha(120))),
                    const Spacer(),
                    Text(l10n.comingSoon,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withAlpha(80))),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.circle_outlined, color: cs.onSurfaceVariant.withAlpha(100), size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.mediaKindGame,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withAlpha(120))),
                    const Spacer(),
                    Text(l10n.comingSoon,
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant.withAlpha(80))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _translateStatus(String status, AppLocalizations l10n) => switch (status) {
        'CURRENT' => l10n.statusCurrentAnime,
        'PLANNING' => l10n.statusPlanning,
        'COMPLETED' => l10n.statusCompleted,
        'DROPPED' => l10n.statusDropped,
        'PAUSED' => l10n.statusPaused,
        'REPEATING' => l10n.statusRepeating,
        _ => status,
      };
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  const _BigStat(this.value, this.label);
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

class _GenreBar extends StatelessWidget {
  const _GenreBar({
    required this.genre,
    required this.count,
    required this.maxCount,
    required this.color,
  });
  final String genre;
  final int count;
  final int maxCount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final ratio = maxCount > 0 ? count / maxCount : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(genre, style: TextStyle(fontSize: 12, color: cs.onSurface)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 8,
                backgroundColor: cs.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation(color.withAlpha(180)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 30,
            child: Text('$count',
                textAlign: TextAlign.end,
                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface))),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cs.onSurface)),
        ],
      ),
    );
  }
}

class _FavCard extends StatelessWidget {
  const _FavCard({required this.media, required this.kind});
  final Map<String, dynamic> media;
  final MediaKind kind;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ?? '';
    final cover = (media['coverImage'] as Map?)?['large'] as String?;
    final id = media['id'] as int?;

    return GestureDetector(
      onTap: id != null
          ? () => context.push('/media/$id?kind=${kind.code}')
          : null,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: cover != null
                  ? CachedNetworkImage(
                      imageUrl: cover,
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 130,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.image),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _kindIcon(MediaKind kind) => switch (kind) {
      MediaKind.anime => Icons.animation_rounded,
      MediaKind.manga => Icons.menu_book_rounded,
      MediaKind.movie => Icons.movie_rounded,
      MediaKind.tv => Icons.tv_rounded,
      MediaKind.game => Icons.sports_esports_rounded,
    };

Color _kindColor(MediaKind kind, ColorScheme cs) => switch (kind) {
      MediaKind.anime => cs.primary,
      MediaKind.manga => Colors.deepPurple,
      MediaKind.movie => Colors.amber.shade700,
      MediaKind.tv => Colors.teal,
      MediaKind.game => Colors.redAccent,
    };
