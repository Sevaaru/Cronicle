import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:riverpod/riverpod.dart' show AsyncData, Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import 'package:cronicle/core/cache/json_cache.dart';
import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/data/datasources/igdb_auth_datasource.dart';
import 'package:cronicle/features/games/data/games_feed_section.dart';

part 'game_providers.g.dart';

const String _igdbHomeFeedCacheKey = 'igdb_games_home_feed';
const String _igdbPopularCacheKey = 'igdb_games_popular';

List<Map<String, dynamic>> _normalizeGamesSafe(List<Map<String, dynamic>> raw) {
  final out = <Map<String, dynamic>>[];
  for (final m in raw) {
    try {
      out.add(IgdbApiDatasource.normalize(m));
    } catch (_) {}
  }
  return out;
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
  for (var attempt = 0; attempt < 2; attempt++) {
    if (attempt > 0) {
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }
    try {
      final raw = await fetch();
      return _filterReviewsWithGame(raw);
    } catch (_) {}
  }
  return [];
}

int _reviewCreatedAtSec(Map<String, dynamic> r) {
  final t = r['created_at'];
  if (t is int) return t;
  if (t is num) return t.toInt();
  return 0;
}

int _reviewScoreSafe(Map<String, dynamic> r) {
  final s = r['score'];
  if (s is int) return s;
  if (s is num) return s.toInt();
  return 0;
}

List<Map<String, dynamic>> _sortReviewsByCreatedDesc(
  List<Map<String, dynamic>> list,
) {
  final copy = List<Map<String, dynamic>>.from(list);
  copy.sort(
    (a, b) => _reviewCreatedAtSec(b).compareTo(_reviewCreatedAtSec(a)),
  );
  return copy;
}

List<Map<String, dynamic>> _sortReviewsByScoreDesc(
  List<Map<String, dynamic>> list,
) {
  final copy = List<Map<String, dynamic>>.from(list);
  copy.sort((a, b) {
    final sb = _reviewScoreSafe(b).compareTo(_reviewScoreSafe(a));
    if (sb != 0) return sb;
    return _reviewCreatedAtSec(b).compareTo(_reviewCreatedAtSec(a));
  });
  return copy;
}

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

  Map<String, dynamic> toJson() => {
        'anticipated': anticipated,
        'recentlyReleased': recentlyReleased,
        'reviewsRecent': reviewsRecent,
        'comingSoon': comingSoon,
        'bestRated': bestRated,
        'reviewsCritics': reviewsCritics,
        'indie': indie,
        'horror': horror,
        'multiplayer': multiplayer,
        'rpg': rpg,
        'sports': sports,
      };

  factory IgdbGamesHomeFeedData.fromJson(Map<String, dynamic> json) {
    return IgdbGamesHomeFeedData(
      anticipated: jsonListAsMaps(json['anticipated']),
      recentlyReleased: jsonListAsMaps(json['recentlyReleased']),
      reviewsRecent: jsonListAsMaps(json['reviewsRecent']),
      comingSoon: jsonListAsMaps(json['comingSoon']),
      bestRated: jsonListAsMaps(json['bestRated']),
      reviewsCritics: jsonListAsMaps(json['reviewsCritics']),
      indie: jsonListAsMaps(json['indie']),
      horror: jsonListAsMaps(json['horror']),
      multiplayer: jsonListAsMaps(json['multiplayer']),
      rpg: jsonListAsMaps(json['rpg']),
      sports: jsonListAsMaps(json['sports']),
    );
  }
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

@Riverpod(keepAlive: true)
class IgdbPopular extends _$IgdbPopular {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_igdbPopularCacheKey);
    final api = ref.read(igdbApiProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final raw = await api.fetchPopularGames(limit: 24);
          final norm = _normalizeGamesSafe(raw);
          await cache.write(_igdbPopularCacheKey, {'items': norm});
          state = AsyncData(norm);
        } catch (_) {}
      });
      return jsonListAsMaps(cached.data['items']);
    }

    final raw = await api.fetchPopularGames(limit: 24);
    final norm = _normalizeGamesSafe(raw);
    await cache.write(_igdbPopularCacheKey, {'items': norm});
    return norm;
  }
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

Future<IgdbGamesHomeFeedData> _fetchIgdbGamesHomeFeed(
  IgdbApiDatasource api,
) async {
  final results = await Future.wait([
    api.fetchHomeFeedGames(),
    _igdbTryReviews(api, () => api.fetchReviewsRecent(limit: 36)),
    _igdbTryReviews(api, () => api.fetchReviewsHighScore(limit: 24)),
  ]);

  final feed = results[0] as Map<String, List<Map<String, dynamic>>>;
  final reviewsRecent = results[1] as List<Map<String, dynamic>>;
  final reviewsCritics = results[2] as List<Map<String, dynamic>>;

  List<Map<String, dynamic>> rail(String key) =>
      _normalizeGamesSafe(feed[key] ?? []);

  return IgdbGamesHomeFeedData(
    anticipated: rail('anticipated'),
    recentlyReleased: rail('recentlyReleased'),
    comingSoon: rail('comingSoon'),
    bestRated: rail('bestRated'),
    indie: rail('indie'),
    horror: rail('horror'),
    multiplayer: rail('multiplayer'),
    rpg: rail('rpg'),
    sports: rail('sports'),
    reviewsRecent: _sortReviewsByCreatedDesc(reviewsRecent),
    reviewsCritics: _sortReviewsByScoreDesc(reviewsCritics),
  );
}

