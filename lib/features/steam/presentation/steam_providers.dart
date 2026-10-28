import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/cache/json_cache.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/steam/data/datasources/steam_api_datasource.dart';
import 'package:cronicle/features/steam/data/datasources/steam_auth_datasource.dart';

const String _steamOwnedGamesCacheKey = 'steam_owned_games';

final steamAuthProvider = Provider<SteamAuthDatasource>((ref) {
  return SteamAuthDatasource(const FlutterSecureStorage());
});

final steamApiProvider = Provider<SteamApiDatasource>((ref) {
  return SteamApiDatasource(ref.watch(dioProvider));
});

class SteamSessionState {
  const SteamSessionState({
    required this.connected,
    this.steamId,
    this.personaName,
    this.avatarUrl,
    this.profileUrl,
  });

  final bool connected;
  final String? steamId;
  final String? personaName;
  final String? avatarUrl;
  final String? profileUrl;

  static const disconnected = SteamSessionState(connected: false);
}

class SteamSessionNotifier extends AsyncNotifier<SteamSessionState> {
  @override
  Future<SteamSessionState> build() async {
    final auth = ref.watch(steamAuthProvider);
    final id = await auth.getSteamId();
    if (id == null || id.isEmpty) return SteamSessionState.disconnected;
    final persona = await auth.getPersonaName();
    final avatar = await auth.getAvatarUrl();
    final profileUrl = await auth.getProfileUrl();
    return SteamSessionState(
      connected: true,
      steamId: id,
      personaName: persona,
      avatarUrl: avatar,
      profileUrl: profileUrl,
    );
  }

  /// Trigger the Steam OpenID flow (web bridge → Steam → deep link back).
  /// On success, persists the SteamID and refreshes the player summary.
  Future<void> connect() async {
    final auth = ref.read(steamAuthProvider);
    final api = ref.read(steamApiProvider);
    final steamId = await auth.connectViaBridge();
    await auth.saveSteamId(steamId);
    try {
      final summary = await api.fetchPlayerSummary(steamId);
      if (summary != null) {
        await auth.savePlayerSummary(
          personaName: summary['personaname'] as String?,
          avatarUrl: (summary['avatarfull'] as String?) ??
              (summary['avatarmedium'] as String?) ??
              (summary['avatar'] as String?),
          profileUrl: summary['profileurl'] as String?,
        );
      }
    } catch (_) {
      // Player summary is best-effort; the session is still valid.
    }
    ref.invalidateSelf();
    ref.invalidate(steamOwnedGamesProvider);
    await future;
  }

  Future<void> refreshPlayerSummary() async {
    final auth = ref.read(steamAuthProvider);
    final api = ref.read(steamApiProvider);
    final id = await auth.getSteamId();
    if (id == null || id.isEmpty) return;
    final summary = await api.fetchPlayerSummary(id);
    if (summary == null) return;
    await auth.savePlayerSummary(
      personaName: summary['personaname'] as String?,
      avatarUrl: (summary['avatarfull'] as String?) ??
          (summary['avatarmedium'] as String?) ??
          (summary['avatar'] as String?),
      profileUrl: summary['profileurl'] as String?,
    );
    ref.invalidateSelf();
  }

  Future<void> disconnect() async {
    await ref.read(steamAuthProvider).clearSession();
    await ref.read(jsonCacheProvider).clear(_steamOwnedGamesCacheKey);
    ref.invalidate(steamOwnedGamesProvider);
    state = const AsyncData(SteamSessionState.disconnected);
  }
}

final steamSessionProvider =
    AsyncNotifierProvider<SteamSessionNotifier, SteamSessionState>(
  SteamSessionNotifier.new,
);

/// Loads the user's owned Steam games. Uses a stale-while-revalidate cache
/// so opening the Steam page is instant after the first sync.
final steamOwnedGamesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final session = await ref.watch(steamSessionProvider.future);
  if (!session.connected || session.steamId == null) {
    return const [];
  }
  final cache = ref.watch(jsonCacheProvider);
  final api = ref.watch(steamApiProvider);

  final cached = cache.read(_steamOwnedGamesCacheKey);
  final cachedList = cached == null
      ? const <Map<String, dynamic>>[]
      : jsonListAsMaps(cached.data['games']);

  Future<void> revalidate() async {
    try {
      final fresh = await api.fetchOwnedGames(session.steamId!);
      await cache.write(_steamOwnedGamesCacheKey, {'games': fresh});
      ref.invalidateSelf();
    } catch (_) {}
  }

  if (cachedList.isNotEmpty &&
      cached != null &&
      cache.isFresh(cached.fetchedAt, const Duration(hours: 6))) {
    return cachedList;
  }

  if (cachedList.isNotEmpty) {
    // Fire-and-forget revalidation
    unawaited(revalidate());
    return cachedList;
  }

  try {
    final fresh = await api.fetchOwnedGames(session.steamId!);
    await cache.write(_steamOwnedGamesCacheKey, {'games': fresh});
    return fresh;
  } catch (e) {
    if (cachedList.isNotEmpty) return cachedList;
    rethrow;
  }
});

