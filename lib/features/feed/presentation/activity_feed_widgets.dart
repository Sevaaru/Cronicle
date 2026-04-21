import 'dart:math' show max;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/anilist_markdown.dart';
import 'package:cronicle/shared/widgets/animated_like_button.dart';
import 'package:cronicle/shared/widgets/glass_card.dart';


String activityTimeAgo(DateTime dt, AppLocalizations l10n) {
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return l10n.timeNow;
  if (diff.inMinutes < 60) return l10n.timeMinutes(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHours(diff.inHours);
  if (diff.inDays < 7) return l10n.timeDays(diff.inDays);
  return l10n.timeWeeks((diff.inDays / 7).floor());
}


enum FeedActivityScope { following, global }

class FeedActivityScopeBar extends StatelessWidget {
  const FeedActivityScopeBar({
    super.key,
    required this.scope,
    required this.onChanged,
    required this.l10n,
  });

  final FeedActivityScope scope;
  final ValueChanged<FeedActivityScope> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilterChip(
            selected: scope == FeedActivityScope.following,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 15),
                const SizedBox(width: 4),
                Text(l10n.filterFollowing,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onSelected: (_) => onChanged(FeedActivityScope.following),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          FilterChip(
            selected: scope == FeedActivityScope.global,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded, size: 15),
                const SizedBox(width: 4),
                Text(l10n.filterGlobal,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onSelected: (_) => onChanged(FeedActivityScope.global),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}


class FollowingFeedGuard extends ConsumerWidget {
  const FollowingFeedGuard({
    super.key,
    required this.feedScopeBar,
    required this.onRefresh,
    required this.onLoadMore,
    required this.l10n,
    required this.activityTypeApi,
  });
  final Widget feedScopeBar;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final AppLocalizations l10n;

  final String? activityTypeApi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenAsync = ref.watch(anilistTokenProvider);

    return tokenAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => Center(child: Text(l10n.errorVerifyingSession)),
      data: (token) {
        if (token == null) {
          final cs = Theme.of(context).colorScheme;
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: feedScopeBar,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 56,
                          color: cs.onSurfaceVariant.withAlpha(100)),
                      const SizedBox(height: 16),
                      Text(
                        l10n.loginRequiredFollowing,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: cs.onSurfaceVariant, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.login, size: 18),
                        label: Text(l10n.goToSettings),
                        onPressed: () => context.go('/settings'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        final feed = anilistSocialFeedProvider(activityTypeApi, true);
        return ActivityFeedList(
          feedAsync: ref.watch(feed),
          onRefresh: onRefresh,
          onLoadMore: onLoadMore,
          hasMore: () {
            try {
              return ref.read(feed.notifier).hasMore;
            } catch (_) {
              return false;
            }
          },
          feedIsFollowing: true,
          feedScopeHeader: feedScopeBar,
          l10n: l10n,
        );
      },
    );
  }
}


class ActivityFeedList extends ConsumerStatefulWidget {
  const ActivityFeedList({
    super.key,
    required this.feedAsync,
    required this.onRefresh,
    required this.onLoadMore,
    required this.hasMore,
    required this.feedIsFollowing,
    required this.feedScopeHeader,
    required this.l10n,
  });

  final AsyncValue<List<FeedActivity>> feedAsync;
  final VoidCallback onRefresh;
  final VoidCallback onLoadMore;
  final bool Function() hasMore;
  final bool feedIsFollowing;
  final Widget? feedScopeHeader;
  final AppLocalizations l10n;

  @override
  ConsumerState<ActivityFeedList> createState() => _ActivityFeedListState();
}

class _ActivityFeedListState extends ConsumerState<ActivityFeedList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  bool get _hasMore {
    try {
      return widget.hasMore();
    } catch (_) {
      return false;
    }
  }

  void _onScroll() {
    if (!_hasMore) return;
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    if (current >= maxScroll - 300) {
      widget.onLoadMore();
    }
  }

  int get _scopeHeaderLen => widget.feedScopeHeader != null ? 1 : 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMore = _hasMore;
    final scopeHeader = widget.feedScopeHeader;
    final listPadding = EdgeInsets.fromLTRB(
      16,
      scopeHeader != null ? 0 : 4,
      16,
      100,
    );

    return widget.feedAsync.when(
      loading: () {
        if (scopeHeader != null) {
          return LayoutBuilder(
            builder: (context, c) {
              return ListView(
                controller: _scrollController,
                padding: listPadding,
                children: [
                  scopeHeader,
                  SizedBox(height: max(100.0, c.maxHeight * 0.22)),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            },
          );
        }
        return const Center(child: CircularProgressIndicator());
      },
      error: (e, st) {
        debugPrint(
          '[AniList] ActivityFeedList error '
          '(following=${widget.feedIsFollowing}): $e',
        );
        final isRateLimit = e is AnilistRateLimitException;
        final retryHint =
            isRateLimit ? (e).retryAfterSeconds : null;
        final errorIcon =
            isRateLimit ? Icons.hourglass_top_rounded : Icons.wifi_off;
        final errorMessage = isRateLimit
            ? (retryHint != null && retryHint > 0
                ? widget.l10n.errorAnilistRateLimitWithSeconds(retryHint)
                : widget.l10n.errorAnilistRateLimit)
            : widget.l10n.errorNetwork;
        if (scopeHeader != null) {
          return LayoutBuilder(
            builder: (context, c) {
              return ListView(
                controller: _scrollController,
                padding: listPadding,
                children: [
                  scopeHeader,
                  SizedBox(height: max(48.0, c.maxHeight * 0.12)),
                  Icon(errorIcon, size: 48, color: colorScheme.error),
                  const SizedBox(height: 12),
                  Center(child: Text(errorMessage)),
                  const SizedBox(height: 12),
                  Center(
                    child: FilledButton(
                      onPressed: widget.onRefresh,
                      child: Text(widget.l10n.feedRetry),
                    ),
                  ),
                ],
              );
            },
          );
        }
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(errorIcon, size: 48, color: colorScheme.error),
              const SizedBox(height: 12),
              Text(errorMessage),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: widget.onRefresh,
                child: Text(widget.l10n.feedRetry),
              ),
            ],
          ),
        );
      },
      data: (activities) {
        final hideText = ref.watch(hideTextActivitiesProvider);
        final filtered = hideText
            ? activities.where((a) => !a.isTextActivity).toList()
            : activities;
        final firstCompose = _scopeHeaderLen;

        if (filtered.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async => widget.onRefresh(),
            child: ListView(
              controller: _scrollController,
              padding: listPadding,
              children: [
                ?scopeHeader,
                ComposeCard(onPosted: widget.onRefresh),
                Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: Center(
                    child: Text(
                      widget.l10n.feedEmpty,
                      style:
                          TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final totalItems =
            firstCompose + 1 + filtered.length + (hasMore ? 1 : 0);
        return RefreshIndicator(
          onRefresh: () async => widget.onRefresh(),
          child: ListView.builder(
            controller: _scrollController,
            padding: listPadding,
            addRepaintBoundaries: true,
            addAutomaticKeepAlives: false,
            itemCount: totalItems,
            itemBuilder: (context, i) {
              if (scopeHeader != null && i == 0) {
                return scopeHeader;
              }
              if (i == firstCompose) {
                return ComposeCard(onPosted: widget.onRefresh);
              }
              final actIdx = i - firstCompose - 1;
              if (actIdx >= filtered.length) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2)),
                );
              }
              return RepaintBoundary(
                child: ActivityCard(activity: filtered[actIdx]),
              );
            },
          ),
        );
      },
    );
  }
}


