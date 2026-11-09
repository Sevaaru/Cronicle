import 'dart:convert';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

/// Generic SharedPreferences-backed JSON cache with timestamps.
///
/// Used for stale-while-revalidate patterns across the app:
/// home feeds (Trakt, IGDB, Books, AniList trending), profile snapshots,
/// and any other JSON-encodable network response that should survive a
/// cold app start.
class JsonCache {
  JsonCache(this._prefs);

  final SharedPreferences _prefs;

  static String _keyFor(String name) => 'json_cache_v1::$name';

  CachedJson? read(String name) {
    final raw = _prefs.getString(_keyFor(name));
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (json['fetchedAt'] as num?)?.toInt();
      final data = json['data'];
      if (ts == null || data is! Map) return null;
      return CachedJson(
        data: Map<String, dynamic>.from(data),
        fetchedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write(String name, Map<String, dynamic> data) async {
    try {
      final payload = jsonEncode({
        'fetchedAt': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      });
      await _prefs.setString(_keyFor(name), payload);
    } catch (_) {
      // Ignore non-encodable values silently; cache is best-effort.
    }
  }

  Future<void> clear(String name) async {
    await _prefs.remove(_keyFor(name));
  }

  bool isFresh(DateTime fetchedAt, Duration window) {
    return DateTime.now().difference(fetchedAt) < window;
  }
}

class CachedJson {
  const CachedJson({required this.data, required this.fetchedAt});

  final Map<String, dynamic> data;
  final DateTime fetchedAt;
}

final jsonCacheProvider = Provider<JsonCache>((ref) {
  return JsonCache(ref.watch(sharedPreferencesProvider));
});

/// Helper to safely cast a List of decoded JSON to `List<Map<String, dynamic>>`.
List<Map<String, dynamic>> jsonListAsMaps(dynamic raw) {
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map) {
      out.add(Map<String, dynamic>.from(e));
    }
  }
  return out;
}
