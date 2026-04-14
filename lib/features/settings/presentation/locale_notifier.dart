import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'locale_notifier.g.dart';

@riverpod
class LocaleNotifier extends _$LocaleNotifier {
  static const _key = 'locale_code';
  static const _supported = ['es', 'en'];

  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final saved = prefs.getString(_key);
    if (saved != null) return Locale(saved);

    final deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    return Locale(_supported.contains(deviceLang) ? deviceLang : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}
