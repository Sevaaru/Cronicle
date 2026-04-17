/// Segmentos de ruta `/profile/favorites/:kind`.
enum ProfileFavoritesKind {
  anime('anime'),
  manga('manga'),
  games('games'),
  movies('movies'),
  tv('tv');

  const ProfileFavoritesKind(this.segment);
  final String segment;

  static ProfileFavoritesKind? tryParse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final v in ProfileFavoritesKind.values) {
      if (v.segment == raw) return v;
    }
    return null;
  }
}
