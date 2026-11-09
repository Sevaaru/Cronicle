import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/utils/anilist_media_title.dart';
import 'package:cronicle/core/utils/anilist_notification_contexts.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';

String _timeAgo(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return l10n.timeWeeks((diff.inDays / 7).floor());
}

int _kindCodeFromAnilistType(String? t) =>
    t == 'MANGA' ? MediaKind.manga.code : MediaKind.anime.code;

void _navigateShellRoute(BuildContext context, String location) {
  if (!context.mounted) return;
  GoRouter.of(context).push(location);
}

class AnilistNotificationsPage extends ConsumerWidget {
  const AnilistNotificationsPage({super.key});

  String _titleLine(Map<String, dynamic> n, AppLocalizations l10n) {
    final t = n['__typename'] as String? ?? '';
    if (t == 'AiringNotification') {
      final ctxs = n['contexts'];
      if (ctxs is List && ctxs.isNotEmpty) {
        final flat = anilistFlattenContexts(ctxs).trim();
        if (flat.isNotEmpty) return flat;
      }
      final media = n['media'] as Map<String, dynamic>? ?? {};
      final mediaTitle = anilistMediaDisplayTitle(media);
      final ep = (n['episode'] as num?)?.toInt();
      if (ep != null && mediaTitle != 'Media') {
        final isManga = (media['type'] as String? ?? '') == 'MANGA';
        return isManga
            ? l10n.notificationAiringHeadlineManga(mediaTitle, ep)
            : l10n.notificationAiringHeadlineAnime(mediaTitle, ep);
      }
      if (mediaTitle != 'Media') return mediaTitle;
      return l10n.notificationTypeAiring;
    }

    final actor = _actorName(n);
    if (actor != null && actor.isNotEmpty) return actor;

    final ctx = n['context'] as String?;
    if (ctx != null && ctx.isNotEmpty) return ctx.trim();
    final ctxs = n['contexts'];
    if (ctxs is List && ctxs.isNotEmpty) {
      final flat = anilistFlattenContexts(ctxs).trim();
      if (flat.isNotEmpty) return flat;
    }
    return switch (t) {
      'ActivityReplyNotification' => l10n.notificationTypeActivityReply,
      'ActivityMentionNotification' => l10n.notificationTypeActivityMention,
      'ActivityMessageNotification' => l10n.notificationTypeActivityMessage,
      'FollowingNotification' => l10n.notificationTypeFollowing,
      'RelatedMediaAdditionNotification' =>
        l10n.notificationTypeRelatedMedia,
      'MediaDataChangeNotification' => l10n.notificationTypeMediaDataChange,
      'MediaMergeNotification' => l10n.notificationTypeMediaMerge,
      'MediaDeletionNotification' => l10n.notificationTypeMediaDeletion,
      'ThreadCommentReplyNotification' => l10n.notificationTypeThreadReply,
      'ThreadCommentMentionNotification' =>
        l10n.notificationTypeThreadMention,
      'ThreadCommentSubscribedNotification' =>
        l10n.notificationTypeThreadSubscribed,
      'ThreadLikeNotification' => l10n.notificationTypeThreadLike,
      'ActivityLikeNotification' => l10n.notificationTypeActivityLike,
      'ActivityReplyLikeNotification' =>
        l10n.notificationTypeActivityReplyLike,
      'ActivityReplySubscribedNotification' =>
        l10n.notificationTypeActivityReplySubscribed,
      'ThreadCommentLikeNotification' =>
        l10n.notificationTypeThreadCommentLike,
      'MediaSubmissionUpdateNotification' =>
        l10n.notificationTypeMediaSubmission,
      'StaffSubmissionUpdateNotification' =>
        l10n.notificationTypeStaffSubmission,
      'CharacterSubmissionUpdateNotification' =>
        l10n.notificationTypeCharacterSubmission,
      _ => l10n.notificationTypeGeneric,
    };
  }

