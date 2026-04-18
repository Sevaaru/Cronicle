import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/feed/presentation/activity_feed_widgets.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class SocialPage extends ConsumerStatefulWidget {
  const SocialPage({super.key});

  @override
  ConsumerState<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends ConsumerState<SocialPage> {
  FeedActivityScope _scope = FeedActivityScope.global;
  bool _scopeInitialized = false;

  void _setScope(FeedActivityScope next) {
    setState(() => _scope = next);
    ref.read(defaultFeedActivityScopeProvider.notifier).set(
          next == FeedActivityScope.following ? 'following' : 'global',
        );
  }

  void _invalidate() {
    ref.invalidate(anilistFeedFollowingProvider);
    ref.invalidate(anilistFeedProvider);
  }

  void _loadMore() {
    switch (_scope) {
      case FeedActivityScope.following:
        ref.read(anilistFeedFollowingProvider.notifier).loadMore();
      case FeedActivityScope.global:
        ref.read(anilistFeedProvider.notifier).loadMore();
    }
  }

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

    final scopeBar = FeedActivityScopeBar(
      scope: _scope,
      onChanged: _setScope,
      l10n: l10n,
    );

    return Scaffold(
      appBar: AppBar(
        leading: const ProfileAvatarButton(),
        titleSpacing: 0,
        title: Text(l10n.socialTitle, style: pageTitleStyle()),
      ),
      body: _scope == FeedActivityScope.following
          ? FollowingFeedGuard(
              feedScopeBar: scopeBar,
              onRefresh: _invalidate,
              onLoadMore: _loadMore,
              l10n: l10n,
            )
          : ActivityFeedList(
              feedAsync: ref.watch(anilistFeedProvider),
              onRefresh: _invalidate,
              onLoadMore: _loadMore,
              hasMore: () {
                try {
                  return ref.read(anilistFeedProvider.notifier).hasMore;
                } catch (_) {
                  return false;
                }
              },
              feedIsFollowing: false,
              feedScopeHeader: scopeBar,
              l10n: l10n,
            ),
    );
  }
}
