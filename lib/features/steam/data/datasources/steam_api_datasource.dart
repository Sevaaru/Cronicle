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
}
