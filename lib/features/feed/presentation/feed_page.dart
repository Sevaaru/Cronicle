import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class FeedPage extends ConsumerWidget {
  const FeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final feedAsync = ref.watch(anilistFeedProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(anilistFeedProvider),
          ),
        ],
      ),
      body: feedAsync.when(
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
                onPressed: () => ref.invalidate(anilistFeedProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('No hay actividad reciente'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(anilistFeedProvider),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
              itemCount: activities.length,
              itemBuilder: (context, i) =>
                  _ActivityCard(activity: activities[i]),
            ),
          );
        },
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.surfaceContainerHighest,
            backgroundImage: activity.userAvatarUrl != null
                ? CachedNetworkImageProvider(activity.userAvatarUrl!)
                : null,
            child: activity.userAvatarUrl == null
                ? Text(
                    activity.userName.isNotEmpty
                        ? activity.userName[0].toUpperCase()
                        : '?',
                    style: TextStyle(color: colorScheme.onSurface),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      activity.userName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Icon(
                      _sourceIcon(activity.source),
                      size: 14,
                      color: _sourceColor(activity.source, colorScheme),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _timeAgo(activity.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13,
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
                if (activity.mediaPosterUrl != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: activity.mediaPosterUrl!,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
