import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';

part 'anime_providers.g.dart';

@Riverpod(keepAlive: true)
AnilistAuthDatasource anilistAuth(AnilistAuthRef ref) {
  return AnilistAuthDatasource(const FlutterSecureStorage());
}

@Riverpod(keepAlive: true)
AnilistGraphqlDatasource anilistGraphql(AnilistGraphqlRef ref) {
  return AnilistGraphqlDatasource(ref.watch(dioProvider));
}

@riverpod
class AnilistToken extends _$AnilistToken {
  @override
  Future<String?> build() async {
    return ref.read(anilistAuthProvider).getToken();
  }

  Future<void> setToken(String token) async {
    await ref.read(anilistAuthProvider).saveToken(token);
    state = AsyncData(token);
  }

  Future<void> clearToken() async {
    await ref.read(anilistAuthProvider).deleteToken();
    state = const AsyncData(null);
  }
}

@riverpod
Future<List<Map<String, dynamic>>> animeSearch(
  AnimeSearchRef ref,
  String query,
) async {
  if (query.trim().isEmpty) return [];
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.searchAnime(query);
}

@riverpod
Future<List<Map<String, dynamic>>> anilistSearch(
  AnilistSearchRef ref,
  String query,
  String type,
) async {
  if (query.trim().isEmpty) return [];
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.searchMedia(query, type: type);
}

FeedActivity _mapActivity(Map<String, dynamic> a) {
  final media = a['media'] as Map<String, dynamic>;
  final user = a['user'] as Map<String, dynamic>;
  final title = media['title'] as Map<String, dynamic>? ?? {};
  final avatar = user['avatar'] as Map<String, dynamic>? ?? {};
  final coverImage = media['coverImage'] as Map<String, dynamic>? ?? {};

  final mediaType = media['type'] as String?;
  final kind = mediaType == 'MANGA' ? MediaKind.manga : MediaKind.anime;

  String action = (a['status'] as String? ?? 'updated');
  final progress = a['progress'] as String?;
  if (progress != null) action = '$action $progress';

  return FeedActivity(
    id: a['id'].toString(),
    source: kind,
    userName: user['name'] as String? ?? '',
    userAvatarUrl: avatar['medium'] as String?,
    action: action,
    mediaTitle: (title['english'] as String?) ??
        (title['romaji'] as String?) ??
        'Unknown',
    mediaPosterUrl: coverImage['large'] as String?,
    mediaId: media['id'] as int?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(
      ((a['createdAt'] as int?) ?? 0) * 1000,
    ),
  );
}

@riverpod
Future<List<FeedActivity>> anilistFeed(AnilistFeedRef ref) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final animeRaw = await graphql.fetchRecentActivityByType(
      activityType: 'ANIME_LIST', perPage: 20);
  final mangaRaw = await graphql.fetchRecentActivityByType(
      activityType: 'MANGA_LIST', perPage: 20);

  final all = [
    ...animeRaw.map(_mapActivity),
    ...mangaRaw.map(_mapActivity),
  ];
  all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return all;
}

@riverpod
Future<List<FeedActivity>> anilistFeedByType(
  AnilistFeedByTypeRef ref,
  String activityType,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final raw = await graphql.fetchRecentActivityByType(
    activityType: activityType,
    perPage: 30,
  );
  return raw.map(_mapActivity).toList();
}

@riverpod
Future<Map<String, dynamic>?> anilistMediaDetail(
  AnilistMediaDetailRef ref,
  int mediaId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchMediaDetail(mediaId);
}
