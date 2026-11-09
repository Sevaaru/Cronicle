import 'dart:async';
import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/presentation/feed_filter_layout_notifier.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';

/// Sources that can be toggled in the Social feed source filter.
enum SocialFeedSource { anilist, steam }

/// Notifier that persists the set of enabled feed sources in SharedPreferences.
/// At least one source is always enabled (the notifier silently ignores
/// requests that would empty the set).
class SocialFeedSourcesNotifier extends Notifier<Set<SocialFeedSource>> {
  static const _prefsKey = 'social_feed_sources_v1';

  @override
  Set<SocialFeedSource> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getStringList(_prefsKey);
    if (raw == null || raw.isEmpty) {
      return {SocialFeedSource.anilist, SocialFeedSource.steam};
    }
    final out = <SocialFeedSource>{};
    for (final id in raw) {
      switch (id) {
        case 'anilist':
          out.add(SocialFeedSource.anilist);
          break;
        case 'steam':
          out.add(SocialFeedSource.steam);
          break;
      }
    }
    if (out.isEmpty) {
      return {SocialFeedSource.anilist, SocialFeedSource.steam};
    }
    return out;
  }

  Future<void> toggle(SocialFeedSource source) async {
    final next = {...state};
    if (next.contains(source)) {
      next.remove(source);
    } else {
      next.add(source);
    }
    if (next.isEmpty) return; // never allow zero sources
    state = next;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(
      _prefsKey,
      next.map((e) => e.name).toList(),
    );
  }
}

final socialFeedSourcesProvider =
    NotifierProvider<SocialFeedSourcesNotifier, Set<SocialFeedSource>>(
  SocialFeedSourcesNotifier.new,
);

/// True when the user selected "games" as one of their interests during
/// onboarding (i.e. the `game` slot in the feed filter layout is visible).
final socialGamesInterestProvider = Provider<bool>((ref) {
  final layout = ref.watch(feedFilterLayoutProvider);
  return layout.visibleIdSet.contains('game');
});

/// Kind of activity surfaced for a Steam friend in the social feed.
enum SteamFriendActivityKind {
  /// Friend played a game recently (uses `rtime_last_played` from the
  /// owned-games endpoint as the timestamp).
  played,

  /// Friend's library grew since the previous snapshot — interpreted as
  /// "added N games to the library" (likely purchases / gifts / free
  /// claims). The timestamp is the moment the diff was detected.
  purchased,

  /// Friend unlocked an achievement (uses the unlock time reported by
  /// `GetPlayerAchievements`). Best-effort — only for friends with
  /// public game stats.
  achievement,
}

/// One Steam friend's recent presence info, used to render a "friend
/// activity" tile in the Following feed. The `kind` field decides how
/// the card is rendered.
class SteamFriendActivityItem {
  const SteamFriendActivityItem({
    required this.kind,
    required this.timestamp,
    required this.steamId,
    required this.personaName,
    this.avatarUrl,
    this.profileUrl,
    this.appId = 0,
    this.gameName = '',
    this.gameIconUrl,
    this.playtimeForever = 0,
    this.playtime2Weeks = 0,
    this.achievementName,
    this.achievementDescription,
    this.achievementIconUrl,
    this.newGamesCount = 0,
    this.newGameNames = const <String>[],
  });

  final SteamFriendActivityKind kind;
  final DateTime timestamp;

  final String steamId;
  final String personaName;
  final String? avatarUrl;
  final String? profileUrl;

  /// Game associated with the activity (0 / empty for purchase summaries
  /// that span multiple games).
  final int appId;
  final String gameName;
  final String? gameIconUrl;

  final int playtimeForever; // minutes
  final int playtime2Weeks; // minutes

  // Achievement-only fields.
  final String? achievementName;
  final String? achievementDescription;
  final String? achievementIconUrl;

  // Purchase-only fields.
  final int newGamesCount;
  final List<String> newGameNames;
}

const _kFriendsToScan = 30;
const _kFriendsConcurrency = 6;
const _kRecentDays = 30;
const _kAchievementGamesPerFriend = 2;
const _kFeedItemsCap = 60;
const _kSnapshotPrefsKey = 'steam_friend_lib_snapshot_v1';

