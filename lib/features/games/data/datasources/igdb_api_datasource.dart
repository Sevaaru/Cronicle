import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/features/games/data/datasources/igdb_auth_datasource.dart';

class IgdbWebUnsupportedException implements Exception {
  const IgdbWebUnsupportedException();
}

class IgdbApiDatasource {
  IgdbApiDatasource(this._dio, this._auth);

  final Dio _dio;
  final IgdbAuthDatasource _auth;

  static String get _baseUrl => EnvConfig.igdbApiV4BaseUrl;

  static bool get _blockWebWithoutProxy =>
      kIsWeb && !EnvConfig.hasDevApiProxy;

  int? _cachedVisitPopularityTypeId;

  String? _cachedReviewsPath;

  static const _queryRetryDelayMs = 40;

  String? _cachedHeaderToken;
  Options? _cachedHeaderOptions;

  Future<Options> _headers() async {
    final token = await _auth.getValidToken();
    if (_cachedHeaderToken == token && _cachedHeaderOptions != null) {
      return _cachedHeaderOptions!;
    }
    _cachedHeaderToken = token;
    _cachedHeaderOptions = Options(
      headers: {
        'Client-ID': _auth.clientId,
        'Authorization': 'Bearer $token',
      },
    );
    return _cachedHeaderOptions!;
  }

  static String coverUrl(String imageId, {String size = 't_cover_big'}) =>
      'https://images.igdb.com/igdb/image/upload/$size/$imageId.jpg';

  static String screenshotUrl(String imageId) =>
      'https://images.igdb.com/igdb/image/upload/t_screenshot_big/$imageId.jpg';

  Future<List<Map<String, dynamic>>> searchGames(String query) async {
    final escaped = query.replaceAll('"', '\\"');
    final body = '''
search "$escaped";
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
limit 20;
''';
    return _postList('/games', body);
  }

  Future<List<Map<String, dynamic>>> fetchGamesHomeRatedPage({
    int limit = 24,
    int offset = 0,
  }) async {
    try {
      return await _postList('/games', '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & total_rating > 0;
sort total_rating desc;
offset $offset;
limit $limit;
''');
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPopularGames({int limit = 24}) async {
    try {
      final fast = await _postList('/games', '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & total_rating > 0;
sort total_rating desc;
limit $limit;
''');
      if (fast.isNotEmpty) return fast;
    } catch (_) {}

    final viaPop = await _fetchPopularViaPopularityPrimitives(limit: limit);
    if (viaPop.isNotEmpty) return viaPop;

    final candidates = <String>[
      '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & total_rating > 0;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, total_rating, first_release_date;
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

  Future<List<Map<String, dynamic>>> fetchGamesByFirstReleaseBetween({
    required int startSec,
    required int endSec,
    int limit = 100,
  }) async {
    if (_blockWebWithoutProxy) throw const IgdbWebUnsupportedException();

    const fetchCap = 500;

    final fieldsGames = '''
fields name, cover.image_id, genres.name, platforms.name, platforms.abbreviation,
       total_rating, first_release_date, release_dates.date;
''';

    Future<List<Map<String, dynamic>>> runGames(String where, String sort) async {
      return _postList(
        '/games',
        '''
$fieldsGames
where $where;
$sort
limit $limit;
''',
      );
    }

    try {
      try {
        final rd = await _postList(
          '/release_dates',
          '''
fields date,
      game.id, game.category, game.version_parent,
      game.name, game.cover.image_id, game.genres.name,
      game.platforms.name, game.platforms.abbreviation, game.total_rating,
      game.first_release_date;
where date >= $startSec & date <= $endSec;
sort date desc;
limit $fetchCap;
''',
        );
        final out = _gamesFromReleaseDateRows(rd, limit: limit);
        if (out.isNotEmpty) return out;
      } catch (_) {}

      try {
        final list = await runGames(
          'category = 0 & version_parent = null & release_dates.date >= $startSec & release_dates.date <= $endSec',
          'sort first_release_date desc;',
        );
        final d = _dedupeIgdbGamesById(list);
        if (d.isNotEmpty) return d;
      } catch (_) {}

      try {
        final list = await runGames(
          'category = 0 & release_dates.date >= $startSec & release_dates.date <= $endSec',
          'sort first_release_date desc;',
        );
        final d = _dedupeIgdbGamesById(list);
        if (d.isNotEmpty) return d;
      } catch (_) {}

      final byFirst = await runGames(
        'category = 0 & version_parent = null & first_release_date >= $startSec & first_release_date <= $endSec',
        'sort first_release_date desc;',
      );
      return _dedupeIgdbGamesById(byFirst);
    } catch (_) {
      return [];
    }
  }

  static List<Map<String, dynamic>> _gamesFromReleaseDateRows(
    List<Map<String, dynamic>> rows, {
    required int limit,
  }) {
    final out = <Map<String, dynamic>>[];
    final seen = <int>{};
    for (final row in rows) {
      if (out.length >= limit) break;
      final g = row['game'];
      if (g is! Map) continue;
      final m = Map<String, dynamic>.from(g);
      if (!_igdbIsMainGameForBrowse(m)) continue;
      final idRaw = m['id'];
      final id = idRaw is int
          ? idRaw
          : idRaw is num
              ? idRaw.toInt()
              : null;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      out.add(m);
    }
    return out;
  }

  static bool _igdbIsMainGameForBrowse(Map<String, dynamic> g) {
    if (g['version_parent'] != null) return false;
    final c = g['category'];
    if (c is num) return c.toInt() == 0;
    return true;
  }

  static List<Map<String, dynamic>> _dedupeIgdbGamesById(
    List<Map<String, dynamic>> rows,
  ) {
    final seen = <int>{};
    final out = <Map<String, dynamic>>[];
    for (final r in rows) {
      final idRaw = r['id'];
      final id = idRaw is int
          ? idRaw
          : idRaw is num
              ? idRaw.toInt()
              : null;
      if (id == null || seen.contains(id)) continue;
      seen.add(id);
      out.add(r);
    }
    return out;
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
       total_rating, first_release_date, category;
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
      } catch (e) {
        if (isRateLimitError(e)) rethrow;
      }
    }
    return [];
  }

