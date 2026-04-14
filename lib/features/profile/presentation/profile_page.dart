import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(anilistProfileProvider);
    final tokenAsync = ref.watch(anilistTokenProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: tokenAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => const Center(child: Text('Error al cargar perfil')),
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
              Text('Usuario local',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 4),
              Text('Conecta Anilist en Ajustes para ver tus estadísticas completas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Biblioteca local', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
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
                    child: Text('Tu biblioteca está vacía',
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
                      _StatRow(_kindIcon(kind), kind.label,
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

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 140,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 90, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: cs.surface,
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700)),
                          if (siteUrl != null)
                            Text('anilist.co',
                                style: TextStyle(
                                    fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
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
              _SectionHeader('Anime', Icons.animation_rounded, cs.primary),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BigStat('$animeCount', 'Títulos'),
                        _BigStat('$episodesWatched', 'Episodios'),
                        _BigStat('${daysWatched}d', 'Días viendo'),
                        _BigStat(animeMean.toStringAsFixed(1), 'Nota media'),
                      ],
                    ),
                    if (animeStatuses.isNotEmpty) ...[
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: animeStatuses.map((s) {
                          final status = _translateStatus(s['status'] as String? ?? '');
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
                      const Text('Top géneros anime',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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
              _SectionHeader('Manga', Icons.menu_book_rounded, Colors.deepPurple),
              const SizedBox(height: 8),
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _BigStat('$mangaCount', 'Títulos'),
                        _BigStat('$chaptersRead', 'Capítulos'),
                        _BigStat('$volumesRead', 'Volúmenes'),
                        _BigStat(mangaMean.toStringAsFixed(1), 'Nota media'),
                      ],
                    ),
                    if (mangaStatuses.isNotEmpty) ...[
                      const Divider(height: 24),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: mangaStatuses.map((s) {
                          final status = _translateStatus(s['status'] as String? ?? '');
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
                      const Text('Top géneros manga',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
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

              const SizedBox(height: 16),

              // Connected accounts
              _SectionHeader('Cuentas conectadas', Icons.link_rounded, cs.tertiary),
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
                    Text('Próximamente',
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
                    Text('Juegos',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: cs.onSurfaceVariant.withAlpha(120))),
                    const Spacer(),
                    Text('Próximamente',
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

  String _translateStatus(String status) => switch (status) {
        'CURRENT' => 'Viendo',
        'PLANNING' => 'Planeado',
        'COMPLETED' => 'Completado',
        'DROPPED' => 'Abandonado',
        'PAUSED' => 'Pausado',
        'REPEATING' => 'Repitiendo',
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
