import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/animated_like_button.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
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
  Map<String, dynamic>? _activityMap;
  List<Map<String, dynamic>>? _replies;
  int _rootActivityId = 0;
  bool _loading = true;
  String? _error;
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _rootActivityId = widget.activityId;
    _load();
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    const maxTries = 3;
    for (var attempt = 0; attempt < maxTries; attempt++) {
      try {
        final graphql = ref.read(anilistGraphqlProvider);
        final token = await ref.read(anilistTokenProvider.future);
        final data = await graphql.fetchActivityRepliesPageData(
          widget.activityId,
          token: token,
        );
        if (!mounted) return;
        setState(() {
          _activityMap = data['activity'] as Map<String, dynamic>?;
          _replies =
              (data['replies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
          _rootActivityId = data['rootActivityId'] as int? ?? widget.activityId;
          _loading = false;
          _error = null;
        });
        return;
      } catch (e) {
        if (!mounted) return;
        if (attempt == maxTries - 1) {
          setState(() {
            _loading = false;
            _error = '$e';
          });
        } else {
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
      }
    }
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
      final result = await graphql.saveActivityReply(_rootActivityId, text, token);
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
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(title: Text(l10n.commentsTitle)),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.cloud_off_rounded,
                                  size: 48, color: cs.onSurfaceVariant.withAlpha(120)),
                              const SizedBox(height: 12),
                              Text(
                                l10n.activityThreadLoadError,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurfaceVariant.withAlpha(180),
                                ),
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _load,
                                icon: const Icon(Icons.refresh_rounded),
                                label: Text(l10n.feedRetry),
                              ),
                            ],
                          ),
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          if (_activityMap != null) ...[
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 12, 16, 4),
                                child: Text(
                                  l10n.activityOriginalPost,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            SliverToBoxAdapter(
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: _ThreadOriginalBlock(
                                  activity: _activityMap!,
                                  timeAgo: (dt) => _timeAgo(dt, l10n),
                                ),
                              ),
                            ),
                          ],
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                  16, _activityMap != null ? 4 : 12, 16, 8),
                              child: Text(
                                l10n.activityRepliesHeading,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                          if (_replies == null || _replies!.isEmpty)
                            SliverFillRemaining(
                              hasScrollBody: false,
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.chat_bubble_outline,
                                        size: 48,
                                        color: cs.onSurfaceVariant.withAlpha(80)),
                                    const SizedBox(height: 12),
                                    Text(l10n.noComments,
                                        style: TextStyle(
                                            color: cs.onSurfaceVariant)),
                                  ],
                                ),
                              ),
                            )
                          else
                            SliverPadding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 160),
                              sliver: SliverList(
                                delegate: SliverChildBuilderDelegate(
                                  (context, i) => _ReplyCard(
                                    reply: _replies![i],
                                    timeAgo: (dt) => _timeAgo(dt, l10n),
                                  ),
                                  childCount: _replies!.length,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReplyInputBar(
              controller: _replyController,
              sending: _sending,
              onSend: _sendReply,
            ),
          ),
        ],
      ),
    );
  }
}

class _ThreadOriginalBlock extends ConsumerWidget {
  const _ThreadOriginalBlock({
    required this.activity,
    required this.timeAgo,
  });

  final Map<String, dynamic> activity;
  final String Function(DateTime) timeAgo;

  IconData _sourceIcon(MediaKind kind) => switch (kind) {
        MediaKind.anime => Icons.animation_rounded,
        MediaKind.manga => Icons.menu_book_rounded,
        MediaKind.movie => Icons.movie_rounded,
        MediaKind.tv => Icons.tv_rounded,
        MediaKind.game => Icons.sports_esports_rounded,
        MediaKind.book => Icons.auto_stories_rounded,
      };