/// Real activity feed of the user's Steam friends. Combines:
///   • `played` events (per game, dated by `rtime_last_played`)
///   • `purchased` events (delta vs last library snapshot in SharedPref)
///   • `achievement` events (best-effort, last 30 days, top played games)
///
/// All items carry real timestamps and are sorted desc by the consumer.
final steamFriendsRecentActivityProvider =
    FutureProvider<List<SteamFriendActivityItem>>((ref) async {
  final session = await ref.watch(steamSessionProvider.future);
  // ignore: avoid_print
  print('[SteamFeed] start connected=${session.connected} steamId=${session.steamId}');
  if (!session.connected || session.steamId == null) {
    throw StateError('steam_not_connected');
  }
  final api = ref.watch(steamApiProvider);
  final prefs = ref.read(sharedPreferencesProvider);

  // Load previous library snapshot for purchase diffing.
  Map<String, Set<int>> snapshot = const {};
  try {
    final raw = prefs.getString(_kSnapshotPrefsKey);
    if (raw != null && raw.isNotEmpty) {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        snapshot = {
          for (final e in decoded.entries)
            if (e.key is String && e.value is List)
              e.key as String: <int>{
                for (final v in (e.value as List))
                  if (v is num) v.toInt(),
              },
        };
      }
    }
  } catch (_) {
    snapshot = const {};
  }

  final friendIds = await api.fetchFriendList(session.steamId!);
  // ignore: avoid_print
  print('[SteamFeed] friendList count=${friendIds.length}');
  if (friendIds.isEmpty) {
    throw StateError('steam_friends_empty');
  }

  final pick = friendIds.take(_kFriendsToScan).toList();

  // One batched call for avatars + persona names.
  final summaries = await api.fetchPlayerSummaries(pick);
  final summaryById = <String, Map<String, dynamic>>{
    for (final s in summaries)
      if (s['steamid'] is String) (s['steamid'] as String): s,
  };

  final now = DateTime.now();
  final cutoff = now.subtract(const Duration(days: _kRecentDays));
  final allItems = <SteamFriendActivityItem>[];
  final newSnapshot = <String, Set<int>>{};

  Future<void> processFriend(String fid) async {
    final s = summaryById[fid];
    final personaName = (s?['personaname'] as String?) ?? 'Friend $fid';
    final avatarUrl = (s?['avatarfull'] as String?) ??
        (s?['avatarmedium'] as String?) ??
        (s?['avatar'] as String?);
    final profileUrl = s?['profileurl'] as String?;

    // 1) Try owned games (provides rtime_last_played + library snapshot for
    //    purchase diff). This requires "Game details" to be public on the
    //    friend's profile — many users have this private, so we always
    //    fall back to recently_played below to keep the feed populated.
    List<Map<String, dynamic>> owned = const [];
    try {
      owned = await api.fetchOwnedGames(fid);
    } catch (e) {
      owned = const [];
    }

    // Snapshot bookkeeping (only when we got real data).
    if (owned.isNotEmpty) {
      final currentAppIds = <int>{
        for (final g in owned)
          if ((g['appid'] as num?)?.toInt() != null)
            (g['appid'] as num).toInt(),
      };
      newSnapshot[fid] = currentAppIds;

      final prevSet = snapshot[fid];
      if (prevSet != null && prevSet.isNotEmpty) {
        final added = currentAppIds.difference(prevSet);
        if (added.isNotEmpty) {
          final addedNames = <String>[];
          for (final g in owned) {
            final appId = (g['appid'] as num?)?.toInt() ?? 0;
            if (added.contains(appId)) {
              final name = (g['name'] as String?) ?? 'App $appId';
              addedNames.add(name);
              if (addedNames.length >= 3) break;
            }
          }
          allItems.add(SteamFriendActivityItem(
            kind: SteamFriendActivityKind.purchased,
            timestamp: now,
            steamId: fid,
            personaName: personaName,
            avatarUrl: avatarUrl,
            profileUrl: profileUrl,
            newGamesCount: added.length,
            newGameNames: addedNames,
          ));
        }
      }
    }

    // 2) Build the list of "recently played" games. Prefer the owned-games
    //    list filtered by rtime_last_played (real timestamps); fall back
    //    to GetRecentlyPlayedGames (more permissive, but no per-game
    //    timestamp — we synthesize one from the iteration order).
    final played = <SteamFriendActivityItem>[];
    final scanForAchievements = <Map<String, dynamic>>[];

    final withTime = owned.where((g) {
      final ts = (g['rtime_last_played'] as num?)?.toInt() ?? 0;
      return ts > 0;
    }).toList()
      ..sort((a, b) {
        final ta = (a['rtime_last_played'] as num?)?.toInt() ?? 0;
        final tb = (b['rtime_last_played'] as num?)?.toInt() ?? 0;
        return tb.compareTo(ta);
      });

    if (withTime.isNotEmpty) {
      var emitted = 0;
      for (final g in withTime) {
        final ts = (g['rtime_last_played'] as num?)?.toInt() ?? 0;
        final when = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        if (when.isBefore(cutoff)) break;
        final appId = (g['appid'] as num?)?.toInt() ?? 0;
        final name = (g['name'] as String?) ?? 'App $appId';
        final icon = g['img_icon_url'] as String?;
        played.add(SteamFriendActivityItem(
          kind: SteamFriendActivityKind.played,
          timestamp: when,
          steamId: fid,
          personaName: personaName,
          avatarUrl: avatarUrl,
          profileUrl: profileUrl,
          appId: appId,
          gameName: name,
          gameIconUrl: (appId > 0)
              ? 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg'
              : null,
          playtimeForever: (g['playtime_forever'] as num?)?.toInt() ?? 0,
          playtime2Weeks: (g['playtime_2weeks'] as num?)?.toInt() ?? 0,
        ));
        scanForAchievements.add(g);
        emitted++;
        if (emitted >= 4) break;
      }
    }

    // Fallback A: if owned didn't yield any timestamped entry, try the
    // recently_played endpoint (more permissive privacy-wise).
    if (played.isEmpty) {
      List<Map<String, dynamic>> recent;
      try {
        recent = await api.fetchRecentlyPlayed(fid);
      } catch (e) {
        recent = <Map<String, dynamic>>[];
      }
      // Defensive copy: the datasource may return an unmodifiable view.
      recent = [...recent];
      recent.sort((a, b) {
        final pa = (a['playtime_2weeks'] as num?)?.toInt() ?? 0;
        final pb = (b['playtime_2weeks'] as num?)?.toInt() ?? 0;
        return pb.compareTo(pa);
      });
      var idx = 0;
      for (final g in recent.take(4)) {
        final appId = (g['appid'] as num?)?.toInt() ?? 0;
        final name = (g['name'] as String?) ?? 'App $appId';
        final icon = g['img_icon_url'] as String?;
        final synth = now.subtract(Duration(minutes: 30 + idx * 90));
        played.add(SteamFriendActivityItem(
          kind: SteamFriendActivityKind.played,
          timestamp: synth,
          steamId: fid,
          personaName: personaName,
          avatarUrl: avatarUrl,
          profileUrl: profileUrl,
          appId: appId,
          gameName: name,
          gameIconUrl: (appId > 0)
              ? 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg'
              : null,
          playtimeForever: (g['playtime_forever'] as num?)?.toInt() ?? 0,
          playtime2Weeks: (g['playtime_2weeks'] as num?)?.toInt() ?? 0,
        ));
        scanForAchievements.add(g);
        idx++;
      }
    }

    // Fallback B: still nothing but we DO have an owned-games list. The
    // friend's profile likely hides last-played timestamps. Use the
    // top-played games as a "library highlight" entry so the card shows
    // up at all instead of the friend being silent.
    if (played.isEmpty && owned.isNotEmpty) {
      final byPlaytime = [...owned]..sort((a, b) {
          final pa = (a['playtime_forever'] as num?)?.toInt() ?? 0;
          final pb = (b['playtime_forever'] as num?)?.toInt() ?? 0;
          return pb.compareTo(pa);
        });
      var idx = 0;
      for (final g in byPlaytime.take(2)) {
        final appId = (g['appid'] as num?)?.toInt() ?? 0;
        if (appId == 0) continue;
        final mins = (g['playtime_forever'] as num?)?.toInt() ?? 0;
        if (mins <= 0) continue; // ignore never-played entries
        final name = (g['name'] as String?) ?? 'App $appId';
        final icon = g['img_icon_url'] as String?;
        // Bury library-highlight entries deeper in the timeline so they
        // never outrank real played/news items.
        final synth = now.subtract(Duration(hours: 6 + idx * 8));
        played.add(SteamFriendActivityItem(
          kind: SteamFriendActivityKind.played,
          timestamp: synth,
          steamId: fid,
          personaName: personaName,
          avatarUrl: avatarUrl,
          profileUrl: profileUrl,
          appId: appId,
          gameName: name,
          gameIconUrl: (appId > 0)
              ? 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg'
              : null,
          playtimeForever: mins,
          playtime2Weeks: (g['playtime_2weeks'] as num?)?.toInt() ?? 0,
        ));
        scanForAchievements.add(g);
        idx++;
      }
    }

    allItems.addAll(played);

    // 3) Achievements — best-effort over the most recent games we found.
    //    Many friends have private game stats and these calls return [].
    final achGames =
        scanForAchievements.take(_kAchievementGamesPerFriend).toList();
    for (final g in achGames) {
      final appId = (g['appid'] as num?)?.toInt() ?? 0;
      if (appId == 0) continue;
      final name = (g['name'] as String?) ?? 'App $appId';
      final gameIconUrl = appId > 0
          ? 'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg'
          : null;
      List<Map<String, dynamic>> ach;
      try {
        ach = await api.fetchPlayerAchievements(fid, appId);
      } catch (_) {
        continue;
      }
      final unlocks = <SteamFriendActivityItem>[];
      for (final a in ach) {
        final achieved = (a['achieved'] as num?)?.toInt() == 1;
        if (!achieved) continue;
        final ts = (a['unlocktime'] as num?)?.toInt() ?? 0;
        if (ts <= 0) continue;
        final when = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        if (when.isBefore(cutoff)) continue;
        final achName =
            (a['name'] as String?) ?? (a['apiname'] as String?) ?? '';
        if (achName.isEmpty) continue;
        unlocks.add(SteamFriendActivityItem(
          kind: SteamFriendActivityKind.achievement,
          timestamp: when,
          steamId: fid,
          personaName: personaName,
          avatarUrl: avatarUrl,
          profileUrl: profileUrl,
          appId: appId,
          gameName: name,
          gameIconUrl: gameIconUrl,
          achievementName: achName,
          achievementDescription: a['description'] as String?,
        ));
      }
      unlocks.sort((x, y) => y.timestamp.compareTo(x.timestamp));
      allItems.addAll(unlocks.take(3));
    }
  }

  // Run friends in batches with bounded concurrency.
  for (var i = 0; i < pick.length; i += _kFriendsConcurrency) {
    final end = (i + _kFriendsConcurrency).clamp(0, pick.length);
    final chunk = pick.sublist(i, end);
    await Future.wait(chunk.map(processFriend), eagerError: false);
  }

  // Persist updated snapshot for next-refresh diffing.
  try {
    final encoded = <String, List<int>>{
      for (final e in newSnapshot.entries) e.key: e.value.toList(),
    };
    await prefs.setString(_kSnapshotPrefsKey, jsonEncode(encoded));
  } catch (_) {}

  // Sort by real timestamp desc (most recent first), then cap.
  allItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  // ignore: avoid_print
  print('[SteamFeed] finished items=${allItems.length}');
  return allItems.take(_kFeedItemsCap).toList();
});

