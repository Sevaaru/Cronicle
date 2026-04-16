import 'package:cronicle/features/trakt/data/trakt_genre_utils.dart';

/// Trakt devuelve rutas tipo `media.trakt.tv/images/...` sin esquema; en web el
/// `<img>` las resolvería contra el origen de la app y fallan.
String? _httpsImageUrl(String? url) {
  if (url == null || url.isEmpty) return null;
  final t = url.trim();
  if (t.startsWith('https://') || t.startsWith('http://')) return t;
  if (t.startsWith('//')) return 'https:$t';
  return 'https://$t';
}

String? _nonEmptyString(dynamic v) {
  if (v is String && v.isNotEmpty) return v;
  return null;
}

String? _urlFromImageMap(Map<dynamic, dynamic> m) {
  return _nonEmptyString(m['full']) ??
      _nonEmptyString(m['medium']) ??
      _nonEmptyString(m['thumb']) ??
      _nonEmptyString(m['standard']);
}

String? _firstImageUrl(Map<String, dynamic>? images, String key) {
  if (images == null) return null;
  final v = images[key];
  final asStr = _nonEmptyString(v);
  if (asStr != null) return asStr;
  if (v is Map) {
    final fromMap = _urlFromImageMap(v);
    if (fromMap != null) return fromMap;
  }
  if (v is List) {
    for (final el in v) {
      final s = _nonEmptyString(el);
      if (s != null) return s;
      if (el is Map) {
        final u = _urlFromImageMap(el);
        if (u != null) return u;
      }
    }
  }
  return null;
}

Map<String, dynamic> _detailExtras(Map<String, dynamic> raw, {required bool isShow}) {
  final images = raw['images'] as Map<String, dynamic>?;
  final ids = raw['ids'] as Map<String, dynamic>? ?? {};
  final fanart = _httpsImageUrl(
    _firstImageUrl(images, 'fanart') ?? _firstImageUrl(images, 'banner'),
  );
  final votes = (raw['votes'] as num?)?.toInt();
  return <String, dynamic>{
    if (fanart case final String f) 'fanart': f,
    if (raw['tagline'] != null) 'tagline': raw['tagline'],
    if (raw['homepage'] != null) 'homepage': raw['homepage'],
    if (raw['trailer'] != null) 'trailer': raw['trailer'],
    if (raw['certification'] != null) 'certification': raw['certification'],
    if (raw['status'] != null) 'trakt_status': raw['status'],
    if (votes != null && votes > 0) 'votes': votes,
    if (raw['country'] != null) 'country': raw['country'],
    if (raw['language'] != null) 'language': raw['language'],
    if (raw['languages'] is List) 'languages': raw['languages'],
    if (raw['released'] != null || (isShow && raw['first_aired'] != null))
      'released': raw['released'] ?? raw['first_aired'],
    if (raw['original_title'] != null) 'original_title': raw['original_title'],
    if (raw['subgenres'] is List) 'subgenres': raw['subgenres'],
    if (ids['imdb'] != null) 'imdb_id': ids['imdb'],
    if (ids['tmdb'] != null) 'tmdb_id': ids['tmdb'],
    if (ids['slug'] != null) 'trakt_slug': ids['slug'],
    if (isShow && raw['network'] != null) 'network': raw['network'],
    if (isShow && raw['runtime'] != null) 'episode_runtime': raw['runtime'],
  };
}

/// Convierte un objeto `movie` de Trakt a la forma que usan [BrowseResultCard] y
/// [showAddToLibrarySheet] (título Anilist-like + `id` numérico Trakt).
Map<String, dynamic> normalizeTraktMovie(Map<String, dynamic> raw) {
  final ids = raw['ids'] as Map<String, dynamic>? ?? {};
  final traktId = ids['trakt'];
  final id = traktId is int ? traktId : int.tryParse('$traktId') ?? 0;
  final title = raw['title'] as String? ?? '';
  final images = raw['images'] as Map<String, dynamic>?;
  final poster = _httpsImageUrl(
    _firstImageUrl(images, 'poster') ?? _firstImageUrl(images, 'thumb'),
  );
  final rating = (raw['rating'] as num?)?.toDouble();
  final genres = (raw['genres'] as List?)?.map((e) => '$e').toList();

  return {
    'id': id,
    'title': {'english': title, 'romaji': title},
    'coverImage': {
      'large': poster,
      'extraLarge': poster,
    },
    if (rating != null) 'averageScore': (rating * 10).round().clamp(0, 100),
    'genres': genres,
    'runtime': raw['runtime'],
    'year': raw['year'],
    'overview': raw['overview'],
    'trakt_ids': ids,
    'trakt_type': 'movie',
    ..._detailExtras(raw, isShow: false),
  };
}

Map<String, dynamic> normalizeTraktShow(Map<String, dynamic> raw) {
  final ids = raw['ids'] as Map<String, dynamic>? ?? {};
  final traktId = ids['trakt'];
  final id = traktId is int ? traktId : int.tryParse('$traktId') ?? 0;
  final title = raw['title'] as String? ?? '';
  final images = raw['images'] as Map<String, dynamic>?;
  final poster = _httpsImageUrl(
    _firstImageUrl(images, 'poster') ?? _firstImageUrl(images, 'thumb'),
  );
  final rating = (raw['rating'] as num?)?.toDouble();
  final genres = (raw['genres'] as List?)?.map((e) => '$e').toList();
  final aired = (raw['aired_episodes'] as num?)?.toInt();

  return {
    'id': id,
    'title': {'english': title, 'romaji': title},
    'coverImage': {
      'large': poster,
      'extraLarge': poster,
    },
    if (rating != null) 'averageScore': (rating * 10).round().clamp(0, 100),
    'genres': genres,
    'episodes': aired ?? (raw['episode_count'] as num?)?.toInt(),
    'year': raw['year'],
    'overview': raw['overview'],
    'trakt_ids': ids,
    'trakt_type': 'show',
    ..._detailExtras(raw, isShow: true),
  };
}

bool rawTraktMovieIsAnime(Map<String, dynamic> raw) =>
    traktGenresIncludeAnime(raw['genres'] as List?);

bool rawTraktShowIsAnime(Map<String, dynamic> raw) =>
    traktGenresIncludeAnime(raw['genres'] as List?);
