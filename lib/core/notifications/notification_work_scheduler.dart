import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/notifications/notification_background.dart';

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
