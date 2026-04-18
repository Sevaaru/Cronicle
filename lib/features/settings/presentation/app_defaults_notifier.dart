import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'app_defaults_notifier.g.dart';

// ─── Scoring system ─────────────────────────────────────────────────────────

enum ScoringSystem {
  point100('POINT_100'),
  point10Decimal('POINT_10_DECIMAL'),
  point10('POINT_10'),
  point5('POINT_5'),
  point3('POINT_3');

  const ScoringSystem(this.id);
  final String id;

  static ScoringSystem fromId(String? id) => switch (id) {
        'POINT_100' => point100,
        'POINT_10_DECIMAL' => point10Decimal,
        'POINT_10' => point10,
        'POINT_5' => point5,
        'POINT_3' => point3,
        _ => point10,
      };

  double get max => switch (this) {
        point100 => 100,
        point10Decimal || point10 => 10,
        point5 => 5,
        point3 => 3,
      };

  int get divisions => switch (this) {
        point100 => 100,
        point10Decimal => 100,
        point10 => 10,
        point5 => 5,
        point3 => 3,
      };

  String formatScore(double v) {
    if (v == 0) return '—';
    return switch (this) {
      point100 => '${v.round()}/100',
      point10Decimal => '${v.toStringAsFixed(1)}/10',
      point10 => '${v.round()}/10',
      point5 => '${'★' * v.round()}${'☆' * (5 - v.round())}',
      point3 => switch (v.round()) {
          1 => '😞',
          2 => '😐',
          3 => '😊',
          _ => '—',
        },
    };
  }

  /// Normalise any raw score (stored as 0-10 int in DB) to this system's range.
  double fromStoredScore(int? raw) {
    if (raw == null || raw == 0) return 0;
    final clamped = raw.clamp(0, 10).toDouble();
    return switch (this) {
      point100 => clamped * 10,
      point10Decimal || point10 => clamped,
      point5 => (clamped / 2).clamp(0, 5),
      point3 => (clamped / 3.34).ceil().clamp(1, 3).toDouble(),
    };
  }

  /// Convert the user-facing score back to 0-10 int for storage.
  int toStoredScore(double v) {
    if (v == 0) return 0;
    return switch (this) {
      point100 => (v / 10).round().clamp(0, 10),
      point10Decimal || point10 => v.round().clamp(0, 10),
      point5 => (v * 2).round().clamp(0, 10),
      point3 => (v * 3.34).round().clamp(0, 10),
    };
  }
}

@riverpod
class ScoringSystemSetting extends _$ScoringSystemSetting {
  static const _key = 'scoring_system';

  @override
  ScoringSystem build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ScoringSystem.fromId(prefs.getString(_key));
  }

  Future<void> set(ScoringSystem system) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, system.id);
    state = system;
  }
}

// ─── Anilist advanced scoring ───────────────────────────────────────────────

@riverpod
class AnilistAdvancedScoringEnabled extends _$AnilistAdvancedScoringEnabled {
  static const _key = 'anilist_advanced_scoring';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = !state;
    await prefs.setBool(_key, next);
    state = next;
  }
}

const kAnilistAdvancedScoringCategories = [
  'Story',
  'Characters',
  'Visuals',
  'Audio',
  'Enjoyment',
];

@riverpod
class AnilistAdvancedScores extends _$AnilistAdvancedScores {
  static const _keyPrefix = 'anilist_adv_score_';

  @override
  Map<String, double> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return {
      for (final cat in kAnilistAdvancedScoringCategories)
        cat: prefs.getDouble('$_keyPrefix$cat') ?? 0,
    };
  }

  Future<void> setScore(String category, double value) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble('$_keyPrefix$category', value);
    state = {...state, category: value};
  }

  Future<void> reset() async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final cat in kAnilistAdvancedScoringCategories) {
      await prefs.remove('$_keyPrefix$cat');
    }
    state = {for (final cat in kAnilistAdvancedScoringCategories) cat: 0};
  }
}

@riverpod
class DefaultStartPage extends _$DefaultStartPage {
  static const _key = 'default_start_page';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key) ?? '/feed';
  }

  Future<void> set(String route) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, route);
    state = route;
  }
}

@riverpod
class DefaultFeedTab extends _$DefaultFeedTab {
  static const _key = 'default_feed_tab';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return 'anime';
    if (raw == 'following' || raw == 'all' || raw == 'feed') return 'anime';
    return raw;
  }

  Future<void> set(String tab) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, tab);
    state = tab;
  }
}

@riverpod
class DefaultFeedActivityScope extends _$DefaultFeedActivityScope {
  static const _key = 'default_feed_activity_scope';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == 'following') return 'following';
    if (raw == 'global') return 'global';
    final legacyTab = prefs.getString('default_feed_tab');
    if (legacyTab == 'following') return 'following';
    return 'global';
  }

  Future<void> set(String scope) async {
    if (scope != 'following' && scope != 'global') return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, scope);
    state = scope;
  }
}

@riverpod
class HideTextActivities extends _$HideTextActivities {
  static const _key = 'hide_text_activities';

  @override
  bool build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getBool(_key) ?? false;
  }

  Future<void> toggle() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final next = !state;
    await prefs.setBool(_key, next);
    state = next;
  }
}
