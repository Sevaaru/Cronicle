import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/features/anime/presentation/media_detail_page.dart';
import 'package:cronicle/features/anime/presentation/media_genre_tag_browse_page.dart';
import 'package:cronicle/features/anime/presentation/review_detail_page.dart';
import 'package:cronicle/features/auth/presentation/auth_page.dart';
import 'package:cronicle/features/feed/presentation/activity_replies_page.dart';
import 'package:cronicle/features/feed/presentation/anilist_notifications_page.dart';
import 'package:cronicle/features/feed/presentation/feed_page.dart';
import 'package:cronicle/features/games/presentation/game_detail_page.dart';
import 'package:cronicle/features/games/presentation/games_home_section_list_page.dart';
import 'package:cronicle/features/games/presentation/games_page.dart';
import 'package:cronicle/features/games/presentation/igdb_game_review_detail_page.dart';
import 'package:cronicle/features/library/presentation/library_page.dart';
import 'package:cronicle/features/movies/presentation/movies_page.dart';
import 'package:cronicle/features/profile/presentation/profile_page.dart';
import 'package:cronicle/features/profile/presentation/user_profile_page.dart';
import 'package:cronicle/features/search/presentation/search_page.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/settings_page.dart';
import 'package:cronicle/features/tv/presentation/tv_page.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';

part 'app_router.g.dart';

class _InvalidBrowseParamsPage extends StatelessWidget {
  const _InvalidBrowseParamsPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.mediaBrowseInvalidParams,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// [Navigator] raíz de [GoRouter]. Usar para [showDialog] antes de que exista
/// un [BuildContext] bajo el árbol del router (p. ej. desde [MaterialApp]).
final cronicleRootNavigatorKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

int _tabIndexFromPath(String path) {
  if (path.startsWith('/library')) return 1;
  if (path.startsWith('/search')) return 2;
  if (path.startsWith('/profile') && !path.startsWith('/profile/')) return 3;
  if (path.startsWith('/settings')) return 4;
  return 0;
}

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final startPage = ref.read(defaultStartPageProvider);

  return GoRouter(
    navigatorKey: cronicleRootNavigatorKey,
    initialLocation: startPage,
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final location = state.uri.path;
          final index = _tabIndexFromPath(location);

          return AppShell(
            currentIndex: index,
            onTabChanged: (i) {
              const routes = ['/feed', '/library', '/search', '/profile', '/settings'];
              context.go(routes[i]);
            },
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/feed',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FeedPage(),
            ),
          ),
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const AnilistNotificationsPage(),
          ),
          GoRoute(
            path: '/library',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LibraryPage(),
            ),
          ),
          GoRoute(
            path: '/search',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
          ),
          GoRoute(
            path: '/media/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final kindCode = int.tryParse(
                      state.uri.queryParameters['kind'] ?? '') ??
                  0;
              return MediaDetailPage(
                mediaId: id,
                kind: MediaKind.fromCode(kindCode),
              );
            },
          ),
          GoRoute(
            path: '/browse/media',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final kindCode = int.tryParse(q['kind'] ?? '') ?? 0;
              final kind = switch (MediaKind.fromCode(kindCode)) {
                MediaKind.manga => MediaKind.manga,
                _ => MediaKind.anime,
              };
              final genre = q['genre'];
              final tag = q['tag'];
              final sort = q['sort'] ?? 'popularity';
              final sortKey =
                  sort == 'score' || sort == 'name' ? sort : 'popularity';
              if ((genre == null || genre.isEmpty) &&
                  (tag == null || tag.isEmpty)) {
                return const _InvalidBrowseParamsPage();
              }
              return MediaGenreTagBrowsePage(
                kind: kind,
                genre: (genre != null && genre.isNotEmpty) ? genre : null,
                tag: (tag != null && tag.isNotEmpty) ? tag : null,
                initialSortKey: sortKey,
              );
            },
          ),
          GoRoute(
            path: '/user/:id',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['id']!);
              return UserProfilePage(userId: userId);
            },
          ),
          GoRoute(
            path: '/activity/:id/replies',
            builder: (context, state) {
              final activityId = int.parse(state.pathParameters['id']!);
              return ActivityRepliesPage(activityId: activityId);
            },
          ),
          GoRoute(
            path: '/review/:id',
            builder: (context, state) {
              final reviewId = int.parse(state.pathParameters['id']!);
              final extra = state.extra as Map<String, dynamic>?;
              return ReviewDetailPage(reviewId: reviewId, initialData: extra);
            },
          ),
          GoRoute(
            path: '/games/section/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return GamesHomeSectionListPage(slug: slug);
            },
          ),
          GoRoute(
            path: '/game/:id',
            builder: (context, state) {
              final gameId = int.parse(state.pathParameters['id']!);
              return GameDetailPage(gameId: gameId);
            },
          ),
          GoRoute(
            path: '/igdb-review/:id',
            builder: (context, state) {
              final reviewId = int.parse(state.pathParameters['id']!);
              return IgdbGameReviewDetailPage(reviewId: reviewId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/movies',
        builder: (context, state) => const MoviesPage(),
      ),
      GoRoute(
        path: '/tv',
        builder: (context, state) => const TvPage(),
      ),
      GoRoute(
        path: '/games',
        builder: (context, state) => const GamesPage(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
    ],
  );
}
