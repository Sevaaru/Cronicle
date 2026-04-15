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

  /// Resuelve el `popularity_type` de visitas IGDB (PopScore); cacheado en memoria.
  int? _cachedVisitPopularityTypeId;

  static const _queryRetryDelayMs = 180;

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

  /// Popular vía IGDB PopScore (`/popularity_primitives` + `/games` por ids en
  /// orden de visitas). Si no hay datos, orden estable por `total_rating`.
  Future<List<Map<String, dynamic>>> fetchPopularGames({int limit = 24}) async {
    final viaPop = await _fetchPopularViaPopularityPrimitives(limit: limit);
    if (viaPop.isNotEmpty) return viaPop;

    final candidates = <String>[
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
fields name, cover.image_id, total_rating, first_release_date, summary;
where category = 0;
sort id desc;
limit $limit;
''',
    ];
    for (var i = 0; i < candidates.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(
            const Duration(milliseconds: _queryRetryDelayMs));
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

  Future<int> _resolveVisitPopularityTypeId() async {
    if (_cachedVisitPopularityTypeId != null) {
      return _cachedVisitPopularityTypeId!;
    }
    try {
      final rows = await _postList('/popularity_types', 'fields id, name; limit 100;');
      for (final r in rows) {
        final name = (r['name'] as String? ?? '').toLowerCase();
        final idRaw = r['id'];
        final tid =
            idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : null;
        if (tid == null) continue;
        if (name.contains('visit') ||
            name.contains('traffic') ||
            name.contains('page view')) {
          _cachedVisitPopularityTypeId = tid;
          return tid;
        }
      }
    } catch (_) {}
    _cachedVisitPopularityTypeId = 1;
    return 1;
  }

  int? _popularityPrimitiveGameId(Map<String, dynamic> p) {
    final v = p['game_id'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    final g = p['game'];
    if (g is int) return g;
    if (g is num) return g.toInt();
    if (g is Map<String, dynamic>) {
      final id = g['id'];
      if (id is int) return id;
      if (id is num) return id.toInt();
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchPopularViaPopularityPrimitives({
    required int limit,
  }) async {
    try {
      final typeId = await _resolveVisitPopularityTypeId();
      const maxScan = 100;
      final primitives = await _postList('/popularity_primitives', '''
fields game_id, value, popularity_type;
where popularity_type = $typeId;
sort value desc;
limit $maxScan;
''');
      final orderedIds = <int>[];
      final seen = <int>{};
      for (final p in primitives) {
        final gid = _popularityPrimitiveGameId(p);
        if (gid == null || seen.contains(gid)) continue;
        seen.add(gid);
        orderedIds.add(gid);
      }
      if (orderedIds.isEmpty) return [];

      final idList = orderedIds.join(',');
      final games = await _postList('/games', '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date, summary, category;
where id = ($idList);
limit ${orderedIds.length};
''');
      final byId = <int, Map<String, dynamic>>{};
      for (final g in games) {
        final idRaw = g['id'];
        final gid =
            idRaw is int ? idRaw : idRaw is num ? idRaw.toInt() : null;
        if (gid != null) byId[gid] = g;
      }
      final out = <Map<String, dynamic>>[];
      for (final id in orderedIds) {
        final g = byId[id];
        if (g == null) continue;
        final cat = g['category'];
        final c = cat is int ? cat : cat is num ? cat.toInt() : null;
        if (c != null && c != 0) continue;
        out.add(g);
        if (out.length >= limit) break;
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Ejecuta varias consultas `/games` hasta obtener resultados (p. ej. tras 400
  /// por campos retirados o listas vacías por filtros demasiado estrictos).
  Future<List<Map<String, dynamic>>> _tryPostGameQueries(
    List<String> candidates,
  ) async {
    for (var i = 0; i < candidates.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(
            const Duration(milliseconds: _queryRetryDelayMs));
      }
      try {
        final list = await _postList('/games', candidates[i]);
        if (list.isNotEmpty) return list;
      } catch (_) {}
    }
    return [];
  }

  /// Próximos lanzamientos (fecha futura); intenta sin `hypes` primero porque
  /// puede devolver HTTP 400 o cero filas.
  Future<List<Map<String, dynamic>>> fetchGamesMostAnticipated(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final oneYear = now + 365 * 24 * 3600;
    final twoYears = now + 730 * 24 * 3600;
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now & first_release_date < $twoYears;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, release_dates.date, summary;
where category = 0 & release_dates.date > $now & release_dates.date < $twoYears;
sort release_dates.date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary, hypes;
where category = 0 & first_release_date > $now & first_release_date < $oneYear;
sort hypes desc;
limit $limit;
''',
    ]);
  }

  /// Lanzados recientemente (ventana ~18 meses, con ampliaciones y `release_dates`).
  Future<List<Map<String, dynamic>>> fetchGamesRecentlyReleased(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final past = now - 548 * 24 * 3600; // ~18 months
    final pastWide = now - 1095 * 24 * 3600; // ~36 months
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, first_release_date, total_rating, summary;
where category = 0 & first_release_date <= $now & first_release_date >= $past;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date <= $now & first_release_date >= $past & first_release_date != null;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, release_dates.date, summary;
where category = 0 & release_dates.date <= $now & release_dates.date >= $past;
sort release_dates.date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date <= $now & first_release_date >= $pastWide;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date <= $now & first_release_date != null;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where first_release_date <= $now & first_release_date >= $past;
sort first_release_date desc;
limit $limit;
''',
    ]);
  }

  /// Próximo a salir (fecha futura); alternativas por `release_dates` y sin tope.
  Future<List<Map<String, dynamic>>> fetchGamesComingSoon({int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cap = now + 730 * 24 * 3600; // 2 years
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now & first_release_date < $cap;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, release_dates.date, summary;
where category = 0 & release_dates.date > $now & release_dates.date < $cap;
sort release_dates.date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where category = 0 & first_release_date > $now;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, first_release_date, summary;
where first_release_date > $now & first_release_date < $cap;
sort first_release_date asc;
limit $limit;
''',
    ]);
  }

  /// Reseñas recientes (comunidad IGDB).
  Future<List<Map<String, dynamic>>> fetchReviewsRecent({int limit = 30}) async {
    final body = '''
fields id, title, content, score, created_at, user.username,
       game.id, game.name, game.cover.image_id;
sort created_at desc;
limit $limit;
''';
    try {
      final raw = await _postReviewsList(body);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    } catch (_) {
      return [];
    }
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
      final raw = await _postReviewsList(body);
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
    try {
      final list = await _postReviewsList(body);
      return list.isEmpty ? null : list.first;
    } catch (_) {
      return null;
    }
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

  /// Community reviews for a game (IGDB `review` / `reviews`).
  Future<List<Map<String, dynamic>>> fetchGameReviews(int gameId) async {
    final body = '''
fields id, title, content, score, created_at, user.username;
where game = $gameId;
sort created_at desc;
limit 15;
''';
    try {
      return await _postReviewsList(body);
    } catch (_) {
      return [];
    }
  }

  /// Prueba `/review` y `/reviews` (Apicalypse); si ambos devuelven 404, [].
  Future<List<Map<String, dynamic>>> _postReviewsList(String body) async {
    const candidates = ['/review', '/reviews'];
    for (var i = 0; i < candidates.length; i++) {
      try {
        return await _postList(candidates[i], body);
      } on Object catch (e) {
        final is404 = _isIgdbNotFound(e);
        if (is404 && i < candidates.length - 1) {
          await Future<void>.delayed(
              const Duration(milliseconds: _queryRetryDelayMs));
          continue;
        }
        if (is404) return [];
        rethrow;
      }
    }
    return [];
  }

  static bool _isIgdbNotFound(Object e) {
    final s = e.toString();
    return s.contains('HTTP 404') || s.contains('(404)');
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
