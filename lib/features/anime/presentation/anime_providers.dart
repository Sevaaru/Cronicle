import 'dart:async';
import 'dart:convert';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart'
  show kIsWeb, defaultTargetPlatform, TargetPlatform, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/cache/json_cache.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/anime/presentation/anilist_feed_cache.dart';
import 'package:cronicle/features/settings/presentation/app_defaults_notifier.dart';
import 'package:cronicle/shared/models/feed_activity.dart';
import 'package:cronicle/shared/models/media_kind.dart';

part 'anime_providers.g.dart';

String _anilistPopularCacheKey(String type) =>
    'anilist_popular_${type.toUpperCase()}';
const String _anilistProfileCacheKey = 'anilist_profile';
String _anilistMediaDetailCacheKey(int id) => 'anilist_media_$id';
String _anilistCharacterDetailCacheKey(int id) => 'anilist_character_$id';
String _anilistStaffDetailCacheKey(int id) => 'anilist_staff_$id';
String _anilistMediaThreadsCacheKey(int id) => 'anilist_media_threads_$id';
String _anilistForumThreadCacheKey(int id) => 'anilist_forum_thread_$id';
String _anilistBrowseMediaCacheKey(String type, String category) =>
    'anilist_browse_${type}_$category';

// Stale-while-revalidate freshness windows. Anilist data for a single
// media/character/staff entity changes very rarely (cover art, description,
// favorite count) so we can serve cached copies aggressively to slash the
// rate-limit footprint of opening detail pages over and over.
const Duration _anilistMediaDetailFreshness = Duration(hours: 2);
const Duration _anilistCharacterDetailFreshness = Duration(hours: 24);
const Duration _anilistStaffDetailFreshness = Duration(hours: 24);
const Duration _anilistMediaThreadsFreshness = Duration(hours: 6);
const Duration _anilistForumThreadFreshness = Duration(minutes: 10);
const Duration _anilistBrowseMediaFreshness = Duration(hours: 6);

/// Stale-while-revalidate helper for `Map<String, dynamic>?` detail fetches.
/// If the cache is fresh, returns it without touching the network. If the
/// cache is stale or missing, performs the fetch; on network failure the
/// stale entry (if any) is returned so the UI keeps working offline.
Future<Map<String, dynamic>?> _staleWhileRevalidateMap({
  required JsonCache cache,
  required String key,
  required Duration freshness,
  required Future<Map<String, dynamic>?> Function() fetch,
}) async {
  final cached = cache.read(key);
  if (cached != null && cache.isFresh(cached.fetchedAt, freshness)) {
    return cached.data;
  }
  try {
    final fresh = await fetch();
    if (fresh != null) {
      await cache.write(key, fresh);
      return fresh;
    }
  } catch (e) {
    if (cached != null) return cached.data;
    rethrow;
  }
  return cached?.data;
}

/// Same as [_staleWhileRevalidateMap] but for endpoints that return a list.
/// Wraps the list under an `items` key for storage.
Future<List<Map<String, dynamic>>> _staleWhileRevalidateList({
  required JsonCache cache,
  required String key,
  required Duration freshness,
  required Future<List<Map<String, dynamic>>> Function() fetch,
}) async {
  final cached = cache.read(key);
  if (cached != null && cache.isFresh(cached.fetchedAt, freshness)) {
    return jsonListAsMaps(cached.data['items']);
  }
  try {
    final fresh = await fetch();
    await cache.write(key, {'items': fresh});
    return fresh;
  } catch (e) {
    if (cached != null) return jsonListAsMaps(cached.data['items']);
    rethrow;
  }
}

