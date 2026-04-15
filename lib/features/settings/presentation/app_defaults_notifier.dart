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
    return prefs.getString(_key) ?? 'all';
  }

  Future<void> set(String tab) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, tab);
    state = tab;
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
