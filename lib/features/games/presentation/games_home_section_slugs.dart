/// Segmento de ruta para `GoRouter`: `/games/section/:slug`.
abstract final class GamesHomeSectionSlug {
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

  static const values = <String>{
    popular,
    anticipated,
    reviewsRecent,
    reviewsCritics,
    recentlyReleased,
    comingSoon,
    bestRated,
    indie,
    horror,
    multiplayer,
  };

  static bool isValid(String s) => values.contains(s);
}
