import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/shared/models/feed_activity.dart';

class AnilistFeedCache {
  AnilistFeedCache(this._prefs);

  final SharedPreferences _prefs;

  static const Duration defaultFreshness = Duration(seconds: 60);

  static String _keyFor(String? activityType, bool isFollowing) {
    final type = activityType ?? '_all';
    return 'anilist_feed_cache_v1::$type::${isFollowing ? 'foll' : 'glob'}';
  }

  ({List<FeedActivity> items, DateTime fetchedAt})? read(
    String? activityType,
    bool isFollowing,
  ) {
    final raw = _prefs.getString(_keyFor(activityType, isFollowing));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ts = json['fetchedAt'] as int?;
      final list = (json['items'] as List?) ?? const [];
      if (ts == null) return null;
      final items = <FeedActivity>[];
      for (final e in list) {
        if (e is Map<String, dynamic>) {
          try {
            items.add(FeedActivity.fromJson(e));
          } catch (_) {}
        }
      }
      return (
        items: items,
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(
    String? activityType,
    bool isFollowing,
    List<FeedActivity> items,
  ) async {
    // Bug-guard: nunca persistas un feed vacío. Antes, si AniList devolvía
    // momentáneamente `activities: []`, escribíamos esa lista vacía en
    // SharedPreferences y, en builds posteriores, el feed de "Siguiendo"
    // se quedaba en blanco ("no hay actividad reciente") hasta reiniciar.
    if (items.isEmpty) return;
    final capped = items.take(50).toList();
    final payload = jsonEncode({
      'fetchedAt': DateTime.now().millisecondsSinceEpoch,
      'items': capped.map((e) => e.toJson()).toList(),
    });
    await _prefs.setString(_keyFor(activityType, isFollowing), payload);
  }

  bool isFresh(DateTime fetchedAt, {Duration window = defaultFreshness}) {
    return DateTime.now().difference(fetchedAt) < window;
  }
}
