import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'locale_notifier.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'locale_code';

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final code = prefs.getString(_key) ?? 'es';
    return Locale(code);
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}
