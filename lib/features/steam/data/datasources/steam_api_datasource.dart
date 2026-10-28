import 'package:dio/dio.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Thin wrapper over the public Steam Web API.
///
/// All methods require [EnvConfig.steamApiKey] to be configured. The key is
/// embedded in the Flutter binary (mirrors the existing Twitch/Trakt secret
/// pattern in this app); Steam's free Web API keys are intended for client
/// use and rate-limit per IP, so this is acceptable for a personal app.
class SteamApiDatasource {
  SteamApiDatasource(this._dio);

  final Dio _dio;

  static const _base = 'https://api.steampowered.com';

  String get _key => EnvConfig.steamApiKey;

  bool get hasApiKey => _key.trim().isNotEmpty;

  Future<Map<String, dynamic>?> _get(
    String path,
    Map<String, dynamic> query,
  ) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base$path',
      queryParameters: query,
      options: Options(
        responseType: ResponseType.json,
        validateStatus: (s) => s != null && s >= 200 && s < 500,
      ),
    );
    if (res.statusCode != 200) return null;
    return res.data;
  }

  /// Returns basic profile info: persona name, avatar, profile URL.
  Future<Map<String, dynamic>?> fetchPlayerSummary(String steamId) async {
    if (!hasApiKey) throw StateError('no_api_key');
    final data = await _get(
      '/ISteamUser/GetPlayerSummaries/v0002/',
      {'key': _key, 'steamids': steamId},
    );
    final players =
        (data?['response'] as Map<String, dynamic>?)?['players'] as List?;
    if (players == null || players.isEmpty) return null;
    final p = players.first;
    if (p is Map) return Map<String, dynamic>.from(p);
    return null;
  }

  /// Returns the user's owned games (requires the profile to be public, or
  /// "Game details" set to public). Each entry includes:
  /// `appid`, `name`, `playtime_forever` (minutes), `img_icon_url`,
  /// `playtime_2weeks` (optional), `rtime_last_played`.
  Future<List<Map<String, dynamic>>> fetchOwnedGames(String steamId) async {
    if (!hasApiKey) throw StateError('no_api_key');
    final data = await _get(
      '/IPlayerService/GetOwnedGames/v0001/',
      {
        'key': _key,
        'steamid': steamId,
        'include_appinfo': 1,
        'include_played_free_games': 1,
        'format': 'json',
      },
    );
    final games =
        (data?['response'] as Map<String, dynamic>?)?['games'] as List?;
    if (games == null) return const [];
    return games
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Recently played games (last 2 weeks).
  Future<List<Map<String, dynamic>>> fetchRecentlyPlayed(String steamId) async {
    if (!hasApiKey) throw StateError('no_api_key');
    final data = await _get(
      '/IPlayerService/GetRecentlyPlayedGames/v0001/',
      {'key': _key, 'steamid': steamId, 'format': 'json'},
    );
    final games =
        (data?['response'] as Map<String, dynamic>?)?['games'] as List?;
    if (games == null) return const [];
    return games
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Per-game achievement progress (unlocked yes/no + unlock time).
  ///
  /// Returns an empty list if the game has no achievements or the user's
  /// stats are private. Achievement details (display name, description,
  /// icons) come from [fetchGameSchema].
  Future<List<Map<String, dynamic>>> fetchPlayerAchievements(
    String steamId,
    int appId,
  ) async {
    if (!hasApiKey) throw StateError('no_api_key');
    final data = await _get(
      '/ISteamUserStats/GetPlayerAchievements/v0001/',
      {
        'key': _key,
        'steamid': steamId,
        'appid': appId,
        'l': 'english',
      },
    );
    final ps = data?['playerstats'] as Map<String, dynamic>?;
    if (ps == null || ps['success'] != true) return const [];
    final raw = ps['achievements'] as List?;
    if (raw == null) return const [];
    return raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Achievement schema for a game (display names, descriptions, icons,
  /// hidden flag). Useful to enrich [fetchPlayerAchievements] entries.
  Future<List<Map<String, dynamic>>> fetchGameSchema(int appId) async {
    if (!hasApiKey) throw StateError('no_api_key');
    final data = await _get(
      '/ISteamUserStats/GetSchemaForGame/v2/',
      {'key': _key, 'appid': appId, 'l': 'english'},
    );
    final game = data?['game'] as Map<String, dynamic>?;
    final stats = game?['availableGameStats'] as Map<String, dynamic>?;
    final achievements = stats?['achievements'] as List?;
    if (achievements == null) return const [];
    return achievements
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Steam Store page details (public, no API key required).
  /// Returns the 'data' map (name, short_description, developers, metacritic…)
  /// or null if the app has no store page or the request fails.
  Future<Map<String, dynamic>?> fetchAppDetails(int appId) async {
    try {
      final res = await _dio.get<dynamic>(
        'https://store.steampowered.com/api/appdetails',
        queryParameters: {'appids': appId, 'l': 'english', 'cc': 'us'},
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s >= 200 && s < 500,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final appEntry = (res.data as Map<dynamic, dynamic>?)?['$appId'];
      if (appEntry is! Map || appEntry['success'] != true) return null;
      final data = appEntry['data'];
      if (data is Map) return Map<String, dynamic>.from(data as Map);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches user review summary + up to 5 recent reviews from the
  /// Steam Store reviews endpoint (no API key required).
  Future<Map<String, dynamic>?> fetchUserReviews(int appId) async {
    try {
      final res = await _dio.get<dynamic>(
        'https://store.steampowered.com/appreviews/$appId',
        queryParameters: {
          'json': 1,
          'language': 'english',
          'review_type': 'all',
          'purchase_type': 'all',
          'num_per_page': 5,
          'filter': 'recent',
        },
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s >= 200 && s < 500,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.statusCode != 200 || res.data == null) return null;
      final data = res.data;
      if (data is! Map || data['success'] != 1) return null;
      return Map<String, dynamic>.from(data as Map);
    } catch (_) {
      return null;
    }
  }

  /// Concurrent player count for [appId].
  Future<int?> fetchCurrentPlayers(int appId) async {
    if (!hasApiKey) return null;
    try {
      final data = await _get(
        '/ISteamUserStats/GetNumberOfCurrentPlayers/v1/',
        {'appid': appId},
      );
      final count =
          (data?['response'] as Map<String, dynamic>?)?['player_count'];
      if (count is int) return count;
      if (count is num) return count.toInt();
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Returns the list of friend steamIDs (requires the user's friend list to
  /// be public). Returns an empty list on any error or private profile.
  Future<List<String>> fetchFriendList(String steamId) async {
    if (!hasApiKey) return const [];
    try {
      final data = await _get(
        '/ISteamUser/GetFriendList/v0001/',
        {'key': _key, 'steamid': steamId, 'relationship': 'friend'},
      );
      final friends =
          (data?['friendslist'] as Map<String, dynamic>?)?['friends'] as List?;
      if (friends == null) return const [];
      return friends
          .whereType<Map>()
          .map((e) => (e['steamid'] as String?) ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Batch-fetch player summaries for up to 100 steamIDs (single API call).
  Future<List<Map<String, dynamic>>> fetchPlayerSummaries(
    List<String> steamIds,
  ) async {
    if (!hasApiKey || steamIds.isEmpty) return const [];
    try {
      final data = await _get(
        '/ISteamUser/GetPlayerSummaries/v0002/',
        {'key': _key, 'steamids': steamIds.take(100).join(',')},
      );
      final players =
          (data?['response'] as Map<String, dynamic>?)?['players'] as List?;
      if (players == null) return const [];
      return players
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Convenience: store icon URL for an owned game.
  static String? gameIconUrl(int appId, String? imgIconUrl) {
    if (imgIconUrl == null || imgIconUrl.isEmpty) return null;
    return 'https://media.steampowered.com/steamcommunity/public/images/apps/$appId/$imgIconUrl.jpg';
  }

  /// Steam CDN library / capsule artwork URL for a given app ID.
  static String capsuleUrl(int appId) =>
      'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/library_600x900.jpg';

  static String headerUrl(int appId) =>
      'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId/header.jpg';

  /// Ordered list of artwork URL candidates for [appId]. Some titles
  /// (free-to-play, recently launched, region-restricted) only expose a
  /// subset of artwork variants; consumers should try them in order and
  /// fall through on 404. Vertical capsule first → suits row thumbnails;
  /// horizontal header last → suits hero banners.
  static List<String> artworkCandidates(int appId, {bool preferHeader = false}) {
    final cf = 'https://cdn.cloudflare.steamstatic.com/steam/apps/$appId';
    final ak = 'https://cdn.akamai.steamstatic.com/steam/apps/$appId';
    final shared =
        'https://shared.cloudflare.steamstatic.com/store_item_assets/steam/apps/$appId';
    final vertical = [
      '$cf/library_600x900.jpg',
      '$ak/library_600x900.jpg',
      '$shared/library_600x900.jpg',
      '$cf/library_600x900_2x.jpg',
    ];
    final horizontal = [
      '$cf/header.jpg',
      '$ak/header.jpg',
      '$shared/header.jpg',
      '$cf/capsule_616x353.jpg',
      '$cf/library_hero.jpg',
    ];
    return preferHeader
        ? [...horizontal, ...vertical]
        : [...vertical, ...horizontal];
  }

  /// Public Steam news / events for [appId] (no API key required).
  ///
  /// Returns up to [count] news items, each with `title`, `url`, `author`,
  /// `contents`, `date` (unix seconds), `feedlabel`, `feedname`, `tags`.
  /// Maximum length per item body limited by [maxLength]. We request
  /// `feeds=steam_community_announcements` to surface the official
  /// developer announcements that show up under "Events & Announcements"
  /// on the store page.
  Future<List<Map<String, dynamic>>> fetchAppNews(
    int appId, {
    int count = 8,
    int maxLength = 600,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '$_base/ISteamNews/GetNewsForApp/v2/',
        queryParameters: {
          'appid': appId,
          'count': count,
          'maxlength': maxLength,
          'feeds': 'steam_community_announcements',
          'format': 'json',
        },
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s >= 200 && s < 500,
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      if (res.statusCode != 200 || res.data == null) return const [];
      final raw = res.data;
      Map<String, dynamic>? items;
      if (raw is Map) {
        items = (raw['appnews'] as Map?)?.cast<String, dynamic>();
      }
      final list = items?['newsitems'] as List?;
      if (list == null) return const [];
      return list
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  /// Popular community-voted tags for [appId] from the public SteamSpy API.
  /// Returns a map of `tag → vote count` sorted descending. Returns an
  /// empty map on any error (network, parse, or rate-limit).
  Future<Map<String, int>> fetchSteamSpyTags(int appId) async {
    try {
      final res = await _dio.get<dynamic>(
        'https://steamspy.com/api.php',
        queryParameters: {'request': 'appdetails', 'appid': appId},
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (s) => s != null && s >= 200 && s < 500,
          receiveTimeout: const Duration(seconds: 8),
        ),
      );
      if (res.statusCode != 200 || res.data == null) return const {};
      final raw = res.data;
      if (raw is! Map) return const {};
      final tags = raw['tags'];
      if (tags is! Map) return const {};
      final out = <String, int>{};
      tags.forEach((k, v) {
        if (k is String && v is num) out[k] = v.toInt();
      });
      // Sort by votes desc.
      final sorted = out.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return Map.fromEntries(sorted);
    } catch (_) {
      return const {};
    }
  }
}