  Future<List<Map<String, dynamic>>> fetchGamesMostAnticipated(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final twoYears = now + 730 * 24 * 3600;
    // El multiquery del home usa `version_parent = null` (no `category = 0`)
    // y ordena por `first_release_date asc`. Mantengamos ese mismo patrón
    // como base —ordenar por `hypes desc` antes vacíaba la lista porque
    // muchos juegos tienen `hypes = null` y IGDB los excluye del sort—.
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date, hypes, total_rating;
where first_release_date > $now & first_release_date < $twoYears
      & version_parent = null
      & hypes != null;
sort hypes desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date, total_rating;
where first_release_date > $now & first_release_date < $twoYears
      & version_parent = null;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where category = 0 & first_release_date > $now & first_release_date < $twoYears;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       release_dates.date;
where category = 0 & release_dates.date > $now & release_dates.date < $twoYears;
sort release_dates.date asc;
limit $limit;
''',
    ]);
  }

  Future<List<Map<String, dynamic>>> fetchGamesRecentlyReleased(
      {int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final past = now - 548 * 24 * 3600; // ~18 months
    final pastWide = now - 1095 * 24 * 3600; // ~36 months
    // Igual que el multiquery del home: `version_parent = null` (no
    // `category = 0`) — el home funciona con esto, las versiones con
    // `category` daban 0 resultados en algunas regiones.
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date, total_rating;
where first_release_date <= $now & first_release_date >= $past
      & version_parent = null;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date, release_dates.date;
where release_dates.date <= $now & release_dates.date >= $past
      & version_parent = null;
sort release_dates.date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where first_release_date <= $now & first_release_date >= $pastWide
      & version_parent = null;
sort first_release_date desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where category = 0 & first_release_date <= $now & first_release_date >= $pastWide;
sort first_release_date desc;
limit $limit;
''',
    ]);
  }

  Future<List<Map<String, dynamic>>> fetchGamesComingSoon({int limit = 24}) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final cap = now + 730 * 24 * 3600; // 2 years
    // Mismo filtro que el multiquery del home (`version_parent = null`).
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where first_release_date > $now & first_release_date < $cap
      & version_parent = null;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       release_dates.date;
where release_dates.date > $now & release_dates.date < $cap
      & version_parent = null;