/// Optimistically updates a single field on a cached detail map. Used when
/// we know the server-side change (e.g. toggled favourite) so the next read
/// from cache reflects the new state without a round-trip refetch.
Future<void> _patchCachedDetail(
  JsonCache cache,
  String key,
  Map<String, dynamic> patch,
) async {
  final cached = cache.read(key);
  if (cached == null) return;
  await cache.write(key, {...cached.data, ...patch});
}

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
      final opts = viewer?['mediaListOptions'] as Map<String, dynamic>?;
      final fmt = opts?['scoreFormat'] as String?;
      if (fmt != null) {
        final system = ScoringSystem.fromId(fmt);
        await ref.read(scoringSystemSettingProvider.notifier).set(system);
      }
    } catch (_) {}
    state = AsyncData(token);
    _invalidateSessionScopedProviders();
    unawaited(
      ref
          .read(favoriteAnilistMediaProvider.notifier)
          .pushPendingFavoritesToAnilist(token),
    );
    unawaited(
      ref
          .read(favoriteAnilistCharactersProvider.notifier)
          .pushPendingFavoritesToAnilist(token),
    );
    unawaited(
      ref
          .read(favoriteAnilistStaffProvider.notifier)
          .pushPendingFavoritesToAnilist(token),
    );
  }

  Future<void> clearToken() async {
    await ref.read(anilistAuthProvider).deleteToken();
    state = const AsyncData(null);
    _invalidateSessionScopedProviders();
  }

  void _invalidateSessionScopedProviders() {
    // Al cambiar login limpiamos cache de providers para evitar datos viejos.
    ref.invalidate(anilistProfileProvider);
    ref.invalidate(anilistMediaDetailProvider);
    ref.invalidate(anilistForumThreadProvider);
    ref.invalidate(anilistCharacterDetailProvider);
    ref.invalidate(anilistStaffDetailProvider);
    ref.invalidate(anilistFeedProvider);
    ref.invalidate(anilistFeedFollowingProvider);
    ref.invalidate(anilistFeedByTypeProvider);
    ref.invalidate(anilistSocialFeedProvider);
    ref.invalidate(anilistUnreadNotificationCountProvider);
    ref.invalidate(anilistNotificationsListProvider);
    ref.invalidate(favoriteAnilistCharactersProvider);
    ref.invalidate(favoriteAnilistStaffProvider);
  }

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
class AnilistPopular extends _$AnilistPopular {
  @override
  Future<List<Map<String, dynamic>>> build(String type) async {
    final cache = ref.read(jsonCacheProvider);
    final cacheKey = _anilistPopularCacheKey(type);
    final cached = cache.read(cacheKey);
    final graphql = ref.read(anilistGraphqlProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final fresh = await graphql.fetchPopular(type: type);
          await cache.write(cacheKey, {'items': fresh});
          state = AsyncData(fresh);
        } catch (_) {}
      });
      return jsonListAsMaps(cached.data['items']);
    }

    final fresh = await graphql.fetchPopular(type: type);
    await cache.write(cacheKey, {'items': fresh});
    return fresh;
  }
}

@Riverpod(keepAlive: true)
class AnilistBrowseMedia extends _$AnilistBrowseMedia {
  static const _perPage = 24;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

  bool get hasMore => _hasMore;

  @override
  Future<List<Map<String, dynamic>>> build(String type, String category) async {
    _generation++;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    final graphql = ref.read(anilistGraphqlProvider);
    final cache = ref.read(jsonCacheProvider);
    final cacheKey = _anilistBrowseMediaCacheKey(type, category);
    final cached = cache.read(cacheKey);
    if (cached != null &&
        cache.isFresh(cached.fetchedAt, _anilistBrowseMediaFreshness)) {
      _hasMore = (cached.data['hasMore'] as bool?) ?? false;
      return jsonListAsMaps(cached.data['items']);
    }
    final page = await graphql.fetchBrowseMedia(
      type: type,
      category: category,
      page: 1,
      perPage: _perPage,
    );
    _hasMore = page.hasNextPage;
    await cache.write(cacheKey, {
      'items': page.items,
      'hasMore': page.hasNextPage,
    });
    return page.items;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    // Si llega una respuesta vieja, la descartamos con generation.
    final generation = _generation;
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
      if (generation != _generation) return;
      _hasMore = page.hasNextPage;
      final seen = prev.map((m) => (m['id'] as num).toInt()).toSet();
      final appended = [
        ...prev,
        ...page.items.where((m) => !seen.contains((m['id'] as num).toInt())),
      ];
      state = AsyncData(appended);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] Browse loadMore failed ($type/$category): $e');
    } finally {
      _isLoadingMore = false;
    }
  }
}

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