  String? _actorName(Map<String, dynamic> n) {
    final user = n['user'] as Map<String, dynamic>?;
    if (user != null) return user['name'] as String?;
    final staff = n['staff'] as Map<String, dynamic>?;
    if (staff != null) {
      final nm = staff['name'] as Map<String, dynamic>?;
      final full = nm?['full'] as String?;
      if (full != null && full.isNotEmpty) return full;
    }
    final character = n['character'] as Map<String, dynamic>?;
    if (character != null) {
      final nm = character['name'] as Map<String, dynamic>?;
      final full = nm?['full'] as String?;
      if (full != null && full.isNotEmpty) return full;
    }
    final submitted = n['submittedTitle'] as String?;
    if (submitted != null && submitted.isNotEmpty) return submitted;
    return null;
  }

  String? _subtitle(Map<String, dynamic> n, AppLocalizations l10n) {
    final t = n['__typename'] as String? ?? '';
    if (t == 'AiringNotification') {
      final ctxs = n['contexts'];
      final hasCtx =
          ctxs is List && anilistFlattenContexts(ctxs).trim().isNotEmpty;
      if (!hasCtx) return null;
      final media = n['media'] as Map<String, dynamic>? ?? {};
      final mediaTitle = anilistMediaDisplayTitle(media);
      final ep = (n['episode'] as num?)?.toInt();
      if (ep != null && mediaTitle != 'Media') {
        final isManga = (media['type'] as String? ?? '') == 'MANGA';
        return isManga
            ? l10n.notificationAiringHeadlineManga(mediaTitle, ep)
            : l10n.notificationAiringHeadlineAnime(mediaTitle, ep);
      }
      return mediaTitle != 'Media' ? mediaTitle : null;
    }

    final actor = _actorName(n);
    if (actor != null && actor.isNotEmpty) {
      final ctx = n['context'] as String?;
      if (ctx != null && ctx.isNotEmpty) return ctx.trim();
      final ctxs = n['contexts'];
      if (ctxs is List && ctxs.isNotEmpty) {
        final flat = anilistFlattenContexts(ctxs).trim();
        if (flat.isNotEmpty) return flat;
      }
      final media = n['media'] as Map<String, dynamic>?;
      if (media != null) {
        final resolved = anilistMediaDisplayTitle(media);
        if (resolved != 'Media') return resolved;
      }
      final thread = n['thread'] as Map<String, dynamic>?;
      if (thread != null) return thread['title'] as String?;
      return null;
    }

    final media = n['media'] as Map<String, dynamic>?;
    if (media != null) {
      final resolved = anilistMediaDisplayTitle(media);
      return resolved == 'Media' ? null : resolved;
    }
    final thread = n['thread'] as Map<String, dynamic>?;
    if (thread != null) return thread['title'] as String?;
    final del = n['deletedMediaTitle'] as String?;
    if (del != null && del.isNotEmpty) return del;
    final dels = n['deletedMediaTitles'] as List?;
    if (dels != null && dels.isNotEmpty) return dels.first.toString();
    return null;
  }

  String? _avatarUrl(Map<String, dynamic> n) {
    final user = n['user'] as Map<String, dynamic>?;
    if (user != null) {
      final av = user['avatar'] as Map<String, dynamic>?;
      return av?['medium'] as String?;
    }
    final character = n['character'] as Map<String, dynamic>?;
    if (character != null) {
      final img = character['image'] as Map<String, dynamic>?;
      return img?['large'] as String?;
    }
    final media = n['media'] as Map<String, dynamic>?;
    if (media != null) {
      final cover = media['coverImage'] as Map<String, dynamic>?;
      return cover?['large'] as String?;
    }
    return null;
  }

  int? _avatarUserId(Map<String, dynamic> n) {
    final user = n['user'] as Map<String, dynamic>?;
    return (user?['id'] as num?)?.toInt();
  }

