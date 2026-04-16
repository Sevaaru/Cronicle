import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'app_defaults_notifier.g.dart';

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
    if (raw == null || raw.isEmpty) return 'feed';
    if (raw == 'following' || raw == 'all') return 'feed';
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