@Riverpod(keepAlive: true)
class AnilistFeed extends _$AnilistFeed {
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _generation++;
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
    final generation = _generation;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (generation != _generation) return;
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] Feed loadMore failed: $e');
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
class AnilistFeedByType extends _$AnilistFeedByType {
  static const _perPage = 15;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build(String activityType) async {
    _generation++;
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
    final generation = _generation;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (generation != _generation) return;
      state = AsyncData([...prev, ...next]);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] FeedByType loadMore failed ($activityType): $e');
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
class AnilistFeedFollowing extends _$AnilistFeedFollowing {
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build() async {
    _generation++;
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
    final generation = _generation;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (generation != _generation) return;
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] Following feed loadMore failed: $e');
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
class AnilistSocialFeed extends _$AnilistSocialFeed {
  static const _perPage = 25;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;
  DateTime? _lastFetchedAt;

  bool get hasMore => _hasMore;

  @override
  Future<List<FeedActivity>> build(
    String? activityType,
    bool isFollowing,
  ) async {
    _generation++;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;

    final cache = AnilistFeedCache(ref.read(sharedPreferencesProvider));
    final cached = cache.read(activityType, isFollowing);
    if (cached != null) {
      _lastFetchedAt = cached.fetchedAt;
      if (cache.isFresh(cached.fetchedAt) && cached.items.isNotEmpty) {
        debugPrint(
          '[AniList] Social feed (type=$activityType, foll=$isFollowing) '
          'sirviendo desde caché fresca (${cached.items.length} ítems).',
        );
        return cached.items;
      }
      if (cached.items.isNotEmpty) {
        final generation = _generation;
        scheduleMicrotask(() async {
          try {
            final fresh = await _fetchPage();
            if (generation != _generation) return;
            // Bug-guard: AniList ocasionalmente devuelve `activities: []`
            // (rate-limit suave, hipo del backend, carrera con el refresh
            // del token, etc.). Si teníamos ítems en caché, NO sobreescribir
            // el estado ni la caché con una lista vacía: provocaba que el
            // feed de "Siguiendo" se vaciara y mostrara "no hay actividad
            // reciente" hasta reiniciar la app.
            if (fresh.isEmpty && cached.items.isNotEmpty) {
              debugPrint(
                '[AniList] Social feed (type=$activityType, '
                'foll=$isFollowing) refresh devolvió 0 ítems; '
                'manteniendo caché previa de ${cached.items.length}.',
              );
              return;
            }
            _lastFetchedAt = DateTime.now();
            if (fresh.isNotEmpty) {
              unawaited(
                cache.write(activityType, isFollowing, fresh),
              );
            }
            state = AsyncData(fresh);
          } catch (e) {
            debugPrint(
              '[AniList] Social feed background refresh failed: $e',
            );
          }
        });
        return cached.items;
      }
    }

    final fresh = await _fetchPage();
    _lastFetchedAt = DateTime.now();
    // No persistir caché vacía: si la primera petición devuelve [] por
    // un hipo transitorio de AniList, escribir [] envenenaría el build()
    // siguiente (cached.items.isEmpty → no se programa revalidación de
    // fondo y el feed se queda vacío hasta reiniciar).
    if (fresh.isNotEmpty) {
      unawaited(cache.write(activityType, isFollowing, fresh));
      return fresh;
    }
    // Reintento corto cuando la primera carga viene vacía sin caché —
    // evita que un único hipo de AniList deje el feed Siguiendo sin
    // datos hasta que el usuario tire-para-refrescar.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    try {
      final retry = await _fetchPage();
      if (retry.isNotEmpty) {
        unawaited(cache.write(activityType, isFollowing, retry));
        return retry;
      }
    } catch (_) {}
    return fresh;
  }

