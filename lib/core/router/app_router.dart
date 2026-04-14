import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/features/auth/presentation/auth_page.dart';
import 'package:cronicle/features/feed/presentation/feed_page.dart';
import 'package:cronicle/features/games/presentation/games_page.dart';
import 'package:cronicle/features/library/presentation/library_page.dart';
import 'package:cronicle/features/movies/presentation/movies_page.dart';
import 'package:cronicle/features/search/presentation/search_page.dart';
import 'package:cronicle/features/settings/presentation/settings_page.dart';
import 'package:cronicle/features/tv/presentation/tv_page.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';

part 'app_router.g.dart';

final _rootKey = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: '/feed',
    routes: [
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final location = state.uri.path;
          int index = 0;
          if (location.startsWith('/library')) {
            index = 1;
          } else if (location.startsWith('/search')) {
            index = 2;
          } else if (location.startsWith('/settings')) {
            index = 3;
          }

          return AppShell(
            currentIndex: index,
            onTabChanged: (i) {
              final routes = ['/feed', '/library', '/search', '/settings'];
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
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsPage(),
            ),
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
