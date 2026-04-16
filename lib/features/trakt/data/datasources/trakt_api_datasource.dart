import 'package:dio/dio.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/trakt/data/trakt_normalize.dart';

/// Trakt.tv API v2. Requiere [EnvConfig.traktClientId] en cabecera `trakt-api-key`.
class TraktApiDatasource {
  TraktApiDatasource(this._dio);

  final Dio _dio;

  static const _base = 'https://api.trakt.tv';
  static const _extended = 'full,images';

  void _ensureClientId() {
    if (EnvConfig.traktClientId.isEmpty) {
      throw StateError('TRAKT_CLIENT_ID no configurado');
    }
  }

  Future<Options> _options({
    String? bearerToken,
    bool accept404 = false,
    bool accept401 = false,
  }) async {
    _ensureClientId();
    final headers = <String, dynamic>{
      'Content-Type': 'application/json',
      'trakt-api-version': '2',
      'trakt-api-key': EnvConfig.traktClientId,
    };
    if (bearerToken != null && bearerToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $bearerToken';
    }
    bool Function(int?)? validateStatus;
    if (accept404) {
      validateStatus = (s) => s == 200 || s == 404;
    } else if (accept401) {
      validateStatus = (s) => s == 200 || s == 401;
    }
    return Options(headers: headers, validateStatus: validateStatus);
  }

