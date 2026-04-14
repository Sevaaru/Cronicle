import 'package:dio/dio.dart';

/// Queries the public Anilist GraphQL API.
class AnilistGraphqlDatasource {
  AnilistGraphqlDatasource(this._dio);

  final Dio _dio;
  static const _url = 'https://graphql.anilist.co';

  Future<Map<String, dynamic>> _post(
    String query, {
    Map<String, dynamic>? variables,
    String? token,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) headers['Authorization'] = 'Bearer $token';

    final res = await _dio.post<Map<String, dynamic>>(
      _url,
      data: {'query': query, 'variables': variables},
      options: Options(headers: headers),
    );
    return res.data!;
  }

  /// Recent public anime activity (global feed).
  Future<List<Map<String, dynamic>>> fetchRecentActivity({
    int page = 1,
    int perPage = 25,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          activities(type: ANIME_LIST, sort: ID_DESC) {
            ... on ListActivity {
              id
              status
              progress
              createdAt
              media {
                id
                title { romaji english }
                coverImage { large }
              }
              user {
                name
                avatar { medium }
              }
            }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {
      'page': page,
      'perPage': perPage,
    });
    final activities =
        (data['data']?['Page']?['activities'] as List?)?.cast<Map<String, dynamic>>() ??
            [];
    return activities.where((a) => a['media'] != null).toList();
  }

  /// Search anime by title.
  Future<List<Map<String, dynamic>>> searchAnime(String search) async {
    return searchMedia(search, type: 'ANIME');
  }

  /// Search manga by title.
  Future<List<Map<String, dynamic>>> searchManga(String search) async {
    return searchMedia(search, type: 'MANGA');
  }

  /// Search Anilist media by type (ANIME or MANGA).
  Future<List<Map<String, dynamic>>> searchMedia(
    String search, {
    required String type,
  }) async {
    const query = r'''
      query ($search: String, $type: MediaType) {
        Page(page: 1, perPage: 20) {
          media(search: $search, type: $type, sort: POPULARITY_DESC) {
            id
            type
            title { romaji english }
            coverImage { large }
            episodes
            chapters
            volumes
            averageScore
            status
            format
            genres
          }
        }
      }
    ''';
    final data = await _post(query, variables: {
      'search': search,
      'type': type,
    });
    return (data['data']?['Page']?['media'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  /// Fetch user anime list (requires token).
  Future<List<Map<String, dynamic>>> fetchUserAnimeList(
    String token,
    String userName,
  ) async {
    const query = r'''
      query ($userName: String) {
        MediaListCollection(userName: $userName, type: ANIME) {
          lists {
            name
            entries {
              id
              status
              score
              progress
              media {
                id
                title { romaji english }
                coverImage { large }
                episodes
              }
            }
          }
        }
      }
    ''';
    final data = await _post(
      query,
      variables: {'userName': userName},
      token: token,
    );
    final lists = (data['data']?['MediaListCollection']?['lists'] as List?) ??
        [];
    final entries = <Map<String, dynamic>>[];
    for (final list in lists) {
      for (final entry in (list['entries'] as List? ?? [])) {
        entries.add(entry as Map<String, dynamic>);
      }
    }
    return entries;
  }

  /// Get current authenticated user info.
  Future<Map<String, dynamic>?> fetchViewer(String token) async {
    const query = r'''
      query {
        Viewer {
          id
          name
          avatar { medium }
        }
      }
    ''';
    final data = await _post(query, token: token);
    return data['data']?['Viewer'] as Map<String, dynamic>?;
  }
}
