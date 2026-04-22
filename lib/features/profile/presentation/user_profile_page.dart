import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/utils/json_int.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/profile/presentation/anilist_profile_follow_row.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/animated_like_button.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class UserProfilePage extends ConsumerStatefulWidget {
  const UserProfilePage({super.key, required this.userId});
  final int userId;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {
  Map<String, dynamic>? _profile;
  List<Map<String, dynamic>> _activity = [];
  bool _loading = true;
  bool _isFollowing = false;
  bool _togglingFollow = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);

    final results = await Future.wait([
      graphql.fetchUserProfile(widget.userId, token: token),
      graphql.fetchUserActivity(widget.userId, token: token),
    ]);

    if (!mounted) return;
    setState(() {
      _profile = results[0] as Map<String, dynamic>?;
      _activity = results[1] as List<Map<String, dynamic>>;
      _isFollowing = _profile?['isFollowing'] as bool? ?? false;
      _loading = false;
    });
  }

  Future<void> _toggleFollow() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredFollow)),
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
        body: Center(child: Text(AppLocalizations.of(context)!.profileNotFound)),
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
    final l10n = AppLocalizations.of(context)!;

    final favs = p['favourites'] as Map<String, dynamic>? ?? {};
    final favAnime = (favs['anime'] as Map?)?['nodes'] as List? ?? [];
    final favManga = (favs['manga'] as Map?)?['nodes'] as List? ?? [];
    final favCharacters = (favs['characters'] as Map?)?['nodes'] as List? ?? [];
    final favStaff = (favs['staff'] as Map?)?['nodes'] as List? ?? [];

    final isDark = Theme.of(context).brightness == Brightness.dark;

    const bannerH = 150.0;
    const avatarRowTop = 105.0;
    const avatarOuter = 84.0; // (38+4)*2
    const headerStackHeight = avatarRowTop + avatarOuter;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarIconBrightness: (banner != null || isDark) ? Brightness.light : Brightness.dark,
        statusBarBrightness: (banner != null || isDark) ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
      body: CustomScrollView(
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
                        width: double.infinity,
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
                        child: SafeArea(
                          bottom: false,
                          child: Align(
                            alignment: Alignment.topLeft,
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back, color: Colors.white),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black26,
                                ),
                                onPressed: () => Navigator.of(context).maybePop(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ),
                    Positioned(
                      left: 16, right: 16, top: avatarRowTop,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
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
                                backgroundImage: avatar != null
                                    ? CachedNetworkImageProvider(avatar)
                                    : null,
                                child: avatar == null
                                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontSize: 24))
                                    : null,
                              ),
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
                          _togglingFollow
                              ? const SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : FilledButton.icon(
                                  icon: Icon(
                                    _isFollowing ? Icons.person_remove : Icons.person_add,
                                    size: 16,
                                  ),
                                  label: Text(_isFollowing ? l10n.following : l10n.follow,
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
                  ],
                ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: AnilistProfileFollowRow(
                    userId: widget.userId,
                    followersCount: jsonInt(p['followersCount']),
                    followingCount: jsonInt(p['followingCount']),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList.list(
              children: [
                if (about != null && about.isNotEmpty) ...[
                  GlassCard(
                    child: AnilistMarkdown(about,
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant, height: 1.4)),
                  ),
                  const SizedBox(height: 12),
                ],

                _SectionHeader(l10n.sectionAnime, Icons.animation_rounded, cs.primary),
                const SizedBox(height: 8),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigStat('$animeCount', l10n.statTitles),
                      _BigStat('$episodesWatched', l10n.statEpisodes),
                      _BigStat('${daysWatched}d', l10n.statDays),
                      _BigStat(animeMean.toStringAsFixed(1), l10n.statMeanScore),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _SectionHeader(l10n.sectionManga, Icons.menu_book_rounded, Colors.deepPurple),
                const SizedBox(height: 8),
                GlassCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _BigStat('$mangaCount', l10n.statTitles),
                      _BigStat('$chaptersRead', l10n.statChapters),
                      _BigStat(mangaMean.toStringAsFixed(1), l10n.statMeanScore),
                    ],
                  ),
                ),

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
                      itemBuilder: (context, i) => _FavCard(
                        media: favAnime[i] as Map<String, dynamic>,
                        kind: MediaKind.anime,
                      ),
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
                      itemBuilder: (context, i) => _FavCard(
                        media: favManga[i] as Map<String, dynamic>,
                        kind: MediaKind.manga,
                      ),
                    ),
                  ),
                ],

                if (favCharacters.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(l10n.sectionFavCharacters, Icons.face_rounded, Colors.pinkAccent),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: favCharacters.length,
                      itemBuilder: (context, i) => _FavPersonCard(
                        node: favCharacters[i] as Map<String, dynamic>,
                        isCharacter: true,
                      ),
                    ),
                  ),
                ],

                if (favStaff.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(l10n.sectionFavStaff, Icons.badge_rounded, Colors.indigoAccent),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemCount: favStaff.length,
                      itemBuilder: (context, i) => _FavPersonCard(
                        node: favStaff[i] as Map<String, dynamic>,
                        isCharacter: false,
                      ),
                    ),
                  ),
                ],

                if (_activity.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _SectionHeader(l10n.sectionRecentActivity, Icons.history_rounded, cs.tertiary),
                  const SizedBox(height: 8),
                  ..._activity.map((a) => _UserActivityCard(activity: a, cs: cs)),
                ],
              ],
            ),
          ),
        ],
      ),
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

