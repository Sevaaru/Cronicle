import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/utils/json_int.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/books/presentation/book_providers.dart';
import 'package:cronicle/features/games/presentation/game_providers.dart';
import 'package:cronicle/features/profile/presentation/anilist_profile_follow_row.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_kind.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_preview.dart';
import 'package:cronicle/features/profile/presentation/profile_stats_shared.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final profileAsync = ref.watch(anilistProfileProvider);
    final tokenAsync = ref.watch(anilistTokenProvider);

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileLeadingCloseButton(),
        leadingWidth: kProfileLeadingWidth,
        automaticallyImplyLeading: false,
        title: Text(l10n.profileTitle),
      ),
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
        Consumer(
          builder: (context, ref, _) {
            final favGames = ref.watch(favoriteGamesProvider);
            if (favGames.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(l10n.sectionFavGames,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(right: 8),
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemCount: favGames.length,
                    itemBuilder: (context, i) {
                      return _FavoriteGameCard(game: favGames[i]);
                    },
                  ),
                ),
              ],
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final local = ref.watch(favoriteAnilistMediaProvider);
            final anime = local
                .where((e) =>
                    (e['type'] as String? ?? 'ANIME').toUpperCase() == 'ANIME')
                .toList();
            final manga = local
                .where((e) =>
                    (e['type'] as String? ?? 'ANIME').toUpperCase() == 'MANGA')
                .toList();
            if (anime.isEmpty && manga.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (anime.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.sectionFavAnime,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 8),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: anime.length,
                      itemBuilder: (context, i) =>
                          _FavoriteAnilistMediaCard(item: anime[i]),
                    ),
                  ),
                ],
                if (manga.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(l10n.sectionFavManga,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 8),
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: manga.length,
                      itemBuilder: (context, i) =>
                          _FavoriteAnilistMediaCard(item: manga[i]),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  const _ProfileContent({required this.profile});
  final Map<String, dynamic> profile;

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryRefreshTraktAvatar());
  }

  Future<void> _tryRefreshTraktAvatar() async {
    if (!mounted) return;
    final s = await ref.read(traktSessionProvider.future);
    if (!mounted || !s.connected) return;
    if ((s.userAvatarUrl ?? '').isEmpty) {
      await ref.read(traktSessionProvider.notifier).refreshFromNetwork();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final traktSessionAsync = ref.watch(traktSessionProvider);
    final name = profile['name'] as String? ?? '';
    final anilistUserId = jsonInt(profile['id']);
    final avatar = (profile['avatar'] as Map?)?['large'] as String?;
    final banner = profile['bannerImage'] as String?;
    final about = profile['about'] as String?;
    final siteUrl = profile['siteUrl'] as String?;

    final trakt = traktSessionAsync.valueOrNull;
    final traktConnected = trakt?.connected == true;
    final traktImg = (trakt?.userAvatarUrl ?? '').trim();
    final hasTraktImg = traktImg.isNotEmpty;
    final traktName = trakt?.userName ?? '';

    final favs = profile['favourites'] as Map<String, dynamic>? ?? {};
    final favAnime = (favs['anime'] as Map?)?['nodes'] as List? ?? [];
    final favManga = (favs['manga'] as Map?)?['nodes'] as List? ?? [];

    // Misma geometría que [UserProfilePage]: banner 150px + fila avatar (top 105, ~84px alto).
    const bannerH = 150.0;
    const avatarRowTop = 105.0;
    const avatarOuter = 84.0;
    const headerStackHeight = avatarRowTop + avatarOuter;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Column(
            children: [
              SizedBox(
                height: headerStackHeight,
                child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: bannerH,
                    child: GestureDetector(
                    onTap: banner != null ? () => showFullscreenImage(context, banner) : null,
                    child: Container(
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
                  ),
                  ),
                  Positioned(
                    left: 16, right: 16, top: avatarRowTop,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: avatar != null ? () => showFullscreenImage(context, avatar) : null,
                              child: Container(
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
                            ),
                            if (traktConnected) ...[
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: hasTraktImg ? () => showFullscreenImage(context, traktImg) : null,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: cs.surface, width: 4),
                                  ),
                                  child: CircleAvatar(
                                    radius: 34,
                                    backgroundImage:
                                        hasTraktImg ? CachedNetworkImageProvider(traktImg) : null,
                                    child: !hasTraktImg
                                        ? Text(
                                            traktName.isNotEmpty ? traktName[0].toUpperCase() : 'T',
                                            style: const TextStyle(fontSize: 24),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ],
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
              ),
              if (anilistUserId > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AnilistProfileFollowRow(
                    userId: anilistUserId,
                    followersCount: jsonInt(profile['followersCount']),
                    followingCount: jsonInt(profile['followingCount']),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverList.list(
            children: [
              if (about != null && about.isNotEmpty) ...[
                GlassCard(
                  child: AnilistMarkdown(about,
                      style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
                ),
                const SizedBox(height: 12),
              ],

              _PersonalStatsNavTile(l10n: l10n, colorScheme: cs),
              const SizedBox(height: 12),

              Consumer(
                builder: (context, ref, _) {
                  final favGames = ref.watch(favoriteGamesProvider);
                  final favBooks = ref.watch(favoriteBooksProvider);
                  final favTraktAll = ref.watch(favoriteTraktTitlesProvider);
                  final localAnilistFavs = ref.watch(favoriteAnilistMediaProvider);
                  final favAnimeMerged = mergeAnilistFavoriteApiNodesWithLocal(
                    apiNodes: favAnime,
                    localSnapshots: localAnilistFavs,
                    mediaTypeUpper: 'ANIME',
                  );
                  final favMangaMerged = mergeAnilistFavoriteApiNodesWithLocal(
                    apiNodes: favManga,
                    localSnapshots: localAnilistFavs,
                    mediaTypeUpper: 'MANGA',
                  );
                  final favMovies = favTraktAll
                      .where((e) => (e['trakt_type'] as String?) != 'show')
                      .toList();
                  final favShows =
                      favTraktAll.where((e) => (e['trakt_type'] as String?) == 'show').toList();

                  List<ProfileFavPreviewThumb> thumbsFromNodes(List<dynamic> nodes, IconData fb) {
                    return nodes
                        .take(80)
                        .map((raw) {
                          final m = raw as Map<String, dynamic>;
                          final u = (m['coverImage'] as Map?)?['large'] as String?;
                          return ProfileFavPreviewThumb(imageUrl: u, fallbackIcon: fb);
                        })
                        .toList();
                  }

                  List<ProfileFavPreviewThumb> thumbsFromBookFavorites(
                    List<Map<String, dynamic>> books,
                  ) {
                    return books
                        .take(80)
                        .map((m) {
                          final u = (m['coverImage'] as Map?)?['large'] as String?;
                          return ProfileFavPreviewThumb(
                            imageUrl: u,
                            fallbackIcon: Icons.auto_stories_rounded,
                          );
                        })
                        .toList();
                  }

                  final previewRows = <Widget>[];
                  if (favAnimeMerged.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.animation_rounded,
                        iconColor: Colors.red.shade400,
                        title: l10n.sectionFavAnime,
                        count: favAnimeMerged.length,
                        thumbs: thumbsFromNodes(favAnimeMerged, Icons.animation_rounded),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.anime.segment}'),
                      ),
                    );
                  }
                  if (favMangaMerged.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.menu_book_rounded,
                        iconColor: Colors.deepPurple,
                        title: l10n.sectionFavManga,
                        count: favMangaMerged.length,
                        thumbs: thumbsFromNodes(favMangaMerged, Icons.menu_book_rounded),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.manga.segment}'),
                      ),
                    );
                  }
                  if (favMovies.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.movie_outlined,
                        iconColor: Colors.amber.shade700,
                        title: l10n.sectionFavTraktMovies,
                        count: favMovies.length,
                        thumbs: thumbsFromNodes(favMovies, Icons.movie_outlined),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.movies.segment}'),
                      ),
                    );
                  }
                  if (favShows.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.tv_rounded,
                        iconColor: Colors.teal,
                        title: l10n.sectionFavTraktShows,
                        count: favShows.length,
                        thumbs: thumbsFromNodes(favShows, Icons.tv_rounded),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.tv.segment}'),
                      ),
                    );
                  }
                  if (favGames.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.sports_esports_rounded,
                        iconColor: Colors.redAccent.shade400,
                        title: l10n.sectionFavGames,
                        count: favGames.length,
                        thumbs: thumbsFromNodes(favGames, Icons.sports_esports_rounded),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.games.segment}'),
                      ),
                    );
                  }
                  if (favBooks.isNotEmpty) {
                    previewRows.add(
                      ProfileFavoritesPreviewRow(
                        icon: Icons.auto_stories_rounded,
                        iconColor: Colors.brown.shade500,
                        title: l10n.sectionFavBooks,
                        count: favBooks.length,
                        thumbs: thumbsFromBookFavorites(favBooks),
                        onTap: () => context.push('/profile/favorites/${ProfileFavoritesKind.books.segment}'),
                      ),
                    );
                  }

                  if (previewRows.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      ProfileStatsSectionHeader(
                        l10n.profileFavoritesSectionTitle,
                        Icons.favorite_rounded,
                        Colors.red.shade400,
                      ),
                      const SizedBox(height: 8),
                      GlassCard(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < previewRows.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: cs.outlineVariant.withValues(alpha: 0.32),
                                ),
                              previewRows[i],
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 16),

              // Connected accounts
              ProfileStatsSectionHeader(l10n.sectionConnectedAccounts, Icons.link_rounded, cs.tertiary),
              const SizedBox(height: 8),
              GlassCard(
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade400, size: 20),
                    const SizedBox(width: 8),
                    Text(l10n.anilistTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const Spacer(),
                    Text(name,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              traktSessionAsync.when(
                loading: () => GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(l10n.traktTitle,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                error: (e, st) => GlassCard(
                  child: Row(
                    children: [
                      Icon(Icons.circle_outlined,
                          color: cs.onSurfaceVariant.withAlpha(100), size: 20),
                      const SizedBox(width: 8),
                      Text(l10n.traktTitle,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      const Spacer(),
                      Text(l10n.profileTraktNotConnected,
                          style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                    ],
                  ),
                ),
                data: (s) => GlassCard(
                  child: Row(
                    children: [
                      Icon(
                        s.connected ? Icons.check_circle : Icons.circle_outlined,
                        color: s.connected
                            ? Colors.green.shade400
                            : cs.onSurfaceVariant.withAlpha(100),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.traktTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: s.connected
                              ? cs.onSurface
                              : cs.onSurfaceVariant.withAlpha(120),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        s.connected
                            ? (s.userSlug ?? s.userName ?? '')
                            : l10n.profileTraktNotConnected,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Entrada a estadísticas personales (mismo estilo plano que el resto de `GlassCard` del perfil).
class _PersonalStatsNavTile extends StatelessWidget {
  const _PersonalStatsNavTile({
    required this.l10n,
    required this.colorScheme,
  });

  final AppLocalizations l10n;
  final ColorScheme colorScheme;

  static const double _radius = 20;

  @override
  Widget build(BuildContext context) {
    final cs = colorScheme;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(_radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        borderRadius: BorderRadius.circular(_radius),
        onTap: () => context.push('/profile/personal-stats'),
        splashColor: cs.primary.withValues(alpha: 0.12),
        highlightColor: cs.primary.withValues(alpha: 0.06),
        child: GlassCard(
          borderRadius: _radius,
          padding: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(Icons.insights_rounded, color: cs.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.profilePersonalStatsTitle,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.profilePersonalStatsSubtitle,
                        style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
              ],
            ),
          ),
        ),
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

class _FavoriteAnilistMediaCard extends StatelessWidget {
  const _FavoriteAnilistMediaCard({required this.item});
  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = item['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';
    final cover = (item['coverImage'] as Map?)?['large'] as String?;
    final id = (item['id'] as num?)?.toInt();
    final isManga =
        (item['type'] as String? ?? 'ANIME').toUpperCase() == 'MANGA';
    final kindCode = isManga ? MediaKind.manga.code : MediaKind.anime.code;

    return GestureDetector(
      onTap: id != null
          ? () => context.push('/media/$id?kind=$kindCode')
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
                      child: Icon(
                        isManga ? Icons.menu_book_rounded : Icons.animation_rounded,
                      ),
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

class _FavoriteGameCard extends StatelessWidget {
  const _FavoriteGameCard({required this.game});
  final Map<String, dynamic> game;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final title = game['title'] as Map<String, dynamic>? ?? {};
    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        '';
    final cover = (game['coverImage'] as Map?)?['large'] as String?;
    final id = (game['id'] as num?)?.toInt();

    return GestureDetector(
      onTap: id != null ? () => context.push('/game/$id') : null,
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
                      child: const Icon(Icons.sports_esports),
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
      MediaKind.book => Icons.auto_stories_rounded,
    };

Color _kindColor(MediaKind kind, ColorScheme cs) => switch (kind) {
      MediaKind.anime => cs.primary,
      MediaKind.manga => Colors.deepPurple,
      MediaKind.movie => Colors.amber.shade700,
      MediaKind.tv => Colors.teal,
      MediaKind.game => Colors.redAccent,
      MediaKind.book => const Color(0xFFAB47BC),
    };