  Future<void> refresh({bool force = false}) async {
    _generation++;
    _page = 1;
    _hasMore = true;
    _isLoadingMore = false;
    final prev = state.valueOrNull;
    state = const AsyncLoading<List<FeedActivity>>().copyWithPrevious(state);
    try {
      var fresh = await _fetchPage();
      // Si el resultado vino vacío y NO había datos previos visibles,
      // intentamos una segunda vez tras un breve delay — AniList suele
      // devolver `activities: []` en condiciones de rate-limit suave o
      // cuando el token acaba de refrescarse, y el feed Siguiendo es
      // especialmente susceptible. Esto evita que el usuario se quede
      // viendo "feed vacío" sin manera de recuperar.
      if (fresh.isEmpty && (prev == null || prev.isEmpty)) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        try {
          final retry = await _fetchPage();
          if (retry.isNotEmpty) fresh = retry;
        } catch (_) {}
      }
      // Bug-guard: cuando NO es un refresh forzado por el usuario, no
      // destruimos una lista válida si la API devuelve [] de forma
      // transitoria. Cuando el usuario tira-para-refrescar (force=true)
      // sí queremos reflejar el resultado real para que la UI no parezca
      // ignorar la acción.
      if (!force && fresh.isEmpty && prev != null && prev.isNotEmpty) {
        debugPrint(
          '[AniList] Social feed refresh devolvió 0 ítems; '
          'manteniendo ${prev.length} ítems previos.',
        );
        state = AsyncData(prev);
        return;
      }
      _lastFetchedAt = DateTime.now();
      final cache = AnilistFeedCache(ref.read(sharedPreferencesProvider));
      if (fresh.isNotEmpty) {
        unawaited(cache.write(activityType, isFollowing, fresh));
      }
      state = AsyncData(fresh);
    } catch (e, st) {
      // Preservar datos previos: AsyncError sin previousData hace que el
      // feed se vacíe en pantalla aunque ya teníamos ítems válidos.
      if (prev != null && prev.isNotEmpty) {
        state = AsyncError<List<FeedActivity>>(e, st).copyWithPrevious(
          AsyncData<List<FeedActivity>>(prev),
        );
      } else {
        state = AsyncError(e, st);
      }
    }
  }

  Future<List<FeedActivity>> _fetchPage() async {
    final graphql = ref.read(anilistGraphqlProvider);
    final token = await ref.read(anilistTokenProvider.future);
    if (isFollowing && token == null) {
      // Antes devolvíamos [] aquí, lo que se confundía con "no hay
      // actividad" y se persistía en caché. Mejor lanzar para que el
      // catch del refresh de fondo preserve el estado/caché previos.
      _hasMore = false;
      throw StateError('AniList token no disponible para feed Siguiendo');
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
    final generation = _generation;
    _page++;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage();
      if (generation != _generation) return;
      final byId = <String, FeedActivity>{
        for (final a in prev) a.id: a,
        for (final a in next) a.id: a,
      };
      final merged = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncData(merged);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] Social feed loadMore failed: $e');
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
class AnilistGenreTagBrowse extends _$AnilistGenreTagBrowse {
  static const _perPage = 24;
  int _page = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _generation = 0;

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
    _generation++;
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
    final generation = _generation;
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
      if (generation != _generation) return;
      if (!page.hasNextPage) _hasMore = false;
      if (page.items.isEmpty) _hasMore = false;
      final seen = prev.map((m) => m['id'] as int).toSet();
      final appended = [
        ...prev,
        ...page.items.where((m) => !seen.contains(m['id'] as int)),
      ];
      state = AsyncData(appended);
    } catch (e) {
      _page--;
      _hasMore = false;
      state = AsyncData(prev);
      debugPrint('[AniList] Genre/Tag browse loadMore failed: $e');
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
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistMediaDetailCacheKey(mediaId),
    freshness: _anilistMediaDetailFreshness,
    fetch: () => graphql.fetchMediaDetail(mediaId, token: token),
  );
}

@riverpod
Future<Map<String, dynamic>?> anilistCharacterDetail(
  AnilistCharacterDetailRef ref,
  int characterId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistCharacterDetailCacheKey(characterId),
    freshness: _anilistCharacterDetailFreshness,
    fetch: () => graphql.fetchCharacterDetail(characterId, token: token),
  );
}

