import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod/riverpod.dart' show AsyncData, Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/data/datasources/igdb_auth_datasource.dart';
import 'package:cronicle/features/games/data/games_feed_section.dart';

part 'game_providers.g.dart';

List<Map<String, dynamic>> _normalizeGamesSafe(List<Map<String, dynamic>> raw) {
  final out = <Map<String, dynamic>>[];
  for (final m in raw) {
    try {
      out.add(IgdbApiDatasource.normalize(m));
    } catch (_) {}
  }
  return out;
}

Future<void> _igdbPacingDelay() =>
    Future<void>.delayed(const Duration(milliseconds: 55));

/// Reintentos ante fallos transitorios; si la consulta filtrada devuelve [] tras
/// normalizar, [IgdbApiDatasource.fetchGamesHomeRatedPage] con [homeFallbackSlot]
/// evita que todos los carruseles repitan exactamente los mismos títulos.
Future<List<Map<String, dynamic>>> _igdbTryGames(
  IgdbApiDatasource api,
  Future<List<Map<String, dynamic>>> Function() fetch, {
  int homeFallbackSlot = 0,
}) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 110 * attempt));
    }
    try {
      final raw = await fetch();
      final next = _normalizeGamesSafe(raw);
      if (next.isNotEmpty) return next;
      if (raw.isEmpty) break;
    } catch (_) {}
  }
  try {
    final off = (homeFallbackSlot * 7).clamp(0, 400);
    var raw = await api.fetchGamesHomeRatedPage(limit: 24, offset: off);
    var next = _normalizeGamesSafe(raw);
    if (next.isNotEmpty) return next;
    if (off > 0) {
      raw = await api.fetchGamesHomeRatedPage(limit: 24, offset: 0);
      next = _normalizeGamesSafe(raw);
      if (next.isNotEmpty) return next;
    }
  } catch (_) {}
  return [];
}

List<Map<String, dynamic>> _filterReviewsWithGame(
  List<Map<String, dynamic>> raw,
) {
  final out = <Map<String, dynamic>>[];
  for (final r in raw) {
    final g = r['game'];
    if (g is Map<String, dynamic>) {
      out.add(r);
    } else if (g is Map) {
      final copy = Map<String, dynamic>.from(r);
      copy['game'] = Map<String, dynamic>.from(g);
      out.add(copy);
    }
  }
  return out;
}

Future<List<Map<String, dynamic>>> _igdbTryReviews(
  IgdbApiDatasource api,
  Future<List<Map<String, dynamic>>> Function() fetch,
) async {
  for (var attempt = 0; attempt < 3; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(Duration(milliseconds: 110 * attempt));
    }
    try {
      final raw = await fetch();
      return _filterReviewsWithGame(raw);
    } catch (_) {}
  }
  return [];
}

/// All IGDB home rows except [igdbPopular] (loaded separately for faster first paint).
class IgdbGamesHomeFeedData {
  const IgdbGamesHomeFeedData({
    required this.anticipated,
    required this.recentlyReleased,
    required this.reviewsRecent,
    required this.comingSoon,
    required this.bestRated,
    required this.reviewsCritics,
    required this.indie,
    required this.horror,
    required this.multiplayer,
    required this.rpg,
    required this.sports,
  });

  final List<Map<String, dynamic>> anticipated;
  final List<Map<String, dynamic>> recentlyReleased;
  final List<Map<String, dynamic>> reviewsRecent;
  final List<Map<String, dynamic>> comingSoon;
  final List<Map<String, dynamic>> bestRated;
  final List<Map<String, dynamic>> reviewsCritics;
  final List<Map<String, dynamic>> indie;
  final List<Map<String, dynamic>> horror;
  final List<Map<String, dynamic>> multiplayer;
  final List<Map<String, dynamic>> rpg;
  final List<Map<String, dynamic>> sports;
}

