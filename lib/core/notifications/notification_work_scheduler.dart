import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/notifications/notification_background.dart';

/// Registra o cancela la tarea periódica según preferencias.
class NotificationWorkScheduler {
  NotificationWorkScheduler._();

  static Future<void> applyFromPrefs(SharedPreferences prefs) async {
    if (kIsWeb) return;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    await CronicleLocalNotifications.init();
    await ensureNotificationWorkmanagerInitialized();

    final master =
        prefs.getBool(DeviceNotificationPrefs.masterEnabled) ?? false;
    final airing =
        prefs.getBool(DeviceNotificationPrefs.airingEnabled) ?? true;
    final anilist =
        prefs.getBool(DeviceNotificationPrefs.anilistInboxEnabled) ?? true;

    if (!master || (!airing && !anilist)) {
      await Workmanager().cancelByUniqueName(kCronicleNotifWorkName);
      return;
    }

    // Android aplaza con frecuencia los trabajos de ~1 h; 15 min es el mínimo
    // fiable de WorkManager y encaja con avisos tipo bandeja de Anilist.
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;

    await Workmanager().registerPeriodicTask(
      kCronicleNotifWorkName,
      kCronicleNotifWorkName,
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