  Future<void> _openNotification(
    BuildContext context,
    Map<String, dynamic> n,
  ) async {
    final t = n['__typename'] as String? ?? '';
    final l10n = AppLocalizations.of(context)!;

    switch (t) {
      case 'ActivityReplyNotification':
      case 'ActivityMentionNotification':
      case 'ActivityMessageNotification':
      case 'ActivityLikeNotification':
      case 'ActivityReplyLikeNotification':
      case 'ActivityReplySubscribedNotification':
        final aid = n['activityId'] as int?;
        if (aid != null) {
          _navigateShellRoute(context, '/activity/$aid/replies');
        }
        return;
      case 'FollowingNotification':
        final uid = (n['user'] as Map<String, dynamic>?)?['id'] as int?;
        if (uid != null) {
          _navigateShellRoute(context, '/user/$uid');
        }
        return;
      case 'AiringNotification':
      case 'RelatedMediaAdditionNotification':
      case 'MediaDataChangeNotification':
      case 'MediaMergeNotification':
      case 'MediaSubmissionUpdateNotification':
        final media = n['media'] as Map<String, dynamic>?;
        final mid = media?['id'] as int?;
        final mtype = media?['type'] as String? ?? 'ANIME';
        if (mid != null) {
          _navigateShellRoute(
            context,
            '/media/$mid?kind=${_kindCodeFromAnilistType(mtype)}',
          );
        }
        return;
      case 'ThreadCommentReplyNotification':
      case 'ThreadCommentMentionNotification':
      case 'ThreadCommentSubscribedNotification':
      case 'ThreadLikeNotification':
      case 'ThreadCommentLikeNotification':
        final thread = n['thread'] as Map<String, dynamic>?;
        final tid = thread?['id'] as int?;
        if (tid != null) {
          final uri = Uri.parse('https://anilist.co/forum/thread/$tid');
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
        return;
      default:
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.notificationNoLink)),
          );
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final token = ref.watch(anilistTokenProvider).valueOrNull;
    final listAsync = ref.watch(anilistNotificationsListProvider);
    final cached = ref.watch(anilistCachedNotificationsProvider);

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: SizedBox(
          width: kProfileLeadingWidth,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: kProfileLeadingPadding,
              child: IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: kProfileLeadingCircleSize,
                  minHeight: kProfileLeadingCircleSize,
                ),
                style: IconButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ),
        leadingWidth: kProfileLeadingWidth,
        automaticallyImplyLeading: false,
        title: Text(l10n.notificationsTitle),
      ),
      body: token == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.notificationsLoginRequired,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ),
            )
          : listAsync.when(
              loading: () => cached.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _buildNotificationsList(
                      context,
                      ref,
                      cached,
                      l10n,
                      cs,
                      refreshing: true,
                    ),
              error: (e, _) => cached.isNotEmpty
                  ? _buildNotificationsList(
                      context,
                      ref,
                      cached,
                      l10n,
                      cs,
                      refreshing: false,
                      banner: _OfflineBanner(
                        message: l10n.errorWithMessage('$e'),
                        onRetry: () =>
                            ref.invalidate(anilistNotificationsListProvider),
                        retryLabel: l10n.feedRetry,
                      ),
                    )
                  : Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(l10n.errorWithMessage('$e'),
                                textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: () => ref.invalidate(
                                  anilistNotificationsListProvider),
                              child: Text(l10n.feedRetry),
                            ),
                          ],
                        ),
                      ),
                    ),
              data: (items) {
                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.notificationsEmpty,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  );
                }
                return _buildNotificationsList(
                  context,
                  ref,
                  items,
                  l10n,
                  cs,
                  refreshing: false,
                );
              },
            ),
    );
  }

  /// Renders the notifications list with a `RefreshIndicator`. When
  /// [refreshing] is true a slim linear progress strip is shown above the
  /// list so the user knows fresher data is on the way; we still let them
  /// interact with the cached items immediately.
  Widget _buildNotificationsList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> items,
    AppLocalizations l10n,
    ColorScheme cs, {
    required bool refreshing,
    Widget? banner,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(anilistNotificationsListProvider);
        await ref.read(anilistNotificationsListProvider.future);
      },
      child: Column(
        children: [
          if (refreshing)
            const SizedBox(
              height: 2,
              child: LinearProgressIndicator(),
            ),
          if (banner != null) banner,
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final n = items[i];
                final created = n['createdAt'] as int?;
                final dt = created != null
                    ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
                    : null;
                final avatar = _avatarUrl(n);
                final subtitle = _subtitle(n, l10n);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NotificationTile(
                    title: _titleLine(n, l10n),
                    subtitle: subtitle,
                    timeLabel: dt != null ? _timeAgo(dt, l10n) : null,
                    avatarUrl: avatar,
                    kindIcon: _kindIcon(n),
                    kindAccent: _kindAccent(n, cs),
                    onTap: () => _openNotification(context, n),
                    onAvatarTap: () {
                      final uid = _avatarUserId(n);
                      if (uid != null) {
                        _navigateShellRoute(context, '/user/$uid');
                      } else {
                        _openNotification(context, n);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _kindIcon(Map<String, dynamic> n) {
    final t = n['__typename'] as String? ?? '';
    return switch (t) {
      'AiringNotification' => Icons.live_tv_rounded,
      'FollowingNotification' => Icons.person_add_alt_1_rounded,
      'ActivityLikeNotification' ||
      'ActivityReplyLikeNotification' ||
      'ThreadLikeNotification' ||
      'ThreadCommentLikeNotification' =>
        Icons.favorite_rounded,
      'ActivityReplyNotification' ||
      'ActivityReplySubscribedNotification' ||
      'ThreadCommentReplyNotification' =>
        Icons.reply_rounded,
      'ActivityMentionNotification' ||
      'ActivityMessageNotification' ||
      'ThreadCommentMentionNotification' =>
        Icons.alternate_email_rounded,
      'ThreadCommentSubscribedNotification' => Icons.forum_rounded,
      'RelatedMediaAdditionNotification' ||
      'MediaDataChangeNotification' ||
      'MediaMergeNotification' =>
        Icons.update_rounded,
      'MediaDeletionNotification' => Icons.delete_outline_rounded,
      'MediaSubmissionUpdateNotification' ||
      'StaffSubmissionUpdateNotification' ||
      'CharacterSubmissionUpdateNotification' =>
        Icons.assignment_turned_in_rounded,
      _ => Icons.notifications_rounded,
    };
  }

  Color _kindAccent(Map<String, dynamic> n, ColorScheme cs) {
    final t = n['__typename'] as String? ?? '';
    return switch (t) {
      'AiringNotification' => cs.primary,
      'FollowingNotification' => cs.tertiary,
      'ActivityLikeNotification' ||
      'ActivityReplyLikeNotification' ||
      'ThreadLikeNotification' ||
      'ThreadCommentLikeNotification' =>
        cs.error,
      'ActivityReplyNotification' ||
      'ActivityReplySubscribedNotification' ||
      'ThreadCommentReplyNotification' ||
      'ActivityMentionNotification' ||
      'ActivityMessageNotification' ||
      'ThreadCommentMentionNotification' =>
        cs.secondary,
      _ => cs.primary,
    };
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.timeLabel,
    required this.avatarUrl,
    required this.kindIcon,
    required this.kindAccent,
    required this.onTap,
    required this.onAvatarTap,
  });

  final String title;
  final String? subtitle;
  final String? timeLabel;
  final String? avatarUrl;
  final IconData kindIcon;
  final Color kindAccent;
  final VoidCallback onTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: kindAccent.withValues(alpha: 0.14),
        highlightColor: kindAccent.withValues(alpha: 0.06),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onAvatarTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: avatarUrl != null
                          ? CachedNetworkImage(
                              imageUrl: avatarUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              color: cs.surfaceContainerHighest,
                              child: Icon(
                                Icons.person_rounded,
                                color: cs.onSurfaceVariant,
                                size: 24,
                              ),
                            ),
                    ),
                    Positioned(
                      right: -2,
                      bottom: -2,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: kindAccent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: cs.surfaceContainerLow,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          kindIcon,
                          size: 12,
                          color: cs.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                        color: cs.onSurface,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.3,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (timeLabel != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: cs.onSurfaceVariant.withAlpha(160),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeLabel!,
                            style: TextStyle(
                              fontSize: 11,
                              color: cs.onSurfaceVariant.withAlpha(180),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant.withAlpha(150),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Slim banner shown above the cached notifications list when the live fetch
/// failed (e.g. no network) — surfaces the error and a quick retry button
/// while still letting the user read what we already have.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({
    required this.message,
    required this.onRetry,
    required this.retryLabel,
  });

  final String message;
  final VoidCallback onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: cs.errorContainer.withAlpha(140),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_rounded, size: 18, color: cs.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: cs.onErrorContainer,
              ),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: cs.onErrorContainer,
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: Text(retryLabel),
          ),
        ],
      ),
    );
  }
}
