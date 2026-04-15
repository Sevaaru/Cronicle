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

    late final Map<String, dynamic> body;
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
      if (res.data is Map<String, dynamic>) {
        body = res.data as Map<String, dynamic>;
      } else {
        throw Exception('HTTP ${res.statusCode}');
      }
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        body = data;
      } else {
        throw Exception('Network error: ${e.message}');
      }
    }

    final errors = body['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final msg = (errors.first as Map)['message'] as String? ?? 'GraphQL error';
      throw Exception(msg);
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
          }
        }
      }
    ''';
    final data = await _post(query, variables: {'type': type});
    return (data['data']?['Page']?['media'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
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
    final data = await _post(query, variables: {'id': id});
    return data['data']?['Media'] as Map<String, dynamic>?;
  }

  /// Recent public activity. Pass null [activityType] for all types.
  /// If [isFollowing] is true, only shows activity from users the viewer follows.
  Future<List<Map<String, dynamic>>> fetchRecentActivityByType({
    String? activityType,
    int page = 1,
    int perPage = 25,
    String? token,
    bool isFollowing = false,
  }) async {
    const query = r'''
      query ($page: Int, $perPage: Int, $type: ActivityType, $isFollowing: Boolean) {
        Page(page: $page, perPage: $perPage) {
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
    final activities =
        (data['data']?['Page']?['activities'] as List?)
                ?.cast<Map<String, dynamic>>() ??
            [];
    return activities.where((a) => a['media'] != null || a['type'] == 'TEXT').toList();
  }

  /// Toggle like on an activity or reply. Requires auth token.
  Future<bool> toggleLike(int id, String token, {String type = 'ACTIVITY'}) async {
    const query = r'''
      mutation ($id: Int, $type: LikeableType) {
        ToggleLikeV2(id: $id, type: $type) {
          ... on ListActivity { id isLiked likeCount }
          ... on TextActivity { id isLiked likeCount }
          ... on ActivityReply { id isLiked likeCount }
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
      mutation ($activityText: String) {
        SaveTextActivity(text: $activityText) {
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
    final data = await _post(query, variables: {'activityText': text}, token: token);
    return data['data']!['SaveTextActivity'] as Map<String, dynamic>;
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

  /// Fetch replies for an activity.
  Future<List<Map<String, dynamic>>> fetchActivityReplies(int activityId, {String? token}) async {
    const query = r'''
      query ($activityId: Int) {
        Page(page: 1, perPage: 25) {
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
    final data = await _post(query, variables: {'activityId': activityId}, token: token);
    return (data['data']?['Page']?['activityReplies'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
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
    final data = await _post(query, variables: {'id': userId}, token: token);
    return data['data']?['User'] as Map<String, dynamic>?;
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
  /// [score] expects POINT_10 format (0-10), converted to scoreRaw (0-100).
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
          score(format: POINT_10)
          progress
          notes
        }
      }
    ''';
    final variables = <String, dynamic>{'mediaId': mediaId};
    if (status != null) variables['status'] = status;
    if (score != null) variables['scoreRaw'] = score * 10;
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
    return data['data']?['Viewer'] as Map<String, dynamic>?;
  }
}