  Color _sourceColor(MediaKind kind, ColorScheme cs) => switch (kind) {
        MediaKind.anime => cs.primary,
        MediaKind.manga => Colors.deepPurple,
        MediaKind.movie => Colors.amber.shade700,
        MediaKind.tv => Colors.teal,
        MediaKind.game => Colors.redAccent,
        MediaKind.book => const Color(0xFFAB47BC),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final tn = activity['__typename'] as String? ?? '';

    if (tn == 'MessageActivity') {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        ((activity['createdAt'] as int?) ?? 0) * 1000,
      );
      return GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mail_outline_rounded,
                    size: 18, color: cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.activityMessageActivity,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                ),
                Text(
                  timeAgo(createdAt),
                  style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _OriginalActivityLikeRow(activityMap: activity),
          ],
        ),
      );
    }

    final mapped = feedActivityFromAnilistActivityMap(activity);
    if (mapped == null) {
      return GlassCard(
        padding: const EdgeInsets.all(12),
        child: Text(
          l10n.activityThreadLoadError,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
        ),
      );
    }

    return GlassCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (mapped.mediaId != null) {
                context.push(
                    '/media/${mapped.mediaId}?kind=${mapped.source.code}');
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: mapped.userId != null
                      ? () => context.push('/user/${mapped.userId}')
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: cs.surfaceContainerHighest,
                    backgroundImage: mapped.userAvatarUrl != null
                        ? CachedNetworkImageProvider(mapped.userAvatarUrl!)
                        : null,
                    child: mapped.userAvatarUrl == null
                        ? Text(
                            mapped.userName.isNotEmpty
                                ? mapped.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface,
                            ),
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: GestureDetector(
                              onTap: mapped.userId != null
                                  ? () =>
                                      context.push('/user/${mapped.userId}')
                                  : null,
                              child: Text(
                                mapped.userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            mapped.isTextActivity
                                ? Icons.edit_note_rounded
                                : _sourceIcon(mapped.source),
                            size: 13,
                            color: mapped.isTextActivity
                                ? cs.onSurfaceVariant
                                : _sourceColor(mapped.source, cs),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo(mapped.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (mapped.isTextActivity)
                        AnilistMarkdown(
                          mapped.mediaTitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: cs.onSurface,
                            height: 1.4,
                          ),
                        )
                      else
                        RichText(
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: mapped.action,
                                style:
                                    TextStyle(color: cs.onSurfaceVariant),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: mapped.mediaTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (mapped.mediaPosterUrl != null) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: mapped.mediaPosterUrl!,
                      width: 45,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 6),
          _OriginalActivityLikeRow(activityMap: activity),
        ],
      ),
    );
  }
}

class _OriginalActivityLikeRow extends ConsumerWidget {
  const _OriginalActivityLikeRow({required this.activityMap});

  final Map<String, dynamic> activityMap;

  Future<bool?> _handleLike(WidgetRef ref, BuildContext context) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return null;
    }
    final id = activityMap['id'] as int?;
    if (id == null) return null;
    final graphql = ref.read(anilistGraphqlProvider);
    return graphql.toggleLike(id, token);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const SizedBox(width: 4),
        AnimatedLikeButton(
          isLiked: activityMap['isLiked'] as bool? ?? false,
          likeCount: activityMap['likeCount'] as int? ?? 0,
          onToggle: () => _handleLike(ref, context),
          compact: true,
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bottomSafe = MediaQuery.viewPaddingOf(context).bottom;
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Sit above the floating navbar pill from AppShell. The navbar uses
    // 4dp top pad + content height + max(bottomSafe, 10) bottom pad.
    final navbarTotal = 4 +
        kGlassBottomNavContentHeight +
        (bottomSafe > 0 ? bottomSafe : 10);
    final bottomPad = keyboardInset > 0 ? 8.0 : navbarTotal + 6;

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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  enabled: isLoggedIn && !sending,
                  maxLines: 4,
                  minLines: 1,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: isLoggedIn
                        ? AppLocalizations.of(context)!.writeReplyHint
                        : AppLocalizations.of(context)!.loginRequiredLike,
                    hintStyle:
                        TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
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
      ),
    );
  }
}

class _ReplyCard extends ConsumerWidget {
  const _ReplyCard({required this.reply, required this.timeAgo});
  final Map<String, dynamic> reply;
  final String Function(DateTime) timeAgo;

  Future<bool?> _handleLike(WidgetRef ref, BuildContext context) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return null;
    }
    final replyId = reply['id'] as int?;
    if (replyId == null) return null;
    final graphql = ref.read(anilistGraphqlProvider);
    return graphql.toggleLike(replyId, token, type: 'ACTIVITY_REPLY');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final user = reply['user'] as Map<String, dynamic>? ?? {};
    final avatar = (user['avatar'] as Map?)?['medium'] as String?;
    final userName = user['name'] as String? ?? '';
    final userId = user['id'] as int?;
    final text = reply['text'] as String? ?? '';
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
          const SizedBox(height: 6),
          AnimatedLikeButton(
            isLiked: reply['isLiked'] as bool? ?? false,
            likeCount: reply['likeCount'] as int? ?? 0,
            iconSize: 15,
            onToggle: () => _handleLike(ref, context),
            compact: true,
          ),
        ],
      ),
    );
  }
}
