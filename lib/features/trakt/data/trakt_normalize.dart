import 'package:cronicle/features/trakt/data/trakt_genre_utils.dart';

String? _firstImageUrl(Map<String, dynamic>? images, String key) {
  if (images == null) return null;
  final v = images[key];
  if (v is String && v.isNotEmpty) return v;
  if (v is List && v.isNotEmpty) {
    final first = v.first;
    if (first is String && first.isNotEmpty) return first;
  }
  return null;
}

/// Convierte un objeto `movie` de Trakt a la forma que usan [BrowseResultCard] y
/// [showAddToLibrarySheet] (título Anilist-like + `id` numérico Trakt).
Map<String, dynamic> normalizeTraktMovie(Map<String, dynamic> raw) {
  final ids = raw['ids'] as Map<String, dynamic>? ?? {};
  final traktId = ids['trakt'];
  final id = traktId is int ? traktId : int.tryParse('$traktId') ?? 0;
  final title = raw['title'] as String? ?? '';
  final images = raw['images'] as Map<String, dynamic>?;
  final poster = _firstImageUrl(images, 'poster') ?? _firstImageUrl(images, 'thumb');
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
  };
}

Map<String, dynamic> normalizeTraktShow(Map<String, dynamic> raw) {
  final ids = raw['ids'] as Map<String, dynamic>? ?? {};
  final traktId = ids['trakt'];
  final id = traktId is int ? traktId : int.tryParse('$traktId') ?? 0;
  final title = raw['title'] as String? ?? '';
  final images = raw['images'] as Map<String, dynamic>?;
  final poster = _firstImageUrl(images, 'poster') ?? _firstImageUrl(images, 'thumb');
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
  };
}

bool rawTraktMovieIsAnime(Map<String, dynamic> raw) =>
    traktGenresIncludeAnime(raw['genres'] as List?);

bool rawTraktShowIsAnime(Map<String, dynamic> raw) =>
    traktGenresIncludeAnime(raw['genres'] as List?);
