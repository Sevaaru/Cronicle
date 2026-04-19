import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/features/books/presentation/books_home_feed_view.dart';
import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/features/games/presentation/games_section_titles.dart';
import 'package:cronicle/features/trakt/presentation/trakt_home_section_list_page.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/models/media_kind.dart';

/// Filtro de contenido «popular» en búsqueda (sin «todo»).
enum SearchBrowseCategoryMode {
  anime,
  manga,
  movie,
  tv,
  game,
  book,
}

typedef _HubEntry = ({IconData icon, String title, VoidCallback onTap});

/// Hub sin llamadas a API: solo navega a listas concretas.
class SearchCategoryBrowseHub extends StatelessWidget {
  const SearchCategoryBrowseHub({super.key, required this.mode});

  final SearchBrowseCategoryMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entries = switch (mode) {
      SearchBrowseCategoryMode.anime => _animeEntries(context, l10n),
      SearchBrowseCategoryMode.manga => _mangaEntries(context, l10n),
      SearchBrowseCategoryMode.movie => _movieEntries(context, l10n),
      SearchBrowseCategoryMode.tv => _tvEntries(context, l10n),
      SearchBrowseCategoryMode.game => _gameEntries(context, l10n),
      SearchBrowseCategoryMode.book => _bookEntries(context, l10n),
    };

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 10,
        // Mitad de altura respecto a un cuadrado (ancho × alto): ratio = ancho/alto = 2
        childAspectRatio: 2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return _HubSquareTile(
          icon: e.icon,
          title: e.title,
          onTap: e.onTap,
        );
      },
    );
  }

  List<_HubEntry> _animeEntries(BuildContext context, AppLocalizations l10n) =>
      [
        (
          icon: Icons.calendar_month_rounded,
          title: l10n.feedBrowseSeasonal,
          onTap: () => context.push('/search/anilist/ANIME/seasonal'),
        ),
        (
          icon: Icons.local_fire_department_rounded,
          title: l10n.feedBrowseTrending,
          onTap: () => context.push('/search/anilist/ANIME/trending'),
        ),
        (
          icon: Icons.star_rate_rounded,
          title: l10n.feedBrowseTopRated,
          onTap: () => context.push('/search/anilist/ANIME/top_rated'),
        ),
        (
          icon: Icons.trending_up_rounded,
          title: l10n.searchBrowsePopularityAllTime,
          onTap: () => context.push('/search/anilist/ANIME/popularity'),
        ),
        (
          icon: Icons.new_releases_rounded,
          title: l10n.feedBrowseRecentlyReleased,
          onTap: () => context.push('/search/anilist/ANIME/recently_released'),
        ),
        (
          icon: Icons.event_rounded,
          title: l10n.searchBrowseByStartDate,
          onTap: () =>
              context.push('/search/browse-by-date?kind=${MediaKind.anime.code}'),
        ),
        (
          icon: Icons.schedule_rounded,
          title: l10n.feedBrowseUpcoming,
          onTap: () => context.push('/search/anilist/ANIME/upcoming'),
        ),
        (
          icon: Icons.category_rounded,
          title: l10n.searchBrowseByGenre,
          onTap: () => context.push('/search/anilist-genres?type=ANIME'),
        ),
      ];

  List<_HubEntry> _mangaEntries(BuildContext context, AppLocalizations l10n) =>
      [
        (
          icon: Icons.local_fire_department_rounded,
          title: l10n.feedBrowseTrending,
          onTap: () => context.push('/search/anilist/MANGA/trending'),
        ),
        (
          icon: Icons.star_rate_rounded,
          title: l10n.feedBrowseTopRated,
          onTap: () => context.push('/search/anilist/MANGA/top_rated'),
        ),
        (
          icon: Icons.trending_up_rounded,
          title: l10n.searchBrowsePopularityAllTime,
          onTap: () => context.push('/search/anilist/MANGA/popularity'),
        ),
        (
          icon: Icons.new_releases_rounded,
          title: l10n.feedBrowseRecentlyReleased,
          onTap: () => context.push('/search/anilist/MANGA/recently_released'),
        ),
        (
          icon: Icons.event_rounded,
          title: l10n.searchBrowseByStartDate,
          onTap: () =>
              context.push('/search/browse-by-date?kind=${MediaKind.manga.code}'),
        ),
        (
          icon: Icons.schedule_rounded,
          title: l10n.feedBrowseUpcoming,
          onTap: () => context.push('/search/anilist/MANGA/upcoming'),
        ),
        (
          icon: Icons.category_rounded,
          title: l10n.searchBrowseByGenre,
          onTap: () => context.push('/search/anilist-genres?type=MANGA'),
        ),
      ];

  List<_HubEntry> _movieEntries(BuildContext context, AppLocalizations l10n) {
    void go(String slug) => context.push('/trakt-section/movie/$slug');
    return [
      (
        icon: Icons.event_rounded,
        title: l10n.searchBrowseByStartDate,
        onTap: () =>
            context.push('/search/browse-by-date?kind=${MediaKind.movie.code}'),
      ),
      (
        icon: Icons.whatshot_rounded,
        title: l10n.traktSectionTrending,
        onTap: () => go(TraktFeedSection.trending),
      ),
      (
        icon: Icons.trending_up_rounded,
        title: l10n.traktSectionPopular,
        onTap: () => go(TraktFeedSection.popular),
      ),
      (
        icon: Icons.upcoming_rounded,
        title: l10n.traktSectionAnticipatedMovies,
        onTap: () => go(TraktFeedSection.anticipated),
      ),
      (
        icon: Icons.play_circle_outline_rounded,
        title: l10n.traktSectionMostPlayed,
        onTap: () => go(TraktFeedSection.played),
      ),
      (
        icon: Icons.visibility_rounded,
        title: l10n.traktSectionMostWatched,
        onTap: () => go(TraktFeedSection.watched),
      ),
      (
        icon: Icons.collections_bookmark_rounded,
        title: l10n.traktSectionMostCollected,
        onTap: () => go(TraktFeedSection.collected),
      ),
    ];
  }

  List<_HubEntry> _tvEntries(BuildContext context, AppLocalizations l10n) {
    void go(String slug) => context.push('/trakt-section/tv/$slug');
    return [
      (
        icon: Icons.event_rounded,
        title: l10n.searchBrowseByStartDate,
        onTap: () =>
            context.push('/search/browse-by-date?kind=${MediaKind.tv.code}'),
      ),
      (
        icon: Icons.whatshot_rounded,
        title: l10n.traktSectionTrending,
        onTap: () => go(TraktFeedSection.trending),
      ),
      (
        icon: Icons.remove_red_eye_rounded,
        title: l10n.traktSectionWatchingNow,
        onTap: () => go(TraktFeedSection.watching),
      ),
      (
        icon: Icons.upcoming_rounded,
        title: l10n.traktSectionAnticipatedShows,
        onTap: () => go(TraktFeedSection.anticipated),
      ),
      (
        icon: Icons.visibility_rounded,
        title: l10n.traktSectionMostWatched,
        onTap: () => go(TraktFeedSection.watched),
      ),
      (
        icon: Icons.collections_bookmark_rounded,
        title: l10n.traktSectionMostCollected,
        onTap: () => go(TraktFeedSection.collected),
      ),
      (
        icon: Icons.trending_up_rounded,
        title: l10n.traktSectionPopular,
        onTap: () => go(TraktFeedSection.popular),
      ),
    ];
  }

  List<_HubEntry> _gameEntries(BuildContext context, AppLocalizations l10n) {
    void section(String slug) => context.push('/games/section/$slug');
    return [
      (
        icon: Icons.event_rounded,
        title: l10n.searchBrowseByStartDate,
        onTap: () =>
            context.push('/search/browse-by-date?kind=${MediaKind.game.code}'),
      ),
      (
        icon: Icons.sports_esports_rounded,
        title: gamesHomeSectionTitle(l10n, GamesFeedSection.popular),
        onTap: () => section(GamesFeedSection.popular),
      ),
      (
        icon: Icons.hourglass_top_rounded,
        title: gamesHomeSectionTitle(l10n, GamesFeedSection.anticipated),
        onTap: () => section(GamesFeedSection.anticipated),
      ),
      (
        icon: Icons.star_rate_rounded,
        title: gamesHomeSectionTitle(l10n, GamesFeedSection.bestRated),
        onTap: () => section(GamesFeedSection.bestRated),
      ),
      (
        icon: Icons.new_releases_rounded,
        title: gamesHomeSectionTitle(l10n, GamesFeedSection.recentlyReleased),
        onTap: () => section(GamesFeedSection.recentlyReleased),
      ),
      (
        icon: Icons.event_available_rounded,
        title: gamesHomeSectionTitle(l10n, GamesFeedSection.comingSoon),
        onTap: () => section(GamesFeedSection.comingSoon),
      ),
      (
        icon: Icons.category_rounded,
        title: l10n.searchBrowseGameThemes,
        onTap: () => context.push('/search/games-themes'),
      ),
    ];
  }

  List<_HubEntry> _bookEntries(BuildContext context, AppLocalizations l10n) {
    void section(String slug) => context.push('/books/section/$slug');
    return [
      (
        icon: Icons.event_rounded,
        title: l10n.searchBrowseByStartDate,
        onTap: () =>
            context.push('/search/browse-by-date?kind=${MediaKind.book.code}'),
      ),
      (
        icon: Icons.local_fire_department_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.trending),
        onTap: () => section(BookFeedSection.trending),
      ),
      (
        icon: Icons.favorite_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.love),
        onTap: () => section(BookFeedSection.love),
      ),
      (
        icon: Icons.auto_fix_high_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.fantasy),
        onTap: () => section(BookFeedSection.fantasy),
      ),
      (
        icon: Icons.rocket_launch_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.scienceFiction),
        onTap: () => section(BookFeedSection.scienceFiction),
      ),
      (
        icon: Icons.menu_book_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.classics),
        onTap: () => section(BookFeedSection.classics),
      ),
      (
        icon: Icons.search_rounded,
        title: booksHomeSectionTitle(l10n, BookFeedSection.mystery),
        onTap: () => section(BookFeedSection.mystery),
      ),
      (
        icon: Icons.public_rounded,
        title: l10n.searchBrowseBookSubjectsOpenLibrary,
        onTap: () => context.push('/search/book-subjects'),
      ),
    ];
  }
}

class _HubSquareTile extends StatelessWidget {
  const _HubSquareTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: cs.primary),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                      fontSize: 15,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
