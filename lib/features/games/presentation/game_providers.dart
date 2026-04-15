import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/features/games/data/datasources/igdb_auth_datasource.dart';

part 'game_providers.g.dart';

/// Datos agregados para la pestaña inicio de juegos (`/games`).
class IgdbGamesHomeData {
  const IgdbGamesHomeData({
    required this.popular,
    required this.anticipated,
    required this.recentlyReleased,
    required this.comingSoon,
    required this.reviewsRecent,
    required this.reviewsFeatured,
  });

  final List<Map<String, dynamic>> popular;
  final List<Map<String, dynamic>> anticipated;
  final List<Map<String, dynamic>> recentlyReleased;
  final List<Map<String, dynamic>> comingSoon;
  final List<Map<String, dynamic>> reviewsRecent;
  final List<Map<String, dynamic>> reviewsFeatured;
}

@Riverpod(keepAlive: true)
IgdbAuthDatasource igdbAuth(IgdbAuthRef ref) {
  return IgdbAuthDatasource(const FlutterSecureStorage(), ref.watch(dioProvider));
}

@Riverpod(keepAlive: true)
IgdbApiDatasource igdbApi(IgdbApiRef ref) {
  return IgdbApiDatasource(ref.watch(dioProvider), ref.watch(igdbAuthProvider));
}

@riverpod
Future<List<Map<String, dynamic>>> igdbSearch(
  IgdbSearchRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];
  final api = ref.read(igdbApiProvider);
  final raw = await api.searchGames(query);
  return raw.map(IgdbApiDatasource.normalize).toList();
}

/// AutoDispose so leaving Search and returning refetches trending (avoids stale empty).
@riverpod
Future<List<Map<String, dynamic>>> igdbPopular(IgdbPopularRef ref) async {
  final api = ref.read(igdbApiProvider);
  final raw = await api.fetchPopularGames();
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
  final normalized = IgdbApiDatasource.normalize(raw);
  try {
    final reviews = await api.fetchGameReviews(gameId);
    normalized['igdb_reviews'] = reviews;
  } catch (_) {
    normalized['igdb_reviews'] = <Map<String, dynamic>>[];
  }
  return normalized;
}

@riverpod
Future<IgdbGamesHomeData> igdbGamesHome(IgdbGamesHomeRef ref) async {
  final api = ref.read(igdbApiProvider);
  final popularRaw = api.fetchPopularGames(limit: 24);
  final anticipatedRaw = api.fetchGamesMostAnticipated(limit: 24);
  final releasedRaw = api.fetchGamesRecentlyReleased(limit: 24);
  final soonRaw = api.fetchGamesComingSoon(limit: 24);
  final reviewsRaw = api.fetchReviewsRecent(limit: 36);
  final featuredRaw = api.fetchReviewsHighScore(limit: 24);

  final results = await Future.wait<List<Map<String, dynamic>>>([
    popularRaw,
    anticipatedRaw,
    releasedRaw,
    soonRaw,
    reviewsRaw,
    featuredRaw,
  ]);

  return IgdbGamesHomeData(
    popular: results[0].map(IgdbApiDatasource.normalize).toList(),
    anticipated: results[1].map(IgdbApiDatasource.normalize).toList(),
    recentlyReleased: results[2].map(IgdbApiDatasource.normalize).toList(),
    comingSoon: results[3].map(IgdbApiDatasource.normalize).toList(),
    reviewsRecent: results[4],
    reviewsFeatured: results[5],
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