/// Player achievements for a single owned game (combined with the schema for
/// rich display: name, description, icon).
class SteamAchievement {
  const SteamAchievement({
    required this.apiName,
    required this.displayName,
    required this.description,
    required this.iconUrl,
    required this.iconGrayUrl,
    required this.achieved,
    required this.unlockTime,
    required this.hidden,
  });

  final String apiName;
  final String displayName;
  final String description;
  final String? iconUrl;
  final String? iconGrayUrl;
  final bool achieved;
  final DateTime? unlockTime;
  final bool hidden;
}

class SteamAchievementsResult {
  const SteamAchievementsResult({
    required this.achievements,
    required this.unlocked,
    required this.total,
  });

  final List<SteamAchievement> achievements;
  final int unlocked;
  final int total;
}

final steamGameAchievementsProvider = FutureProvider
    .family<SteamAchievementsResult, int>((ref, appId) async {
  final session = await ref.watch(steamSessionProvider.future);
  final api = ref.watch(steamApiProvider);

  // Always try to load the schema — it lists all achievements available
  // for the game regardless of ownership / login state. Player progress
  // is fetched only when we have a session and is best-effort.
  final schemaFuture =
      api.fetchGameSchema(appId).catchError((_) => <Map<String, dynamic>>[]);
  final playerFuture = (session.connected && session.steamId != null)
      ? api
          .fetchPlayerAchievements(session.steamId!, appId)
          .catchError((_) => <Map<String, dynamic>>[])
      : Future.value(<Map<String, dynamic>>[]);

  final results = await Future.wait<List<Map<String, dynamic>>>(
      [playerFuture, schemaFuture]);
  final player = results[0];
  final schema = results[1];

  // Build progress lookup by api name from the player call (if any).
  final progressByName = <String, Map<String, dynamic>>{
    for (final p in player)
      if (p['apiname'] is String) p['apiname'] as String: p,
  };

  final out = <SteamAchievement>[];
  var unlocked = 0;

  // Prefer schema as the source of truth for "all achievements". Fall back
  // to the player list when schema is unavailable (e.g. games without a
  // public schema endpoint).
  if (schema.isNotEmpty) {
    for (final s in schema) {
      final apiName = (s['name'] as String?) ?? '';
      final p = progressByName[apiName];
      final achieved = (p?['achieved'] as num?)?.toInt() == 1;
      if (achieved) unlocked++;
      final unlockTs = (p?['unlocktime'] as num?)?.toInt() ?? 0;
      out.add(SteamAchievement(
        apiName: apiName,
        displayName: (p?['name'] as String?) ??
            (s['displayName'] as String?) ??
            apiName,
        description: (p?['description'] as String?) ??
            (s['description'] as String?) ??
            '',
        iconUrl: s['icon'] as String?,
        iconGrayUrl: s['icongray'] as String?,
        achieved: achieved,
        unlockTime: unlockTs > 0
            ? DateTime.fromMillisecondsSinceEpoch(unlockTs * 1000)
            : null,
        hidden: ((s['hidden'] as num?)?.toInt() ?? 0) == 1,
      ));
    }
  } else {
    for (final ach in player) {
      final apiName = ach['apiname'] as String? ?? '';
      final achieved = (ach['achieved'] as num?)?.toInt() == 1;
      if (achieved) unlocked++;
      final unlockTs = (ach['unlocktime'] as num?)?.toInt() ?? 0;
      out.add(SteamAchievement(
        apiName: apiName,
        displayName: (ach['name'] as String?) ?? apiName,
        description: (ach['description'] as String?) ?? '',
        iconUrl: null,
        iconGrayUrl: null,
        achieved: achieved,
        unlockTime: unlockTs > 0
            ? DateTime.fromMillisecondsSinceEpoch(unlockTs * 1000)
            : null,
        hidden: false,
      ));
    }
  }

  // Sort: unlocked first (most recent unlock), then locked.
  out.sort((a, b) {
    if (a.achieved != b.achieved) return a.achieved ? -1 : 1;
    final at = a.unlockTime?.millisecondsSinceEpoch ?? 0;
    final bt = b.unlockTime?.millisecondsSinceEpoch ?? 0;
    return bt.compareTo(at);
  });
  return SteamAchievementsResult(
    achievements: out,
    unlocked: unlocked,
    total: out.length,
  );
});

// ─── Store details (short description, metacritic, developer) ─────────────────

final steamAppDetailsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, appId) async {
  final api = ref.watch(steamApiProvider);
  return api.fetchAppDetails(appId);
});

// ─── App news / events / announcements (public, no API key required) ─────────

final steamAppNewsProvider = FutureProvider
    .family<List<Map<String, dynamic>>, int>((ref, appId) async {
  final api = ref.watch(steamApiProvider);
  return api.fetchAppNews(appId, count: 8, maxLength: 600);
});

// ─── SteamSpy popular tags (public, no key) ──────────────────────────────────

final steamSpyTagsProvider =
    FutureProvider.family<Map<String, int>, int>((ref, appId) async {
  final api = ref.watch(steamApiProvider);
  return api.fetchSteamSpyTags(appId);
});