@Riverpod(keepAlive: true)
IgdbAuthDatasource igdbAuth(IgdbAuthRef ref) {
  return IgdbAuthDatasource(const FlutterSecureStorage(), ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
IgdbApiDatasource igdbApi(IgdbApiRef ref) {
  return IgdbApiDatasource(ref.watch(dioProvider), ref.watch(igdbAuthProvider));
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> igdbSearch(
  IgdbSearchRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];
  final api = ref.read(igdbApiProvider);
  final raw = await api.searchGames(query);
  return _normalizeGamesSafe(raw);
}

/// Popular (PopScore + mismo listado que el carrusel “Popular ahora”).
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> igdbPopular(IgdbPopularRef ref) async {
  final api = ref.read(igdbApiProvider);
  final raw = await api.fetchPopularGames(limit: 24);
  return _normalizeGamesSafe(raw);
}

@riverpod
Future<Map<String, dynamic>?> igdbGameDetail(
  IgdbGameDetailRef ref,
  int gameId,
) async {
  final api = ref.read(igdbApiProvider);
  final raw = await api.fetchGameDetail(gameId);
  if (raw == null) return null;
  final reviewsRaw = raw.remove('__igdb_reviews');
  final reviews = reviewsRaw is List
      ? reviewsRaw.cast<Map<String, dynamic>>()
      : <Map<String, dynamic>>[];
  final normalized = IgdbApiDatasource.normalize(raw);
  normalized['igdb_reviews'] = reviews;
  return normalized;
}

/// Aside del home: consultas IGDB **con filtros reales** (fechas, géneros,
/// `game_modes`, ratings) como en [IgdbApiDatasource]; peticiones **secuenciales**
/// con pacing para respetar rate limits. Reseñas: endpoints de review.
@Riverpod(keepAlive: true)
Future<IgdbGamesHomeFeedData> igdbGamesHomeFeed(IgdbGamesHomeFeedRef ref) async {
  final api = ref.read(igdbApiProvider);
  const n = 24;

  final anticipated = await _igdbTryGames(
    api,
    () => api.fetchGamesMostAnticipated(limit: n),
    homeFallbackSlot: 0,
  );
  await _igdbPacingDelay();
  final recentlyReleased = await _igdbTryGames(
    api,
    () => api.fetchGamesRecentlyReleased(limit: n),
    homeFallbackSlot: 1,
  );
  await _igdbPacingDelay();
  final reviewsRecent =
      await _igdbTryReviews(api, () => api.fetchReviewsRecent(limit: 36));
  await _igdbPacingDelay();
  final comingSoon = await _igdbTryGames(
    api,
    () => api.fetchGamesComingSoon(limit: n),
    homeFallbackSlot: 2,
  );
  await _igdbPacingDelay();
  final bestRated = await _igdbTryGames(
    api,
    () => api.fetchGamesBestRated(limit: n),
    homeFallbackSlot: 3,
  );
  await _igdbPacingDelay();
  final reviewsCritics =
      await _igdbTryReviews(api, () => api.fetchReviewsHighScore(limit: n));
  await _igdbPacingDelay();
  final indie = await _igdbTryGames(
    api,
    () => api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdIndie, limit: n),
    homeFallbackSlot: 4,
  );
  await _igdbPacingDelay();
  final horror = await _igdbTryGames(
    api,
    () => api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdHorror, limit: n),
    homeFallbackSlot: 5,
  );
  await _igdbPacingDelay();
  final multiplayer = await _igdbTryGames(
    api,
    () => api.fetchGamesMultiplayerPopular(limit: n),
    homeFallbackSlot: 6,
  );
  await _igdbPacingDelay();
  final rpg = await _igdbTryGames(
    api,
    () => api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdRpg, limit: n),
    homeFallbackSlot: 7,
  );
  await _igdbPacingDelay();
  final sports = await _igdbTryGames(
    api,
    () => api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdSports, limit: n),
    homeFallbackSlot: 8,
  );

  return IgdbGamesHomeFeedData(
    anticipated: anticipated,
    recentlyReleased: recentlyReleased,
    reviewsRecent: reviewsRecent,
    comingSoon: comingSoon,
    bestRated: bestRated,
    reviewsCritics: reviewsCritics,
    indie: indie,
    horror: horror,
    multiplayer: multiplayer,
    rpg: rpg,
    sports: sports,
  );
}

@riverpod
Future<Map<String, dynamic>?> igdbReviewById(
  IgdbReviewByIdRef ref,
  int reviewId,
) async {
  final api = ref.read(igdbApiProvider);
  return api.fetchReviewById(reviewId);
}

/// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
@riverpod
Future<List<Map<String, dynamic>>> igdbGamesSectionList(
  IgdbGamesSectionListRef ref,
  String slug,
) async {
  const gameLimit = 80;
  const reviewLimit = 50;
  final api = ref.read(igdbApiProvider);
  switch (slug) {
    case GamesFeedSection.popular:
      final raw = await api.fetchPopularGames(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.anticipated:
      final raw = await api.fetchGamesMostAnticipated(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.recentlyReleased:
      final raw = await api.fetchGamesRecentlyReleased(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.comingSoon:
      final raw = await api.fetchGamesComingSoon(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.reviewsRecent:
      final raw = await api.fetchReviewsRecent(limit: reviewLimit);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    case GamesFeedSection.reviewsCritics:
      final raw = await api.fetchReviewsHighScore(limit: reviewLimit);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    case GamesFeedSection.bestRated:
      final raw = await api.fetchGamesBestRated(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.indie:
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdIndie,
        limit: gameLimit,
      );
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.horror:
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdHorror,
        limit: gameLimit,
      );
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.multiplayer:
      final raw = await api.fetchGamesMultiplayerPopular(limit: gameLimit);
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.rpg:
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdRpg,
        limit: gameLimit,
      );
      return _normalizeGamesSafe(raw);
    case GamesFeedSection.sports:
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdSports,
        limit: gameLimit,
      );
      return _normalizeGamesSafe(raw);
    default:
      return [];
  }
}

const _favoriteGamesPrefsKey = 'favorite_games_v1';

List<Map<String, dynamic>> _decodeFavoriteGamesJson(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _snapshotGameForFavorites(Map<String, dynamic> game) {
  final title = game['title'] as Map<String, dynamic>? ?? {};
  final cover = game['coverImage'] as Map<String, dynamic>? ?? {};
  return {
    'id': game['id'],
    'title': {
      'english': title['english'],
      'romaji': title['romaji'],
    },
    'coverImage': {
      'large': cover['large'] ?? cover['extraLarge'],
    },
  };
}

/// Juegos marcados como favoritos (solo local, SharedPreferences).
@Riverpod(keepAlive: true)
class FavoriteGames extends _$FavoriteGames {
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteGamesJson(prefs.getString(_favoriteGamesPrefsKey));
  }

  Future<void> toggleFavorite(Map<String, dynamic> game) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final id = (game['id'] as num?)?.toInt();
    if (id == null) return;
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere((e) => (e['id'] as num?)?.toInt() == id);
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotGameForFavorites(game));
    }
    await prefs.setString(_favoriteGamesPrefsKey, jsonEncode(next));
    state = next;
  }
}

/// Estado de la cuenta Twitch vinculada a IGDB (OAuth de usuario).
class TwitchIgdbAccountState {
  const TwitchIgdbAccountState({
    required this.userConnected,
    this.login,
  });

  final bool userConnected;
  final String? login;
}

@Riverpod(keepAlive: true)
class TwitchIgdbAccount extends _$TwitchIgdbAccount {
  static const _oauthStatePrefsKey = 'twitch_oauth_state';

  @override
  Future<TwitchIgdbAccountState> build() async {
    final auth = ref.watch(igdbAuthProvider);
    return TwitchIgdbAccountState(
      userConnected: await auth.hasUserSession(),
      login: await auth.getUserLogin(),
    );
  }

  /// OAuth en navegador seguro; no disponible en web (IGDB no expone CORS ahí).
  Future<void> connectOAuth() async {
    if (kIsWeb) {
      throw UnsupportedError('web');
    }
    if (EnvConfig.twitchClientId.isEmpty ||
        EnvConfig.twitchClientSecret.isEmpty) {
      throw StateError('no_credentials');
    }
    final redirectRaw = EnvConfig.twitchRedirectUri.trim();
    if (redirectRaw.isEmpty) {
      throw StateError('no_redirect_uri');
    }
    Uri redirectParsed;
    try {
      redirectParsed = Uri.parse(redirectRaw);
    } catch (_) {
      throw StateError('invalid_redirect_uri');
    }
    if (redirectParsed.scheme != 'https') {
      throw StateError('redirect_must_be_https');
    }
    final auth = ref.read(igdbAuthProvider);
    final oauthState = const Uuid().v4();
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_oauthStatePrefsKey, oauthState);

    final uri = auth.buildAuthorizeUri(oauthState);
    final result = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: 'cronicle',
      options: const FlutterWebAuth2Options(
        intentFlags: ephemeralIntentFlags,
      ),
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
    invalidateIgdbProviders(ref);
    // No invalidar este mismo provider desde el notifier: puede provocar
    // rebuild reentrante y "A provider cannot depend on itself".
    final login = await auth.getUserLogin();
    state = AsyncData(
      TwitchIgdbAccountState(userConnected: true, login: login),
    );
  }

  Future<void> disconnectUser() async {
    await ref.read(igdbAuthProvider).clearUserSession();
    invalidateIgdbProviders(ref);
    state = const AsyncData(
      TwitchIgdbAccountState(userConnected: false, login: null),
    );
  }
}

void invalidateIgdbProviders(Ref ref) {
  ref.invalidate(igdbPopularProvider);
  ref.invalidate(igdbGamesHomeFeedProvider);
  ref.invalidate(igdbGamesSectionListProvider);
  ref.invalidate(igdbGameDetailProvider);
  ref.invalidate(igdbReviewByIdProvider);
  ref.invalidate(igdbSearchProvider);
}
