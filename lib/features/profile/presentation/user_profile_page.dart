import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key, required this.userId});
  final int userId;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  Map<String, dynamic>? _profile;
  bool _loading = true;
  bool _isFollowing = false;
  bool _togglingFollow = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final data = await graphql.fetchUserProfile(widget.userId, token: token);
    if (!mounted) return;
    setState(() {
      _profile = data;
      _isFollowing = data?['isFollowing'] as bool? ?? false;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicia sesión en Anilist para seguir usuarios')),
      );
      return;
    }
    setState(() => _togglingFollow = true);
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final result = await graphql.toggleFollow(widget.userId, token);
      if (mounted) setState(() => _isFollowing = result);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _togglingFollow = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_profile == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No se encontró el usuario')),
      );
    }

    final p = _profile!;
    final name = p['name'] as String? ?? '';
    final avatar = (p['avatar'] as Map?)?['large'] as String?;
    final banner = p['bannerImage'] as String?;
    final about = p['about'] as String?;

    final stats = p['statistics'] as Map<String, dynamic>? ?? {};
    final animeStats = stats['anime'] as Map<String, dynamic>? ?? {};
    final mangaStats = stats['manga'] as Map<String, dynamic>? ?? {};

    final animeCount = animeStats['count'] as int? ?? 0;
    final episodesWatched = animeStats['episodesWatched'] as int? ?? 0;
    final minutesWatched = animeStats['minutesWatched'] as int? ?? 0;
    final animeMean = (animeStats['meanScore'] as num?)?.toDouble() ?? 0;
    final mangaCount = mangaStats['count'] as int? ?? 0;
    final chaptersRead = mangaStats['chaptersRead'] as int? ?? 0;
    final mangaMean = (mangaStats['meanScore'] as num?)?.toDouble() ?? 0;

    final daysWatched = (minutesWatched / 60 / 24).toStringAsFixed(1);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (banner != null)
                    CachedNetworkImage(
                      imageUrl: banner,
                      fit: BoxFit.cover,
                      color: Colors.black.withAlpha(80),
                      colorBlendMode: BlendMode.darken,
                    )
                  else
                    Container(color: cs.primaryContainer),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Transform.translate(
                offset: const Offset(0, -30),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: cs.surface,
                      child: CircleAvatar(
                        radius: 38,
                        backgroundImage: avatar != null
                            ? CachedNetworkImageProvider(avatar)
                            : null,
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
                          Text('anilist.co',
                              style: TextStyle(
                                  fontSize: 12, color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    _togglingFollow
                        ? const SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : FilledButton.icon(
                            icon: Icon(
                              _isFollowing ? Icons.person_remove : Icons.person_add,
                              size: 16,
                            ),
                            label: Text(_isFollowing ? 'Siguiendo' : 'Seguir',
                                style: const TextStyle(fontSize: 12)),
                            style: FilledButton.styleFrom(
                              backgroundColor:
                                  _isFollowing ? cs.surfaceContainerHighest : null,
                              foregroundColor:
                                  _isFollowing ? cs.onSurface : null,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: _toggleFollow,
                          ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.list(
              children: [
                if (about != null && about.isNotEmpty) ...[
                  GlassCard(
                    child: Text(about,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                ],
                _SectionHeader('Anime', Icons.animation_rounded, cs.primary),
                const SizedBox(height: 8),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigStat('$animeCount', 'Títulos'),
                      _BigStat('$episodesWatched', 'Episodios'),
                      _BigStat('${daysWatched}d', 'Días'),
                      _BigStat(animeMean.toStringAsFixed(1), 'Media'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader('Manga', Icons.menu_book_rounded, Colors.deepPurple),
                const SizedBox(height: 8),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigStat('$mangaCount', 'Títulos'),
                      _BigStat('$chaptersRead', 'Capítulos'),
                      _BigStat(mangaMean.toStringAsFixed(1), 'Media'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
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
        Text(title,
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: color)),
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
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: cs.onSurface)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant)),
      ],
    );
  }
}
