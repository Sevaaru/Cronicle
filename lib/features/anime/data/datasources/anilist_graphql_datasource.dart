import 'package:dio/dio.dart';

import 'package:cronicle/core/utils/json_int.dart';

/// Queries the public Anilist GraphQL API.
class AnilistGraphqlDatasource {
  AnilistGraphqlDatasource(this._dio);

  final Dio _dio;
  static const _url = 'https://graphql.anilist.co';

  /// AniList devuelve a veces `message: "validation"` con el detalle en [validation].
  static String formatGraphQLErrors(List<dynamic> errors) {
    final lines = <String>[];
    for (final raw in errors) {
      if (raw is! Map) continue;
      final err = Map<String, dynamic>.from(raw);
      var addedFromValidation = false;
      final validation = err['validation'];
      if (validation is Map) {
        for (final e in validation.entries) {
          final field = e.key.toString();
          final msgs = e.value;
          if (msgs is List) {
            for (final m in msgs) {
              lines.add('$field: $m');
              addedFromValidation = true;
            }
          } else if (msgs != null) {
            lines.add('$field: $msgs');
            addedFromValidation = true;
          }
        }
      }
      if (!addedFromValidation) {
        final m = err['message'] as String?;
        if (m != null && m.isNotEmpty) {
          lines.add(m);
        }
      }
    }
    return lines.isNotEmpty ? lines.join('\n') : 'GraphQL error';
  }

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

