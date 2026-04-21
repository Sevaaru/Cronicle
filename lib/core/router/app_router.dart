import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/router/profile_route_transition.dart';
import 'package:cronicle/core/router/shell_nav_tab.dart';
import 'package:cronicle/features/anime/presentation/media_detail_page.dart';
import 'package:cronicle/features/anime/presentation/media_genre_tag_browse_page.dart';
import 'package:cronicle/features/anime/presentation/media_characters_page.dart';
import 'package:cronicle/features/anime/presentation/media_staff_page.dart';
import 'package:cronicle/features/anime/presentation/character_detail_page.dart';
import 'package:cronicle/features/anime/presentation/staff_detail_page.dart';
import 'package:cronicle/features/anime/presentation/forum_media_threads_page.dart';
import 'package:cronicle/features/anime/presentation/forum_thread_page.dart';
import 'package:cronicle/features/anime/presentation/review_detail_page.dart';
import 'package:cronicle/features/auth/presentation/auth_page.dart';
import 'package:cronicle/features/books/presentation/book_detail_page.dart';
import 'package:cronicle/features/books/presentation/book_subject_browse_page.dart';
import 'package:cronicle/features/books/presentation/books_home_feed_view.dart';
import 'package:cronicle/features/books/presentation/books_home_section_list_page.dart';
import 'package:cronicle/features/trakt/presentation/trakt_home_section_list_page.dart';
import 'package:cronicle/features/feed/presentation/activity_replies_page.dart';
import 'package:cronicle/features/feed/presentation/anilist_notifications_page.dart';
import 'package:cronicle/features/feed/presentation/feed_page.dart';
import 'package:cronicle/features/games/presentation/game_detail_page.dart';
import 'package:cronicle/features/games/presentation/games_home_section_list_page.dart';
import 'package:cronicle/features/games/presentation/games_page.dart';
import 'package:cronicle/features/games/presentation/igdb_game_review_detail_page.dart';
import 'package:cronicle/features/library/presentation/library_page.dart';
import 'package:cronicle/features/movies/presentation/movies_page.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_page.dart';
import 'package:cronicle/features/profile/presentation/personal_stats_page.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_kind.dart';
import 'package:cronicle/features/profile/presentation/profile_favorites_page.dart';
import 'package:cronicle/features/profile/presentation/user_follow_list_page.dart';
import 'package:cronicle/features/profile/presentation/user_profile_page.dart';
import 'package:cronicle/features/games/presentation/search_games_theme_list_page.dart';
import 'package:cronicle/features/search/presentation/search_anilist_browse_list_page.dart';
import 'package:cronicle/features/search/presentation/search_anilist_genre_list_page.dart';
import 'package:cronicle/features/search/presentation/search_book_subject_list_page.dart';
import 'package:cronicle/features/search/presentation/search_browse_by_release_date_page.dart';
import 'package:cronicle/features/search/presentation/search_page.dart';
import 'package:cronicle/features/social/presentation/social_page.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/features/settings/presentation/settings_page.dart';
import 'package:cronicle/features/trakt/presentation/trakt_movie_detail_page.dart';
import 'package:cronicle/features/trakt/presentation/trakt_show_detail_page.dart';
import 'package:cronicle/features/tv/presentation/tv_page.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:cronicle/shared/widgets/app_shell.dart';
import 'package:cronicle/shared/widgets/fullscreen_image_viewer.dart';

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

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final startPage = ref.read(defaultStartPageProvider);
  final onboardingDone = ref.read(onboardingCompletedProvider);

  return GoRouter(
    navigatorKey: cronicleRootNavigatorKey,
    initialLocation: onboardingDone ? startPage : '/onboarding',
    redirect: (context, state) {
      // Android entrega el intent OAuth a MainActivity; el sistema puede
      // exponerlo como "ruta" y GoRouter no tiene match → GoException.
      // AppLinks ya maneja el deep link; mantener al usuario en la página actual.
      if (state.uri.scheme == 'cronicle') {
        final current =
            GoRouter.of(context).routerDelegate.currentConfiguration.uri.path;
        if (current.isNotEmpty && current != '/') return current;
        final done = ref.read(onboardingCompletedProvider);
        return done ? startPage : '/onboarding';
      }
      // Rutas con barra final no coincidían con los paths registrados.
      final path = state.uri.path;
      if (path.length > 1 && path.endsWith('/')) {
        return state.uri.replace(path: path.substring(0, path.length - 1)).toString();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
        redirect: (context, state) {
          final done = ref.read(onboardingCompletedProvider);
          if (done) return startPage;
          return null;
        },
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (context, state, child) {
          final location = state.uri.path;
          final index =
              ref.read(shellNavTabProvider.notifier).bottomNavIndex(location);

          // No modificar providers durante build; persistir tab principal después del frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(shellNavTabProvider.notifier)
                .rememberPrimaryTabFromPath(location);
          });

          return AppShell(
            currentIndex: index,
            onTabChanged: (i) {
              // Cierra PopupMenu / overlays del tab anterior (p. ej. filtro biblioteca).
              _shellKey.currentState?.popUntil(
                (route) => route is! PopupRoute,
              );
              const routes = ['/feed', '/library', '/search', '/social', '/settings'];
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
            routes: [
              GoRoute(
                path: 'anilist/:mediaType/:category',
                parentNavigatorKey: _shellKey,
                builder: (context, state) {
                  final mediaType =
                      state.pathParameters['mediaType']!.toUpperCase();
                  final category = state.pathParameters['category']!;
                  if (mediaType != 'ANIME' && mediaType != 'MANGA') {
                    return const _InvalidBrowseParamsPage();
                  }
                  if (!isValidAnilistBrowseCategory(category)) {
                    return const _InvalidBrowseParamsPage();
                  }
                  return SearchAnilistBrowseListPage(
                    mediaType: mediaType,
                    category: category,
                  );
                },
              ),
              GoRoute(
                path: 'anilist-genres',
                parentNavigatorKey: _shellKey,
                builder: (context, state) {
                  final t = (state.uri.queryParameters['type'] ?? 'ANIME')
                      .toUpperCase();
                  final mediaType = t == 'MANGA' ? 'MANGA' : 'ANIME';
                  return SearchAnilistGenreListPage(mediaType: mediaType);
                },
              ),
              GoRoute(
                path: 'book-subjects',
                parentNavigatorKey: _shellKey,
                builder: (context, state) => const SearchBookSubjectListPage(),
              ),
              GoRoute(
                path: 'games-themes',
                parentNavigatorKey: _shellKey,
                builder: (context, state) => const SearchGamesThemeListPage(),
              ),
              GoRoute(
                path: 'browse-by-date',
                parentNavigatorKey: _shellKey,
                builder: (context, state) {
                  final kindCode =
                      int.tryParse(state.uri.queryParameters['kind'] ?? '') ?? 0;
                  final kind = MediaKind.fromCode(kindCode);
                  return SearchBrowseByReleaseDatePage(mediaKind: kind);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/social',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SocialPage(),
            ),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => buildProfileTransitionPage(state),
          ),
          GoRoute(
            path: '/profile/personal-stats',
            builder: (context, state) => const PersonalStatsPage(),
          ),
          GoRoute(
            path: '/profile/favorites/:kind',
            builder: (context, state) {
              final kind = ProfileFavoritesKind.tryParse(state.pathParameters['kind']);
              if (kind == null) {
                return const _InvalidBrowseParamsPage();
              }
              return ProfileFavoritesPage(kind: kind);
            },
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
            path: '/media/:id/characters',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return MediaCharactersPage(mediaId: id);
            },
          ),
          GoRoute(
            path: '/media/:id/staff',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return MediaStaffPage(mediaId: id);
            },
          ),
          GoRoute(
            path: '/character/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return CharacterDetailPage(characterId: id);
            },
          ),
          GoRoute(
            path: '/staff/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return StaffDetailPage(staffId: id);
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
            path: '/user/:id/followers',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['id']!);
              return UserFollowListPage(userId: userId, followers: true);
            },
          ),
          GoRoute(
            path: '/user/:id/following',
            builder: (context, state) {
              final userId = int.parse(state.pathParameters['id']!);
              return UserFollowListPage(userId: userId, followers: false);
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
            path: '/forum/media/:id',
            builder: (context, state) {
              final mediaId = int.parse(state.pathParameters['id']!);
              return ForumMediaThreadsPage(mediaId: mediaId);
            },
          ),
          GoRoute(
            path: '/forum/thread/:id',
            builder: (context, state) {
              final threadId = int.parse(state.pathParameters['id']!);
              final extra = state.extra as Map<String, dynamic>?;
              return ForumThreadPage(threadId: threadId, initialData: extra);
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
          GoRoute(
            path: '/trakt-movie/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TraktMovieDetailPage(traktId: id);
            },
          ),
          GoRoute(
            path: '/trakt-show/:id',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return TraktShowDetailPage(traktId: id);
            },
          ),
          GoRoute(
            path: '/book/:workKey',
            builder: (context, state) {
              final workKey = state.pathParameters['workKey']!;
              return BookDetailPage(workKey: workKey);
            },
          ),
          GoRoute(
            path: '/books/section/:slug',
            builder: (context, state) {
              final slug = state.pathParameters['slug']!;
              return BooksHomeSectionListPage(slug: slug);
            },
          ),
          GoRoute(
            path: '/books/subject',
            builder: (context, state) {
              final q = state.uri.queryParameters;
              final subject = q['subject'] ?? '';
              final sort = q['sort'] ?? 'popularity';
              if (subject.isEmpty) return const _InvalidBrowseParamsPage();
              return BookSubjectBrowsePage(
                subject: subject,
                initialSortKey: sort,
              );
            },
          ),
          GoRoute(
            path: '/trakt-section/:kind/:slug',
            builder: (context, state) {
              final kind = state.pathParameters['kind']! == 'movie'
                  ? MediaKind.movie
                  : MediaKind.tv;
              final slug = state.pathParameters['slug']!;
              return TraktHomeSectionListPage(kind: kind, slug: slug);
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
        path: '/books',
        builder: (context, state) => const Scaffold(
          body: BooksHomeFeedView(),
        ),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) => const AuthPage(),
      ),
      /// Visor de imagen a pantalla completa (misma pila que GoRouter → atrás del sistema coherente).
      GoRoute(
        path: '/full-image',
        parentNavigatorKey: cronicleRootNavigatorKey,
        pageBuilder: (context, state) {
          final url = state.extra as String? ?? '';
          return CustomTransitionPage<void>(
            key: state.pageKey,
            name: state.name,
            fullscreenDialog: true,
            opaque: false,
            barrierDismissible: false,
            barrierColor: null,
            transitionDuration: const Duration(milliseconds: 280),
            transitionsBuilder: (context, animation, _, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: FullscreenImagePage(imageUrl: url),
          );
        },
      ),
    ],
  );
}
