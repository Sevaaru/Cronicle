import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

enum _FeedFilter {
  all,
  anime,
  manga,
  movie,
  tv,
  game;

  String get label => switch (this) {
        _FeedFilter.all => 'Global',
        _FeedFilter.anime => 'Anime',
        _FeedFilter.manga => 'Manga',
        _FeedFilter.movie => 'Películas',
        _FeedFilter.tv => 'Series',
        _FeedFilter.game => 'Juegos',
      };

  IconData get icon => switch (this) {
        _FeedFilter.all => Icons.public_rounded,
        _FeedFilter.anime => Icons.animation_rounded,
        _FeedFilter.manga => Icons.menu_book_rounded,
        _FeedFilter.movie => Icons.movie_rounded,
        _FeedFilter.tv => Icons.tv_rounded,
        _FeedFilter.game => Icons.sports_esports_rounded,
      };
}

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  _FeedFilter _filter = _FeedFilter.all;

  AsyncValue<List<FeedActivity>> _getFilteredFeed() {
    return switch (_filter) {
      _FeedFilter.all => ref.watch(anilistFeedProvider),
      _FeedFilter.anime =>
        ref.watch(anilistFeedByTypeProvider('ANIME_LIST')),
      _FeedFilter.manga =>
        ref.watch(anilistFeedByTypeProvider('MANGA_LIST')),
      _ => const AsyncData([]),
    };
  }

  void _invalidateFeed() {
    switch (_filter) {
      case _FeedFilter.all:
        ref.invalidate(anilistFeedProvider);
      case _FeedFilter.anime:
        ref.invalidate(anilistFeedByTypeProvider('ANIME_LIST'));
      case _FeedFilter.manga:
        ref.invalidate(anilistFeedByTypeProvider('MANGA_LIST'));
      default:
        break;
    }
  }

  bool get _isPlaceholderFilter =>
      _filter == _FeedFilter.movie ||
      _filter == _FeedFilter.tv ||
      _filter == _FeedFilter.game;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _invalidateFeed,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: _FeedFilter.values.length,
              itemBuilder: (context, i) {
                final f = _FeedFilter.values[i];
                final selected = _filter == f;
                return FilterChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 15),
                      const SizedBox(width: 4),
                      Text(f.label, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                  onSelected: (_) => setState(() => _filter = f),
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _isPlaceholderFilter
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_filter.icon, size: 48,
                            color: colorScheme.onSurfaceVariant.withAlpha(80)),
                        const SizedBox(height: 12),
                        Text(
                          'Feed de ${_filter.label} — próximamente',
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  )
                : _FeedList(
                    feedAsync: _getFilteredFeed(),
                    onRefresh: _invalidateFeed,
                    l10n: l10n,
                  ),
          ),
        ],
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  const _FeedList({
    required this.feedAsync,
    required this.onRefresh,
    required this.l10n,
  });

  final AsyncValue<List<FeedActivity>> feedAsync;
  final VoidCallback onRefresh;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return feedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 48, color: colorScheme.error),
            const SizedBox(height: 12),
            Text(l10n.errorNetwork),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRefresh,
              child: Text(l10n.feedRetry),
            ),
          ],
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return Center(child: Text(l10n.feedEmpty));
        }
        return RefreshIndicator(
          onRefresh: () async => onRefresh(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
            itemCount: activities.length,
            itemBuilder: (context, i) =>
                _ActivityCard(activity: activities[i]),
          ),
        );
      },
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});

  final FeedActivity activity;

  IconData _sourceIcon(MediaKind kind) => switch (kind) {
        MediaKind.anime => Icons.animation_rounded,
        MediaKind.manga => Icons.menu_book_rounded,
        MediaKind.movie => Icons.movie_rounded,
        MediaKind.tv => Icons.tv_rounded,
        MediaKind.game => Icons.sports_esports_rounded,
      };

  Color _sourceColor(MediaKind kind, ColorScheme cs) => switch (kind) {
        MediaKind.anime => cs.primary,
        MediaKind.manga => Colors.deepPurple,
        MediaKind.movie => Colors.amber.shade700,
        MediaKind.tv => Colors.teal,
        MediaKind.game => Colors.redAccent,
      };

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'ahora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}sem';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          if (activity.mediaId != null) {
            context.push('/media/${activity.mediaId}?kind=${activity.source.code}');
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.surfaceContainerHighest,
              backgroundImage: activity.userAvatarUrl != null
                  ? CachedNetworkImageProvider(activity.userAvatarUrl!)
                  : null,
              child: activity.userAvatarUrl == null
                  ? Text(
                      activity.userName.isNotEmpty
                          ? activity.userName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          activity.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        _sourceIcon(activity.source),
                        size: 13,
                        color: _sourceColor(activity.source, colorScheme),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _timeAgo(activity.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface,
                      ),
                      children: [
                        TextSpan(
                          text: activity.action,
                          style: TextStyle(color: colorScheme.onSurfaceVariant),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: activity.mediaTitle,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (activity.mediaPosterUrl != null) ...[
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: activity.mediaPosterUrl!,
                  width: 45,
                  height: 64,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
