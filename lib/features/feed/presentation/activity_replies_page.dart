import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

String _timeAgo(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return l10n.timeWeeks((diff.inDays / 7).floor());
}

class ActivityRepliesPage extends ConsumerStatefulWidget {
  const ActivityRepliesPage({super.key, required this.activityId});
  final int activityId;

  @override
  ConsumerState<ActivityRepliesPage> createState() =>
      _ActivityRepliesPageState();
}

class _ActivityRepliesPageState extends ConsumerState<ActivityRepliesPage> {
  List<Map<String, dynamic>>? _replies;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final data = await graphql.fetchActivityReplies(widget.activityId,
        token: token);
    if (!mounted) return;
    setState(() {
      _replies = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commentsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _replies == null || _replies!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 48, color: cs.onSurfaceVariant.withAlpha(80)),
                      const SizedBox(height: 12),
                      Text(l10n.noComments,
                          style: TextStyle(color: cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _replies!.length,
                  itemBuilder: (context, i) =>
                      _ReplyCard(reply: _replies![i], timeAgo: (dt) => _timeAgo(dt, l10n)),
                ),
    );
  }
}

class _ReplyCard extends StatelessWidget {
  const _ReplyCard({required this.reply, required this.timeAgo});
  final Map<String, dynamic> reply;
  final String Function(DateTime) timeAgo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = reply['user'] as Map<String, dynamic>? ?? {};
    final avatar = (user['avatar'] as Map?)?['medium'] as String?;
    final userName = user['name'] as String? ?? '';
    final userId = user['id'] as int?;
    final text = reply['text'] as String? ?? '';
    final likeCount = reply['likeCount'] as int? ?? 0;
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      ((reply['createdAt'] as int?) ?? 0) * 1000,
    );

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: userId != null
                    ? () => context.push('/user/$userId')
                    : null,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: cs.surfaceContainerHighest,
                  backgroundImage:
                      avatar != null ? CachedNetworkImageProvider(avatar) : null,
                  child: avatar == null
                      ? Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                          style: TextStyle(fontSize: 10, color: cs.onSurface))
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: userId != null
                      ? () => context.push('/user/$userId')
                      : null,
                  child: Text(userName,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              Text(timeAgo(createdAt),
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          AnilistMarkdown(text,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface, height: 1.4)),
          if (likeCount > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.favorite, size: 14, color: Colors.red.shade300),
                const SizedBox(width: 4),
                Text('$likeCount',
                    style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