    late final Map<String, dynamic> body;
    const maxAttempts = 3;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final res = await _dio.post<dynamic>(
          _url,
          data: {'query': query, 'variables': variables},
          options: Options(
            headers: headers,
            responseType: ResponseType.json,
            validateStatus: (_) => true,
          ),
        );
        // Retry on 429 Too Many Requests
        if (res.statusCode == 429 && attempt < maxAttempts) {
          final retryAfter = int.tryParse(
                  res.headers.value('retry-after') ?? '') ??
              (attempt * 2);
          await Future<void>.delayed(
              Duration(seconds: retryAfter.clamp(1, 60)));
          continue;
        }
        if (res.data is Map<String, dynamic>) {
          body = res.data as Map<String, dynamic>;
        } else {
          throw Exception('HTTP ${res.statusCode}');
        }
      } on DioException catch (e) {
        // Retry on 429 from DioException too
        if (e.response?.statusCode == 429 && attempt < maxAttempts) {
          final retryAfter = int.tryParse(
                  e.response?.headers.value('retry-after') ?? '') ??
              (attempt * 2);
          await Future<void>.delayed(
              Duration(seconds: retryAfter.clamp(1, 60)));
          continue;
        }
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          body = data;
        } else {
          throw Exception('Network error: ${e.message}');
        }
      }
      break;
    }

    final errors = body['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      throw Exception(formatGraphQLErrors(errors));
    }
    return body;
  }

  /// Recent public anime activity (global feed).
  Future<List<Map<String, dynamic>>> fetchRecentActivity({
    int page = 1,
    int perPage = 25,
    String? token,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          activities(type: ANIME_LIST, sort: ID_DESC) {
            ... on ListActivity {
              id
              type
              status
              progress
              createdAt
              likeCount
              replyCount
              isLiked
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
              user {
                id
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
    }, token: token);
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

  /// Fetch trending/popular media by type.
  Future<List<Map<String, dynamic>>> fetchPopular({required String type}) async {
    const query = r'''
      query ($type: MediaType) {
        Page(page: 1, perPage: 20) {
          media(type: $type, sort: TRENDING_DESC) {
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
            nextAiringEpisode { episode }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'type': type});
    return (data['data']?['Page']?['media'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  /// Anilist season convention (Winter includes December → next [seasonYear]).
  static ({String season, int seasonYear}) currentMediaSeason() {
    final now = DateTime.now();
    final m = now.month;
    final y = now.year;
    if (m == 12) return (season: 'WINTER', seasonYear: y + 1);
    if (m <= 2) return (season: 'WINTER', seasonYear: y);
    if (m <= 5) return (season: 'SPRING', seasonYear: y);
    if (m <= 8) return (season: 'SUMMER', seasonYear: y);
    return (season: 'FALL', seasonYear: y);
  }

  /// Home browse rails for Anilist: [category] is
  /// `seasonal`, `trending`, `top_rated`, `upcoming`, `recently_released`,
  /// `popularity` (POPULARITY_DESC), `start_date` (START_DATE_DESC).
  Future<({List<Map<String, dynamic>> items, bool hasNextPage})> fetchBrowseMedia({
    required String type,
    required String category,
    int page = 1,
    int perPage = 24,
  }) async {
    const mediaFields = '''
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
            nextAiringEpisode { episode }
    ''';

    final s = currentMediaSeason();

    if (category == 'seasonal') {
      final query = '''
      query (\$type: MediaType, \$season: MediaSeason, \$seasonYear: Int, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, season: \$season, seasonYear: \$seasonYear, sort: POPULARITY_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'season': s.season,
        'seasonYear': s.seasonYear,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'trending') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, sort: TRENDING_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'top_rated') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, sort: SCORE_DESC, averageScore_greater: 60) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'upcoming') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, status: NOT_YET_RELEASED, sort: POPULARITY_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'recently_released') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, status: RELEASING, sort: START_DATE_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'popularity') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, sort: POPULARITY_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    if (category == 'start_date') {
      final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(type: \$type, sort: START_DATE_DESC) {
            $mediaFields
          }
        }
      }
    ''';
      final data = await _post(query, variables: {
        'type': type,
        'page': page,
        'perPage': perPage,
      });
      final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
      final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
      final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
      final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      return (items: list, hasNextPage: hasNext);
    }

    return (items: <Map<String, dynamic>>[], hasNextPage: false);
  }

  /// Rango de fechas de estreno (FuzzyDateInt: YYYYMMDD). Inclusive en ambos extremos.
  Future<({List<Map<String, dynamic>> items, bool hasNextPage})>
      fetchMediaByReleaseDateRange({
    required String type,
    required int startDateGreaterOrEqual,
    required int startDateLesserOrEqual,
    int page = 1,
    int perPage = 24,
  }) async {
    const mediaFields = '''
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
            startDate { year month day }
            nextAiringEpisode { episode }
    ''';

    // Fechas como literales en el documento: en web, JSON numérico en variables
    // a veces se tipa como Int y Anilist exige FuzzyDateInt en esas posiciones.
    final query = '''
      query (\$type: MediaType, \$page: Int, \$perPage: Int) {
        Page(page: \$page, perPage: \$perPage) {
          pageInfo { hasNextPage }
          media(
            type: \$type
            startDate_greater: $startDateGreaterOrEqual
            startDate_lesser: $startDateLesserOrEqual
            sort: POPULARITY_DESC
          ) {
            $mediaFields
          }
        }
      }
    ''';
    final data = await _post(query, variables: {
      'type': type,
      'page': page,
      'perPage': perPage,
    });
    final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
    final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
    final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
    final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
        [];
    return (items: list, hasNextPage: hasNext);
  }

  /// Listado paginado por género y/o etiqueta Anilist ([genre] / [tag] son listas de un elemento).
  ///
  /// [sortKey]: `score` | `popularity` | `name` → SCORE_DESC, POPULARITY_DESC, TITLE_ROMAJI.
  Future<({List<Map<String, dynamic>> items, bool hasNextPage})>
      fetchMediaByGenreTagPage({
    required String type,
    required String sortKey,
    String? genre,
    String? tag,
    int page = 1,
    int perPage = 24,
  }) async {
    final sortEnum = switch (sortKey) {
      'score' => 'SCORE_DESC',
      'name' => 'TITLE_ROMAJI',
      _ => 'POPULARITY_DESC',
    };

    const mediaFields = '''
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
            nextAiringEpisode { episode }
    ''';

    final useGenre = genre != null && genre.isNotEmpty;
    final useTag = tag != null && tag.isNotEmpty;
    if (!useGenre && !useTag) {
      return (items: <Map<String, dynamic>>[], hasNextPage: false);
    }

    final varLines = <String>[
      r'$type: MediaType',
      r'$page: Int',
      r'$perPage: Int',
      r'$sort: [MediaSort]',
    ];
    final mediaFilters = <String>[r'type: $type', r'sort: $sort'];
    if (useGenre) {
      varLines.add(r'$genre_in: [String]');
      mediaFilters.add(r'genre_in: $genre_in');
    }
    if (useTag) {
      varLines.add(r'$tag_in: [String]');
      mediaFilters.add(r'tag_in: $tag_in');
    }

    final queryBuilt = StringBuffer()
      ..write('query (')
      ..write(varLines.join(', '))
      ..writeln(') {')
      ..writeln('  Page(page: \$page, perPage: \$perPage) {')
      ..writeln('    pageInfo { hasNextPage }')
      ..write('    media(')
      ..write(mediaFilters.join(', '))
      ..writeln(') {')
      ..writeln(mediaFields)
      ..writeln('    }')
      ..writeln('  }')
      ..write('}');

    final queryStr = queryBuilt.toString();

    final variables = <String, dynamic>{
      'type': type,
      'page': page,
      'perPage': perPage,
      'sort': [sortEnum],
    };
    if (useGenre) variables['genre_in'] = [genre];
    if (useTag) variables['tag_in'] = [tag];

    final data = await _post(queryStr, variables: variables);
    final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
    final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
    final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
    final list = (pageMap?['media'] as List?)?.cast<Map<String, dynamic>>() ??
        <Map<String, dynamic>>[];
    return (items: list, hasNextPage: hasNext);
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
            nextAiringEpisode { episode airingAt timeUntilAiring }
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

  /// Metadatos de emisión para varios anime (API pública; no requiere token).
  Future<Map<int, Map<String, dynamic>>> fetchMediaAiringSnapshots(
    List<int> ids,
  ) async {
    if (ids.isEmpty) return {};
    const chunkSize = 50;
    final out = <int, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = i + chunkSize > ids.length ? ids.length : i + chunkSize;
      final slice = ids.sublist(i, end);
      const query = r'''
        query ($ids: [Int], $page: Int, $perPage: Int) {
          Page(page: $page, perPage: $perPage) {
            media(id_in: $ids) {
              id
              status
              episodes
              nextAiringEpisode { episode airingAt timeUntilAiring }
            }
          }
        }
      ''';
      final data = await _post(query, variables: {
        'ids': slice,
        'page': 1,
        'perPage': chunkSize,
      });
      final list = (data['data']?['Page']?['media'] as List?)
              ?.cast<Map<String, dynamic>>() ??
          [];
      for (final m in list) {
        final id = jsonInt(m['id']);
        if (id > 0) {
          out[id] = m;
        }
      }
    }
    return out;
  }

  /// Fetch full media details by Anilist ID.
  /// Pass [token] so `isFavourite` reflects the logged-in viewer.
  Future<Map<String, dynamic>?> fetchMediaDetail(int id, {String? token}) async {
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
          isFavourite
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
              body(asHtml: false)
              score
              rating
              ratingAmount
              userRating
              user { id name avatar { medium } }
            }
          }
          stats {
            scoreDistribution { score amount }
            statusDistribution { status amount }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'id': id}, token: token);
    return data['data']?['Media'] as Map<String, dynamic>?;
  }

  /// Toggle viewer favourite for this anime or manga on Anilist (requires auth).
  Future<void> toggleFavouriteMedia({
    required int mediaId,
    required String mediaType,
    required String token,
  }) async {
    final isAnime = mediaType == 'ANIME';
    // La API devuelve [Favourites], no User: no existe `id` en ese tipo.
    const mutation = r'''
      mutation ($animeId: Int, $mangaId: Int) {
        ToggleFavourite(animeId: $animeId, mangaId: $mangaId) {
          __typename
        }
      }
    ''';
    await _post(
      mutation,
      variables: {
        if (isAnime) 'animeId': mediaId,
        if (!isAnime) 'mangaId': mediaId,
      },
      token: token,
    );
  }

  /// Unread notification count for the authenticated viewer.
  Future<int?> fetchUnreadNotificationCount(String token) async {
    const query = r'''
      query { Viewer { unreadNotificationCount } }
    ''';
    final data = await _post(query, token: token);
    return data['data']?['Viewer']?['unreadNotificationCount'] as int?;
  }

  /// Inbox notifications (requires auth). Set [resetNotificationCount] to clear unread on Anilist.
  Future<List<Map<String, dynamic>>> fetchNotifications({
    required String token,
    int page = 1,
    int perPage = 25,
    bool resetNotificationCount = false,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int, $reset: Boolean) {
        Page(page: $page, perPage: $perPage) {
          notifications(resetNotificationCount: $reset) {
            __typename
            ... on AiringNotification {
              id
              type
              createdAt
              episode
              contexts
              media {
                id
                type
                title { romaji english native }
                coverImage { large }
              }
            }
            ... on ActivityReplyNotification {
              id
              type
              createdAt
              activityId
              context
              user { id name avatar { medium } }
            }
            ... on ActivityMentionNotification {
              id
              type
              createdAt
              activityId
              context
              user { id name avatar { medium } }
            }
            ... on ActivityMessageNotification {
              id
              type
              createdAt
              activityId
              context
              message { id }
              user { id name avatar { medium } }
            }
            ... on FollowingNotification {
              id
              type
              createdAt
              context
              user { id name avatar { medium } }
            }
            ... on RelatedMediaAdditionNotification {
              id
              type
              createdAt
              context
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
            }
            ... on MediaDataChangeNotification {
              id
              type
              createdAt
              context
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
            }
            ... on MediaMergeNotification {
              id
              type
              createdAt
              context
              media { id type title { romaji english } }
              deletedMediaTitles
            }
            ... on MediaDeletionNotification {
              id
              type
              createdAt
              context
              deletedMediaTitle
              reason
            }
            ... on ThreadCommentReplyNotification {
              id
              type
              createdAt
              context
              thread { id title }
            }
            ... on ThreadCommentMentionNotification {
              id
              type
              createdAt
              context
              thread { id title }
            }
            ... on ThreadCommentSubscribedNotification {
              id
              type
              createdAt
              context
              thread { id title }
            }
            ... on ThreadLikeNotification {
              id
              type
              createdAt
              context
              thread { id title }
              user { id name }
            }
            ... on ActivityLikeNotification {
              id
              type
              createdAt
              activityId
              context
              user { id name avatar { medium } }
            }
            ... on ActivityReplyLikeNotification {
              id
              type
              createdAt
              activityId
              context
              user { id name avatar { medium } }
            }
            ... on ActivityReplySubscribedNotification {
              id
              type
              createdAt
              activityId
              context
              user { id name avatar { medium } }
            }
            ... on ThreadCommentLikeNotification {
              id
              type
              createdAt
              context
              commentId
              thread { id title }
              user { id name avatar { medium } }
            }
            ... on MediaSubmissionUpdateNotification {
              id
              type
              createdAt
              contexts
              status
              submittedTitle
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
            }
            ... on StaffSubmissionUpdateNotification {
              id
              type
              createdAt
              contexts
              status
              staff {
                id
                name { full }
              }
            }
            ... on CharacterSubmissionUpdateNotification {
              id
              type
              createdAt
              contexts
              status
              character {
                id
                name { full }
                image { large }
              }
            }
          }
        }
      }
    ''';
    final data = await _post(
      query,
      variables: {
        'page': page,
        'perPage': perPage,
        'reset': resetNotificationCount,
      },
      token: token,
    );
    return (data['data']?['Page']?['notifications'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
  }

  /// Recent public activity. Pass null [activityType] for all types.
  /// If [isFollowing] is true, only shows activity from users the viewer follows.
  /// [hasNextPage] reflects Anilist pagination (do not infer from filtered length).
  Future<({List<Map<String, dynamic>> items, bool hasNextPage})>
      fetchRecentActivityByType({
    String? activityType,
    int page = 1,
    int perPage = 25,
    String? token,
    bool isFollowing = false,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int, $type: ActivityType, $isFollowing: Boolean) {
        Page(page: $page, perPage: $perPage) {
          pageInfo {
            hasNextPage
          }
          activities(type: $type, sort: ID_DESC, isFollowing: $isFollowing) {
            ... on ListActivity {
              id
              type
              status
              progress
              createdAt
              likeCount
              replyCount
              isLiked
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
              user {
                id
                name
                avatar { medium }
              }
            }
            ... on TextActivity {
              id
              type
              text(asHtml: false)
              createdAt
              likeCount
              replyCount
              isLiked
              user {
                id
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
      if (activityType != null) 'type': activityType,
      'isFollowing': isFollowing ? true : null,
    }, token: token);
    final pageMap = data['data']?['Page'] as Map<String, dynamic>?;
    final pageInfo = pageMap?['pageInfo'] as Map<String, dynamic>?;
    final hasNext = pageInfo?['hasNextPage'] as bool? ?? false;
    final activities =
        (pageMap?['activities'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final filtered = activities
        .where((a) => a['media'] != null || a['type'] == 'TEXT')
        .toList();
    return (items: filtered, hasNextPage: hasNext);
  }

  /// Toggle like on an activity, reply, thread or thread comment. Requires auth token.
  Future<bool> toggleLike(int id, String token, {String type = 'ACTIVITY'}) async {
    const query = r'''
      mutation ($id: Int, $type: LikeableType) {
        ToggleLikeV2(id: $id, type: $type) {
          ... on ListActivity { id isLiked likeCount }
          ... on TextActivity { id isLiked likeCount }
          ... on ActivityReply { id isLiked likeCount }
          ... on Thread { id isLiked likeCount }
          ... on ThreadComment { id isLiked likeCount }
        }
      }
    ''';
    final data = await _post(query,
        variables: {'id': id, 'type': type}, token: token);
    return data['data']?['ToggleLikeV2']?['isLiked'] as bool? ?? false;
  }

  /// Post a text activity to the authenticated user's feed.
  Future<Map<String, dynamic>> saveTextActivity(String text, String token) async {
    const query = r'''
      mutation ($text: String!) {
        SaveTextActivity(text: $text) {
          id
          type
          text(asHtml: false)
          createdAt
          likeCount
          replyCount
          isLiked
          user { id name avatar { medium } }
        }
      }
    ''';
    final data = await _post(query, variables: {'text': text}, token: token);
    final saved = data['data']?['SaveTextActivity'];
    if (saved is Map<String, dynamic>) return saved;
    if (saved is Map) {
      return Map<String, dynamic>.from(saved);
    }
    throw Exception('SaveTextActivity returned no data');
  }

  /// Post a reply to an activity.
  Future<Map<String, dynamic>> saveActivityReply(int activityId, String text, String token) async {
    const query = r'''
      mutation ($activityId: Int, $replyText: String) {
        SaveActivityReply(activityId: $activityId, text: $replyText) {
          id
          text(asHtml: false)
          likeCount
          isLiked
          createdAt
          user { id name avatar { medium } }
        }
      }
    ''';
    final data = await _post(
      query,
      variables: {'activityId': activityId, 'replyText': text},
      token: token,
    );
    return data['data']!['SaveActivityReply'] as Map<String, dynamic>;
  }

  /// Fetch replies for an activity (root [activityId] only).
  Future<List<Map<String, dynamic>>> fetchActivityReplies(int activityId, {String? token}) async {
    final bundle = await fetchActivityRepliesPageData(activityId, token: token);
    return (bundle['replies'] as List?)?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Si [ambiguousId] es un [ActivityReply] id, devuelve el `activityId` padre; si no, el mismo id.
  Future<int> resolveRootActivityId(int ambiguousId, {String? token}) async {
    const q = r'''
      query ($id: Int!) {
        ActivityReply(id: $id) {
          activityId
        }
      }
    ''';
    try {
      final data = await _post(q, variables: {'id': ambiguousId}, token: token);
      final aid = data['data']?['ActivityReply']?['activityId'] as int?;
      if (aid != null) return aid;
    } catch (_) {
      // Sin reply con ese id: se asume id de actividad raíz.
    }
    return ambiguousId;
  }

  /// Actividad raíz + respuestas. [ambiguousId] puede ser id de actividad o de reply.
  ///
  /// Primero se pide [Activity] + [activityReplies] con ese id (caso típico al abrir desde el feed).
  /// Si no hay actividad ni respuestas, se intenta resolver como id de [ActivityReply] (p. ej. desde una notificación).
  Future<Map<String, dynamic>> fetchActivityRepliesPageData(
    int ambiguousId, {
    String? token,
  }) async {
    const query = r'''
      query ($activityId: Int!) {
        Activity(id: $activityId) {
          __typename
          ... on TextActivity {
            id
            type
            text(asHtml: false)
            createdAt
            likeCount
            replyCount
            isLiked
            user {
              id
              name
              avatar { medium }
            }
          }
          ... on ListActivity {
            id
            type
            status
            progress
            createdAt
            likeCount
            replyCount
            isLiked
            user {
              id
              name
              avatar { medium }
            }
            media {
              id
              type
              title { romaji english }
              coverImage { large }
            }
          }
          ... on MessageActivity {
            id
            type
            createdAt
            likeCount
            replyCount
            isLiked
          }
        }
        Page(page: 1, perPage: 50) {
          activityReplies(activityId: $activityId) {
            id
            text(asHtml: false)
            likeCount
            isLiked
            createdAt
            user {
              id
              name
              avatar { medium }
            }
          }
        }
      }
    ''';
    Future<Map<String, dynamic>> bundleFor(int activityId) async {
      final data = await _post(query, variables: {'activityId': activityId}, token: token);
      return {
        'activity': data['data']?['Activity'] as Map<String, dynamic>?,
        'replies': (data['data']?['Page']?['activityReplies'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [],
        'rootActivityId': activityId,
      };
    }

    var rootId = ambiguousId;
    var out = await bundleFor(rootId);
    final act = out['activity'] as Map<String, dynamic>?;
    final reps = out['replies'] as List<Map<String, dynamic>>;
    if (act == null && reps.isEmpty) {
      final resolved = await resolveRootActivityId(ambiguousId, token: token);
      if (resolved != ambiguousId) {
        rootId = resolved;
        out = await bundleFor(rootId);
      }
    }
    return {
      'activity': out['activity'],
      'replies': out['replies'],
      'rootActivityId': out['rootActivityId'] as int? ?? rootId,
    };
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
              score(format: POINT_100)
              progress
              progressVolumes
              notes
              updatedAt
              media {
                id
                type
                title { romaji english }
                coverImage { large }
                episodes
                chapters
                volumes
                format
                status
                nextAiringEpisode { episode }
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

  /// Entradas en **CURRENT** (viendo/leyendo) con `media.status` y `nextAiringEpisode`
  /// (para avisos de nuevos capítulos en segundo plano).
  Future<List<Map<String, dynamic>>> fetchCurrentListWithAiringSchedule({
    required String token,
    required String userName,
    required String type,
  }) async {
    const query = r'''
      query ($userName: String, $type: MediaType) {
        MediaListCollection(userName: $userName, type: $type, status: CURRENT) {
          lists {
            entries {
              progress
              media {
                id
                type
                status
                title { romaji english native }
                nextAiringEpisode { airingAt episode }
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
          mediaListOptions { scoreFormat }
        }
      }
    ''';
    final data = await _post(query, token: token);
    return data['data']?['Viewer'] as Map<String, dynamic>?;
  }

  /// Totales de seguidores y seguidos (una sola petición con dos campos [Page]).
  Future<Map<String, int>> fetchUserFollowCounts(int userId, {String? token}) async {
    const query = r'''
      query ($userId: Int!) {
        fc: Page(page: 1, perPage: 1) {
          pageInfo { total }
          followers(userId: $userId) { id }
        }
        fg: Page(page: 1, perPage: 1) {
          pageInfo { total }
          following(userId: $userId) { id }
        }
      }
    ''';
    final data = await _post(query, variables: {'userId': userId}, token: token);
    final fc = data['data']?['fc'] as Map<String, dynamic>?;
    final fg = data['data']?['fg'] as Map<String, dynamic>?;
    final followers = jsonInt((fc?['pageInfo'] as Map?)?['total']);
    final following = jsonInt((fg?['pageInfo'] as Map?)?['total']);
    return {'followers': followers, 'following': following};
  }

  /// Lista paginada de seguidores o de cuentas que [userId] sigue.
  Future<({List<Map<String, dynamic>> users, bool hasNextPage, int total})>
      fetchUserFollowListPage(
    int userId, {
    required bool followers,
    int page = 1,
    int perPage = 50,
    String? token,
  }) async {
    const followersQ = r'''
      query ($userId: Int!, $page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          pageInfo {
            total
            hasNextPage
          }
          followers(userId: $userId) {
            id
            name
            avatar { large medium }
          }
        }
      }
    ''';
    const followingQ = r'''
      query ($userId: Int!, $page: Int, $perPage: Int) {
        Page(page: $page, perPage: $perPage) {
          pageInfo {
            total
            hasNextPage
          }
          following(userId: $userId) {
            id
            name
            avatar { large medium }
          }
        }
      }
    ''';
    final query = followers ? followersQ : followingQ;
    final data = await _post(
      query,
      variables: {'userId': userId, 'page': page, 'perPage': perPage},
      token: token,
    );
    final field = followers ? 'followers' : 'following';
    final pageData = data['data']?['Page'] as Map<String, dynamic>?;
    final pageInfo = pageData?['pageInfo'] as Map<String, dynamic>? ?? {};
    final total = jsonInt(pageInfo['total']);
    final hasNextPage = pageInfo['hasNextPage'] as bool? ?? false;
    final users =
        (pageData?[field] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ??
            <Map<String, dynamic>>[];
    return (users: users, hasNextPage: hasNextPage, total: total);
  }

  /// Fetch a public user profile by ID, including favourites.
  Future<Map<String, dynamic>?> fetchUserProfile(int userId, {String? token}) async {
    const query = r'''
      query ($id: Int) {
        User(id: $id) {
          id
          name
          about
          avatar { large medium }
          bannerImage
          siteUrl
          isFollowing
          isFollower
          favourites {
            anime(perPage: 10) {
              nodes { id title { romaji english } coverImage { large } }
            }
            manga(perPage: 10) {
              nodes { id title { romaji english } coverImage { large } }
            }
          }
          statistics {
            anime {
              count
              meanScore
              minutesWatched
              episodesWatched
              genres(sort: COUNT_DESC, limit: 5) { genre count }
              statuses { status count }
            }
            manga {
              count
              meanScore
              chaptersRead
              volumesRead
              genres(sort: COUNT_DESC, limit: 5) { genre count }
              statuses { status count }
            }
          }
        }
      }
    ''';
    final results = await Future.wait([
      _post(query, variables: {'id': userId}, token: token),
      fetchUserFollowCounts(userId, token: token)
          .catchError((Object _) => <String, int>{'followers': 0, 'following': 0}),
    ]);
    final body = results[0];
    final user = body['data']?['User'] as Map<String, dynamic>?;
    if (user == null) return null;
    final counts = results[1];
    user['followersCount'] = jsonInt(counts['followers']);
    user['followingCount'] = jsonInt(counts['following']);
    return user;
  }

  /// Fetch recent activity of a specific user.
  Future<List<Map<String, dynamic>>> fetchUserActivity(int userId, {String? token}) async {
    const query = r'''
      query ($userId: Int) {
        Page(page: 1, perPage: 15) {
          activities(userId: $userId, sort: ID_DESC) {
            ... on ListActivity {
              id
              type
              status
              progress
              createdAt
              likeCount
              replyCount
              isLiked
              media {
                id
                type
                title { romaji english }
                coverImage { large }
              }
              user {
                id
                name
                avatar { medium }
              }
            }
            ... on TextActivity {
              id
              type
              text(asHtml: false)
              createdAt
              likeCount
              replyCount
              isLiked
              user {
                id
                name
                avatar { medium }
              }
            }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'userId': userId}, token: token);
    final activities =
        (data['data']?['Page']?['activities'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    return activities.where((a) => a['media'] != null || a['type'] == 'TEXT').toList();
  }

  /// Save (create/update) a media list entry on Anilist.
  /// [score] expects 0-100 raw format, sent directly as scoreRaw.
  Future<Map<String, dynamic>?> saveMediaListEntry({
    required int mediaId,
    required String token,
    String? status,
    int? score,
    int? progress,
    String? notes,
  }) async {
    const query = r'''
      mutation ($mediaId: Int, $status: MediaListStatus, $scoreRaw: Int, $progress: Int, $notes: String) {
        SaveMediaListEntry(mediaId: $mediaId, status: $status, scoreRaw: $scoreRaw, progress: $progress, notes: $notes) {
          id
          status
          score(format: POINT_100)
          progress
          notes
        }
      }
    ''';
    final variables = <String, dynamic>{'mediaId': mediaId};
    if (status != null) variables['status'] = status;
    if (score != null) variables['scoreRaw'] = score;
    if (progress != null) variables['progress'] = progress;
    if (notes != null) variables['notes'] = notes;

    final data = await _post(query, variables: variables, token: token);
    return data['data']?['SaveMediaListEntry'] as Map<String, dynamic>?;
  }

  /// Fetch a single review by ID.
  Future<Map<String, dynamic>?> fetchReviewById(int reviewId, {String? token}) async {
    const query = r'''
      query ($id: Int) {
        Review(id: $id) {
          id
          summary
          body(asHtml: false)
          score
          rating
          ratingAmount
          userRating
          createdAt
          media {
            id
            type
            title { romaji english }
            coverImage { large }
          }
          user { id name avatar { medium large } }
        }
      }
    ''';
    final data = await _post(query, variables: {'id': reviewId}, token: token);
    return data['data']?['Review'] as Map<String, dynamic>?;
  }

  /// Rate a review (UP_VOTE, DOWN_VOTE, NO_VOTE).
  Future<Map<String, dynamic>?> rateReview(int reviewId, String rating, String token) async {
    const query = r'''
      mutation ($reviewId: Int, $rating: ReviewRating) {
        RateReview(reviewId: $reviewId, rating: $rating) {
          id
          rating
          ratingAmount
          userRating
        }
      }
    ''';
    final data = await _post(query, variables: {'reviewId': reviewId, 'rating': rating}, token: token);
    return data['data']?['RateReview'] as Map<String, dynamic>?;
  }

  /// Find the Anilist MediaList entry ID for a given media.
  Future<int?> findMediaListEntryId(int mediaId, String token) async {
    final viewer = await fetchViewer(token);
    if (viewer == null) return null;
    final userId = viewer['id'] as int?;
    if (userId == null) return null;

    const query = r'''
      query ($mediaId: Int, $userId: Int) {
        MediaList(mediaId: $mediaId, userId: $userId) {
          id
        }
      }
    ''';
    try {
      final data = await _post(
        query,
        variables: {'mediaId': mediaId, 'userId': userId},
        token: token,
      );
      return data['data']?['MediaList']?['id'] as int?;
    } catch (_) {
      return null;
    }
  }

  /// Delete a media list entry from Anilist by list entry ID.
  Future<void> deleteMediaListEntry(int entryId, String token) async {
    const query = r'''
      mutation ($id: Int) {
        DeleteMediaListEntry(id: $id) { deleted }
      }
    ''';
    await _post(query, variables: {'id': entryId}, token: token);
  }

  /// Toggle follow on a user.
  Future<bool> toggleFollow(int userId, String token) async {
    const query = r'''
      mutation ($userId: Int) {
        ToggleFollow(userId: $userId) {
          id
          isFollowing
        }
      }
    ''';
    final data = await _post(query, variables: {'userId': userId}, token: token);
    return data['data']?['ToggleFollow']?['isFollowing'] as bool? ?? false;
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
          favourites {
            anime(perPage: 10) {
              nodes { id title { romaji english } coverImage { large } }
            }
            manga(perPage: 10) {
              nodes { id title { romaji english } coverImage { large } }
            }
          }
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
    final user = data['data']?['Viewer'] as Map<String, dynamic>?;
    if (user == null) return null;
    final id = jsonInt(user['id']);
    if (id > 0) {
      try {
        final counts = await fetchUserFollowCounts(id, token: token);
        user['followersCount'] = jsonInt(counts['followers']);
        user['followingCount'] = jsonInt(counts['following']);
      } catch (_) {
        user['followersCount'] = 0;
        user['followingCount'] = 0;
      }
    } else {
      user['followersCount'] = 0;
      user['followingCount'] = 0;
    }
    return user;
  }

  /// Post a comment on a forum thread. Requires auth.
  Future<Map<String, dynamic>> saveThreadComment(
      int threadId, String text, String token, {int? parentCommentId}) async {
    const query = r'''
      mutation ($threadId: Int, $parentCommentId: Int, $comment: String) {
        SaveThreadComment(threadId: $threadId, parentCommentId: $parentCommentId, comment: $comment) {
          id comment createdAt isLiked likeCount
          user { id name avatar { medium } }
        }
      }
    ''';
    final data = await _post(
        query,
        variables: {'threadId': threadId, 'parentCommentId': parentCommentId, 'comment': text},
        token: token);
    final saved = data['data']?['SaveThreadComment'];
    if (saved is Map<String, dynamic>) return saved;
    if (saved is Map) return Map<String, dynamic>.from(saved);
    throw Exception('SaveThreadComment returned no data');
  }

  /// Forum threads related to a media item.
  Future<List<Map<String, dynamic>>> fetchMediaThreads(int mediaId, {int perPage = 10}) async {
    const query = r'''
      query ($mediaId: Int, $perPage: Int) {
        Page(perPage: $perPage) {
          threads(mediaCategoryId: $mediaId, sort: REPLIED_AT_DESC) {
            id title createdAt updatedAt replyCount viewCount
            user { id name avatar { medium } }
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'mediaId': mediaId, 'perPage': perPage});
    final threads = data['data']?['Page']?['threads'] as List?;
    return threads?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Full forum thread with comments.
  Future<Map<String, dynamic>?> fetchForumThread(int threadId, {String? token}) async {
    const query = r'''
      query ($id: Int, $perPage: Int) {
        Thread(id: $id) {
          id title body createdAt updatedAt replyCount viewCount isLiked likeCount
          user { id name avatar { medium } }
          categories { id name }
          mediaCategories { id type title { romaji english } coverImage { large } }
        }
        Page(perPage: $perPage) {
          threadComments(threadId: $id) {
            id comment createdAt isLiked likeCount isLocked
            user { id name avatar { medium } }
            childComments
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'id': threadId, 'perPage': 25}, token: token);
    final thread = data['data']?['Thread'] as Map<String, dynamic>?;
    if (thread == null) return null;
    final comments = (data['data']?['Page']?['threadComments'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    return {...thread, 'comments': comments};
  }

  /// Browse forum threads with optional category filter and sort.
  /// [categoryId]: Anilist forum category (e.g. 1=General, 2=Anime, 3=Manga,
  /// 5=Release Discussions, 7=Music, 9=Gaming, etc.)
  /// [sort]: e.g. REPLIED_AT_DESC, CREATED_AT_DESC, IS_STICKY, etc.
  Future<List<Map<String, dynamic>>> fetchForumThreads({
    int? categoryId,
    String sort = 'REPLIED_AT_DESC',
    int perPage = 15,
    int page = 1,
  }) async {
    const query = r'''
      query ($categoryId: Int, $sort: [ThreadSort], $perPage: Int, $page: Int) {
        Page(perPage: $perPage, page: $page) {
          threads(categoryId: $categoryId, sort: $sort) {
            id title createdAt updatedAt replyCount viewCount isSticky isLocked
            user { id name avatar { medium } }
            categories { id name }
            repliedAt
          }
        }
      }
    ''';
    final data = await _post(query, variables: {
      if (categoryId != null) 'categoryId': categoryId,
      'sort': [sort],
      'perPage': perPage,
      'page': page,
    });
    final threads = data['data']?['Page']?['threads'] as List?;
    return threads?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Search forum threads by query string.
  Future<List<Map<String, dynamic>>> searchForumThreads({
    required String search,
    int? categoryId,
    int perPage = 20,
    int page = 1,
  }) async {
    const query = r'''
      query ($search: String, $categoryId: Int, $sort: [ThreadSort], $perPage: Int, $page: Int) {
        Page(perPage: $perPage, page: $page) {
          threads(search: $search, categoryId: $categoryId, sort: $sort) {
            id title createdAt updatedAt replyCount viewCount isSticky isLocked
            user { id name avatar { medium } }
            categories { id name }
            repliedAt
          }
        }
      }
    ''';
    final data = await _post(query, variables: {
      'search': search,
      if (categoryId != null) 'categoryId': categoryId,
      'sort': ['SEARCH_MATCH'],
      'perPage': perPage,
      'page': page,
    });
    final threads = data['data']?['Page']?['threads'] as List?;
    return threads?.cast<Map<String, dynamic>>() ?? [];
  }

  /// Fetch all forum feed sections using individual queries.
  /// Returns a map with keys: 'sticky', 'recent', 'newest', 'releases'.
  Future<Map<String, List<Map<String, dynamic>>>> fetchForumFeed({
    int? categoryId,
  }) async {
    final results = await Future.wait([
      fetchForumThreads(categoryId: categoryId, sort: 'IS_STICKY', perPage: 10),
      fetchForumThreads(categoryId: categoryId, sort: 'REPLIED_AT_DESC', perPage: 8),
      fetchForumThreads(categoryId: categoryId, sort: 'CREATED_AT_DESC', perPage: 8),
      fetchForumThreads(categoryId: 5, sort: 'REPLIED_AT_DESC', perPage: 8),
    ]);
    return {
      'sticky': results[0].where((t) => t['isSticky'] == true).toList(),
      'recent': results[1],
      'newest': results[2],
      'releases': results[3],
    };
  }
}