/// One Steam announcement / news item ready to render in the Global feed.
class SteamNewsFeedItem {
  const SteamNewsFeedItem({
    required this.appId,
    required this.gameName,
    required this.gameIconUrl,
    required this.title,
    required this.contents,
    required this.url,
    required this.author,
    required this.publishedAt,
    this.feedLabel,
  });

  final int appId;
  final String gameName;
  final String? gameIconUrl;
  final String title;
  final String contents;
  final String url;
  final String author;
  final DateTime publishedAt;
  final String? feedLabel;
}

const _kNewsTopGames = 6;
const _kNewsPerGame = 4;
const _kNewsCap = 30;

/// News and announcements aggregated from the user's most-played owned
/// games (top 6 by total playtime). Empty list when no Steam session or
/// no games owned. Gated upstream by games-interest selection.
final steamOwnedGamesNewsProvider =
    FutureProvider<List<SteamNewsFeedItem>>((ref) async {
  final session = await ref.watch(steamSessionProvider.future);
  if (!session.connected || session.steamId == null) return const [];
  final games = await ref.watch(steamOwnedGamesProvider.future);
  if (games.isEmpty) return const [];

  // Sort by playtime, take top N.
  final sorted = [...games]..sort((a, b) {
      final pa = (a['playtime_forever'] as num?)?.toInt() ?? 0;
      final pb = (b['playtime_forever'] as num?)?.toInt() ?? 0;
      return pb.compareTo(pa);
    });
  final picked = sorted.take(_kNewsTopGames).toList();

  final api = ref.watch(steamApiProvider);
  final all = <SteamNewsFeedItem>[];

  // Fetch news in parallel for up to 6 games. Each call is best-effort.
  final results = await Future.wait(picked.map((g) async {
    final appId = (g['appid'] as num?)?.toInt();
    if (appId == null) return const <SteamNewsFeedItem>[];
    final name = (g['name'] as String?) ?? 'App $appId';
    try {
      final raw =
          await api.fetchAppNews(appId, count: _kNewsPerGame, maxLength: 600);
      return raw.map((n) {
        final ts = (n['date'] as num?)?.toInt() ?? 0;
        return SteamNewsFeedItem(
          appId: appId,
          gameName: name,
          gameIconUrl:
              'https://shared.fastly.steamstatic.com/store_item_assets/steam/apps/$appId/header.jpg',
          title: (n['title'] as String?) ?? '',
          contents: (n['contents'] as String?) ?? '',
          url: (n['url'] as String?) ?? '',
          author: (n['author'] as String?) ?? '',
          publishedAt: DateTime.fromMillisecondsSinceEpoch(ts * 1000),
          feedLabel: n['feedlabel'] as String?,
        );
      }).toList();
    } catch (_) {
      return const <SteamNewsFeedItem>[];
    }
  }));

  for (final r in results) {
    all.addAll(r);
  }

  all.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
  return all.take(_kNewsCap).toList();
});