@Riverpod(keepAlive: true)
class IgdbGamesHomeFeed extends _$IgdbGamesHomeFeed {
  @override
  Future<IgdbGamesHomeFeedData> build() async {
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_igdbHomeFeedCacheKey);
    final api = ref.read(igdbApiProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final data = await _fetchIgdbGamesHomeFeed(api);
          await cache.write(_igdbHomeFeedCacheKey, data.toJson());
          state = AsyncData(data);
        } catch (_) {}
      });
      return IgdbGamesHomeFeedData.fromJson(cached.data);
    }

    final data = await _fetchIgdbGamesHomeFeed(api);
    await cache.write(_igdbHomeFeedCacheKey, data.toJson());
    return data;
  }
}

@riverpod
Future<Map<String, dynamic>?> igdbReviewById(
  IgdbReviewByIdRef ref,
  int reviewId,
) async {
  final api = ref.read(igdbApiProvider);
  return api.fetchReviewById(reviewId);
}

@riverpod
Future<List<Map<String, dynamic>>> igdbGamesSectionList(
  IgdbGamesSectionListRef ref,
  String slug,
) async {
  const gameLimit = 80;
  const reviewLimit = 50;
  final api = ref.read(igdbApiProvider);

  // Fallback: las funciones IGDB por-sección (`fetchGamesMostAnticipated`,
  // `fetchGamesRecentlyReleased`, `fetchGamesComingSoon`, `fetchGamesBestRated`,
  // `fetchGamesGenreSpotlight`, …) van a través de `_tryPostGameQueries`, que
  // se traga los errores y devuelve `[]`. Si la API rechaza esas queries
  // (p.ej. cambios en filtros como `category`/`hypes`), la pantalla "ver más"
  // se mostraba vacía aunque el carrusel del home tuviese ítems —ya que el
  // home se alimenta de un multiquery distinto (`fetchHomeFeedGames`).
  // Por eso, si la lista por-sección viene vacía, reutilizamos los ítems
  // que el home ya tiene cacheados para el mismo slug. Para Popular usamos
  // su propio provider, que tiene además el fallback vía
  // `popularity_primitives`.
  Future<List<Map<String, dynamic>>> homeFallback() async {
    try {
      if (slug == GamesFeedSection.popular) {
        return await ref.read(igdbPopularProvider.future);
      }
      final aside = await ref.read(igdbGamesHomeFeedProvider.future);
      return switch (slug) {
        GamesFeedSection.anticipated => aside.anticipated,
        GamesFeedSection.recentlyReleased => aside.recentlyReleased,
        GamesFeedSection.comingSoon => aside.comingSoon,
        GamesFeedSection.bestRated => aside.bestRated,
        GamesFeedSection.indie => aside.indie,
        GamesFeedSection.horror => aside.horror,
        GamesFeedSection.multiplayer => aside.multiplayer,
        GamesFeedSection.rpg => aside.rpg,
        GamesFeedSection.sports => aside.sports,
        GamesFeedSection.reviewsRecent => aside.reviewsRecent,
        GamesFeedSection.reviewsCritics => aside.reviewsCritics,
        _ => const <Map<String, dynamic>>[],
      };
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  Future<List<Map<String, dynamic>>> withFallback(
    Future<List<Map<String, dynamic>>> Function() primary,
  ) async {
    try {
      final list = await primary();
      if (list.isNotEmpty) return list;
    } catch (_) {}
    return homeFallback();
  }

  return switch (slug) {
    GamesFeedSection.popular => withFallback(
        () async => _normalizeGamesSafe(await api.fetchPopularGames(limit: gameLimit)),
      ),
    GamesFeedSection.anticipated => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesMostAnticipated(limit: gameLimit)),
      ),
    GamesFeedSection.recentlyReleased => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesRecentlyReleased(limit: gameLimit)),
      ),
    GamesFeedSection.comingSoon => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesComingSoon(limit: gameLimit)),
      ),
    GamesFeedSection.bestRated => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesBestRated(limit: gameLimit)),
      ),
    GamesFeedSection.indie => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdIndie, limit: gameLimit)),
      ),
    GamesFeedSection.horror => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdHorror, limit: gameLimit)),
      ),
    GamesFeedSection.multiplayer => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesMultiplayerPopular(limit: gameLimit)),
      ),
    GamesFeedSection.rpg => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdRpg, limit: gameLimit)),
      ),
    GamesFeedSection.sports => withFallback(
        () async => _normalizeGamesSafe(await api.fetchGamesGenreSpotlight(IgdbApiDatasource.genreIdSports, limit: gameLimit)),
      ),
    GamesFeedSection.reviewsRecent => withFallback(
        () => _igdbTryReviews(api, () => api.fetchReviewsRecent(limit: reviewLimit)),
      ),
    GamesFeedSection.reviewsCritics => withFallback(
        () => _igdbTryReviews(api, () => api.fetchReviewsHighScore(limit: reviewLimit)),
      ),
    _ => <Map<String, dynamic>>[],
  };
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

  Future<void> toggleSteamFavorite(
      int appId, String name, String coverUrl) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere(
        (e) => (e['steam_appid'] as num?)?.toInt() == appId);
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add({
        'id': null,
        'steam_appid': appId,
        'title': {'english': name, 'romaji': null},
        'coverImage': {'large': coverUrl},
      });
    }
    await prefs.setString(_favoriteGamesPrefsKey, jsonEncode(next));
    state = next;
  }
}

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
