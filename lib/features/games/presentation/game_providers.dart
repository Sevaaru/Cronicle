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

part 'game_providers.g.dart';

/// Carruseles del home IGDB excepto “Popular” (ese va en [igdbPopularProvider]).
class IgdbGamesHomeAsideData {
  const IgdbGamesHomeAsideData({
    required this.anticipated,
    required this.recentlyReleased,
    required this.comingSoon,
    required this.reviewsRecent,
    required this.reviewsFeatured,
    required this.bestRated,
    required this.indiePicks,
    required this.horrorPicks,
    required this.multiplayerHits,
  });

  final List<Map<String, dynamic>> anticipated;
  final List<Map<String, dynamic>> recentlyReleased;
  final List<Map<String, dynamic>> comingSoon;
  final List<Map<String, dynamic>> reviewsRecent;
  final List<Map<String, dynamic>> reviewsFeatured;
  final List<Map<String, dynamic>> bestRated;
  final List<Map<String, dynamic>> indiePicks;
  final List<Map<String, dynamic>> horrorPicks;
  final List<Map<String, dynamic>> multiplayerHits;
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
  return raw.map(IgdbApiDatasource.normalize).toList();
}

/// Popular (PopScore + mismo listado que el carrusel “Popular ahora”).
@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> igdbPopular(IgdbPopularRef ref) async {
  final api = ref.read(igdbApiProvider);
  final raw = await api.fetchPopularGames(limit: 24);
  return raw.map(IgdbApiDatasource.normalize).toList();
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

/// Resto del home juegos en paralelo (Popular va aparte para pintarse antes).
@Riverpod(keepAlive: true)
Future<IgdbGamesHomeAsideData> igdbGamesHomeAside(IgdbGamesHomeAsideRef ref) async {
  final api = ref.read(igdbApiProvider);
  final anticipatedRaw = api.fetchGamesMostAnticipated(limit: 24);
  final releasedRaw = api.fetchGamesRecentlyReleased(limit: 24);
  final soonRaw = api.fetchGamesComingSoon(limit: 24);
  final reviewsRaw = api.fetchReviewsRecent(limit: 36);
  final featuredRaw = api.fetchReviewsHighScore(limit: 24);
  final bestRatedRaw = api.fetchGamesBestRated(limit: 24);
  final indieRaw = api.fetchGamesGenreSpotlight(
    IgdbApiDatasource.genreIdIndie,
    limit: 24,
  );
  final horrorRaw = api.fetchGamesGenreSpotlight(
    IgdbApiDatasource.genreIdHorror,
    limit: 24,
  );
  final mpRaw = api.fetchGamesMultiplayerPopular(limit: 24);

  final results = await Future.wait<List<Map<String, dynamic>>>([
    anticipatedRaw,
    releasedRaw,
    soonRaw,
    reviewsRaw,
    featuredRaw,
    bestRatedRaw,
    indieRaw,
    horrorRaw,
    mpRaw,
  ]);

  return IgdbGamesHomeAsideData(
    anticipated: results[0].map(IgdbApiDatasource.normalize).toList(),
    recentlyReleased: results[1].map(IgdbApiDatasource.normalize).toList(),
    comingSoon: results[2].map(IgdbApiDatasource.normalize).toList(),
    reviewsRecent: results[3],
    reviewsFeatured: results[4],
    bestRated: results[5].map(IgdbApiDatasource.normalize).toList(),
    indiePicks: results[6].map(IgdbApiDatasource.normalize).toList(),
    horrorPicks: results[7].map(IgdbApiDatasource.normalize).toList(),
    multiplayerHits: results[8].map(IgdbApiDatasource.normalize).toList(),
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
    case 'popular':
      final raw = await api.fetchPopularGames(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'anticipated':
      final raw = await api.fetchGamesMostAnticipated(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'recently-released':
      final raw = await api.fetchGamesRecentlyReleased(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'coming-soon':
      final raw = await api.fetchGamesComingSoon(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'reviews-recent':
      final raw = await api.fetchReviewsRecent(limit: reviewLimit);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    case 'reviews-critics':
      final raw = await api.fetchReviewsHighScore(limit: reviewLimit);
      return raw
          .where((r) => (r['game'] as Map<String, dynamic>?) != null)
          .toList();
    case 'best-rated':
      final raw = await api.fetchGamesBestRated(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'indie':
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdIndie,
        limit: gameLimit,
      );
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'horror':
      final raw = await api.fetchGamesGenreSpotlight(
        IgdbApiDatasource.genreIdHorror,
        limit: gameLimit,
      );
      return raw.map(IgdbApiDatasource.normalize).toList();
    case 'multiplayer':
      final raw = await api.fetchGamesMultiplayerPopular(limit: gameLimit);
      return raw.map(IgdbApiDatasource.normalize).toList();
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
  ref.invalidate(igdbGamesHomeAsideProvider);
  ref.invalidate(igdbGamesSectionListProvider);
  ref.invalidate(igdbGameDetailProvider);
  ref.invalidate(igdbReviewByIdProvider);
  ref.invalidate(igdbSearchProvider);
}