@riverpod
Future<Map<String, dynamic>?> anilistStaffDetail(
  AnilistStaffDetailRef ref,
  int staffId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistStaffDetailCacheKey(staffId),
    freshness: _anilistStaffDetailFreshness,
    fetch: () => graphql.fetchStaffDetail(staffId, token: token),
  );
}

@Riverpod(keepAlive: true)
class AnilistProfile extends _$AnilistProfile {
  @override
  Future<Map<String, dynamic>?> build() async {
    final token = await ref.watch(anilistTokenProvider.future);
    final cache = ref.read(jsonCacheProvider);

    if (token == null) {
      // Logged out: drop any persisted profile snapshot.
      await cache.clear(_anilistProfileCacheKey);
      return null;
    }

    final cached = cache.read(_anilistProfileCacheKey);
    final graphql = ref.read(anilistGraphqlProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final fresh = await graphql.fetchViewerProfile(token);
          if (fresh != null) {
            await cache.write(_anilistProfileCacheKey, fresh);
            state = AsyncData(fresh);
          }
        } catch (_) {}
      });
      return cached.data;
    }

    final fresh = await graphql.fetchViewerProfile(token);
    if (fresh != null) {
      await cache.write(_anilistProfileCacheKey, fresh);
    }
    return fresh;
  }

  /// Forces a network refetch ignoring cache. Used by pull-to-refresh.
  Future<void> refresh() async {
    final token = await ref.read(anilistTokenProvider.future);
    if (token == null) return;
    final graphql = ref.read(anilistGraphqlProvider);
    final cache = ref.read(jsonCacheProvider);
    try {
      final fresh = await graphql.fetchViewerProfile(token);
      if (fresh != null) {
        await cache.write(_anilistProfileCacheKey, fresh);
        state = AsyncData(fresh);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

@riverpod
Future<List<Map<String, dynamic>>> anilistMediaThreads(
  AnilistMediaThreadsRef ref,
  int mediaId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateList(
    cache: cache,
    key: _anilistMediaThreadsCacheKey(mediaId),
    freshness: _anilistMediaThreadsFreshness,
    fetch: () => graphql.fetchMediaThreads(mediaId),
  );
}

@riverpod
Future<Map<String, dynamic>?> anilistForumThread(
  AnilistForumThreadRef ref,
  int threadId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.read(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistForumThreadCacheKey(threadId),
    freshness: _anilistForumThreadFreshness,
    fetch: () => graphql.fetchForumThread(threadId, token: token),
  );
}

const Duration _anilistUserProfileFreshness = Duration(hours: 1);
const Duration _anilistUserActivityFreshness = Duration(minutes: 15);
const Duration _anilistActivityRepliesFreshness = Duration(minutes: 5);
String _anilistUserProfileCacheKey(int id) => 'anilist_user_profile_$id';
String _anilistUserActivityCacheKey(int id) => 'anilist_user_activity_$id';
String _anilistActivityRepliesCacheKey(int id) =>
    'anilist_activity_replies_$id';

@riverpod
Future<Map<String, dynamic>?> anilistUserProfile(
  AnilistUserProfileRef ref,
  int userId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistUserProfileCacheKey(userId),
    freshness: _anilistUserProfileFreshness,
    fetch: () => graphql.fetchUserProfile(userId, token: token),
  );
}

@riverpod
Future<List<Map<String, dynamic>>> anilistUserActivity(
  AnilistUserActivityRef ref,
  int userId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  return _staleWhileRevalidateList(
    cache: cache,
    key: _anilistUserActivityCacheKey(userId),
    freshness: _anilistUserActivityFreshness,
    fetch: () => graphql.fetchUserActivity(userId, token: token),
  );
}

@riverpod
Future<Map<String, dynamic>> anilistActivityReplies(
  AnilistActivityRepliesRef ref,
  int activityId,
) async {
  final graphql = ref.read(anilistGraphqlProvider);
  final token = await ref.watch(anilistTokenProvider.future);
  final cache = ref.read(jsonCacheProvider);
  final result = await _staleWhileRevalidateMap(
    cache: cache,
    key: _anilistActivityRepliesCacheKey(activityId),
    freshness: _anilistActivityRepliesFreshness,
    fetch: () =>
        graphql.fetchActivityRepliesPageData(activityId, token: token),
  );
  return result ?? const {};
}

@Riverpod(keepAlive: true)
Future<int> anilistUnreadNotificationCount(
  AnilistUnreadNotificationCountRef ref,
) async {
  final token = await ref.watch(anilistTokenProvider.future);
  if (token == null) return 0;
  final graphql = ref.read(anilistGraphqlProvider);
  return await graphql.fetchUnreadNotificationCount(token) ?? 0;
}

@Riverpod(keepAlive: true)
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
  // Persist the latest 20 so the next launch shows them instantly while we
  // refresh in the background.
  unawaited(_writeNotificationsCache(ref, list));
  await Future<void>.delayed(const Duration(milliseconds: 250));
  ref.invalidate(anilistUnreadNotificationCountProvider);
  return list;
}

const _notificationsCacheKey = 'anilist_notifications_cache_v1';
const _notificationsCacheMax = 20;

Future<void> _writeNotificationsCache(
  AnilistNotificationsListRef ref,
  List<Map<String, dynamic>> items,
) async {
  try {
    final prefs = ref.read(sharedPreferencesProvider);
    final trimmed = items.take(_notificationsCacheMax).toList();
    await prefs.setString(_notificationsCacheKey, jsonEncode(trimmed));
  } catch (_) {
    // Cache is best-effort; a write failure shouldn't bubble up.
  }
}

/// Synchronous read of the last persisted notifications batch (up to 20).
/// The notifications page reads this so it can paint instantly on entry
/// instead of staring at a blank spinner while the live request finishes.
@riverpod
List<Map<String, dynamic>> anilistCachedNotifications(
  AnilistCachedNotificationsRef ref,
) {
  try {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_notificationsCacheKey);
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } catch (_) {
    return const [];
  }
}


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

