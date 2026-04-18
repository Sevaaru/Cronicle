import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

String _timeAgoForum(int? createdAt) {
  if (createdAt == null) return '';
  final dt = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  final diff = DateTime.now().difference(dt);
  if (diff.inDays > 365) return '${diff.inDays ~/ 365}a';
  if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo';
  if (diff.inDays > 0) return '${diff.inDays}d';
  if (diff.inHours > 0) return '${diff.inHours}h';
  return '${diff.inMinutes}min';
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class ForumThreadPage extends ConsumerStatefulWidget {
  const ForumThreadPage({
    super.key,
    required this.threadId,
    this.initialData,
  });

  final int threadId;
  final Map<String, dynamic>? initialData;

  @override
  ConsumerState<ForumThreadPage> createState() => _ForumThreadPageState();
}

class _ForumThreadPageState extends ConsumerState<ForumThreadPage> {
  Map<String, dynamic>? _thread;
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  String? _error;

  bool _threadIsLiked = false;
  int _threadLikeCount = 0;

  final Map<int, bool> _commentIsLiked = {};
  final Map<int, int> _commentLikeCount = {};

  final _commentController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final token = await ref.read(anilistTokenProvider.future);
      final data = await graphql.fetchForumThread(widget.threadId, token: token);
      if (!mounted) return;
      final comments =
          (data?['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      setState(() {
        _thread = data;
        _comments = comments;
        _threadIsLiked = data?['isLiked'] as bool? ?? false;
        _threadLikeCount = data?['likeCount'] as int? ?? 0;
        for (final c in comments) {
          final id = c['id'] as int?;
          if (id != null) {
            _commentIsLiked[id] = c['isLiked'] as bool? ?? false;
            _commentLikeCount[id] = c['likeCount'] as int? ?? 0;
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  Future<void> _toggleThreadLike() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return; }
    final id = _thread?['id'] as int?;
    if (id == null) return;
    final liked = await ref.read(anilistGraphqlProvider)
        .toggleLike(id, token, type: 'THREAD');
    if (!mounted) return;
    setState(() {
      _threadIsLiked = liked;
      _threadLikeCount =
          liked ? _threadLikeCount + 1 : (_threadLikeCount - 1).clamp(0, 99999);
    });
  }

  Future<void> _toggleCommentLike(int commentId) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return; }
    final liked = await ref.read(anilistGraphqlProvider)
        .toggleLike(commentId, token, type: 'THREAD_COMMENT');
    if (!mounted) return;
    setState(() {
      _commentIsLiked[commentId] = liked;
      final prev = _commentLikeCount[commentId] ?? 0;
      _commentLikeCount[commentId] =
          liked ? prev + 1 : (prev - 1).clamp(0, 99999);
    });
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return; }
    setState(() => _sending = true);
    try {
      final result = await ref.read(anilistGraphqlProvider)
          .saveThreadComment(widget.threadId, text, token);
      if (!mounted) return;
      _commentController.clear();
      final id = result['id'] as int?;
      if (id != null) {
        _commentIsLiked[id] = false;
        _commentLikeCount[id] = 0;
      }
      setState(() => _comments = [..._comments, result]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.errorWithMessage(e))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showLoginSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppLocalizations.of(context)!.loginRequiredLike)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final title = _thread?['title'] as String? ??
        widget.initialData?['title'] as String? ??
        l10n.forumThread;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? CustomScrollView(slivers: [
                    SliverAppBar(
                        pinned: true,
                        title: Text(title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis)),
                    const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator())),
                  ])
                : _error != null
                    ? CustomScrollView(slivers: [
                        SliverAppBar(
                            pinned: true,
                            title: Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis)),
                        SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off_rounded,
                                    size: 48,
                                    color: cs.onSurfaceVariant.withAlpha(120)),
                                const SizedBox(height: 12),
                                Text(_error!,
                                    textAlign: TextAlign.center,
                                    style:
                                        TextStyle(color: cs.onSurfaceVariant)),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _load,
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: Text(l10n.feedRetry),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ])
                    : _buildContent(context, cs, l10n, title),
          ),
          _ReplyInputBar(
            controller: _commentController,
            sending: _sending,
            onSend: _sendComment,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n,
    String title,
  ) {
    final body = _thread?['body'] as String?;
    final createdAt = _thread?['createdAt'] as int?;
    final viewCount = _thread?['viewCount'] as int? ?? 0;
    final user = _thread?['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final categories =
        (_thread?['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          title: Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),

              if (categories.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: categories.map((c) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(c['name'] as String? ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: cs.onPrimaryContainer,
                              fontWeight: FontWeight.w600)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],

              Row(
                children: [
                  if (avatar != null)
                    ClipOval(
                      child: CachedNetworkImage(
                          imageUrl: avatar,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover),
                    ),
                  if (avatar != null) const SizedBox(width: 6),
                  Text(userName,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 6),
                  Text('Â· ${_timeAgoForum(createdAt)}',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                  const Spacer(),
                  Icon(Icons.visibility_outlined,
                      size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 3),
                  Text('$viewCount',
                      style: TextStyle(
                          fontSize: 12, color: cs.onSurfaceVariant)),
                ],
              ),

              if (body != null && body.isNotEmpty) ...[
                const Divider(height: 24),
                AnilistMarkdown(body,
                    style: TextStyle(
                        fontSize: 14,
                        color: cs.onSurface,
                        height: 1.55)),
              ],

              const SizedBox(height: 8),
              _LikeButton(
                isLiked: _threadIsLiked,
                count: _threadLikeCount,
                onTap: _toggleThreadLike,
                cs: cs,
              ),

              const Divider(height: 32),

              if (_comments.isNotEmpty) ...[
                Text(
                  l10n.forumReplies(_comments.length),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                const SizedBox(height: 10),
                ..._comments.map((c) {
                  final id = c['id'] as int?;
                  return _CommentTile(
                    comment: c,
                    cs: cs,
                    isLiked:
                        id != null ? (_commentIsLiked[id] ?? false) : false,
                    likeCount: id != null
                        ? (_commentLikeCount[id] ?? 0)
                        : (c['likeCount'] as int? ?? 0),
                    onLike: id != null ? () => _toggleCommentLike(id) : null,
                  );
                }),
              ] else
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(l10n.forumNoReplies,
                        style: TextStyle(color: cs.onSurfaceVariant)),
                  ),
                ),

              const SizedBox(height: 16),
            ]),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _LikeButton extends StatelessWidget {
  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.onTap,
    required this.cs,
  });

  final bool isLiked;
  final int count;
  final VoidCallback onTap;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 18,
              color: isLiked ? cs.error : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                color: isLiked ? cs.error : cs.onSurfaceVariant,
                fontWeight: isLiked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.cs,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
  });

  final Map<String, dynamic> comment;
  final ColorScheme cs;
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onLike;

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final body = comment['comment'] as String?;
    final createdAt = comment['createdAt'] as int?;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (avatar != null)
                ClipOval(
                  child: CachedNetworkImage(
                      imageUrl: avatar,
                      width: 22,
                      height: 22,
                      fit: BoxFit.cover),
                ),
              if (avatar != null) const SizedBox(width: 6),
              Text(userName,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              Text(_timeAgoForum(createdAt),
                  style:
                      TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
              const Spacer(),
              if (onLike != null)
                _LikeButton(
                  isLiked: isLiked,
                  count: likeCount,
                  onTap: onLike!,
                  cs: cs,
                ),
            ],
          ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 8),
            AnilistMarkdown(body,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
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
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final isLoggedIn = tokenAsync.valueOrNull != null;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomInset),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: cs.outlineVariant.withAlpha(60))),
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
                    ? l10n.writeReplyHint
                    : l10n.loginRequiredLike,
                hintStyle:
                    TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
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
