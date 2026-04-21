import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/animated_like_button.dart';
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

enum _CommentSort { oldest, newest, mostLiked }

List<Map<String, dynamic>> _parseChildComments(dynamic raw) {
  if (raw is List) {
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }
  if (raw is String && raw.isNotEmpty) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    } catch (_) {
      return const [];
    }
  }
  return const [];
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

  _CommentSort _sort = _CommentSort.oldest;

  ({int id, String name})? _replyTarget;
  final _replyFocusNode = FocusNode();

  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyFocusNode.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final token = await ref.read(anilistTokenProvider.future);
        final data = await graphql
          .fetchForumThread(widget.threadId, token: token)
          .timeout(const Duration(seconds: 30));
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
          final children = _parseChildComments(c['childComments']);
          for (final child in children) {
            final childId = child['id'] as int?;
            if (childId != null) {
              _commentIsLiked[childId] = child['isLiked'] as bool? ?? false;
              _commentLikeCount[childId] = child['likeCount'] as int? ?? 0;
            }
          }
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  Future<bool?> _toggleThreadLike() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return null; }
    final id = _thread?['id'] as int?;
    if (id == null) return null;
    final liked = await ref.read(anilistGraphqlProvider)
        .toggleLike(id, token, type: 'THREAD');
    if (!mounted) return null;
    setState(() {
      _threadIsLiked = liked;
      _threadLikeCount =
          liked ? _threadLikeCount + 1 : (_threadLikeCount - 1).clamp(0, 99999);
    });
    return liked;
  }

  Future<bool?> _toggleCommentLike(int commentId) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return null; }
    final liked = await ref.read(anilistGraphqlProvider)
        .toggleLike(commentId, token, type: 'THREAD_COMMENT');
    if (!mounted) return null;
    setState(() {
      _commentIsLiked[commentId] = liked;
      final prev = _commentLikeCount[commentId] ?? 0;
      _commentLikeCount[commentId] =
          liked ? prev + 1 : (prev - 1).clamp(0, 99999);
    });
    return liked;
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) { _showLoginSnack(); return; }
    final replyTarget = _replyTarget;
    setState(() => _sending = true);
    try {
      final saved = await ref.read(anilistGraphqlProvider).saveThreadComment(
            widget.threadId,
            text,
            token,
            parentCommentId: replyTarget?.id,
          );
      if (!mounted) return;
      _commentController.clear();
      final newComment = Map<String, dynamic>.from(saved)
        ..putIfAbsent('isLocked', () => false)
        ..putIfAbsent('childComments', () => <dynamic>[]);
      final newId = newComment['id'] as int?;
      setState(() {
        _replyTarget = null;
        if (newId != null) {
          _commentIsLiked[newId] = false;
          _commentLikeCount[newId] = 0;
        }
        if (replyTarget == null) {
          // Top-level comment — append to list
          _comments = [..._comments, newComment];
        } else {
          // Reply — insert into parent's childComments
          _comments = _comments.map((c) {
            if (c['id'] == replyTarget.id) {
              final children = List<dynamic>.from(
                  (c['childComments'] as List?) ?? []);
              children.add(newComment);
              return Map<String, dynamic>.from(c)
                ..['childComments'] = children;
            }
            return c;
          }).toList();
        }
      });
      // Scroll to bottom after adding a top-level comment
      if (replyTarget == null && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
          );
        });
      }
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

  void _setReplyTarget(int id, String name) {
    setState(() => _replyTarget = (id: id, name: name));
    _replyFocusNode.requestFocus();
  }

  void _clearReplyTarget() => setState(() => _replyTarget = null);

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
            focusNode: _replyFocusNode,
            sending: _sending,
            onSend: _sendComment,
            replyTarget: _replyTarget,
            onCancelReply: _clearReplyTarget,
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
    final userId = user?['id'] as int?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final categories =
        (_thread?['categories'] as List?)?.cast<Map<String, dynamic>>() ?? [];

    return CustomScrollView(
      controller: _scrollController,
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
                    GestureDetector(
                      onTap: userId != null ? () => context.push('/user/$userId') : null,
                      child: ClipOval(
                        child: CachedNetworkImage(
                            imageUrl: avatar,
                            width: 24,
                            height: 24,
                            fit: BoxFit.cover),
                      ),
                    ),
                  if (avatar != null) const SizedBox(width: 6),
                  GestureDetector(
                    onTap: userId != null ? () => context.push('/user/$userId') : null,
                    child: Text(userName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
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
              AnimatedLikeButton(
                isLiked: _threadIsLiked,
                likeCount: _threadLikeCount,
                onToggle: _toggleThreadLike,
              ),

              const Divider(height: 32),

              if (_comments.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.forumReplies(_comments.length),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                      ),
                    ),
                    SegmentedButton<_CommentSort>(
                      style: SegmentedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        textStyle: const TextStyle(fontSize: 11),
                      ),
                      segments: const [
                        ButtonSegment<_CommentSort>(
                          value: _CommentSort.oldest,
                          icon: Icon(Icons.arrow_upward_rounded, size: 13),
                          tooltip: 'Más antiguos',
                        ),
                        ButtonSegment<_CommentSort>(
                          value: _CommentSort.newest,
                          icon: Icon(Icons.arrow_downward_rounded, size: 13),
                          tooltip: 'Más recientes',
                        ),
                        ButtonSegment<_CommentSort>(
                          value: _CommentSort.mostLiked,
                          icon: Icon(Icons.favorite_rounded, size: 13),
                          tooltip: 'Más likes',
                        ),
                      ],
                      selected: {_sort},
                      onSelectionChanged: (s) {
                        if (s.isNotEmpty) setState(() => _sort = s.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...(() {
                  final sorted = [..._comments];
                  switch (_sort) {
                    case _CommentSort.oldest:
                      sorted.sort((a, b) =>
                          (a['createdAt'] as int? ?? 0)
                              .compareTo(b['createdAt'] as int? ?? 0));
                    case _CommentSort.newest:
                      sorted.sort((a, b) =>
                          (b['createdAt'] as int? ?? 0)
                              .compareTo(a['createdAt'] as int? ?? 0));
                    case _CommentSort.mostLiked:
                      sorted.sort((a, b) =>
                          (_commentLikeCount[b['id'] as int? ?? 0] ??
                                  b['likeCount'] as int? ??
                                  0)
                              .compareTo(
                                  _commentLikeCount[a['id'] as int? ?? 0] ??
                                      a['likeCount'] as int? ??
                                      0));
                  }
                  return sorted.map((c) {
                    final id = c['id'] as int?;
                    return _CommentTile(
                      comment: c,
                      cs: cs,
                      isLiked:
                          id != null ? (_commentIsLiked[id] ?? false) : false,
                      likeCount: id != null
                          ? (_commentLikeCount[id] ?? 0)
                          : (c['likeCount'] as int? ?? 0),
                      onLike: id != null
                          ? () => _toggleCommentLike(id)
                          : null,
                      onReply: _setReplyTarget,
                      isLikedMap: _commentIsLiked,
                      likeCountMap: _commentLikeCount,
                      onToggleChildLike: _toggleCommentLike,
                    );
                  });
                })(),
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

class _CommentTile extends StatefulWidget {
  const _CommentTile({
    required this.comment,
    required this.cs,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onReply,
    required this.isLikedMap,
    required this.likeCountMap,
    required this.onToggleChildLike,
  });

  final Map<String, dynamic> comment;
  final ColorScheme cs;
  final bool isLiked;
  final int likeCount;
  final Future<bool?> Function()? onLike;
  final void Function(int id, String name) onReply;
  final Map<int, bool> isLikedMap;
  final Map<int, int> likeCountMap;
  final Future<bool?> Function(int id) onToggleChildLike;

  @override
  State<_CommentTile> createState() => _CommentTileState();
}

class _CommentTileState extends State<_CommentTile> {
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final cs = widget.cs;
    final user = widget.comment['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final body = widget.comment['comment'] as String?;
    final createdAt = widget.comment['createdAt'] as int?;
    final commentId = widget.comment['id'] as int?;
    final isLocked = widget.comment['isLocked'] as bool? ?? false;
    final children = _parseChildComments(widget.comment['childComments']);
    final hasChildren = children.isNotEmpty;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CommentHeader(
            avatar: avatar,
            userName: userName,
            userId: user?['id'] as int?,
            createdAt: createdAt,
            cs: cs,
          ),
          if (body != null && body.isNotEmpty) ...[
            const SizedBox(height: 8),
            AnilistMarkdown(body,
                style: TextStyle(
                    fontSize: 13, color: cs.onSurface, height: 1.5)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              if (widget.onLike != null)
                AnimatedLikeButton(
                  isLiked: widget.isLiked,
                  likeCount: widget.likeCount,
                  onToggle: widget.onLike!,
                ),
              const SizedBox(width: 12),
              if (commentId != null)
                isLocked
                    ? _LockedChip(cs: cs)
                    : _ReplyButton(
                        onTap: () => widget.onReply(commentId, userName),
                        cs: cs,
                      ),
            ],
          ),
          if (hasChildren) ...[
            const SizedBox(height: 10),
            // Collapse/expand toggle strip
            InkWell(
              onTap: () => setState(() => _collapsed = !_collapsed),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(180),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: cs.outlineVariant.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _collapsed ? -0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          size: 14, color: cs.primary),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _collapsed
                          ? '${children.length} respuesta${children.length == 1 ? '' : 's'}'
                          : 'Ocultar respuestas',
                      style: TextStyle(
                          fontSize: 11,
                          color: cs.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            if (!_collapsed) ...[
              const SizedBox(height: 8),
              ...children.map((child) {
                final childId = child['id'] as int?;
                final childUser = child['user'] as Map<String, dynamic>?;
                final childName = childUser?['name'] as String? ?? '';
                return _ChildCommentTile(
                  comment: child,
                  cs: cs,
                  isLiked: childId != null ? (widget.isLikedMap[childId] ?? false) : false,
                  likeCount: childId != null
                      ? (widget.likeCountMap[childId] ?? 0)
                      : (child['likeCount'] as int? ?? 0),
                  onLike: childId != null ? () => widget.onToggleChildLike(childId) : null,
                  onReply: childId != null
                      ? () => widget.onReply(childId, childName)
                      : null,
                );
              }),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _CommentHeader extends StatelessWidget {
  const _CommentHeader({
    required this.avatar,
    required this.userName,
    this.userId,
    required this.createdAt,
    required this.cs,
    this.small = false,
  });

  final String? avatar;
  final String userName;
  final int? userId;
  final int? createdAt;
  final ColorScheme cs;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final sz = small ? 18.0 : 22.0;
    void goToProfile() {
      if (userId != null) context.push('/user/$userId');
    }
    return Row(
      children: [
        if (avatar != null)
          GestureDetector(
            onTap: goToProfile,
            child: ClipOval(
              child: CachedNetworkImage(
                  imageUrl: avatar!,
                  width: sz,
                  height: sz,
                  fit: BoxFit.cover),
            ),
          ),
        if (avatar != null) SizedBox(width: small ? 4 : 6),
        GestureDetector(
          onTap: goToProfile,
          child: Text(userName,
              style: TextStyle(
                  fontSize: small ? 11.0 : 12.0,
                  fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: small ? 4 : 6),
        Text(_timeAgoForum(createdAt),
            style: TextStyle(
                fontSize: small ? 10.0 : 11.0,
                color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ReplyButton extends StatelessWidget {
  const _ReplyButton({
    required this.onTap,
    required this.cs,
    this.small = false,
  });

  final VoidCallback onTap;
  final ColorScheme cs;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.reply_rounded,
                size: small ? 14.0 : 16.0,
                color: cs.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(l10n.forumReplyButton,
                style: TextStyle(
                    fontSize: small ? 11.0 : 12.0,
                    color: cs.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _LockedChip extends StatelessWidget {
  const _LockedChip({required this.cs, this.small = false});

  final ColorScheme cs;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Este comentario está bloqueado y no acepta respuestas.'),
          duration: Duration(seconds: 3),
        ),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded,
                size: small ? 13.0 : 15.0,
                color: cs.onSurfaceVariant.withAlpha(160)),
            const SizedBox(width: 4),
            Text('Bloqueado',
                style: TextStyle(
                    fontSize: small ? 11.0 : 12.0,
                    color: cs.onSurfaceVariant.withAlpha(160))),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ChildCommentTile extends StatelessWidget {
  const _ChildCommentTile({
    required this.comment,
    required this.cs,
    required this.isLiked,
    required this.likeCount,
    required this.onLike,
    required this.onReply,
  });

  final Map<String, dynamic> comment;
  final ColorScheme cs;
  final bool isLiked;
  final int likeCount;
  final Future<bool?> Function()? onLike;
  final VoidCallback? onReply;

  @override
  Widget build(BuildContext context) {
    final user = comment['user'] as Map<String, dynamic>?;
    final userName = user?['name'] as String? ?? '';
    final avatar = (user?['avatar'] as Map?)?['medium'] as String?;
    final body = comment['comment'] as String?;
    final createdAt = comment['createdAt'] as int?;
    final isLocked = comment['isLocked'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 2,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: cs.outlineVariant,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CommentHeader(
                    avatar: avatar,
                    userName: userName,
                    userId: user?['id'] as int?,
                    createdAt: createdAt,
                    cs: cs,
                    small: true,
                  ),
                  if (body != null && body.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    AnilistMarkdown(body,
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurface, height: 1.5)),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (onLike != null)
                        AnimatedLikeButton(
                          isLiked: isLiked,
                          likeCount: likeCount,
                          onToggle: onLike!,
                          iconSize: 14,
                          fontSize: 11,
                        ),
                      const SizedBox(width: 10),
                      if (isLocked)
                        _LockedChip(cs: cs, small: true)
                      else if (onReply != null)
                        _ReplyButton(onTap: onReply!, cs: cs, small: true),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
class _ReplyInputBar extends ConsumerWidget {
  const _ReplyInputBar({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
    required this.replyTarget,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  final ({int id, String name})? replyTarget;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final isLoggedIn = tokenAsync.valueOrNull != null;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: cs.outlineVariant.withAlpha(60))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (replyTarget != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded,
                      size: 14, color: cs.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.forumReplyingTo(replyTarget!.name),
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.primary,
                          fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: onCancelReply,
                    child: Icon(Icons.close_rounded,
                        size: 16, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 8, 8 + bottomInset),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    enabled: isLoggedIn && !sending,
                    maxLines: 3,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: isLoggedIn
                          ? l10n.writeReplyHint
                          : l10n.loginRequiredComment,
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
          ),
        ],
      ),
    );
  }
}
