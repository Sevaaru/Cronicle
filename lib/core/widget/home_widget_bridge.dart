import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Lightweight bridge to the native Android home-screen widget
/// ([LibraryWidgetProvider]).
///
/// The Flutter side calls [refresh] after any library mutation so the
/// home-screen widget re-queries the SQLite database and updates its list.
///
/// On non-Android platforms (or in tests / web builds) every method is a
/// silent no-op so call sites do not need to guard.
class HomeWidgetBridge {
  HomeWidgetBridge._();

  static const _channel = MethodChannel('cronicle.widget');

  static Future<void> refresh() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('refresh');
    } catch (_) {
      // Widget bridge is best-effort; never surface failures to callers.
    }
  }
}