List<Map<String, dynamic>> mergeAnilistFavoriteApiNodesWithLocal({
  required List<dynamic> apiNodes,
  required List<Map<String, dynamic>> localSnapshots,
  required String mediaTypeUpper,
}) {
  int? parseId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  final want = mediaTypeUpper.toUpperCase();
  final out = <Map<String, dynamic>>[
    ...apiNodes.map((e) => Map<String, dynamic>.from(e as Map)),
  ];
  final seen = out
      .map((m) => parseId(m['id']))
      .whereType<int>()
      .toSet();
  for (final loc in localSnapshots) {
    final t = (loc['type'] as String? ?? 'ANIME').toUpperCase();
    if (t != want) continue;
    final id = parseId(loc['id']);
    if (id == null || id <= 0 || seen.contains(id)) continue;
    out.add(Map<String, dynamic>.from(loc));
    seen.add(id);
  }
  return out;
}

@Riverpod(keepAlive: true)
class FavoriteAnilistMedia extends _$FavoriteAnilistMedia {
  Future<void>? _pushInFlight;

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

  Future<void> pushPendingFavoritesToAnilist(String token) async {
    if (_pushInFlight != null) {
      await _pushInFlight;
      return;
    }

    _pushInFlight = _pushPendingFavoritesToAnilist(token);
    try {
      await _pushInFlight;
    } finally {
      _pushInFlight = null;
    }
  }