class ComposeCard extends ConsumerStatefulWidget {
  const ComposeCard({super.key, required this.onPosted});
  final VoidCallback onPosted;

  @override
  ConsumerState<ComposeCard> createState() => _ComposeCardState();
}

class _ComposeCardState extends ConsumerState<ComposeCard> {
  final _controller = TextEditingController();
  bool _sending = false;
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    final text = _controller.text.trim();
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
      await graphql.saveTextActivity(text, token);
      if (!mounted) return;
      _controller.clear();
      setState(() => _expanded = false);
      widget.onPosted();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorWithMessage(e))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tokenAsync = ref.watch(anilistTokenProvider);
    final isLoggedIn = tokenAsync.valueOrNull != null;

    if (!isLoggedIn) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_expanded)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Row(
                  children: [
                    Icon(Icons.edit_note_rounded,
                        size: 20, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(
                      l10n.composeActivityHint,
                      style: TextStyle(
                          fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              )
            else ...[
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 2,
                enabled: !_sending,
                decoration: InputDecoration(
                  hintText: l10n.composeActivityHint,
                  hintStyle: TextStyle(
                      fontSize: 13, color: cs.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outlineVariant),
                  ),
                  filled: true,
                  fillColor:
                      cs.surfaceContainerHighest.withAlpha(80),
                  contentPadding: const EdgeInsets.all(12),
                  isDense: true,
                ),
                style: TextStyle(fontSize: 13, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: _sending
                        ? null
                        : () => setState(() => _expanded = false),
                    child: Text(l10n.cancelButton),
                  ),
                  const SizedBox(width: 6),
                  _sending
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: Padding(
                            padding: EdgeInsets.all(6),
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        )
                      : FilledButton.icon(
                          onPressed: _post,
                          icon:
                              const Icon(Icons.send_rounded, size: 16),
                          label: Text(l10n.postButton),
                        ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}


class ExpandableText extends StatefulWidget {
  const ExpandableText({super.key, required this.text, this.style});
  final String text;
  final TextStyle? style;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  static const _collapseThreshold = 200;
  bool _expanded = false;

  bool get _isLong => widget.text.length > _collapseThreshold;

  @override
  Widget build(BuildContext context) {
    if (!_isLong || _expanded) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AnilistMarkdown(widget.text, style: widget.style),
          if (_isLong)
            _ExpandToggleButton(
              label: 'Ver menos',
              icon: Icons.expand_less_rounded,
              onTap: () => setState(() => _expanded = false),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 100,
          child: ClipRect(
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.white.withAlpha(0)],
                stops: const [0.6, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.dstIn,
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child:
                    AnilistMarkdown(widget.text, style: widget.style),
              ),
            ),
          ),
        ),
        _ExpandToggleButton(
          label: 'Ver más',
          icon: Icons.expand_more_rounded,
          onTap: () => setState(() => _expanded = true),
        ),
      ],
    );
  }
}

