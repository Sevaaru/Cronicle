import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'theme_mode_notifier.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return ThemeMode.dark;
    return ThemeMode.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => ThemeMode.dark,
    );
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, mode.name);
    state = mode;
  }
}
