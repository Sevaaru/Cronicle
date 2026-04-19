import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
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
    try {
      final viewer =
          await ref.read(anilistGraphqlProvider).fetchViewer(token);
      final name = viewer?['name'] as String?;
      if (name != null && name.isNotEmpty) {
        await ref.read(anilistAuthProvider).saveUserName(name);
      }
      // Auto-set scoring format from AniList account.
      final opts = viewer?['mediaListOptions'] as Map<String, dynamic>?;
      final fmt = opts?['scoreFormat'] as String?;
      if (fmt != null) {
        final system = ScoringSystem.fromId(fmt);
        await ref.read(scoringSystemSettingProvider.notifier).set(system);
      }
    } catch (_) {}
    state = AsyncData(token);
    unawaited(
      ref
          .read(favoriteAnilistMediaProvider.notifier)
          .pushPendingFavoritesToAnilist(token),
    );
  }

  Future<void> clearToken() async {
    await ref.read(anilistAuthProvider).deleteToken();
    state = const AsyncData(null);
  }

  /// OAuth implícito vía HTTPS puente + `cronicle://anilist-oauth` (Android/iOS, navegador externo).
  Future<void> connectOAuthBridge() async {
    if (kIsWeb) {
      throw UnsupportedError('web');
    }
    if (!AnilistAuthDatasource.usesHttpsImplicitBridge) {
      throw StateError('not_configured');
    }
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      throw UnsupportedError('mobile_only');
    }
    final auth = ref.read(anilistAuthProvider);
    final uri = Uri.parse(auth.authorizeUrl);
    final token = await _anilistOAuthAccessToken(uri);
    await setToken(token);
  }
}

