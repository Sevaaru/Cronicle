import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cronicle/core/backup/google_drive_backup_prefs.dart';
import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/notification_background.dart';

/// Registra o cancela la tarea periódica de copia automática a Drive.
class GoogleDriveBackupScheduler {
  GoogleDriveBackupScheduler._();

  static Future<void> applyFromPrefs(SharedPreferences prefs) async {
    if (kIsWeb) return;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    await ensureNotificationWorkmanagerInitialized();

    final enabled =
        prefs.getBool(GoogleDriveBackupPrefs.autoEnabled) ?? false;
    if (!enabled) {
      await Workmanager().cancelByUniqueName(kCronicleDriveBackupWorkName);
      return;
    }

    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    await Workmanager().registerPeriodicTask(
      kCronicleDriveBackupWorkName,
      kCronicleDriveBackupWorkName,
      frequency: isAndroid
          ? const Duration(minutes: 15)
          : const Duration(hours: 1),
      flexInterval: isAndroid ? const Duration(minutes: 5) : null,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
    );
  }
}
