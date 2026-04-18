import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/feed/presentation/activity_feed_widgets.dart';
import 'package:cronicle/features/social/presentation/forum_feed_tab.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

enum _SocialActivityType {
  all,
  status,
  anime,
  manga;

  String? get apiValue => switch (this) {
        _SocialActivityType.all => null,
        _SocialActivityType.status => 'TEXT',
        _SocialActivityType.anime => 'ANIME_LIST',
        _SocialActivityType.manga => 'MANGA_LIST',
      };
}

class _SocialPageState extends ConsumerState<SocialPage>
    with SingleTickerProviderStateMixin {
  FeedActivityScope _scope = FeedActivityScope.global;
  bool _scopeInitialized = false;
  _SocialActivityType _activityType = _SocialActivityType.all;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _setScope(FeedActivityScope next) {
    setState(() => _scope = next);
    ref.read(defaultFeedActivityScopeProvider.notifier).set(
          next == FeedActivityScope.following ? 'following' : 'global',
        );
  }

  void _invalidate() {
    ref.invalidate(
      anilistSocialFeedProvider(_activityType.apiValue, _isFollowing),
    );
  }

  void _loadMore() {
    ref
        .read(
          anilistSocialFeedProvider(_activityType.apiValue, _isFollowing)
              .notifier,
        )
        .loadMore();
  }

  bool get _isFollowing => _scope == FeedActivityScope.following;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_scopeInitialized) {
      final scopeStr = ref.read(defaultFeedActivityScopeProvider);
      _scope = scopeStr == 'following'
          ? FeedActivityScope.following
          : FeedActivityScope.global;
      _scopeInitialized = true;
    }

    final cs = Theme.of(context).colorScheme;

    final feedProvider =
        anilistSocialFeedProvider(_activityType.apiValue, _isFollowing);

    final scopeBar = Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          // Scope chips (siguiendo / global)
          FilterChip(
            selected: _scope == FeedActivityScope.following,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_rounded, size: 15),
                const SizedBox(width: 4),
                Text(l10n.filterFollowing,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onSelected: (_) => _setScope(FeedActivityScope.following),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 6),
          FilterChip(
            selected: _scope == FeedActivityScope.global,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.public_rounded, size: 15),
                const SizedBox(width: 4),
                Text(l10n.filterGlobal,
                    style: const TextStyle(fontSize: 12)),
              ],
            ),
            onSelected: (_) => _setScope(FeedActivityScope.global),
            showCheckmark: false,
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          // Activity type dropdown
          _ActivityTypeDropdown(
            value: _activityType,
            cs: cs,
            l10n: l10n,
            onChanged: (t) => setState(() => _activityType = t),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        clipBehavior: Clip.none,
        leading: const ProfileAvatarButton(),
        leadingWidth: kProfileLeadingWidth,
        titleSpacing: 0,
        title: Text(l10n.socialTitle, style: pageTitleStyle()),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.socialFeedTab),
            Tab(text: l10n.socialForumTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Feed tab
          _isFollowing
              ? FollowingFeedGuard(
                  feedScopeBar: scopeBar,
                  onRefresh: _invalidate,
                  onLoadMore: _loadMore,
                  feedAsync: ref.watch(feedProvider),
                  hasMore: () {
                    try {
                      return ref.read(feedProvider.notifier).hasMore;
                    } catch (_) {
                      return false;
                    }
                  },
                  l10n: l10n,
                )
              : ActivityFeedList(
                  feedAsync: ref.watch(feedProvider),
                  onRefresh: _invalidate,
                  onLoadMore: _loadMore,
                  hasMore: () {
                    try {
                      return ref.read(feedProvider.notifier).hasMore;
                    } catch (_) {
                      return false;
                    }
                  },
                  feedIsFollowing: false,
                  feedScopeHeader: scopeBar,
                  l10n: l10n,
                ),
          // Forum tab
          const ForumFeedTab(),
        ],
      ),
    );
  }
}

class _ActivityTypeDropdown extends StatelessWidget {
  const _ActivityTypeDropdown({
    required this.value,
    required this.cs,
    required this.l10n,
    required this.onChanged,
  });

  final _SocialActivityType value;
  final ColorScheme cs;
  final AppLocalizations l10n;
  final ValueChanged<_SocialActivityType> onChanged;

  String _label(_SocialActivityType t) => switch (t) {
        _SocialActivityType.all => l10n.filterAll,
        _SocialActivityType.status => l10n.filterStatus,
        _SocialActivityType.anime => l10n.filterAnime,
        _SocialActivityType.manga => l10n.filterManga,
      };

  IconData _icon(_SocialActivityType t) => switch (t) {
        _SocialActivityType.all => Icons.dynamic_feed_rounded,
        _SocialActivityType.status => Icons.chat_bubble_outline_rounded,
        _SocialActivityType.anime => Icons.animation_rounded,
        _SocialActivityType.manga => Icons.menu_book_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_SocialActivityType>(
      initialValue: value,
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      position: PopupMenuPosition.under,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon(value), size: 16, color: cs.primary),
            const SizedBox(width: 6),
            Text(
              _label(value),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded,
                size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
      itemBuilder: (_) => _SocialActivityType.values.map((t) {
        final isSelected = t == value;
        return PopupMenuItem<_SocialActivityType>(
          value: t,
          child: Row(
            children: [
              Icon(_icon(t),
                  size: 18,
                  color: isSelected ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Text(
                _label(t),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? cs.primary : cs.onSurface,
                ),
              ),
              const Spacer(),
              if (isSelected)
                Icon(Icons.check_rounded, size: 18, color: cs.primary),
            ],
          ),
        );
      }).toList(),
    );
  }
}