  List<Map<String, dynamic>> _list(dynamic data) {
    if (data is! List) return [];
    return data.cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> _filterMovies(List<Map<String, dynamic>> raw) {
    final out = <Map<String, dynamic>>[];
    for (final m in raw) {
      if (rawTraktMovieIsAnime(m)) continue;
      out.add(normalizeTraktMovie(m));
    }
    return out;
  }

  List<Map<String, dynamic>> _filterShows(List<Map<String, dynamic>> raw) {
    final out = <Map<String, dynamic>>[];
    for (final s in raw) {
      if (rawTraktShowIsAnime(s)) continue;
      out.add(normalizeTraktShow(s));
    }
    return out;
  }

  List<Map<String, dynamic>> _fromTrendingMovies(List<Map<String, dynamic>> rows) {
    final movies = <Map<String, dynamic>>[];
    for (final row in rows) {
      final m = row['movie'] as Map<String, dynamic>?;
      if (m != null) {
        movies.add(m);
      } else if (row.containsKey('title') && row['ids'] != null) {
        movies.add(row);
      }
    }
    return _filterMovies(movies);
  }

  List<Map<String, dynamic>> _fromTrendingShows(List<Map<String, dynamic>> rows) {
    final shows = <Map<String, dynamic>>[];
    for (final row in rows) {
      final s = row['show'] as Map<String, dynamic>?;
      if (s != null) {
        shows.add(s);
      } else if (row.containsKey('title') && row['ids'] != null) {
        shows.add(row);
      }
    }
    return _filterShows(shows);
  }

  Future<List<Map<String, dynamic>>> moviesTrending({int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/trending',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  Future<List<Map<String, dynamic>>> showsTrending({int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/trending',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingShows(_list(res.data));
  }

  Future<List<Map<String, dynamic>>> moviesPopular({int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/popular',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  Future<List<Map<String, dynamic>>> showsPopular({int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/popular',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingShows(_list(res.data));
  }

  Future<List<Map<String, dynamic>>> moviesWatching({int limit = 30}) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/watching',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    final rows = _list(res.data);
    final movies = <Map<String, dynamic>>[];
    for (final row in rows) {
      final m = row['movie'] as Map<String, dynamic>?;
      if (m != null) movies.add(m);
    }
    return _filterMovies(movies);
  }

  Future<List<Map<String, dynamic>>> showsWatching({int limit = 30}) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/watching',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    final rows = _list(res.data);
    final shows = <Map<String, dynamic>>[];
    for (final row in rows) {
      final s = row['show'] as Map<String, dynamic>?;
      if (s != null) shows.add(s);
    }
    return _filterShows(shows);
  }

  /// Actividad pública: usuarios viendo ahora (películas), sin duplicar anime.
  Future<List<Map<String, dynamic>>> moviesWatchingActivity({int limit = 40}) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/watching',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    final out = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final m = row['movie'] as Map<String, dynamic>?;
      final u = row['user'] as Map<String, dynamic>?;
      if (m == null || rawTraktMovieIsAnime(m)) continue;
      out.add({
        'user': u,
        'movie': m,
        'expires_at': row['expires_at'],
      });
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> showsWatchingActivity({int limit = 40}) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/watching',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    final out = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final s = row['show'] as Map<String, dynamic>?;
      final u = row['user'] as Map<String, dynamic>?;
      if (s == null || rawTraktShowIsAnime(s)) continue;
      out.add({
        'user': u,
        'show': s,
        'expires_at': row['expires_at'],
      });
    }
    return out;
  }

  Future<List<Map<String, dynamic>>> searchMovies(String query, {int limit = 15}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final res = await _dio.get<dynamic>(
      '$_base/search/movie',
      queryParameters: {
        'query': q,
        'limit': limit,
        'extended': _extended,
      },
      options: await _options(),
    );
    final movies = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final m = row['movie'] as Map<String, dynamic>?;
      if (m != null) movies.add(m);
    }
    return _filterMovies(movies);
  }

  Future<List<Map<String, dynamic>>> searchShows(String query, {int limit = 15}) async {
    final q = query.trim();
    if (q.isEmpty) return [];
    final res = await _dio.get<dynamic>(
      '$_base/search/show',
      queryParameters: {
        'query': q,
        'limit': limit,
        'extended': _extended,
      },
      options: await _options(),
    );
    final shows = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final s = row['show'] as Map<String, dynamic>?;
      if (s != null) shows.add(s);
    }
    return _filterShows(shows);
  }

  Future<Map<String, dynamic>?> fetchMovieSummary(int traktId) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/$traktId',
      queryParameters: {'extended': _extended},
      options: await _options(accept404: true),
    );
    if (res.statusCode != 200 || res.data is! Map) return null;
    final raw = Map<String, dynamic>.from(res.data as Map);
    if (rawTraktMovieIsAnime(raw)) return null;
    return normalizeTraktMovie(raw);
  }

  Future<Map<String, dynamic>?> fetchShowSummary(int traktId) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/$traktId',
      queryParameters: {'extended': _extended},
      options: await _options(accept404: true),
    );
    if (res.statusCode != 200 || res.data is! Map) return null;
    final raw = Map<String, dynamic>.from(res.data as Map);
    if (rawTraktShowIsAnime(raw)) return null;
    return normalizeTraktShow(raw);
  }

  /// Historial visto (OAuth). Películas completadas / reproducidas.
  Future<List<Map<String, dynamic>>> syncWatchedMovies(String accessToken) async {
    final res = await _dio.get<dynamic>(
      '$_base/sync/watched/movies',
      queryParameters: {'extended': _extended},
      options: await _options(bearerToken: accessToken),
    );
    final out = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final m = row['movie'] as Map<String, dynamic>?;
      if (m == null || rawTraktMovieIsAnime(m)) continue;
      out.add({
        'plays': row['plays'],
        'last_watched_at': row['last_watched_at'],
        'movie': m,
      });
    }
    return out;
  }

  /// Historial series (OAuth).
  Future<List<Map<String, dynamic>>> syncWatchedShows(String accessToken) async {
    final res = await _dio.get<dynamic>(
      '$_base/sync/watched/shows',
      queryParameters: {'extended': _extended},
      options: await _options(bearerToken: accessToken),
    );
    final out = <Map<String, dynamic>>[];
    for (final row in _list(res.data)) {
      final s = row['show'] as Map<String, dynamic>?;
      if (s == null || rawTraktShowIsAnime(s)) continue;
      out.add({
        'plays': row['plays'],
        'last_watched_at': row['last_watched_at'],
        'show': s,
        'seasons': row['seasons'],
      });
    }
    return out;
  }

  Future<Map<String, dynamic>?> fetchUserSettings(String accessToken) async {
    final res = await _dio.get<dynamic>(
      '$_base/users/settings',
      options: await _options(bearerToken: accessToken, accept401: true),
    );
    if (res.statusCode != 200 || res.data is! Map) return null;
    return Map<String, dynamic>.from(res.data as Map);
  }
}

int countWatchedEpisodesFromSeasons(dynamic seasonsRaw) {
  if (seasonsRaw is! List) return 0;
  var n = 0;
  for (final se in seasonsRaw) {
    if (se is! Map) continue;
    final eps = se['episodes'] as List?;
    if (eps == null) continue;
    n += eps.length;
  }
  return n;
}
