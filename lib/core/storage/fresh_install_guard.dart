import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Detects a fresh install (or a restore from cloud backup) and wipes any
/// stale credentials that may have leaked across the reinstall boundary.
///
/// Why this exists:
///  * Android Auto Backup (when enabled) restores SharedPreferences and the
///    EncryptedSharedPreferences blob used by `flutter_secure_storage`, but
///    the Android Keystore key that decrypts that blob is wiped on uninstall.
///    The result: a restored, undecryptable blob and "token inválido" errors.
///  * iOS Keychain persists across uninstall by default, so old OAuth tokens
///    survive even a clean reinstall.
///
/// Strategy: write a sentinel file inside the application-support directory
/// (which is wiped on uninstall on both Android and iOS). If the sentinel is
/// missing on startup we treat this launch as a fresh install and clear the
/// secure storage before anything else reads from it.
Future<void> ensureFreshInstallCleanup() async {
  if (kIsWeb) return;

  try {
    final dir = await getApplicationSupportDirectory();
    final sentinel = File('${dir.path}/.install_sentinel_v1');
    if (await sentinel.exists()) return;

    // Fresh install (or restored backup without app-private files): wipe any
    // leftover OAuth tokens / credentials so the user re-authenticates cleanly.
    try {
      const secure = FlutterSecureStorage();
      await secure.deleteAll();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Cronicle] fresh-install secure wipe failed: $e');
      }
    }

    try {
      await sentinel.create(recursive: true);
      await sentinel.writeAsString(
        DateTime.now().toUtc().toIso8601String(),
        flush: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Cronicle] fresh-install sentinel write failed: $e');
      }
    }

    if (kDebugMode) {
      debugPrint('[Cronicle] fresh install detected: secure storage cleared');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] ensureFreshInstallCleanup error: $e');
    }
  }
}