  Future<void> _pushPendingFavoritesToAnilist(String token) async {
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
      } catch (e) {
        debugPrint('[AniList] Favorite sync failed for $id/$type: $e');
      }
    }
    final cache = ref.read(jsonCacheProvider);
    for (final id in touchedIds) {
      await _patchCachedDetail(
        cache,
        _anilistMediaDetailCacheKey(id),
        const {'isFavourite': true},
      );
      ref.invalidate(anilistMediaDetailProvider(id));
    }
    ref.invalidate(anilistProfileProvider);
  }
}


const _favoriteAnilistCharactersPrefsKey = 'favorite_anilist_characters_v1';
const _favoriteAnilistStaffPrefsKey = 'favorite_anilist_staff_v1';

List<Map<String, dynamic>> _decodeFavoriteAnilistPeopleJson(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _snapshotAnilistPersonForFavorites(
  Map<String, dynamic> person,
) {
  final name = person['name'] as Map<String, dynamic>? ?? {};
  final image = person['image'] as Map<String, dynamic>? ?? {};
  final id = person['id'];
  return {
    'id': id is int ? id : (id as num?)?.toInt(),
    'name': {
      'full': name['full'],
      'native': name['native'],
      'userPreferred': name['userPreferred'],
    },
    'image': {
      'large': image['large'] ?? image['medium'],
      'medium': image['medium'] ?? image['large'],
    },
  };
}

List<Map<String, dynamic>> mergeAnilistFavoritePeopleApiNodesWithLocal({
  required List<dynamic> apiNodes,
  required List<Map<String, dynamic>> localSnapshots,
}) {
  int? parseId(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  final out = <Map<String, dynamic>>[
    ...apiNodes.map((e) => Map<String, dynamic>.from(e as Map)),
  ];
  final seen = out.map((m) => parseId(m['id'])).whereType<int>().toSet();
  for (final loc in localSnapshots) {
    final id = parseId(loc['id']);
    if (id == null || id <= 0 || seen.contains(id)) continue;
    out.add(Map<String, dynamic>.from(loc));
    seen.add(id);
  }
  return out;
}

@Riverpod(keepAlive: true)
class FavoriteAnilistCharacters extends _$FavoriteAnilistCharacters {
  Future<void>? _pushInFlight;

  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteAnilistPeopleJson(
      prefs.getString(_favoriteAnilistCharactersPrefsKey),
    );
  }

  bool hasFavorite(int characterId) {
    return state.any((e) => ((e['id'] as num?)?.toInt() ?? 0) == characterId);
  }

  Future<void> _persist(List<Map<String, dynamic>> next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _favoriteAnilistCharactersPrefsKey,
      jsonEncode(next),
    );
    state = next;
  }

  Future<void> toggleLocalFavorite(Map<String, dynamic> character) async {
    final id = (character['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere(
      (e) => ((e['id'] as num?)?.toInt() ?? 0) == id,
    );
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotAnilistPersonForFavorites(character));
    }
    await _persist(next);
  }

  Future<void> removeFavorite(int characterId) async {
    final next = state
        .where((e) => ((e['id'] as num?)?.toInt() ?? 0) != characterId)
        .toList();
    if (next.length == state.length) return;
    await _persist(next);
  }

  Future<void> pushPendingFavoritesToAnilist(String token) async {
    if (_pushInFlight != null) {
      await _pushInFlight;
      return;
    }
    _pushInFlight = _push(token);
    try {
      await _pushInFlight;
    } finally {
      _pushInFlight = null;
    }
  }

  Future<void> _push(String token) async {
    final graphql = ref.read(anilistGraphqlProvider);
    final pending = List<Map<String, dynamic>>.from(state);
    if (pending.isEmpty) return;
    final touched = <int>{};
    for (final item in pending) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null || id <= 0) continue;
      try {
        final detail = await graphql.fetchCharacterDetail(id, token: token);
        final onServer = detail?['isFavourite'] as bool? ?? false;
        if (!onServer) {
          await graphql.toggleFavouriteCharacter(
            characterId: id,
            token: token,
          );
        }
        await removeFavorite(id);
        touched.add(id);
      } catch (e) {
        debugPrint('[AniList] Character favorite sync failed for $id: $e');
      }
    }
    final cache = ref.read(jsonCacheProvider);
    for (final id in touched) {
      await _patchCachedDetail(
        cache,
        _anilistCharacterDetailCacheKey(id),
        const {'isFavourite': true},
      );
      ref.invalidate(anilistCharacterDetailProvider(id));
    }
    ref.invalidate(anilistProfileProvider);
  }
}

