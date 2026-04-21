import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

class ForumMediaThreadsPage extends ConsumerWidget {
  const ForumMediaThreadsPage({super.key, required this.mediaId});

  final int mediaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final threadsAsync = ref.watch(anilistMediaThreadsProvider(mediaId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.forumDiscussions,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ),
      body: threadsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.errorWithMessage(e))),
        data: (threads) {
          if (threads.isEmpty) {
            return Center(
              child: Text(l10n.forumNoReplies,
                  style: TextStyle(color: cs.onSurfaceVariant)),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: threads.length,
            itemBuilder: (context, index) {
              final t = threads[index];
              return _ThreadTile(thread: t, cs: cs);
            },
          );
        },
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  const _ThreadTile({required this.thread, required this.cs});

  final Map<String, dynamic> thread;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final id = thread['id'] as int?;
    final title = thread['title'] as String? ?? '';
    final replyCount = thread['replyCount'] as int? ?? 0;
    final viewCount = thread['viewCount'] as int? ?? 0;
    final createdAt = thread['createdAt'] as int?;
    final user = thread['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;

    String timeAgo = '';
    if (createdAt != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
      final diff = DateTime.now().difference(dt);
      if (diff.inDays > 365) {
        timeAgo = '${diff.inDays ~/ 365}a';
      } else if (diff.inDays > 30) {
        timeAgo = '${diff.inDays ~/ 30}mo';
      } else if (diff.inDays > 0) {
        timeAgo = '${diff.inDays}d';
      } else if (diff.inHours > 0) {
        timeAgo = '${diff.inHours}h';
      } else {
        timeAgo = '${diff.inMinutes}min';
      }
    }

    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: id == null
            ? null
            : () => context.push('/forum/thread/$id', extra: thread),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                if (avatar != null)
                  ClipOval(
                    child: Image.network(avatar,
                        width: 18, height: 18, fit: BoxFit.cover),
                  ),
                if (avatar != null) const SizedBox(width: 4),
                Text(userName,
                    style:
                        TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
                if (timeAgo.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text('· $timeAgo',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
                const Spacer(),
                Icon(Icons.comment_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$replyCount',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
                const SizedBox(width: 8),
                Icon(Icons.visibility_outlined,
                    size: 14, color: cs.onSurfaceVariant),
                const SizedBox(width: 3),
                Text('$viewCount',
                    style: TextStyle(
                        fontSize: 12, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