class _ExpandToggleButton extends StatelessWidget {
  const _ExpandToggleButton(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: cs.primary.withAlpha(18),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: cs.primary),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.primary)),
            ],
          ),
        ),
      ),
    );
  }
}


class ActivityCard extends ConsumerWidget {
  const ActivityCard({super.key, required this.activity});

  final FeedActivity activity;

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

  Future<bool?> _handleLike(BuildContext context, WidgetRef ref) async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      if (!context.mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.loginRequiredLike)),
      );
      return null;
    }
    final graphql = ref.read(anilistGraphqlProvider);
    final actId = int.tryParse(activity.id);
    if (actId == null) return null;

    final isLiked = await graphql.toggleLike(actId, token);
    final updated = activity.copyWith(
      isLiked: isLiked,
      likeCount: isLiked
          ? activity.likeCount + 1
          : (activity.likeCount - 1).clamp(0, 999999),
    );

    if (ref.exists(anilistFeedProvider)) {
      try {
        ref.read(anilistFeedProvider.notifier).updateActivity(updated);
      } catch (_) {}
    }
    if (ref.exists(anilistFeedByTypeProvider('ANIME_LIST'))) {
      try {
        ref
            .read(anilistFeedByTypeProvider('ANIME_LIST').notifier)
            .updateActivity(updated);
      } catch (_) {}
    }
    if (ref.exists(anilistFeedByTypeProvider('MANGA_LIST'))) {
      try {
        ref
            .read(anilistFeedByTypeProvider('MANGA_LIST').notifier)
            .updateActivity(updated);
      } catch (_) {}
    }
    if (ref.exists(anilistFeedFollowingProvider)) {
      try {
        ref
            .read(anilistFeedFollowingProvider.notifier)
            .updateActivity(updated);
      } catch (_) {}
    }
    return isLiked;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (activity.mediaId != null) {
                context.push(
                    '/media/${activity.mediaId}?kind=${activity.source.code}');
              }
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: activity.userId != null
                      ? () => context.push('/user/${activity.userId}')
                      : null,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor:
                        colorScheme.surfaceContainerHighest,
                    backgroundImage: activity.userAvatarUrl != null
                        ? CachedNetworkImageProvider(
                            activity.userAvatarUrl!)
                        : null,
                    child: activity.userAvatarUrl == null
                        ? Text(
                            activity.userName.isNotEmpty
                                ? activity.userName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
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
                              onTap: activity.userId != null
                                  ? () => context
                                      .push('/user/${activity.userId}')
                                  : null,
                              child: Text(
                                activity.userName,
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
                            activity.isTextActivity
                                ? Icons.edit_note_rounded
                                : _sourceIcon(activity.source),
                            size: 13,
                            color: activity.isTextActivity
                                ? colorScheme.onSurfaceVariant
                                : _sourceColor(
                                    activity.source, colorScheme),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            activityTimeAgo(activity.createdAt, l10n),
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      if (activity.isTextActivity)
                        ExpandableText(
                          text: activity.mediaTitle,
                          style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface),
                        )
                      else
                        RichText(
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface,
                            ),
                            children: [
                              TextSpan(
                                text: activity.action,
                                style: TextStyle(
                                    color:
                                        colorScheme.onSurfaceVariant),
                              ),
                              const TextSpan(text: ' '),
                              TextSpan(
                                text: activity.mediaTitle,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (activity.mediaPosterUrl != null) ...[
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: activity.mediaPosterUrl!,
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
          Row(
            children: [
              const SizedBox(width: 42),
              AnimatedLikeButton(
                isLiked: activity.isLiked,
                likeCount: activity.likeCount,
                onToggle: () => _handleLike(context, ref),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () => context
                    .push('/activity/${activity.id}/replies'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.chat_bubble_outline,
                          size: 15,
                          color: colorScheme.onSurfaceVariant),
                      if (activity.replyCount > 0) ...[
                        const SizedBox(width: 4),
                        Text('${activity.replyCount}',
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    colorScheme.onSurfaceVariant)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
