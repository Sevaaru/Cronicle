/// Trakt usa el género [anime] para animación japonesa; lo excluimos para no
/// duplicar el catálogo de AniList.
bool traktGenresIncludeAnime(Iterable<dynamic>? genres) {
  if (genres == null) return false;
  for (final g in genres) {
    if (g is String && g.toLowerCase() == 'anime') return true;
  }
  return false;
}