// ─── User reviews summary ─────────────────────────────────────────────────────

final steamUserReviewsProvider =
    FutureProvider.family<Map<String, dynamic>?, int>((ref, appId) async {
  final api = ref.watch(steamApiProvider);
  return api.fetchUserReviews(appId);
});

// ─── Current concurrent players ───────────────────────────────────────────────

final steamCurrentPlayersProvider =
    FutureProvider.family<int?, int>((ref, appId) async {
  final api = ref.watch(steamApiProvider);
  return api.fetchCurrentPlayers(appId);
});

// ─── Friends activity ─────────────────────────────────────────────────────────

class SteamFriendsActivity {
  const SteamFriendsActivity({
    required this.friendsWhoOwn,
    required this.totalChecked,
    required this.friendListPrivate,
    this.playtimeByFriendId = const {},
  });

  /// Summaries (personaname, avatarmedium, steamid) of friends who own the game.
  final List<Map<String, dynamic>> friendsWhoOwn;

  /// How many friends were actually checked (may be < total friend count).
  final int totalChecked;

  /// True if the user's friend list is not publicly accessible.
  final bool friendListPrivate;

  /// Maps steamId → playtime in minutes for this game (null = unavailable).
  final Map<String, int?> playtimeByFriendId;
}

const _kFriendsActivityCap = 100;
const _kFriendsActivityConcurrency = 8;

final steamFriendsWithGameProvider =
    FutureProvider.family<SteamFriendsActivity, int>((ref, appId) async {
  final session = await ref.watch(steamSessionProvider.future);
  if (!session.connected || session.steamId == null) {
    return const SteamFriendsActivity(
        friendsWhoOwn: [], totalChecked: 0, friendListPrivate: false);
  }
  final api = ref.watch(steamApiProvider);
  final friendIds = await api.fetchFriendList(session.steamId!);
  if (friendIds.isEmpty) {
    return const SteamFriendsActivity(
        friendsWhoOwn: [], totalChecked: 0, friendListPrivate: true);
  }
  final toCheck = friendIds.take(_kFriendsActivityCap).toList();

  // Check ownership in chunked parallel batches — silently skip private
  // profiles. Batching avoids hammering Steam with 100 simultaneous
  // requests (which can trigger rate limits / 429s, leaving the section
  // empty for popular games like Wuthering Waves where many friends own
  // it but the burst gets throttled).
  final ownerPairs = <MapEntry<String, int?>>[];
  for (var i = 0; i < toCheck.length; i += _kFriendsActivityConcurrency) {
    final end = (i + _kFriendsActivityConcurrency).clamp(0, toCheck.length);
    final chunk = toCheck.sublist(i, end);
    final results = await Future.wait(
      chunk.map((id) async {
        try {
          final games = await api.fetchOwnedGames(id);
          final entry = games.cast<Map<String, dynamic>?>().firstWhere(
            (g) => (g?['appid'] as num?)?.toInt() == appId,
            orElse: () => null,
          );
          if (entry == null) return null;
          final playtime = (entry['playtime_forever'] as num?)?.toInt();
          return MapEntry(id, playtime);
        } catch (_) {
          return null;
        }
      }),
      eagerError: false,
    );
    ownerPairs.addAll(results.whereType<MapEntry<String, int?>>());
  }
  final ownIds = ownerPairs.map((e) => e.key).toList();

  if (ownIds.isEmpty) {
    return SteamFriendsActivity(
        friendsWhoOwn: [], totalChecked: toCheck.length, friendListPrivate: false);
  }
  final playtimeMap = Map<String, int?>.fromEntries(ownerPairs);
  final summaries = await api.fetchPlayerSummaries(ownIds);
  return SteamFriendsActivity(
    friendsWhoOwn: summaries,
    totalChecked: toCheck.length,
    friendListPrivate: false,
    playtimeByFriendId: playtimeMap,
  );
});

// ─── Favourite Steam games (local, SharedPreferences) ────────────────────────

const _kFavoriteSteamGamesKey = 'favorite_steam_games_v1';

List<Map<String, dynamic>> _decodeSteamFavs(SharedPreferences prefs) {
  final raw = prefs.getString(_kFavoriteSteamGamesKey);
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  } catch (_) {
    return [];
  }
}

class FavoriteSteamGamesNotifier
    extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    return _decodeSteamFavs(ref.watch(sharedPreferencesProvider));
  }

  Future<void> toggleFavorite(int appId, String name) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = List<Map<String, dynamic>>.from(state);
    final idx = next.indexWhere((e) => (e['appid'] as num?)?.toInt() == appId);
    if (idx >= 0) {
      next.removeAt(idx);
    } else {
      next.add({'appid': appId, 'name': name});
    }
    await prefs.setString(_kFavoriteSteamGamesKey, jsonEncode(next));
    state = next;
  }
}

final favoriteSteamGamesProvider =
    NotifierProvider<FavoriteSteamGamesNotifier, List<Map<String, dynamic>>>(
  FavoriteSteamGamesNotifier.new,
);
