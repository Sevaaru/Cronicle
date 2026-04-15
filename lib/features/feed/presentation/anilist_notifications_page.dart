import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';

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

/// `/notifications` vive dentro del [ShellRoute]; [push] apila la pantalla destino
/// para que el botón Atrás (p. ej. en Android) vuelva a notificaciones.
void _navigateShellRoute(BuildContext context, String location) {
  if (!context.mounted) return;
  GoRouter.of(context).push(location);
}

class AnilistNotificationsPage extends ConsumerWidget {
  const AnilistNotificationsPage({super.key});

  String _titleLine(Map<String, dynamic> n, AppLocalizations l10n) {
    final t = n['__typename'] as String? ?? '';
    final ctx = n['context'] as String?;
    if (ctx != null && ctx.isNotEmpty) return ctx;
    final ctxs = n['contexts'] as List?;
    if (ctxs != null && ctxs.isNotEmpty) {
      final parts =
          ctxs.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      if (parts.isNotEmpty) return parts.join(' ');
    }
    return switch (t) {
      'AiringNotification' => l10n.notificationTypeAiring,
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

  String? _subtitle(Map<String, dynamic> n) {
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
    final media = n['media'] as Map<String, dynamic>?;
    if (media != null) {
      final title = media['title'] as Map<String, dynamic>? ?? {};
      return (title['english'] as String?) ?? (title['romaji'] as String?);
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

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
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
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.errorWithMessage('$e'),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(anilistNotificationsListProvider),
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
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(anilistNotificationsListProvider);
                    await ref.read(anilistNotificationsListProvider.future);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final n = items[i];
                      final created = n['createdAt'] as int?;
                      final dt = created != null
                          ? DateTime.fromMillisecondsSinceEpoch(created * 1000)
                          : null;
                      final avatar = _avatarUrl(n);
                      final subtitle = _subtitle(n);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => _openNotification(context, n),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: avatar != null
                                      ? CachedNetworkImage(
                                          imageUrl: avatar,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          width: 44,
                                          height: 44,
                                          color: cs.surfaceContainerHighest,
                                          child: Icon(
                                            Icons.notifications_rounded,
                                            color: cs.onSurfaceVariant,
                                            size: 22,
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _titleLine(n, l10n),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      if (subtitle != null &&
                                          subtitle.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                      if (dt != null) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          _timeAgo(dt, l10n),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: cs.onSurfaceVariant
                                                .withAlpha(180),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Icon(Icons.chevron_right_rounded,
                                    color: cs.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