sort release_dates.date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where category = 0 & first_release_date > $now & first_release_date < $cap;
sort first_release_date asc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       first_release_date;
where category = 0 & first_release_date > $now;
sort first_release_date asc;
limit $limit;
''',
    ]);
  }

  static const int genreIdIndie = 32;
  static const int genreIdHorror = 19;
  static const int genreIdRpg = 12;
  static const int genreIdSports = 14;

  Future<List<Map<String, dynamic>>> fetchGamesBestRated({int limit = 24}) async {
    // Antes pedíamos `total_rating_count >= 50 & total_rating >= 85`
    // (combo super estricto): IGDB devolvía 0 ítems en muchos casos y
    // como `_tryPostGameQueries` se traga el error la pantalla quedaba
    // vacía. Bajamos el listón al mismo umbral que ya funciona en el
    // multiquery del home (`total_rating > 80 & total_rating_count > 5`)
    // y añadimos `version_parent = null` para excluir versiones duplicadas.
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, total_rating_count, first_release_date;
where total_rating > 80 & total_rating_count > 5 & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, total_rating_count, first_release_date;
where category = 0 & total_rating > 80 & total_rating_count > 5;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, total_rating_count, first_release_date;
where category = 0 & total_rating_count >= 5 & total_rating > 0;
sort total_rating desc;
limit $limit;
''',
    ]);
  }

  Future<List<Map<String, dynamic>>> fetchGamesGenreSpotlight(
    int genreId, {
    int limit = 24,
    int minRating = 72,
  }) async {
    // Para horror el id 19 es de **themes**, no de **genres**: la query
    // anterior (`genres = (19) ...`) devolvía 0 y la pantalla acababa
    // vacía. Detectamos ese caso y consultamos `themes` además de
    // probar el campo `genres` como fallback. Mantenemos
    // `version_parent = null` como en el multiquery del home.
    final isHorrorTheme = genreId == genreIdHorror;
    final field = isHorrorTheme ? 'themes' : 'genres';
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where $field = ($genreId) & total_rating >= $minRating
      & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where $field = ($genreId) & total_rating >= 50
      & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where $field = ($genreId) & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & $field = ($genreId);
sort total_rating desc;
limit $limit;
''',
    ]);
  }

  Future<List<Map<String, dynamic>>> fetchGamesMultiplayerPopular(
      {int limit = 24}) async {
    // Igual que el multiquery del home: `game_modes = (2) & total_rating > 50`
    // sin `category = 0`, con `version_parent = null` para deduplicar.
    return _tryPostGameQueries([
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where game_modes = (2) & total_rating > 50 & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where game_modes = (2) & version_parent = null;
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & game_modes = (2);
sort total_rating desc;
limit $limit;
''',
      '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date;
where category = 0 & game_modes = (3);
sort total_rating desc;
limit $limit;
''',
    ]);
  }

  static String? reviewNestedCoverImageId(Map<String, dynamic>? game) {
    final coverRaw = game?['cover'];
    Map<String, dynamic>? cover;
    if (coverRaw is Map<String, dynamic>) {
      cover = coverRaw;
    } else if (coverRaw is Map) {
      cover = Map<String, dynamic>.from(coverRaw);
    }
    return _readCoverImageId(cover);
  }

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

  Future<List<Map<String, dynamic>>> fetchReviewsForGameIds(
    List<int> gameIds, {
    int limit = 48,
  }) async {
    if (gameIds.isEmpty) return [];
    final uniq = <int>[];
    final seen = <int>{};
    for (final id in gameIds) {
      if (seen.contains(id)) continue;
      seen.add(id);
      uniq.add(id);
      if (uniq.length >= 25) break;
    }
    if (uniq.isEmpty) return [];
    final joined = uniq.join(',');
    final body = '''
fields id, title, content, score, created_at, user.username,
       game.id, game.name, game.cover.image_id;
where game = ($joined);
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

  /// Resolves an IGDB game id from a Steam app id.
  ///
  /// Phase 1: queries IGDB `external_games` (Steam category = 1) by uid.
  /// Phase 2: if phase 1 yields no result and [gameName] is provided, falls
  /// back to a name search on `/games` and picks the best-matching title.
  Future<int?> findGameIdBySteamAppId(int steamAppId, {String? gameName}) async {
    // --- Phase 1: external_games lookup ---
    try {
      final list = await _postList('/external_games', '''
fields game;
where category = 1 & uid = "$steamAppId";
limit 1;
''');
      if (list.isNotEmpty) {
        final id = list.first['game'];
        if (id is int) return id;
        if (id is num) return id.toInt();
      }
    } catch (_) {}

    // --- Phase 2: name-based fallback ---
    if (gameName == null || gameName.trim().isEmpty) return null;
    try {
      final results = await searchGames(gameName.trim());
      if (results.isEmpty) return null;
      final target = gameName.trim().toLowerCase();
      // Prefer exact name match; otherwise take the first result.
      for (final r in results) {
        final n = (r['name'] as String? ?? '').toLowerCase();
        if (n == target) {
          final id = r['id'];
          if (id is int) return id;
          if (id is num) return id.toInt();
        }
      }
      final first = results.first['id'];
      if (first is int) return first;
      if (first is num) return first.toInt();
    } catch (_) {}

    return null;
  }

  Future<Map<String, dynamic>?> fetchGameDetail(int gameId) async {
    final coreBody = '''
fields name, summary, total_rating, total_rating_count,
       aggregated_rating, aggregated_rating_count,
       cover.image_id,
       first_release_date,
       genres.name,
       platforms.name, platforms.abbreviation,
       status, category, url;
where id = $gameId;
''';
    final extrasBody = '''
fields screenshots.image_id,
       artworks.image_id,
       involved_companies.company.name, involved_companies.developer,
       involved_companies.publisher,
       similar_games.name, similar_games.cover.image_id,
       game_modes.name,
       themes.name,
       websites.url, websites.category,
       external_games.url, external_games.category, external_games.uid,
       external_games.name, external_games.external_game_source.name;
where id = $gameId;
''';

    final results = await Future.wait<dynamic>([
      _postList('/games', coreBody),
      _postList('/games', extrasBody).catchError((_) => <Map<String, dynamic>>[]),
      _fetchGameTimeToBeat(gameId).catchError((_) => null),
      fetchGameReviews(gameId).catchError((_) => <Map<String, dynamic>>[]),
    ]);

    final mainList = results[0] as List<Map<String, dynamic>>;
    if (mainList.isEmpty) return null;
    final game = Map<String, dynamic>.from(mainList.first);

    final extraList = results[1] as List<Map<String, dynamic>>;
    if (extraList.isNotEmpty) {
      final ex = extraList.first;
      for (final e in ex.entries) {
        if (e.key == 'id') continue;
        final v = e.value;
        if (v != null) game[e.key] = v;
      }
    }

    final ttb = results[2] as Map<String, dynamic>?;
    if (ttb != null) game['time_to_beat'] = ttb;
    game['__igdb_reviews'] = results[3] as List<Map<String, dynamic>>;
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

  Future<List<Map<String, dynamic>>> _postReviewsList(String body) async {
    final cached = _cachedReviewsPath;
    if (cached != null) {
      try {
        return await _postList(cached, body);
      } on Object catch (e) {
        if (!_isIgdbNotFound(e)) rethrow;
        _cachedReviewsPath = null;
      }
    }
    const candidates = ['/review', '/reviews'];
    for (var i = 0; i < candidates.length; i++) {
      try {
        final rows = await _postList(candidates[i], body);
        _cachedReviewsPath = candidates[i];
        return rows;
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

  static String? absoluteHttpUrl(String? u) {
    if (u == null || u.isEmpty) return null;
    final t = u.trim();
    if (t.startsWith('//')) return 'https:$t';
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    return 'https://$t';
  }

  static int? _readId(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v');
  }

  static String? _readCoverImageId(Map<String, dynamic>? cover) {
    if (cover == null) return null;
    final v = cover['image_id'];
    if (v == null) return null;
    if (v is String) return v.isEmpty ? null : v;
    return '$v';
  }

  static Map<String, dynamic> normalize(Map<String, dynamic> raw) {
    final name = raw['name']?.toString() ?? '';
    Map<String, dynamic>? cover;
    final coverRaw = raw['cover'];
    if (coverRaw is Map<String, dynamic>) {
      cover = coverRaw;
    } else if (coverRaw is Map) {
      cover = Map<String, dynamic>.from(coverRaw);
    }
    final coverImageId = _readCoverImageId(cover);
    final genres = (raw['genres'] as List?)
        ?.map((g) {
          if (g is Map<String, dynamic>) {
            return g['name'] as String? ?? '';
          }
          if (g is Map) {
            return Map<String, dynamic>.from(g)['name'] as String? ?? '';
          }
          return '';
        })
        .where((g) => g.isNotEmpty)
        .toList();
    final platforms = (raw['platforms'] as List?)
        ?.map((p) {
          if (p is Map<String, dynamic>) {
            return p['abbreviation'] as String? ?? p['name'] as String? ?? '';
          }
          if (p is Map) {
            final m = Map<String, dynamic>.from(p);
            return m['abbreviation'] as String? ?? m['name'] as String? ?? '';
          }
          return '';
        })
        .where((p) => p.isNotEmpty)
        .toList();
    final userRating = raw['total_rating'] as num?;
    final criticRating = raw['aggregated_rating'] as num?;
    final userRatingCount = (raw['total_rating_count'] as num?)?.toInt();
    final criticRatingCount = (raw['aggregated_rating_count'] as num?)?.toInt();
    final gameId = _readId(raw['id']);

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
      'averageScore': userRating?.round(),
      'aggregatedRating': criticRating?.round(),
      'aggregatedRatingCount': criticRatingCount,
      'totalRatingCount': userRatingCount,
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

  static bool isRateLimitError(Object e) {
    final s = e.toString();
    return s.contains('429') || s.contains('Too Many Requests');
  }

  Future<Map<String, List<Map<String, dynamic>>>> _postMultiquery(
      String body) async {
    if (_blockWebWithoutProxy) throw const IgdbWebUnsupportedException();
    var options = await _headers();

    for (var attempt = 0; attempt < 2; attempt++) {
      final res = await _dio.post<dynamic>(
        '$_baseUrl/multiquery',
        data: body,
        options: Options(
          headers: options.headers,
          contentType: 'text/plain',
          validateStatus: (_) => true,
        ),
      );

      final code = res.statusCode ?? 0;

      if (code == 401 && attempt == 0) {
        await _auth.refreshTokenAfterUnauthorized();
        options = await _headers();
        continue;
      }

      if (code == 429 && attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        continue;
      }

      if (code >= 400) {
        final m = res.data is Map<String, dynamic>
            ? res.data as Map<String, dynamic>
            : <String, dynamic>{};
        throw Exception('IGDB multiquery ($code): ${m['message'] ?? res.data}');
      }

      if (res.data is List) {
        final raw = res.data as List;
        final out = <String, List<Map<String, dynamic>>>{};
        final errors = <String>[];
        for (final item in raw) {
          if (item is! Map<String, dynamic>) continue;
          final name = item['name'] as String? ?? '';
          if (name.isEmpty) {
            final title = item['title'] ?? item['message'] ?? item['cause'] ?? item;
            errors.add('$title');
            continue;
          }
          final resultRaw = item['result'];
          if (resultRaw is List) {
            out[name] = resultRaw.whereType<Map<String, dynamic>>().toList();
          } else {
            out[name] = [];
          }
        }
        if (out.isEmpty && errors.isNotEmpty) {
          throw Exception('IGDB multiquery sub-queries all failed: ${errors.join('; ')}');
        }
        return out;
      }
      return {};
    }
    return {};
  }

  Future<Map<String, List<Map<String, dynamic>>>> fetchHomeFeedGames() async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final twoYears = now + 730 * 24 * 3600;
    final past18m = now - 548 * 24 * 3600;

    const f = 'fields name, cover.image_id, genres.name, '
        'platforms.abbreviation, total_rating, first_release_date';

    final body = '''
query games "anticipated" {
  $f, hypes;
  where first_release_date > $now & first_release_date < $twoYears
        & version_parent = null & hypes != null;
  sort hypes desc;
  limit 24;
};
query games "recentlyReleased" {
  $f;
  where first_release_date <= $now & first_release_date >= $past18m & version_parent = null;
  sort first_release_date desc;
  limit 24;
};
query games "comingSoon" {
  $f;
  where first_release_date > $now & first_release_date < $twoYears & version_parent = null;
  sort first_release_date asc;
  limit 24;
};
query games "bestRated" {
  $f, total_rating_count;
  where total_rating > 80 & total_rating_count > 5 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
query games "indie" {
  $f;
  where genres = (32) & total_rating > 60 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
query games "horror" {
  $f;
  where themes = (19) & total_rating > 60 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
query games "multiplayer" {
  $f;
  where game_modes = (2) & total_rating > 50 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
query games "rpg" {
  $f;
  where genres = (12) & total_rating > 65 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
query games "sports" {
  $f;
  where genres = (14) & total_rating > 55 & version_parent = null;
  sort total_rating desc;
  limit 24;
};
''';

    return _postMultiquery(body);
  }

  Future<List<Map<String, dynamic>>> _postList(
      String endpoint, String body) async {
    if (_blockWebWithoutProxy) {
      throw const IgdbWebUnsupportedException();
    }
    var options = await _headers();

    for (var attempt = 0; attempt < 2; attempt++) {
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

      if (code == 401 && attempt == 0) {
        await _auth.refreshTokenAfterUnauthorized();
        options = await _headers();
        continue;
      }

      if (code == 429 && attempt == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 500));
        continue;
      }

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
    return [];
  }
}
