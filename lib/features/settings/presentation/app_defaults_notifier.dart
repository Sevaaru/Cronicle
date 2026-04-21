import 'dart:convert';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'app_defaults_notifier.g.dart';


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

  double fromStoredScore(int? raw) {
    if (raw == null || raw == 0) return 0;
    final clamped = raw.clamp(0, 100).toDouble();
    return switch (this) {
      point100 => clamped,
      point10Decimal => clamped / 10,
      point10 => (clamped / 10).roundToDouble(),
      point5 => (clamped / 20).roundToDouble().clamp(0, 5),
      point3 => (clamped / 33.34).ceil().clamp(1, 3).toDouble(),
    };
  }

  int toStoredScore(double v) {
    if (v == 0) return 0;
    return switch (this) {
      point100 => v.round().clamp(0, 100),
      point10Decimal => (v * 10).round().clamp(0, 100),
      point10 => (v * 10).round().clamp(0, 100),
      point5 => (v * 20).round().clamp(0, 100),
      point3 => (v * 33.34).round().clamp(0, 100),
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

enum ProfileAvatarSource {
  local('local'),
  anilist('anilist'),
  trakt('trakt');

  const ProfileAvatarSource(this.id);
  final String id;

  static ProfileAvatarSource fromId(String? id) {
    return switch (id) {
      'local' => ProfileAvatarSource.local,
      'trakt' => ProfileAvatarSource.trakt,
      _ => ProfileAvatarSource.anilist,
    };
  }
}

@riverpod
class ProfileAvatarSourceSetting extends _$ProfileAvatarSourceSetting {
  static const _key = 'profile_avatar_source';

  @override
  ProfileAvatarSource build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ProfileAvatarSource.fromId(prefs.getString(_key));
  }

  Future<void> set(ProfileAvatarSource source) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, source.id);
    state = source;
  }
}

@riverpod
class LocalProfileAvatar extends _$LocalProfileAvatar {
  static const _key = 'profile_avatar_local_b64';

  @override
  Uint8List? build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  Future<void> setBytes(Uint8List bytes) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, base64Encode(bytes));
    state = bytes;
  }

  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_key);
    state = null;
  }
}