class _FavPersonCard extends StatelessWidget {
  const _FavPersonCard({required this.node, required this.isCharacter});
  final Map<String, dynamic> node;
  final bool isCharacter;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final id = node['id'] as int?;
    final name = (node['name'] as Map?)?['full'] as String? ?? '';
    final img = (node['image'] as Map?)?['large'] as String? ??
        (node['image'] as Map?)?['medium'] as String?;
    return GestureDetector(
      onTap: id != null
          ? () => context.push(isCharacter ? '/character/$id' : '/staff/$id')
          : null,
      child: SizedBox(
        width: 100,
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: img != null
                  ? CachedNetworkImage(
                      imageUrl: img,
                      width: 100,
                      height: 130,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 100,
                      height: 130,
                      color: cs.surfaceContainerHighest,
                      child: const Icon(Icons.person),
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

class _UserActivityCard extends ConsumerWidget {
  const _UserActivityCard({required this.activity, required this.cs});
  final Map<String, dynamic> activity;
  final ColorScheme cs;

  String _timeAgo(int timestamp, AppLocalizations l10n) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return l10n.timeNow;
    if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
    if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
    if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
    return l10n.timeWeeks((diff.inDays / 7).floor());
  }

  Future<bool?> _handleLike(WidgetRef ref, BuildContext context) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return null;
    }
    final actId = activity['id'] as int?;
    if (actId == null) return null;
    final graphql = ref.read(anilistGraphqlProvider);
    return graphql.toggleLike(actId, token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final actType = activity['type'] as String? ?? '';
    final isText = actType == 'TEXT';
    final media = activity['media'] as Map<String, dynamic>? ?? {};
    final title = media['title'] as Map<String, dynamic>? ?? {};
    final cover = (media['coverImage'] as Map?)?['large'] as String?;
    final mediaId = media['id'] as int?;
    final mediaType = media['type'] as String?;
    final kind = mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;

    final status = activity['status'] as String? ?? '';
    final progress = activity['progress'] as String?;
    final createdAt = activity['createdAt'] as int? ?? 0;
    final replyCount = activity['replyCount'] as int? ?? 0;
    final actId = activity['id'] as int?;

    String actionText = status;
    if (progress != null) actionText = '$status $progress';

    final name = (title['english'] as String?) ??
        (title['romaji'] as String?) ?? '';

    final textContent = activity['text'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ExpandableMarkdown(
                    text: textContent,
                    style: TextStyle(fontSize: 12, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded, size: 12, color: cs.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(createdAt, l10n),
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              )
            else
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: mediaId != null
                    ? () => context.push('/media/$mediaId?kind=${kind.code}')
                    : null,
                child: Row(
                  children: [
                    if (cover != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: cover,
                          width: 40,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                    if (cover != null) const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              style: TextStyle(fontSize: 12, color: cs.onSurface),
                              children: [
                                TextSpan(
                                  text: actionText,
                                  style: TextStyle(color: cs.onSurfaceVariant),
                                ),
                                const TextSpan(text: ' '),
                                TextSpan(
                                  text: name,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                kind == MediaKind.manga
                                    ? Icons.menu_book_rounded
                                    : Icons.animation_rounded,
                                size: 12,
                                color: cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _timeAgo(createdAt, l10n),
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Row(
              children: [
                AnimatedLikeButton(
                  isLiked: activity['isLiked'] as bool? ?? false,
                  likeCount: activity['likeCount'] as int? ?? 0,
                  onToggle: () => _handleLike(ref, context),
                  compact: true,
                ),
                const SizedBox(width: 12),
                if (actId != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/activity/$actId/replies'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 15, color: cs.onSurfaceVariant),
                          if (replyCount > 0) ...[
                            const SizedBox(width: 4),
                            Text('$replyCount',
                                style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
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

class _ExpandableMarkdown extends StatefulWidget {
  const _ExpandableMarkdown({required this.text, this.style});
  final String text;
  final TextStyle? style;

  @override
  State<_ExpandableMarkdown> createState() => _ExpandableMarkdownState();
}

class _ExpandableMarkdownState extends State<_ExpandableMarkdown> {
  bool _expanded = false;

  bool get _isLong => widget.text.length > 200;

  @override
  Widget build(BuildContext context) {
    if (!_isLong || _expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnilistMarkdown(widget.text, style: widget.style),
          if (_isLong)
            _ProfileExpandButton(
              label: 'Ver menos',
              icon: Icons.expand_less_rounded,
              onTap: () => setState(() => _expanded = false),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 80,
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white.withAlpha(0)],
                stops: const [0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: AnilistMarkdown(widget.text, style: widget.style),
              ),
            ),
          ),
        ),
        _ProfileExpandButton(
          label: 'Ver más',
          icon: Icons.expand_more_rounded,
          onTap: () => setState(() => _expanded = true),
        ),
      ],
    );
  }
}

class _ProfileExpandButton extends StatelessWidget {
  const _ProfileExpandButton({required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}
