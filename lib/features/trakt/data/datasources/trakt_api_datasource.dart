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
    if (accept404 && accept401) {
      validateStatus = (s) => s == 200 || s == 404 || s == 401;
    } else if (accept404) {
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

  /// Películas más esperadas (la API **no** expone `/movies/watching`; solo existe para series).
  Future<List<Map<String, dynamic>>> moviesAnticipated({int limit = 30}) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/anticipated',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  /// Películas más reproducidas en el período indicado (`weekly`, `monthly`, `yearly`, `all`).
  Future<List<Map<String, dynamic>>> moviesPlayed({
    String period = 'weekly',
    int limit = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/played/$period',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  /// Películas más vistas (usuarios únicos) en el período indicado.
  Future<List<Map<String, dynamic>>> moviesWatched({
    String period = 'weekly',
    int limit = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/watched/$period',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  /// Películas más coleccionadas en el período indicado.
  Future<List<Map<String, dynamic>>> moviesCollected({
    String period = 'weekly',
    int limit = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/movies/collected/$period',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingMovies(_list(res.data));
  }

  /// Series más esperadas.
  Future<List<Map<String, dynamic>>> showsAnticipated({int limit = 20}) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/anticipated',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingShows(_list(res.data));
  }

  /// Series más vistas (usuarios únicos) en el período indicado.
  Future<List<Map<String, dynamic>>> showsWatched({
    String period = 'weekly',
    int limit = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/watched/$period',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingShows(_list(res.data));
  }

  /// Series más coleccionadas en el período indicado.
  Future<List<Map<String, dynamic>>> showsCollected({
    String period = 'weekly',
    int limit = 20,
  }) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/collected/$period',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(),
    );
    return _fromTrendingShows(_list(res.data));
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
      queryParameters: {'extended': _extended},
      options: await _options(bearerToken: accessToken, accept401: true),
    );
    if (res.statusCode != 200 || res.data is! Map) return null;
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Estadísticas públicas de usuario (`/users/{slug}/stats`).
  Future<Map<String, dynamic>> fetchUserStats(String userSlug) async {
    final enc = Uri.encodeComponent(userSlug);
    final res = await _dio.get<dynamic>(
      '$_base/users/$enc/stats',
      options: await _options(accept404: true),
    );
    if (res.statusCode != 200 || res.data is! Map) return {};
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// Favoritos de película en perfil Trakt (excluye anime en normalización).
  ///
  /// [accessToken]: OAuth del usuario; necesario si el perfil o los favoritos
  /// son privados (sin token la API suele devolver 401 y la lista queda vacía).
  Future<List<Map<String, dynamic>>> fetchUserFavoriteMovies(
    String userSlug, {
    int limit = 40,
    String? accessToken,
  }) async {
    final enc = Uri.encodeComponent(userSlug);
    final res = await _dio.get<dynamic>(
      '$_base/users/$enc/favorites/movies',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(
        bearerToken: accessToken,
        accept404: true,
        accept401: true,
      ),
    );
    if (res.statusCode != 200) return [];
    return _favoriteRowsToMedia(_list(res.data), nestedKey: 'movie', isShow: false);
  }

  /// Favoritos de serie en perfil Trakt (excluye anime en normalización).
  ///
  /// [accessToken]: OAuth del usuario para favoritos / perfil privado.
  Future<List<Map<String, dynamic>>> fetchUserFavoriteShows(
    String userSlug, {
    int limit = 40,
    String? accessToken,
  }) async {
    final enc = Uri.encodeComponent(userSlug);
    final res = await _dio.get<dynamic>(
      '$_base/users/$enc/favorites/shows',
      queryParameters: {'limit': limit, 'extended': _extended},
      options: await _options(
        bearerToken: accessToken,
        accept404: true,
        accept401: true,
      ),
    );
    if (res.statusCode != 200) return [];
    return _favoriteRowsToMedia(_list(res.data), nestedKey: 'show', isShow: true);
  }

  List<Map<String, dynamic>> _favoriteRowsToMedia(
    List<Map<String, dynamic>> rows, {
    required String nestedKey,
    required bool isShow,
  }) {
    final out = <Map<String, dynamic>>[];
    for (final row in rows) {
      final raw = row[nestedKey] as Map<String, dynamic>?;
      if (raw == null) continue;
      if (isShow) {
        if (rawTraktShowIsAnime(raw)) continue;
        out.add(normalizeTraktShow(raw));
      } else {
        if (rawTraktMovieIsAnime(raw)) continue;
        out.add(normalizeTraktMovie(raw));
      }
    }
    return out;
  }

  Future<Response<dynamic>> _postAuthorized(
    String path,
    Map<String, dynamic> body,
    String accessToken,
  ) async {
    final baseOpts = await _options(bearerToken: accessToken);
    return _dio.post<dynamic>(
      '$_base$path',
      data: body,
      options: Options(
        headers: baseOpts.headers,
        contentType: Headers.jsonContentType,
        validateStatus: (_) => true,
      ),
    );
  }

  void _ensureSync2xx(Response<dynamic> res, String endpoint) {
    final c = res.statusCode ?? 0;
    if (c < 200 || c >= 300) {
      final msg = res.data is Map
          ? '${(res.data as Map)['error'] ?? res.data}'
          : '$res.data';
      throw StateError('Trakt $endpoint HTTP $c: $msg');
    }
  }

  /// Episodios en orden emisión (temporada asc, episodio asc). Omite temporada 0
  /// (especiales) si existe al menos una temporada > 0.
  Future<List<(int season, int episode)>> fetchShowEpisodesAiringOrder(int showTraktId) async {
    final res = await _dio.get<dynamic>(
      '$_base/shows/$showTraktId/seasons',
      queryParameters: {'extended': 'episodes'},
      options: await _options(),
    );
    if (res.statusCode != 200 || res.data is! List) return [];
    final list = _list(res.data);
    final skipZero = list.any((s) => ((s['number'] as num?)?.toInt() ?? -1) > 0);
    final seasons = [...list]..sort(
        (a, b) => ((a['number'] as num?)?.toInt() ?? 0)
            .compareTo((b['number'] as num?)?.toInt() ?? 0),
      );
    final out = <(int, int)>[];
    for (final s in seasons) {
      final sn = (s['number'] as num?)?.toInt() ?? 0;
      if (skipZero && sn == 0) continue;
      final eps = (s['episodes'] as List?) ?? [];
      final sorted = [...eps]
        ..sort(
          (a, b) => ((((a as Map)['number'] as num?)?.toInt() ?? 0))
              .compareTo((((b as Map)['number'] as num?)?.toInt() ?? 0)),
        );
      for (final ep in sorted) {
        final m = ep as Map<String, dynamic>;
        final en = (m['number'] as num?)?.toInt() ?? 0;
        out.add((sn, en));
      }
    }
    return out;
  }

  Future<void> syncHistoryAddMovies(String accessToken, List<Map<String, dynamic>> movies) async {
    if (movies.isEmpty) return;
    final r = await _postAuthorized('/sync/history', {'movies': movies}, accessToken);
    _ensureSync2xx(r, '/sync/history');
  }

  Future<void> syncHistoryRemoveMovies(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/history/remove', {'movies': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/history/remove');
  }

  Future<void> syncHistoryAddShows(String accessToken, List<Map<String, dynamic>> shows) async {
    if (shows.isEmpty) return;
    final r = await _postAuthorized('/sync/history', {'shows': shows}, accessToken);
    _ensureSync2xx(r, '/sync/history');
  }

  Future<void> syncHistoryRemoveShows(String accessToken, List<Map<String, dynamic>> shows) async {
    if (shows.isEmpty) return;
    final r = await _postAuthorized('/sync/history/remove', {'shows': shows}, accessToken);
    _ensureSync2xx(r, '/sync/history/remove');
  }

  Future<void> syncWatchlistAddMovies(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/watchlist', {'movies': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/watchlist');
  }

  Future<void> syncWatchlistRemoveMovies(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/watchlist/remove', {'movies': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/watchlist/remove');
  }

  Future<void> syncWatchlistAddShows(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/watchlist', {'shows': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/watchlist');
  }

  Future<void> syncWatchlistRemoveShows(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/watchlist/remove', {'shows': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/watchlist/remove');
  }

  Future<void> syncRatingsMovies(String accessToken, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final r = await _postAuthorized('/sync/ratings', {'movies': rows}, accessToken);
    _ensureSync2xx(r, '/sync/ratings');
  }

  Future<void> syncRatingsShows(String accessToken, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    final r = await _postAuthorized('/sync/ratings', {'shows': rows}, accessToken);
    _ensureSync2xx(r, '/sync/ratings');
  }

  Future<void> syncRatingsRemoveMovies(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/ratings/remove', {'movies': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/ratings/remove');
  }

  Future<void> syncRatingsRemoveShows(String accessToken, List<Map<String, dynamic>> idsMaps) async {
    if (idsMaps.isEmpty) return;
    final r = await _postAuthorized('/sync/ratings/remove', {'shows': idsMaps}, accessToken);
    _ensureSync2xx(r, '/sync/ratings/remove');
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
