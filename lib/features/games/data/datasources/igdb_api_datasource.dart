import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cronicle/features/games/data/datasources/igdb_auth_datasource.dart';

/// IGDB does not allow browser origins (no CORS); use Android, iOS, or desktop.
class IgdbWebUnsupportedException implements Exception {
  const IgdbWebUnsupportedException();
}

/// Talks to the IGDB v4 API using Apicalypse query syntax.
class IgdbApiDatasource {
  IgdbApiDatasource(this._dio, this._auth);

  final Dio _dio;
  final IgdbAuthDatasource _auth;

  static const _baseUrl = 'https://api.igdb.com/v4';

  Future<Options> _headers() async {
    final token = await _auth.getValidToken();
    return Options(
      headers: {
        'Client-ID': _auth.clientId,
        'Authorization': 'Bearer $token',
      },
    );
  }

  /// Builds an IGDB image URL from an image_id.
  static String coverUrl(String imageId, {String size = 't_cover_big'}) =>
      'https://images.igdb.com/igdb/image/upload/$size/$imageId.jpg';

  static String screenshotUrl(String imageId) =>
      'https://images.igdb.com/igdb/image/upload/t_screenshot_big/$imageId.jpg';

  /// Search games by name.
  Future<List<Map<String, dynamic>>> searchGames(String query) async {
    final escaped = query.replaceAll('"', '\\"');
    final body = '''
search "$escaped";
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date, summary;
limit 20;
''';
    return _postList('/games', body);
  }

