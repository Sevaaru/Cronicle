import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/animated_like_button.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';

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

  // Pagination. We track the range of pages that has been loaded so we can
  // page forward (oldest sort) or backward from the last page (newest sort)
  // without ever loading every page at once — that would melt AniList's
  // rate limit on long threads.
  int _minLoadedPage = 1;
  int _maxLoadedPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  static const int _commentsPerPage = 25;

  bool get _hasMoreInDirection {
    switch (_sort) {
      case _CommentSort.oldest:
        return _maxLoadedPage < _lastPage;
      case _CommentSort.newest:
        return _minLoadedPage > 1;
      case _CommentSort.mostLiked:
        // Sort by likes operates on whatever the user has scrolled through;
        // we do not auto-fetch in this mode to avoid hammering AniList.
        return false;
    }
  }

  ({int id, String name})? _replyTarget;
  final _replyFocusNode = FocusNode();

  final _commentController = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _replyFocusNode.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 600 &&
        _hasMoreInDirection &&
        !_loadingMore &&
        !_loading) {
      _loadMoreInDirection();
    }
  }

  void _ingestComments(List<Map<String, dynamic>> comments) {
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
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _minLoadedPage = 1;
      _maxLoadedPage = 1;
      _comments = [];
    });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final token = await ref.read(anilistTokenProvider.future);
      final data = await graphql
          .fetchForumThread(widget.threadId,
              token: token, page: 1, perPage: _commentsPerPage)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      final comments =
          (data?['comments'] as List?)?.cast<Map<String, dynamic>>() ?? [];
      final pageInfo = data?['pageInfo'] as Map<String, dynamic>?;
      _ingestComments(comments);
      setState(() {
        _thread = data;
        _comments = comments;
        _threadIsLiked = data?['isLiked'] as bool? ?? false;
        _threadLikeCount = data?['likeCount'] as int? ?? 0;
        _minLoadedPage = (pageInfo?['currentPage'] as int?) ?? 1;
        _maxLoadedPage = _minLoadedPage;
        _lastPage = (pageInfo?['lastPage'] as int?) ?? 1;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = '$e'; });
    }
  }

  /// Loads the next page in the current sort direction:
  /// - oldest  → page after `_maxLoadedPage`, appended to the bottom.
  /// - newest  → page before `_minLoadedPage`, appended (sorting puts it on
  ///   top anyway so it visually fills downward).
  Future<void> _loadMoreInDirection() async {
    if (_loadingMore || !_hasMoreInDirection) return;
    final int targetPage;
    final bool reverse;
    switch (_sort) {
      case _CommentSort.oldest:
        targetPage = _maxLoadedPage + 1;
        reverse = false;
      case _CommentSort.newest:
        targetPage = _minLoadedPage - 1;
        reverse = true;
      case _CommentSort.mostLiked:
        return;
    }
    setState(() => _loadingMore = true);
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final token = await ref.read(anilistTokenProvider.future);
      final result = await graphql
          .fetchForumThreadCommentsPage(widget.threadId,
              token: token, page: targetPage, perPage: _commentsPerPage)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      _ingestComments(result.comments);
      setState(() {
        _comments = [..._comments, ...result.comments];
        _lastPage = (result.pageInfo?['lastPage'] as int?) ?? _lastPage;
        if (reverse) {
          _minLoadedPage = targetPage;
        } else {
          _maxLoadedPage = targetPage;
        }
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Resets the comment list and fetches the first page for the new sort
  /// direction. For `newest` we jump straight to the last page and let the
  /// user scroll backwards page-by-page instead of pulling the whole thread.
  Future<void> _loadInitialForSort(_CommentSort sort) async {
    final int targetPage;
    switch (sort) {
      case _CommentSort.oldest:
        targetPage = 1;
      case _CommentSort.newest:
        targetPage = _lastPage;
      case _CommentSort.mostLiked:
        return;
    }
    if (_loadingMore) return;
    setState(() {
      _loadingMore = true;
      _comments = [];
    });
    try {
      final graphql = ref.read(anilistGraphqlProvider);
      final token = await ref.read(anilistTokenProvider.future);
      final result = await graphql
          .fetchForumThreadCommentsPage(widget.threadId,
              token: token, page: targetPage, perPage: _commentsPerPage)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      _ingestComments(result.comments);
      setState(() {
        _comments = result.comments;
        _minLoadedPage = targetPage;
        _maxLoadedPage = targetPage;
        _lastPage = (result.pageInfo?['lastPage'] as int?) ?? _lastPage;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _setSort(_CommentSort sort) {
    if (sort == _sort) return;
    final previous = _sort;
    setState(() => _sort = sort);
    // Most-liked sorts the comments already in memory — never trigger a full
    // load, that would collapse AniList's rate limit on big threads.
    if (sort == _CommentSort.mostLiked) return;
    // Oldest/newest each have their own pagination window. Reset and fetch
    // the appropriate edge page (page 1 for oldest, last page for newest).
    final needsReload = previous == _CommentSort.mostLiked ||
        (sort == _CommentSort.oldest && _minLoadedPage != 1) ||
        (sort == _CommentSort.newest && _maxLoadedPage != _lastPage);
    if (needsReload) {
      _loadInitialForSort(sort);
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
          _comments = [..._comments, newComment];
        } else {
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: cs.onSurface)),
                    const SizedBox(height: 10),

                    if (categories.isNotEmpty) ...[
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: categories.map((c) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.secondaryContainer
                                  .withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(c['name'] as String? ?? '',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: cs.onSecondaryContainer,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2)),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],

                    Row(
                      children: [
                        if (avatar != null)
                          GestureDetector(
                            onTap: userId != null
                                ? () => context.push('/user/$userId')
                                : null,
                            child: ClipOval(
                              child: CachedNetworkImage(
                                  imageUrl: avatar,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover),
                            ),
                          ),
                        if (avatar != null) const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: userId != null
                                    ? () => context.push('/user/$userId')
                                    : null,
                                child: Text(userName,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: cs.onSurface)),
                              ),
                              Text(_timeAgoForum(createdAt),
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest
                                .withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.visibility_outlined,
                                  size: 13, color: cs.onSurfaceVariant),
                              const SizedBox(width: 5),
                              Text('$viewCount',
                                  style: TextStyle(
                                      fontSize: 11.5,
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),

                    if (body != null && body.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      AnilistMarkdown(body,
                          style: TextStyle(
                              fontSize: 14,
                              color: cs.onSurface,
                              height: 1.55)),
                    ],

                    const SizedBox(height: 12),
                    AnimatedLikeButton(
                      isLiked: _threadIsLiked,
                      likeCount: _threadLikeCount,
                      onToggle: _toggleThreadLike,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              if (_comments.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.forumReplies(_comments.length),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                          if (_lastPage > 1)
                            Text(
                              _sort == _CommentSort.newest
                                  ? 'Pages $_minLoadedPage–$_maxLoadedPage / $_lastPage'
                                  : 'Page $_maxLoadedPage / $_lastPage',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.w500),
                            ),
                        ],
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
                        if (s.isNotEmpty) _setSort(s.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ],
                ),
                if (_loadingMore && _comments.isEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _sort == _CommentSort.newest
                            ? 'Loading newest comments…'
                            : 'Loading comments…',
                        style: TextStyle(
                            fontSize: 12, color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
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
                if (_loadingMore && _comments.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: cs.primary),
                      ),
                    ),
                  ),
                if (!_hasMoreInDirection && _comments.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest
                            .withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '· End of thread ·',
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.4),
                      ),
                    ),
                  ),
                ],
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

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
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
            const SizedBox(height: 10),
            AnilistMarkdown(body,
                style: TextStyle(
                    fontSize: 13.5, color: cs.onSurface, height: 1.5)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (widget.onLike != null)
                AnimatedLikeButton(
                  isLiked: widget.isLiked,
                  likeCount: widget.likeCount,
                  onToggle: widget.onLike!,
                  compact: true,
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
            InkWell(
              onTap: () => setState(() => _collapsed = !_collapsed),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.primaryContainer.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedRotation(
                      turns: _collapsed ? -0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded,
                          size: 16, color: cs.onPrimaryContainer),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _collapsed
                          ? '${children.length} respuesta${children.length == 1 ? '' : 's'}'
                          : 'Ocultar respuestas',
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onPrimaryContainer,
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
    return Material(
      color: cs.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: cs.primary.withValues(alpha: 0.14),
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: small ? 10 : 12, vertical: small ? 5 : 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.reply_rounded,
                  size: small ? 14.0 : 17.0,
                  color: cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(l10n.forumReplyButton,
                  style: TextStyle(
                      fontSize: small ? 11.0 : 12.5,
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LockedChip extends StatelessWidget {
  const _LockedChip({required this.cs, this.small = false});

  final ColorScheme cs;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 10 : 12, vertical: small ? 5 : 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_rounded,
              size: small ? 13.0 : 15.0,
              color: cs.onSurfaceVariant.withAlpha(180)),
          const SizedBox(width: 6),
          Text('Bloqueado',
              style: TextStyle(
                  fontSize: small ? 11.0 : 12.0,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withAlpha(180))),
        ],
      ),
    );
  }
}

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
                          compact: true,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Total visual height of the floating navbar pill (top pad + content +
    // bottom pad). When the keyboard is open, the Scaffold resizes its body so
    // we sit just above the keyboard with a small breathing gap.
    final navbarReserve = kGlassBottomNavContentHeight +
        4 +
        (bottomSafe > 0 ? bottomSafe : 10);
    final bottomPad =
        keyboardInset > 0 ? 8.0 : navbarReserve + 6;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 6, 12, bottomPad),
      child: Material(
        color: isDark
            ? cs.surfaceContainerHigh
            : cs.secondaryContainer,
        elevation: 3,
        shadowColor: Colors.black.withAlpha(isDark ? 60 : 30),
        surfaceTintColor: cs.surfaceTint,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: cs.outlineVariant.withAlpha(isDark ? 70 : 40),
            width: 0.6,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyTarget != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 0),
                child: Row(
                  children: [
                    Icon(Icons.reply_rounded, size: 14, color: cs.primary),
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
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close_rounded,
                            size: 16, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      enabled: isLoggedIn && !sending,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: isLoggedIn
                            ? l10n.writeReplyHint
                            : l10n.loginRequiredComment,
                        hintStyle: TextStyle(
                            fontSize: 14, color: cs.onSurfaceVariant),
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 14, color: cs.onSurface),
                    ),
                  ),
                  const SizedBox(width: 4),
                  sending
                      ? const SizedBox(
                          width: 44,
                          height: 44,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Material(
                          color: isLoggedIn
                              ? cs.primary
                              : cs.surfaceContainerHighest,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: isLoggedIn ? onSend : null,
                            child: SizedBox(
                              width: 44,
                              height: 44,
                              child: Icon(
                                Icons.send_rounded,
                                size: 20,
                                color: isLoggedIn
                                    ? cs.onPrimary
                                    : cs.onSurfaceVariant.withAlpha(120),
                              ),
                            ),
                          ),
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
