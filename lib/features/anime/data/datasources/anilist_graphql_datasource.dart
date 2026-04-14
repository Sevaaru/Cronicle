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

  /// Fetch full media details by Anilist ID.
  Future<Map<String, dynamic>?> fetchMediaDetail(int id) async {
    const query = r'''
      query ($id: Int) {
        Media(id: $id) {
          id
          type
          title { romaji english native }
          coverImage { extraLarge large }
          bannerImage
          description(asHtml: false)
          format
          status
          episodes
          chapters
          volumes
          duration
          season
          seasonYear
          startDate { year month day }
          endDate { year month day }
          averageScore
          meanScore
          popularity
          favourites
          genres
          tags { name rank }
          studios(isMain: true) { nodes { name } }
          source
          countryOfOrigin
          isAdult
          nextAiringEpisode { airingAt timeUntilAiring episode }
          externalLinks { url site icon color }
          streamingEpisodes { title thumbnail url site }
          relations {
            edges {
              relationType
              node {
                id type format
                title { romaji english }
                coverImage { large }
                status
              }
            }
          }
          recommendations(sort: RATING_DESC, perPage: 8) {
            nodes {
              mediaRecommendation {
                id type
                title { romaji english }
                coverImage { large }
                averageScore
              }
            }
          }
          reviews(sort: RATING_DESC, perPage: 5) {
            nodes {
              id
              summary
              score
              rating
              ratingAmount
              user { name avatar { medium } }
            }
          }
          stats {
            scoreDistribution { score amount }
            statusDistribution { status amount }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'id': id});
    return data['data']?['Media'] as Map<String, dynamic>?;
  }

  /// Recent public activity for a media type (ANIME_LIST or MANGA_LIST).
  Future<List<Map<String, dynamic>>> fetchRecentActivityByType({
    required String activityType,
    int page = 1,
    int perPage = 25,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int, $type: ActivityType) {
        Page(page: $page, perPage: $perPage) {
          activities(type: $type, sort: ID_DESC) {
            ... on ListActivity {
              id
              status
              progress
              createdAt
              media {
                id
                type
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
      'type': activityType,
    });
    final activities =
        (data['data']?['Page']?['activities'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    return activities.where((a) => a['media'] != null).toList();
  }

  /// Fetch user media list by type (ANIME or MANGA). Requires token.
  Future<List<Map<String, dynamic>>> fetchUserMediaList(
    String token,
    String userName, {
    required String type,
  }) async {
    const query = r'''
      query ($userName: String, $type: MediaType) {
        MediaListCollection(userName: $userName, type: $type) {
          lists {
            name
            entries {
              id
              status
              score(format: POINT_10)
              progress
              progressVolumes
              notes
              media {
                id
                type
                title { romaji english }
                coverImage { large }
                episodes
                chapters
                volumes
                format
              }
            }
          }
        }
      }
    ''';
    final data = await _post(
      query,
      variables: {'userName': userName, 'type': type},
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

  /// Fetch full user profile with statistics.
  Future<Map<String, dynamic>?> fetchViewerProfile(String token) async {
    const query = r'''
      query {
        Viewer {
          id
          name
          about
          avatar { large medium }
          bannerImage
          siteUrl
          createdAt
          statistics {
            anime {
              count
              meanScore
              minutesWatched
              episodesWatched
              genres(sort: COUNT_DESC, limit: 5) { genre count meanScore minutesWatched }
              statuses { status count }
            }
            manga {
              count
              meanScore
              chaptersRead
              volumesRead
              genres(sort: COUNT_DESC, limit: 5) { genre count meanScore chaptersRead }
              statuses { status count }
            }
          }
        }
      }
    ''';
    final data = await _post(query, token: token);
    return data['data']?['Viewer'] as Map<String, dynamic>?;
  }
}
