import 'dart:ui' show DartPluginRegistrant;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import 'package:cronicle/core/backup/google_drive_auto_backup_runner.dart';
import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/notification_sync_runner.dart';

bool _workmanagerInitialized = false;

Future<void> ensureNotificationWorkmanagerInitialized() async {
  if (kIsWeb || _workmanagerInitialized) return;
  if (!(defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS)) {
    return;
  }

  await Workmanager().initialize(
    notificationCallbackDispatcher,
    isInDebugMode: kDebugMode,
  );
  _workmanagerInitialized = true;
}

@pragma('vm:entry-point')
void notificationCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();
    await CronicleLocalNotifications.init();
    if (task == kCronicleDriveBackupWorkName) {
      return await runGoogleDriveAutoBackupTask();
    }
    final ok = await runNotificationSyncTask();
    await runGoogleDriveAutoBackupTask();
    return ok;
  });
}
