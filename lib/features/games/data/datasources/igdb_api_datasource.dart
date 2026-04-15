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

  /// Fetch popular/highly-rated games.
  Future<List<Map<String, dynamic>>> fetchPopularGames() async {
    const body = '''
fields name, cover.image_id, genres.name, platforms.abbreviation,
       total_rating, first_release_date, summary;
sort total_rating desc;
where total_rating_count > 50 & category = 0;
limit 20;
''';
    return _postList('/games', body);
  }

  /// Full game detail by ID.
  Future<Map<String, dynamic>?> fetchGameDetail(int gameId) async {
    final body = '''
fields name, summary, storyline, total_rating, total_rating_count,
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
       url;
where id = $gameId;
''';
    final list = await _postList('/games', body);
    return list.isEmpty ? null : list.first;
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

    return {
      'id': raw['id'],
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
      'storyline': raw['storyline'],
      'status': raw['status'],
      'url': raw['url'],
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
      ),
    );

    if (res.data is List) {
      return (res.data as List).cast<Map<String, dynamic>>();
    }
    return [];
  }
}