  /// Fetch popular games. Tries several Apicalypse shapes because some
  /// field combinations or filters can yield an empty list on IGDB.
  ///
  /// IGDB's `Game` schema no longer exposes `popularity` on `/games`; asking
  /// for it or `sort popularity desc` returns HTTP 400. Older queries are kept
  /// as fallbacks where useful, but each attempt is wrapped so a 400 does not
  /// block the next candidate.
  Future<List<Map<String, dynamic>>> fetchPopularGames({int limit = 20}) async {
    final candidates = <String>[
      // Main-ish games with user ratings (closest to "trending" without popularity).
      '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date, summary;
where category = 0 & total_rating > 0;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date, summary;
where category = 0;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date, summary;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, total_rating, first_release_date, summary;
sort id desc;
limit $limit;
''',
    ];
    for (var i = 0; i < candidates.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 280));
      }
      try {
        final list = await _postList('/games', candidates[i]);
        if (list.isNotEmpty) return list;
      } catch (_) {
        continue;
      }
    }
    return [];
  }

  /// Próximos lanzamientos con más hype (si el campo existe); si no, por fecha.
  Future<List<Map<String, dynamic>>> fetchGamesMostAnticipated(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final yearAhead = now + 365 * 24 * 3600;
    final candidates = <String>[
      '''
fields name, cover.image_id, first_release_date, summary, hypes;
where category = 0 & first_release_date > $now & first_release_date < $yearAhead;
sort hypes desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now & first_release_date < $yearAhead;
sort first_release_date asc;
limit $limit;
''',
    ];
    for (final body in candidates) {
      try {
        final list = await _postList('/games', body);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  /// Lanzados recientemente (últimos 18 meses).
  Future<List<Map<String, dynamic>>> fetchGamesRecentlyReleased(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final past = now - 548 * 24 * 3600; // ~18 months
    final body = '''
fields name, cover.image_id, first_release_date, total_rating, summary;
where category = 0 & first_release_date <= $now & first_release_date >= $past;
sort first_release_date desc;
limit $limit;
''';
    try {
      return await _postList('/games', body);
    } catch (_) {
      return [];
    }
  }

  /// Próximo a salir (fecha de lanzamiento futura).
  Future<List<Map<String, dynamic>>> fetchGamesComingSoon({int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cap = now + 730 * 24 * 3600; // 2 years
    final body = '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now & first_release_date < $cap;
sort first_release_date asc;
limit $limit;
''';
    try {
      return await _postList('/games', body);
    } catch (_) {
      return [];
    }
  }

  /// Reseñas recientes (comunidad IGDB).
  Future<List<Map<String, dynamic>>> fetchReviewsRecent({int limit = 30}) async {
    final body = '''
fields id, title, content, score, created_at, user.username,
       game.id, game.name, game.cover.image_id;
sort created_at desc;
limit $limit;
''';
    final raw = await _postList('/reviews', body);
    return raw
        .where((r) => (r['game'] as Map<String, dynamic>?) != null)
        .toList();
  }

  /// Reseñas con puntuación alta (aprox. “críticos” / destacadas).
  Future<List<Map<String, dynamic>>> fetchReviewsHighScore(
      {int limit = 24, int minScore = 80}) async {
    final body = '''
fields id, title, content, score, created_at, user.username,
       game.id, game.name, game.cover.image_id;
where score >= $minScore;
sort created_at desc;
limit $limit;
''';
    try {
      final raw = await _postList('/reviews', body);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Una reseña por id (para pantalla de lectura).
  Future<Map<String, dynamic>?> fetchReviewById(int reviewId) async {
    final body = '''
fields id, title, content, score, created_at, user.username,
       game.id, game.name, game.cover.image_id;
where id = $reviewId;
''';
    final list = await _postList('/reviews', body);
    return list.isEmpty ? null : list.first;
  }

  /// Full game detail by ID.
  ///
  /// Playtime estimates live on the separate [GameTimeToBeat] resource
  /// (`/game_time_to_beats`), not as `game.time_to_beat` — requesting the
  /// latter in `fields` returns HTTP 400 from IGDB.
  Future<Map<String, dynamic>?> fetchGameDetail(int gameId) async {
    final body = '''
fields name, summary, total_rating, total_rating_count,
       aggregated_rating, aggregated_rating_count,
       cover.image_id,
       screenshots.image_id,
       artworks.image_id,
       genres.name,
       platforms.name, platforms.abbreviation,
       involved_companies.company.name, involved_companies.developer,
       involved_companies.publisher,
       first_release_date,
       similar_games.name, similar_games.cover.image_id,
       game_modes.name,
       themes.name,
       status,
       category,
       url,
       websites.url, websites.category,
       external_games.url, external_games.category, external_games.uid,
       external_games.name, external_games.external_game_source.name;
where id = $gameId;
''';
    final list = await _postList('/games', body);
    if (list.isEmpty) return null;
    final game = list.first;
    try {
      final ttb = await _fetchGameTimeToBeat(gameId);
      if (ttb != null) {
        game['time_to_beat'] = ttb;
      }
    } catch (_) {
      // Pro tier / network: detail page still works without estimates.
    }
    return game;
  }

  Future<Map<String, dynamic>?> _fetchGameTimeToBeat(int gameId) async {
    final body = '''
fields hastily, normally, completely;
where game_id = $gameId;
limit 1;
''';
    final list = await _postList('/game_time_to_beats', body);
    return list.isEmpty ? null : list.first;
  }

  /// Community reviews for a game (IGDB `/reviews`).
  Future<List<Map<String, dynamic>>> fetchGameReviews(int gameId) async {
    final body = '''
fields id, title, content, score, created_at, user.username;
where game = $gameId;
sort created_at desc;
limit 15;
''';
    return _postList('/reviews', body);
  }

  /// IGDB often returns protocol-relative URLs (`//www.igdb.com/...`).
  static String? absoluteHttpUrl(String? u) {
    if (u == null || u.isEmpty) return null;
    final t = u.trim();
    if (t.startsWith('//')) return 'https:$t';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  /// Normalizes a raw IGDB game map into the common format used by
  /// [SearchPage] and [AddToLibrarySheet].
  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final name = raw['name'] as String? ?? '';
    final cover = raw['cover'] as Map<String, dynamic>?;
    final coverImageId = cover?['image_id'] as String?;
    final genres = (raw['genres'] as List?)
        ?.map((g) => (g as Map<String, dynamic>)['name'] as String? ?? '')
        .where((g) => g.isNotEmpty)
        .toList();
    final platforms = (raw['platforms'] as List?)
        ?.map((p) =>
            (p as Map<String, dynamic>)['abbreviation'] as String? ??
            (p)['name'] as String? ??
            '')
        .where((p) => p.isNotEmpty)
        .toList();
    final rating = raw['total_rating'] as num?;
    final idRaw = raw['id'];
    final gameId = idRaw is int
        ? idRaw
        : idRaw is num
            ? idRaw.toInt()
            : int.tryParse('$idRaw');

    return {
      'id': gameId,
      'title': {'english': name, 'romaji': name},
      'name': name,
      'coverImage': {
        if (coverImageId != null)
          'large': coverUrl(coverImageId)
        else
          'large': null,
        if (coverImageId != null)
          'extraLarge': coverUrl(coverImageId, size: 't_cover_big_2x'),
      },
      'genres': genres ?? <String>[],
      'averageScore': rating?.round(),
      'format': platforms?.take(3).join(', '),
      'summary': raw['summary'],
      'first_release_date': raw['first_release_date'],
      'screenshots': raw['screenshots'],
      'artworks': raw['artworks'],
      'involved_companies': raw['involved_companies'],
      'similar_games': raw['similar_games'],
      'game_modes': raw['game_modes'],
      'themes': raw['themes'],
      'status': raw['status'],
      'url': raw['url'],
      'igdb_page_url': absoluteHttpUrl(raw['url'] as String?),
      'time_to_beat': raw['time_to_beat'],
      'websites': raw['websites'],
      'external_games': raw['external_games'],
      '_raw': raw,
    };
  }

  Future<List<Map<String, dynamic>>> _postList(
      String endpoint, String body) async {
    if (kIsWeb) {
      throw const IgdbWebUnsupportedException();
    }
    final options = await _headers();
    final res = await _dio.post<dynamic>(
      '$_baseUrl$endpoint',
      data: body,
      options: Options(
        headers: options.headers,
        contentType: 'text/plain',
        validateStatus: (_) => true,
      ),
    );

    final code = res.statusCode ?? 0;
    if (code >= 400) {
      if (res.data is Map<String, dynamic>) {
        final m = res.data as Map<String, dynamic>;
        final msg = m['message'] as String? ?? m.toString();
        throw Exception('IGDB ($code): $msg');
      }
      throw Exception('IGDB HTTP $code');
    }

    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    if (res.data is Map<String, dynamic>) {
      final m = res.data as Map<String, dynamic>;
      final msg = m['message'] as String? ?? m.toString();
      throw Exception('IGDB: $msg');
    }
    return [];
  }
}
