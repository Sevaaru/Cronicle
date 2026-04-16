import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';

part 'trakt_providers.g.dart';

@Riverpod(keepAlive: true)
TraktAuthDatasource traktAuth(TraktAuthRef ref) {
  return TraktAuthDatasource(const FlutterSecureStorage(), ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
TraktApiDatasource traktApi(TraktApiRef ref) {
  return TraktApiDatasource(ref.watch(dioProvider));
}

/// Sesión Trakt (OAuth opcional).
@Riverpod(keepAlive: true)
class TraktSession extends _$TraktSession {
  static const _oauthStatePrefsKey = 'trakt_oauth_state';

  @override
  Future<TraktSessionState> build() async {
    final auth = ref.watch(traktAuthProvider);
    final connected = await auth.hasSession();
    final slug = await auth.getUserSlug();
    final name = await auth.getUserName();
    return TraktSessionState(
      connected: connected,
      userSlug: slug,
      userName: name,
    );
  }

  Future<void> refreshFromNetwork() async {
    final auth = ref.read(traktAuthProvider);
    final token = await auth.getValidAccessToken();
    if (token == null) {
      state = AsyncData(
        TraktSessionState(connected: false, userSlug: null, userName: null),
      );
      return;
    }
    final api = ref.read(traktApiProvider);
    final settings = await api.fetchUserSettings(token);
    await auth.saveUserFromSettings(settings);
    final slug = await auth.getUserSlug();
    final name = await auth.getUserName();
    state = AsyncData(
      TraktSessionState(connected: true, userSlug: slug, userName: name),
    );
  }

  Future<void> clear() async {
    await ref.read(traktAuthProvider).clearSession();
    invalidateTraktHomeProviders(ref);
    state = AsyncData(
      TraktSessionState(connected: false, userSlug: null, userName: null),
    );
  }

  /// OAuth en navegador seguro (mismo esquema `cronicle://` que Twitch).
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
    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: 'cronicle',
    );
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

class TraktSessionState {
  const TraktSessionState({
    required this.connected,
    this.userSlug,
    this.userName,
  });

  final bool connected;
  final String? userSlug;
  final String? userName;
}

class TraktMoviesHomeData {
  const TraktMoviesHomeData({
    required this.trending,
    required this.watching,
    required this.popular,
  });

  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> watching;
  final List<Map<String, dynamic>> popular;
}

class TraktShowsHomeData {
  const TraktShowsHomeData({
    required this.trending,
    required this.watching,
    required this.popular,
  });

  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> watching;
  final List<Map<String, dynamic>> popular;
}

@riverpod
Future<TraktMoviesHomeData> traktMoviesHome(TraktMoviesHomeRef ref) async {
  if (EnvConfig.traktClientId.isEmpty) {
    return const TraktMoviesHomeData(trending: [], watching: [], popular: []);
  }
  final api = ref.watch(traktApiProvider);
  final results = await Future.wait([
    api.moviesTrending(limit: 18),
    api.moviesWatching(limit: 18),
    api.moviesPopular(limit: 18),
  ]);
  return TraktMoviesHomeData(
    trending: results[0],
    watching: results[1],
    popular: results[2],
  );
}

@riverpod
Future<TraktShowsHomeData> traktShowsHome(TraktShowsHomeRef ref) async {
  if (EnvConfig.traktClientId.isEmpty) {
    return const TraktShowsHomeData(trending: [], watching: [], popular: []);
  }
  final api = ref.watch(traktApiProvider);
  final results = await Future.wait([
    api.showsTrending(limit: 18),
    api.showsWatching(limit: 18),
    api.showsPopular(limit: 18),
  ]);
  return TraktShowsHomeData(
    trending: results[0],
    watching: results[1],
    popular: results[2],
  );
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

void invalidateTraktHomeProviders(dynamic ref) {
  ref.invalidate(traktMoviesHomeProvider);
  ref.invalidate(traktShowsHomeProvider);
}
