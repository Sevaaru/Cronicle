import 'package:cronicle/features/games/data/games_feed_section.dart';
import 'package:cronicle/l10n/app_localizations.dart';

String gamesHomeSectionTitle(AppLocalizations l10n, String slug) {
  return switch (slug) {
    GamesFeedSection.popular => l10n.gamesHomePopularNow,
    GamesFeedSection.anticipated => l10n.gamesHomeMostAnticipated,
    GamesFeedSection.reviewsRecent => l10n.gamesHomeRecentReviews,
    GamesFeedSection.reviewsCritics => l10n.gamesHomeCriticsReviews,
    GamesFeedSection.recentlyReleased => l10n.gamesHomeRecentlyReleased,
    GamesFeedSection.comingSoon => l10n.gamesHomeComingSoon,
    GamesFeedSection.bestRated => l10n.gamesHomeBestRated,
    GamesFeedSection.indie => l10n.gamesHomeIndiePicks,
    GamesFeedSection.horror => l10n.gamesHomeHorrorPicks,
    GamesFeedSection.multiplayer => l10n.gamesHomeMultiplayer,
    GamesFeedSection.rpg => l10n.gamesHomeRpgSpotlight,
    GamesFeedSection.sports => l10n.gamesHomeSportsSpotlight,
    _ => l10n.gamesHomeNoItems,
  };
}
