/// Segmento de ruta para `GoRouter`: `/games/section/:slug`.
abstract final class GamesHomeSectionSlug {
  static const popular = 'popular';
  static const anticipated = 'anticipated';
  static const reviewsRecent = 'reviews-recent';
  static const reviewsCritics = 'reviews-critics';
  static const recentlyReleased = 'recently-released';
  static const comingSoon = 'coming-soon';

  static const values = <String>{
    popular,
    anticipated,
    reviewsRecent,
    reviewsCritics,
    recentlyReleased,
    comingSoon,
  };

  static bool isValid(String s) => values.contains(s);
}