@Riverpod(keepAlive: true)
class FavoriteAnilistStaff extends _$FavoriteAnilistStaff {
  Future<void>? _pushInFlight;

  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteAnilistPeopleJson(
      prefs.getString(_favoriteAnilistStaffPrefsKey),
    );
  }

  bool hasFavorite(int staffId) {
    return state.any((e) => ((e['id'] as num?)?.toInt() ?? 0) == staffId);
  }

  Future<void> _persist(List<Map<String, dynamic>> next) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _favoriteAnilistStaffPrefsKey,
      jsonEncode(next),
    );
    state = next;
  }

  Future<void> toggleLocalFavorite(Map<String, dynamic> staff) async {
    final id = (staff['id'] as num?)?.toInt();
    if (id == null || id <= 0) return;
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere(
      (e) => ((e['id'] as num?)?.toInt() ?? 0) == id,
    );
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotAnilistPersonForFavorites(staff));
    }
    await _persist(next);
  }

  Future<void> removeFavorite(int staffId) async {
    final next = state
        .where((e) => ((e['id'] as num?)?.toInt() ?? 0) != staffId)
        .toList();
    if (next.length == state.length) return;
    await _persist(next);
  }

  Future<void> pushPendingFavoritesToAnilist(String token) async {
    if (_pushInFlight != null) {
      await _pushInFlight;
      return;
    }
    _pushInFlight = _push(token);
    try {
      await _pushInFlight;
    } finally {
      _pushInFlight = null;
    }
  }

  Future<void> _push(String token) async {
    final graphql = ref.read(anilistGraphqlProvider);
    final pending = List<Map<String, dynamic>>.from(state);
    if (pending.isEmpty) return;
    final touched = <int>{};
    for (final item in pending) {
      final id = (item['id'] as num?)?.toInt();
      if (id == null || id <= 0) continue;
      try {
        final detail = await graphql.fetchStaffDetail(id, token: token);
        final onServer = detail?['isFavourite'] as bool? ?? false;
        if (!onServer) {
          await graphql.toggleFavouriteStaff(
            staffId: id,
            token: token,
          );
        }
        await removeFavorite(id);
        touched.add(id);
      } catch (e) {
        debugPrint('[AniList] Staff favorite sync failed for $id: $e');
      }
    }
    final cache = ref.read(jsonCacheProvider);
    for (final id in touched) {
      await _patchCachedDetail(
        cache,
        _anilistStaffDetailCacheKey(id),
        const {'isFavourite': true},
      );
      ref.invalidate(anilistStaffDetailProvider(id));
    }
    ref.invalidate(anilistProfileProvider);
  }
}
