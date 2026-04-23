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

    // First launch: pick Spanish if ANY of the device's preferred locales
    // is some flavor of Spanish (es, es-ES, es-MX, es-419, ca-es, etc.),
    // otherwise fall back to English.
    final dispatcher = ui.PlatformDispatcher.instance;
    final candidates = <ui.Locale>[
      ...dispatcher.locales,
      dispatcher.locale,
    ];
    final hasSpanish = candidates.any((l) {
      final code = l.languageCode.toLowerCase();
      return code == 'es' || code.startsWith('es_') || code.startsWith('es-');
    });
    return Locale(hasSpanish ? 'es' : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, locale.languageCode);
    state = locale;
  }
}
