/// Route segments for `/games/section/:slug` and keys for IGDB home rails.
abstract final class GamesFeedSection {
  static const popular = 'popular';
  static const anticipated = 'anticipated';
  static const reviewsRecent = 'reviews-recent';
  static const reviewsCritics = 'reviews-critics';
  static const recentlyReleased = 'recently-released';
  static const comingSoon = 'coming-soon';
  static const bestRated = 'best-rated';
  static const indie = 'indie';
  static const horror = 'horror';
  static const multiplayer = 'multiplayer';
  static const rpg = 'rpg';
  static const sports = 'sports';

  /// Game carousels (excludes [popular] and review slugs).
  static const gameRailSlugs = <String>[
    anticipated,
    recentlyReleased,
    comingSoon,
    bestRated,
    indie,
    horror,
    multiplayer,
    rpg,
    sports,
  ];

  static const values = <String>{
    popular,
    ...gameRailSlugs,
    reviewsRecent,
    reviewsCritics,
  };

  static bool isValid(String s) => values.contains(s);
}
