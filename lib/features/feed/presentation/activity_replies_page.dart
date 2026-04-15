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
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
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

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequiredLike)),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final result = await graphql.saveActivityReply(
          widget.activityId, text, token);
      if (!mounted) return;
      _replyController.clear();
      setState(() {
        _replies ??= [];
        _replies!.add(result);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.commentsTitle)),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _replies == null || _replies!.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.chat_bubble_outline,
                                size: 48,
                                color: cs.onSurfaceVariant.withAlpha(80)),
                            const SizedBox(height: 12),
                            Text(l10n.noComments,
                                style: TextStyle(color: cs.onSurfaceVariant)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: _replies!.length,
                        itemBuilder: (context, i) => _ReplyCard(
                          reply: _replies![i],
                          timeAgo: (dt) => _timeAgo(dt, l10n),
                        ),
                      ),
          ),
          _ReplyInputBar(
            controller: _replyController,
            sending: _sending,
            onSend: _sendReply,
          ),
        ],
      ),
    );
  }
}

class _ReplyInputBar extends ConsumerWidget {
  const _ReplyInputBar({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final isLoggedIn = tokenAsync.valueOrNull != null;

    final shellNavPad = MediaQuery.of(context).viewPadding.bottom + 64;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + shellNavPad),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border: Border(top: BorderSide(color: cs.outlineVariant.withAlpha(60))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: isLoggedIn && !sending,
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: isLoggedIn
                    ? AppLocalizations.of(context)!.writeReplyHint
                    : AppLocalizations.of(context)!.loginRequiredLike,
                hintStyle: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                isDense: true,
              ),
              style: TextStyle(fontSize: 13, color: cs.onSurface),
            ),
          ),
          const SizedBox(width: 6),
          sending
              ? const SizedBox(
                  width: 36,
                  height: 36,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  icon: Icon(Icons.send_rounded, color: cs.primary),
                  onPressed: isLoggedIn ? onSend : null,
                ),
        ],
      ),
    );
  }
}

class _ReplyCard extends ConsumerStatefulWidget {
  const _ReplyCard({required this.reply, required this.timeAgo});
  final Map<String, dynamic> reply;
  final String Function(DateTime) timeAgo;

  @override
  ConsumerState<_ReplyCard> createState() => _ReplyCardState();
}

class _ReplyCardState extends ConsumerState<_ReplyCard> {
  late bool _isLiked;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.reply['isLiked'] as bool? ?? false;
    _likeCount = widget.reply['likeCount'] as int? ?? 0;
  }

  Future<void> _handleLike() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return;
    }
    final replyId = widget.reply['id'] as int?;
    if (replyId == null) return;
    final graphql = ref.read(anilistGraphqlProvider);
    final liked = await graphql.toggleLike(replyId, token, type: 'ACTIVITY_REPLY');
    if (!mounted) return;
    setState(() {
      _isLiked = liked;
      _likeCount = liked ? _likeCount + 1 : (_likeCount - 1).clamp(0, 999999);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final user = widget.reply['user'] as Map<String, dynamic>? ?? {};
    final avatar = (user['avatar'] as Map?)?['medium'] as String?;
    final userName = user['name'] as String? ?? '';
    final userId = user['id'] as int?;
    final text = widget.reply['text'] as String? ?? '';
    final createdAt = DateTime.fromMillisecondsSinceEpoch(
      ((widget.reply['createdAt'] as int?) ?? 0) * 1000,
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
              Text(widget.timeAgo(createdAt),
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 8),
          AnilistMarkdown(text,
              style: TextStyle(
                  fontSize: 13, color: cs.onSurface, height: 1.4)),
          const SizedBox(height: 6),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _handleLike,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    size: 15,
                    color: _isLiked ? Colors.red.shade400 : cs.onSurfaceVariant,
                  ),
                  if (_likeCount > 0) ...[
                    const SizedBox(width: 4),
                    Text('$_likeCount',
                        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