Future<String> _anilistOAuthAccessToken(Uri authUri) async {
  final appLinks = AppLinks();
  final completer = Completer<String>();

  void completeIfMatch(Uri u) {
    if (u.scheme != 'cronicle' || u.host != 'anilist-oauth') return;
    final t = u.queryParameters['access_token'];
    if (t != null && t.isNotEmpty && !completer.isCompleted) {
      completer.complete(t);
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

/// Anilist home browse: [type] `ANIME`/`MANGA`, [category]
/// `seasonal`/`trending`/`top_rated`/`upcoming`/`recently_released`/`popularity`/`start_date`.
@riverpod
class AnilistBrowseMedia extends _$AnilistBrowseMedia {
  static const _perPage = 24;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<Map<String, dynamic>>> build(String type, String category) async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    final graphql = ref.read(anilistGraphqlProvider);
    final page = await graphql.fetchBrowseMedia(
      type: type,
      category: category,
      page: 1,
      perPage: _perPage,
    );
    _hasMore = page.hasNextPage;
    return page.items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    final graphql = ref.read(anilistGraphqlProvider);
    try {
      final page = await graphql.fetchBrowseMedia(
        type: type,
        category: category,
        page: _page,
        perPage: _perPage,
      );
      _hasMore = page.hasNextPage;
      final seen = prev.map((m) => (m['id'] as num).toInt()).toSet();
      final appended = [
        ...prev,
        ...page.items.where((m) => !seen.contains((m['id'] as num).toInt())),
      ];
      state = AsyncData(appended);
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

/// Convierte una actividad Anilist (mapa GraphQL) en [FeedActivity] para la UI del feed.
FeedActivity? feedActivityFromAnilistActivityMap(Map<String, dynamic> a) {
  final actType = a['type'] as String? ?? '';

  if (actType == 'TEXT') {
    final user = a['user'] as Map<String, dynamic>? ?? {};
    final avatar = user['avatar'] as Map<String, dynamic>? ?? {};
    final rawText = a['text'] as String? ?? '';
    return FeedActivity(
      id: a['id'].toString(),
      source: MediaKind.anime,
      userName: user['name'] as String? ?? '',
      userId: user['id'] as int?,
      userAvatarUrl: avatar['medium'] as String?,
      action: '',
      mediaTitle: rawText,
      mediaId: null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        ((a['createdAt'] as int?) ?? 0) * 1000,
      ),
      likeCount: a['likeCount'] as int? ?? 0,
      replyCount: a['replyCount'] as int? ?? 0,
      isLiked: a['isLiked'] as bool? ?? false,
      isTextActivity: true,
    );
  }

  final media = a['media'] as Map<String, dynamic>?;
  if (media == null) return null;
  final user = a['user'] as Map<String, dynamic>? ?? {};
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
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    final page = await graphql.fetchRecentActivityByType(
      activityType: null,
      page: _page,
      perPage: _perPage,
      token: token,
    );
    _hasMore = page.hasNextPage;
    final items = page.items
        .map(feedActivityFromAnilistActivityMap)
        .whereType<FeedActivity>()
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
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
    final page = await graphql.fetchRecentActivityByType(
      activityType: activityType,
      page: _page,
      perPage: _perPage,
      token: token,
    );
    _hasMore = page.hasNextPage;
    return page.items
        .map(feedActivityFromAnilistActivityMap)
        .whereType<FeedActivity>()
        .toList();
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
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
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) {
      _hasMore = false;
      return [];
    }
    final page = await graphql.fetchRecentActivityByType(
      activityType: null,
      page: _page,
      perPage: _perPage,
      token: token,
      isFollowing: true,
    );
    _hasMore = page.hasNextPage;
    final items = page.items
        .map(feedActivityFromAnilistActivityMap)
        .whereType<FeedActivity>()
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
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
class AnilistSocialFeed extends _$AnilistSocialFeed {
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build(
    String? activityType,
    bool isFollowing,
  ) async {
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    return _fetchPage();
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    if (isFollowing && token == null) {
      _hasMore = false;
      return [];
    }
    final page = await graphql.fetchRecentActivityByType(
      activityType: activityType,
      page: _page,
      perPage: _perPage,
      token: token,
      isFollowing: isFollowing,
    );
    _hasMore = page.hasNextPage;
    final items = page.items
        .map(feedActivityFromAnilistActivityMap)
        .whereType<FeedActivity>()
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
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

/// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
@riverpod
class AnilistGenreTagBrowse extends _$AnilistGenreTagBrowse {
  static const _perPage = 24;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  late String _mediaType;
  late String _sortKey;
  String? _genre;
  String? _tag;

  bool get hasMore => _hasMore;

  @override
  Future<List<Map<String, dynamic>>> build(
    String mediaType,
    String sortKey,
    String genrePart,
    String tagPart,
  ) async {
    _mediaType = mediaType;
    _sortKey = sortKey;
    _genre = genrePart.isEmpty ? null : genrePart;
    _tag = tagPart.isEmpty ? null : tagPart;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    final graphql = ref.read(anilistGraphqlProvider);
    final page = await graphql.fetchMediaByGenreTagPage(
      type: _mediaType,
      sortKey: _sortKey,
      genre: _genre,
      tag: _tag,
      page: 1,
      perPage: _perPage,
    );
    _hasMore = page.hasNextPage;
    return page.items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    _page++;
    final prev = state.valueOrNull ?? [];
    final graphql = ref.read(anilistGraphqlProvider);
    try {
      final page = await graphql.fetchMediaByGenreTagPage(
        type: _mediaType,
        sortKey: _sortKey,
        genre: _genre,
        tag: _tag,
        page: _page,
        perPage: _perPage,
      );
      if (!page.hasNextPage) _hasMore = false;
      if (page.items.isEmpty) _hasMore = false;
      final seen = prev.map((m) => m['id'] as int).toSet();
      final appended = [
        ...prev,
        ...page.items.where((m) => !seen.contains(m['id'] as int)),
      ];
      state = AsyncData(appended);
    } catch (_) {
      _page--;
    } finally {
      _isLoadingMore = false;
    }
  }
}

@Riverpod(keepAlive: true)
Future<Map<String, dynamic>?> anilistMediaDetail(
  AnilistMediaDetailRef ref,
  int mediaId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  return graphql.fetchMediaDetail(mediaId, token: token);
}

/// Full Anilist user profile with statistics (requires auth).
@riverpod
Future<Map<String, dynamic>?> anilistProfile(AnilistProfileRef ref) async {
  final token = await ref.watch(anilistTokenProvider.future);
  if (token == null) return null;
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchViewerProfile(token);
}

@riverpod
Future<List<Map<String, dynamic>>> anilistMediaThreads(
  AnilistMediaThreadsRef ref,
  int mediaId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  return graphql.fetchMediaThreads(mediaId);
}

@riverpod
Future<Map<String, dynamic>?> anilistForumThread(
  AnilistForumThreadRef ref,
  int threadId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.read(anilistTokenProvider.future);
  return graphql.fetchForumThread(threadId, token: token);
}

/// Unread Anilist notification count (0 if not logged in).
@riverpod
Future<int> anilistUnreadNotificationCount(
  AnilistUnreadNotificationCountRef ref,
) async {
  final token = await ref.watch(anilistTokenProvider.future);
  if (token == null) return 0;
  final graphql = ref.read(anilistGraphqlProvider);
  return await graphql.fetchUnreadNotificationCount(token) ?? 0;
}

/// First page of Anilist notifications; [resetNotificationCount] clears unread on Anilist.
@riverpod
Future<List<Map<String, dynamic>>> anilistNotificationsList(
  AnilistNotificationsListRef ref,
) async {
  final token = await ref.watch(anilistTokenProvider.future);
  if (token == null) return [];
  final graphql = ref.read(anilistGraphqlProvider);
  final list = await graphql.fetchNotifications(
    token: token,
    page: 1,
    perPage: 30,
    resetNotificationCount: true,
  );
  ref.invalidate(anilistUnreadNotificationCountProvider);
  return list;
}

// ---------------------------------------------------------------------------
// Favoritos anime/manga (local sin sesión; al conectar Anilist se suben a la API)
// ---------------------------------------------------------------------------

const _favoriteAnilistPrefsKey = 'favorite_anilist_media_v1';

List<Map<String, dynamic>> _decodeFavoriteAnilistJson(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _snapshotAnilistMediaForFavorites(Map<String, dynamic> media) {
  final title = media['title'] as Map<String, dynamic>? ?? {};
  final cover = media['coverImage'] as Map<String, dynamic>? ?? {};
  final id = media['id'];
  final type = ((media['type'] as String?) ?? 'ANIME').toUpperCase();
  return {
    'id': id is int ? id : (id as num?)?.toInt(),
    'type': type,
    'title': {
      'english': title['english'],
      'romaji': title['romaji'],
    },
    'coverImage': {
      'large': cover['large'] ?? cover['extraLarge'],
    },
  };
}

/// Une los nodos del perfil Anilist con favoritos guardados solo en local.
List<Map<String, dynamic>> mergeAnilistFavoriteApiNodesWithLocal({
  required List<dynamic> apiNodes,
  required List<Map<String, dynamic>> localSnapshots,
  required String mediaTypeUpper,
}) {
  final want = mediaTypeUpper.toUpperCase();
  final out = <Map<String, dynamic>>[
    ...apiNodes.map((e) => Map<String, dynamic>.from(e as Map)),
  ];
  final seen = out.map((m) => m['id']).whereType<int>().toSet();
  for (final loc in localSnapshots) {
    final t = (loc['type'] as String? ?? 'ANIME').toUpperCase();
    if (t != want) continue;
    final id = (loc['id'] as num?)?.toInt();
    if (id == null || id <= 0 || seen.contains(id)) continue;
    out.add(Map<String, dynamic>.from(loc));
    seen.add(id);
  }
  return out;
}

@Riverpod(keepAlive: true)
class FavoriteAnilistMedia extends _$FavoriteAnilistMedia {
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteAnilistJson(prefs.getString(_favoriteAnilistPrefsKey));
  }

  bool hasFavorite(int mediaId, String mediaType) {
    final want = mediaType.toUpperCase();
    return state.any((e) {
      final id = (e['id'] as num?)?.toInt() ?? 0;
      final t = (e['type'] as String? ?? 'ANIME').toUpperCase();
      return id == mediaId && t == want;
    });
  }

  Future<void> _persist(List<Map<String, dynamic>> next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_favoriteAnilistPrefsKey, jsonEncode(next));
    state = next;
  }

  /// Añade o quita favorito solo en dispositivo (sin token Anilist).
  Future<void> toggleLocalFavorite(Map<String, dynamic> media) async {
    final id = (media['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;
    final type = ((media['type'] as String?) ?? 'ANIME').toUpperCase();
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere((e) {
      final eid = (e['id'] as num?)?.toInt() ?? 0;
      final et = (e['type'] as String? ?? 'ANIME').toUpperCase();
      return eid == id && et == type;
    });
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotAnilistMediaForFavorites(media));
    }
    await _persist(next);
  }

  Future<void> removeFavorite(int mediaId, String mediaType) async {
    final want = mediaType.toUpperCase();
    final next = state.where((e) {
      final eid = (e['id'] as num?)?.toInt() ?? 0;
      final et = (e['type'] as String? ?? 'ANIME').toUpperCase();
      return !(eid == mediaId && et == want);
    }).toList();
    if (next.length == state.length) return;
    await _persist(next);
  }

  /// Tras iniciar sesión: favoritos locales que no estén en Anilist se envían con [ToggleFavourite].
  Future<void> pushPendingFavoritesToAnilist(String token) async {
    final graphql = ref.read(anilistGraphqlProvider);
    final pending = List<Map<String, dynamic>>.from(state);
    if (pending.isEmpty) return;
    final touchedIds = <int>{};
    for (final item in pending) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null || id <= 0) continue;
      final type = (item['type'] as String? ?? 'ANIME').toUpperCase();
      try {
        final detail = await graphql.fetchMediaDetail(id, token: token);
        if (detail == null) continue;
        final onServer = detail['isFavourite'] as bool? ?? false;
        if (!onServer) {
          await graphql.toggleFavouriteMedia(
            mediaId: id,
            mediaType: type,
            token: token,
          );
        }
        await removeFavorite(id, type);
        touchedIds.add(id);
      } catch (_) {
        // Mantener en local para reintentar más tarde.
      }
    }
    for (final id in touchedIds) {
      ref.invalidate(anilistMediaDetailProvider(id));
    }
    ref.invalidate(anilistProfileProvider);
  }
}
