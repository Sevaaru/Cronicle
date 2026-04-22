import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import 'package:cronicle/core/cache/json_cache.dart';
import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';

part 'trakt_providers.g.dart';

/// Background refresh throttle for the Trakt session metadata.
const Duration _traktSessionRefreshWindow = Duration(hours: 12);

const String _traktMoviesHomeCacheKey = 'trakt_movies_home';
const String _traktShowsHomeCacheKey = 'trakt_shows_home';

@Riverpod(keepAlive: true)
TraktAuthDatasource traktAuth(TraktAuthRef ref) {
  return TraktAuthDatasource(const FlutterSecureStorage(), ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
TraktApiDatasource traktApi(TraktApiRef ref) {
  return TraktApiDatasource(ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
class TraktSession extends _$TraktSession {
  static const _oauthStatePrefsKey = 'trakt_oauth_state';
  static const _lastRefreshKey = 'trakt_session_last_refresh_ms';

  @override
  Future<TraktSessionState> build() async {
    final auth = ref.watch(traktAuthProvider);
    final connected = await auth.hasSession();
    final slug = await auth.getUserSlug();
    final name = await auth.getUserName();
    final avatarUrl = await auth.getUserAvatarUrl();
    final result = TraktSessionState(
      connected: connected,
      userSlug: slug,
      userName: name,
      userAvatarUrl: avatarUrl,
    );
    if (connected) {
      _scheduleBackgroundRefreshIfStale();
    }
    return result;
  }

  void _scheduleBackgroundRefreshIfStale() {
    final prefs = ref.read(sharedPreferencesProvider);
    final lastMs = prefs.getInt(_lastRefreshKey) ?? 0;
    final age = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(lastMs));
    if (age < _traktSessionRefreshWindow) return;
    Future<void>.microtask(() async {
      try {
        await refreshFromNetwork();
        await prefs.setInt(
          _lastRefreshKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      } catch (_) {}
    });
  }

  Future<void> refreshFromNetwork() async {
    final auth = ref.read(traktAuthProvider);
    final token = await auth.getValidAccessToken();
    if (token == null) {
      state = AsyncData(
        TraktSessionState(
          connected: false,
          userSlug: null,
          userName: null,
          userAvatarUrl: null,
        ),
      );
      return;
    }
    final api = ref.read(traktApiProvider);
    final settings = await api.fetchUserSettings(token);
    await auth.saveUserFromSettings(settings);
    final slug = await auth.getUserSlug();
    final name = await auth.getUserName();
    final avatarUrl = await auth.getUserAvatarUrl();
    state = AsyncData(
      TraktSessionState(
        connected: true,
        userSlug: slug,
        userName: name,
        userAvatarUrl: avatarUrl,
      ),
    );
  }

  Future<void> clear() async {
    await ref.read(traktAuthProvider).clearSession();
    invalidateTraktHomeProviders(ref);
    state = AsyncData(
      TraktSessionState(
        connected: false,
        userSlug: null,
        userName: null,
        userAvatarUrl: null,
      ),
    );
  }

  Future<void> connectOAuth() async {
    if (kIsWeb) {
      throw UnsupportedError('web');
    }
    if (EnvConfig.traktClientId.isEmpty ||
        EnvConfig.traktClientSecret.isEmpty) {
      throw StateError('no_credentials');
    }
    final redirectRaw = EnvConfig.traktRedirectUri.trim();
    if (redirectRaw.isEmpty) {
      throw StateError('no_redirect_uri');
    }
    final auth = ref.read(traktAuthProvider);
    final oauthState = const Uuid().v4();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_oauthStatePrefsKey, oauthState);

    final uri = auth.buildAuthorizeUri(oauthState);
    final String result;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      result = await _traktOAuthAndroidExternalBrowser(uri, oauthState);
    } else {
      result = await FlutterWebAuth2.authenticate(
        url: uri.toString(),
        callbackUrlScheme: 'cronicle',
        options: const FlutterWebAuth2Options(
          intentFlags: ephemeralIntentFlags,
        ),
      );
    }
    final returned = Uri.parse(result);
    if (returned.queryParameters['state'] != oauthState) {
      await prefs.remove(_oauthStatePrefsKey);
      throw StateError('bad_state');
    }
    final code = returned.queryParameters['code'];
    if (code == null || code.isEmpty) {
      await prefs.remove(_oauthStatePrefsKey);
      final desc = returned.queryParameters['error_description'] ??
          returned.queryParameters['error'];
      throw StateError(desc ?? 'no_code');
    }
    await auth.exchangeAuthorizationCode(code);
    await prefs.remove(_oauthStatePrefsKey);
    await refreshFromNetwork();
    invalidateTraktHomeProviders(ref);
  }
}

Future<String> _traktOAuthAndroidExternalBrowser(
  Uri authUri,
  String expectedState,
) async {
  final appLinks = AppLinks();
  final completer = Completer<String>();

  bool matches(Uri u) =>
      u.scheme == 'cronicle' &&
      u.host == 'trakt-oauth' &&
      u.queryParameters['state'] == expectedState;

  void completeIfMatch(Uri u) {
    if (matches(u) && !completer.isCompleted) {
      completer.complete(u.toString());
    }
  }

  final initial = await appLinks.getInitialLink();
  if (initial != null) {
    completeIfMatch(initial);
  }

  late final StreamSubscription<Uri> sub;
  sub = appLinks.uriLinkStream.listen(completeIfMatch);

  if (completer.isCompleted) {
    await sub.cancel();
    return completer.future;
  }

  final launched =
      await launchUrl(authUri, mode: LaunchMode.externalApplication);
  if (!launched) {
    await sub.cancel();
    throw StateError('launch_failed');
  }

  try {
    return await completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => throw StateError('oauth_timeout'),
    );
  } finally {
    await sub.cancel();
  }
}

class TraktSessionState {
  const TraktSessionState({
    required this.connected,
    this.userSlug,
    this.userName,
    this.userAvatarUrl,
  });

  final bool connected;
  final String? userSlug;
  final String? userName;
  final String? userAvatarUrl;
}

class TraktMoviesHomeData {
  const TraktMoviesHomeData({
    required this.trending,
    required this.anticipated,
    required this.popular,
    required this.played,
    required this.watched,
    required this.collected,
  });

  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> anticipated;
  final List<Map<String, dynamic>> popular;
  final List<Map<String, dynamic>> played;
  final List<Map<String, dynamic>> watched;
  final List<Map<String, dynamic>> collected;

  Map<String, dynamic> toJson() => {
        'trending': trending,
        'anticipated': anticipated,
        'popular': popular,
        'played': played,
        'watched': watched,
        'collected': collected,
      };

  factory TraktMoviesHomeData.fromJson(Map<String, dynamic> json) {
    return TraktMoviesHomeData(
      trending: jsonListAsMaps(json['trending']),
      anticipated: jsonListAsMaps(json['anticipated']),
      popular: jsonListAsMaps(json['popular']),
      played: jsonListAsMaps(json['played']),
      watched: jsonListAsMaps(json['watched']),
      collected: jsonListAsMaps(json['collected']),
    );
  }

  bool get isEmpty =>
      trending.isEmpty &&
      anticipated.isEmpty &&
      popular.isEmpty &&
      played.isEmpty &&
      watched.isEmpty &&
      collected.isEmpty;
}

class TraktShowsHomeData {
  const TraktShowsHomeData({
    required this.trending,
    required this.watching,
    required this.popular,
    required this.anticipated,
    required this.watched,
    required this.collected,
  });

  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> watching;
  final List<Map<String, dynamic>> popular;
  final List<Map<String, dynamic>> anticipated;
  final List<Map<String, dynamic>> watched;
  final List<Map<String, dynamic>> collected;

  Map<String, dynamic> toJson() => {
        'trending': trending,
        'watching': watching,
        'popular': popular,
        'anticipated': anticipated,
        'watched': watched,
        'collected': collected,
      };

  factory TraktShowsHomeData.fromJson(Map<String, dynamic> json) {
    return TraktShowsHomeData(
      trending: jsonListAsMaps(json['trending']),
      watching: jsonListAsMaps(json['watching']),
      popular: jsonListAsMaps(json['popular']),
      anticipated: jsonListAsMaps(json['anticipated']),
      watched: jsonListAsMaps(json['watched']),
      collected: jsonListAsMaps(json['collected']),
    );
  }

  bool get isEmpty =>
      trending.isEmpty &&
      watching.isEmpty &&
      popular.isEmpty &&
      anticipated.isEmpty &&
      watched.isEmpty &&
      collected.isEmpty;
}

Future<TraktMoviesHomeData> _fetchTraktMoviesHome(TraktApiDatasource api) async {
  final results = await Future.wait([
    api.moviesTrending(limit: 20),
    api.moviesAnticipated(limit: 18),
    api.moviesPopular(limit: 18),
    api.moviesPlayed(limit: 20),
    api.moviesWatched(limit: 18),
    api.moviesCollected(limit: 18),
  ]);
  return TraktMoviesHomeData(
    trending: results[0],
    anticipated: results[1],
    popular: results[2],
    played: results[3],
    watched: results[4],
    collected: results[5],
  );
}

Future<TraktShowsHomeData> _fetchTraktShowsHome(TraktApiDatasource api) async {
  final results = await Future.wait([
    api.showsTrending(limit: 20),
    api.showsWatching(limit: 18),
    api.showsPopular(limit: 18),
    api.showsAnticipated(limit: 18),
    api.showsWatched(limit: 18),
    api.showsCollected(limit: 18),
  ]);
  return TraktShowsHomeData(
    trending: results[0],
    watching: results[1],
    popular: results[2],
    anticipated: results[3],
    watched: results[4],
    collected: results[5],
  );
}

@Riverpod(keepAlive: true)
class TraktMoviesHome extends _$TraktMoviesHome {
  @override
  Future<TraktMoviesHomeData> build() async {
    if (EnvConfig.traktClientId.isEmpty) {
      return const TraktMoviesHomeData(
        trending: [],
        anticipated: [],
        popular: [],
        played: [],
        watched: [],
        collected: [],
      );
    }
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_traktMoviesHomeCacheKey);
    final api = ref.watch(traktApiProvider);

    if (cached != null) {
      // Always background-refresh so discover shows cached data immediately
      // while fresh data loads.
      Future<void>.microtask(() async {
        try {
          final data = await _fetchTraktMoviesHome(api);
          await cache.write(_traktMoviesHomeCacheKey, data.toJson());
          state = AsyncData(data);
        } catch (_) {
          // Keep cached data on failure.
        }
      });
      return TraktMoviesHomeData.fromJson(cached.data);
    }

    final data = await _fetchTraktMoviesHome(api);
    await cache.write(_traktMoviesHomeCacheKey, data.toJson());
    return data;
  }

  /// Forces a network refetch ignoring cache freshness.
  Future<void> refresh() async {
    final api = ref.read(traktApiProvider);
    final cache = ref.read(jsonCacheProvider);
    state = const AsyncValue.loading();
    try {
      final data = await _fetchTraktMoviesHome(api);
      await cache.write(_traktMoviesHomeCacheKey, data.toJson());
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@Riverpod(keepAlive: true)
class TraktShowsHome extends _$TraktShowsHome {
  @override
  Future<TraktShowsHomeData> build() async {
    if (EnvConfig.traktClientId.isEmpty) {
      return const TraktShowsHomeData(
        trending: [],
        watching: [],
        popular: [],
        anticipated: [],
        watched: [],
        collected: [],
      );
    }
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_traktShowsHomeCacheKey);
    final api = ref.watch(traktApiProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final data = await _fetchTraktShowsHome(api);
          await cache.write(_traktShowsHomeCacheKey, data.toJson());
          state = AsyncData(data);
        } catch (_) {}
      });
      return TraktShowsHomeData.fromJson(cached.data);
    }

    final data = await _fetchTraktShowsHome(api);
    await cache.write(_traktShowsHomeCacheKey, data.toJson());
    return data;
  }

  Future<void> refresh() async {
    final api = ref.read(traktApiProvider);
    final cache = ref.read(jsonCacheProvider);
    state = const AsyncValue.loading();
    try {
      final data = await _fetchTraktShowsHome(api);
      await cache.write(_traktShowsHomeCacheKey, data.toJson());
      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
Future<List<Map<String, dynamic>>> traktSearchMovies(
  TraktSearchMoviesRef ref,
  String query,
) async {
  if (EnvConfig.traktClientId.isEmpty || query.trim().isEmpty) return [];
  return ref.read(traktApiProvider).searchMovies(query);
}

@riverpod
Future<List<Map<String, dynamic>>> traktSearchShows(
  TraktSearchShowsRef ref,
  String query,
) async {
  if (EnvConfig.traktClientId.isEmpty || query.trim().isEmpty) return [];
  return ref.read(traktApiProvider).searchShows(query);
}

@riverpod
Future<Map<String, dynamic>?> traktMovieDetail(
  TraktMovieDetailRef ref,
  int traktId,
) async {
  if (EnvConfig.traktClientId.isEmpty) return null;
  return ref.read(traktApiProvider).fetchMovieSummary(traktId);
}

@riverpod
Future<Map<String, dynamic>?> traktShowDetail(
  TraktShowDetailRef ref,
  int traktId,
) async {
  if (EnvConfig.traktClientId.isEmpty) return null;
  return ref.read(traktApiProvider).fetchShowSummary(traktId);
}

const _favoriteTraktPrefsKey = 'favorite_trakt_titles_v1';

List<Map<String, dynamic>> _decodeFavoriteTraktJson(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _snapshotTraktTitleForFavorites(Map<String, dynamic> item) {
  final title = item['title'] as Map<String, dynamic>? ?? {};
  final cover = item['coverImage'] as Map<String, dynamic>? ?? {};
  return {
    'id': item['id'],
    'trakt_type': item['trakt_type'] ?? 'movie',
    'title': {
      'english': title['english'],
      'romaji': title['romaji'],
    },
    'coverImage': {
      'large': cover['large'] ?? cover['extraLarge'],
    },
  };
}

@Riverpod(keepAlive: true)
class FavoriteTraktTitles extends _$FavoriteTraktTitles {
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteTraktJson(prefs.getString(_favoriteTraktPrefsKey));
  }

  Future<void> toggleFavorite(Map<String, dynamic> item) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = (item['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;
    final type = (item['trakt_type'] as String?) ?? 'movie';
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere((e) {
      final eid = (e['id'] as num?)?.toInt() ?? 0;
      final et = (e['trakt_type'] as String?) ?? 'movie';
      return eid == id && et == type;
    });
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotTraktTitleForFavorites(item));
    }
    await prefs.setString(_favoriteTraktPrefsKey, jsonEncode(next));
    state = next;
  }
}

void invalidateTraktHomeProviders(dynamic ref) {
  ref.invalidate(traktMoviesHomeProvider);
  ref.invalidate(traktShowsHomeProvider);
}
