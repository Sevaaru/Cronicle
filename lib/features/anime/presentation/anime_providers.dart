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

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> anilistPopular(
  AnilistPopularRef ref,
  String type,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchPopular(type: type);
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
    userId: user['id'] as int?,
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
    likeCount: a['likeCount'] as int? ?? 0,
    replyCount: a['replyCount'] as int? ?? 0,
    isLiked: a['isLiked'] as bool? ?? false,
  );
}

@riverpod
class AnilistFeed extends _$AnilistFeed {
  static const _perPage = 15;
  int _animePage = 1;
  int _mangaPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _animePage = 1;
    _mangaPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final results = await Future.wait([
      graphql.fetchRecentActivityByType(
          activityType: 'ANIME_LIST', page: _animePage, perPage: _perPage, token: token),
      graphql.fetchRecentActivityByType(
          activityType: 'MANGA_LIST', page: _mangaPage, perPage: _perPage, token: token),
    ]);
    if (results[0].length < _perPage && results[1].length < _perPage) {
      _hasMore = false;
    }
    final items = [
      ...results[0].map(_mapActivity),
      ...results[1].map(_mapActivity),
    ];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _animePage++;
    _mangaPage++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (next.isEmpty) _hasMore = false;
      state = AsyncData([...prev, ...next]);
    } catch (_) {
      _animePage--;
      _mangaPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  void updateActivity(FeedActivity updated) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([
      for (final a in list)
        if (a.id == updated.id) updated else a,
    ]);
  }
}

@riverpod
class AnilistFeedByType extends _$AnilistFeedByType {
  static const _perPage = 15;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build(String activityType) async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final raw = await graphql.fetchRecentActivityByType(
      activityType: activityType,
      page: _page,
      perPage: _perPage,
      token: token,
    );
    if (raw.length < _perPage) _hasMore = false;
    return raw.map(_mapActivity).toList();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (next.isEmpty) _hasMore = false;
      state = AsyncData([...prev, ...next]);
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }

  void updateActivity(FeedActivity updated) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([
      for (final a in list)
        if (a.id == updated.id) updated else a,
    ]);
  }
}

@riverpod
class AnilistFeedFollowing extends _$AnilistFeedFollowing {
  static const _perPage = 15;
  int _animePage = 1;
  int _mangaPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _animePage = 1;
    _mangaPage = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) return [];
    final results = await Future.wait([
      graphql.fetchRecentActivityByType(
          activityType: 'ANIME_LIST', page: _animePage, perPage: _perPage, token: token, isFollowing: true),
      graphql.fetchRecentActivityByType(
          activityType: 'MANGA_LIST', page: _mangaPage, perPage: _perPage, token: token, isFollowing: true),
    ]);
    if (results[0].length < _perPage && results[1].length < _perPage) {
      _hasMore = false;
    }
    final items = [
      ...results[0].map(_mapActivity),
      ...results[1].map(_mapActivity),
    ];
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _animePage++;
    _mangaPage++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (next.isEmpty) _hasMore = false;
      state = AsyncData([...prev, ...next]);
    } catch (_) {
      _animePage--;
      _mangaPage--;
    } finally {
      _isLoadingMore = false;
    }
  }

  void updateActivity(FeedActivity updated) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData([
      for (final a in list)
        if (a.id == updated.id) updated else a,
    ]);
  }
}

@Riverpod(keepAlive: true)
Future<Map<String, dynamic>?> anilistMediaDetail(
  AnilistMediaDetailRef ref,
  int mediaId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchMediaDetail(mediaId);
}

/// Full Anilist user profile with statistics (requires auth).
@riverpod
Future<Map<String, dynamic>?> anilistProfile(AnilistProfileRef ref) async {
  final token = await ref.watch(anilistTokenProvider.future);
  if (token == null) return null;
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchViewerProfile(token);
}
