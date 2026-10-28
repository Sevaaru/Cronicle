import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/notifications/notification_sync_runner.dart';
import 'package:cronicle/core/notifications/notification_work_scheduler.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';

part 'device_notifications_notifier.g.dart';

class DeviceNotificationState {
  const DeviceNotificationState({
    required this.masterEnabled,
    required this.airingEnabled,
    required this.anilistInboxEnabled,
    required this.anilistSocialEnabled,
  });

  final bool masterEnabled;
  final bool airingEnabled;
  final bool anilistInboxEnabled;
  final bool anilistSocialEnabled;
}

@Riverpod(keepAlive: true)
class DeviceNotificationSettings extends _$DeviceNotificationSettings {
  @override
  DeviceNotificationState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return DeviceNotificationState(
      masterEnabled:
          prefs.getBool(DeviceNotificationPrefs.masterEnabled) ?? false,
      airingEnabled:
          prefs.getBool(DeviceNotificationPrefs.airingEnabled) ?? true,
      anilistInboxEnabled:
          prefs.getBool(DeviceNotificationPrefs.anilistInboxEnabled) ?? true,
      anilistSocialEnabled:
          prefs.getBool(DeviceNotificationPrefs.anilistSocialEnabled) ?? true,
    );
  }

  Future<void> _persistAndSchedule(DeviceNotificationState next) async {
    final p = ref.read(sharedPreferencesProvider);
    await p.setBool(DeviceNotificationPrefs.masterEnabled, next.masterEnabled);
    await p.setBool(DeviceNotificationPrefs.airingEnabled, next.airingEnabled);
    await p.setBool(
      DeviceNotificationPrefs.anilistInboxEnabled,
      next.anilistInboxEnabled,
    );
    await p.setBool(
      DeviceNotificationPrefs.anilistSocialEnabled,
      next.anilistSocialEnabled,
    );
    state = next;
    await NotificationWorkScheduler.applyFromPrefs(p);
    Future<void>.delayed(Duration.zero, () async {
      try {
        await runNotificationSyncTask();
      } catch (_) {}
    });
  }

  Future<void> setMasterEnabled(bool v) async {
    await _persistAndSchedule(
      DeviceNotificationState(
        masterEnabled: v,
        airingEnabled: state.airingEnabled,
        anilistInboxEnabled: state.anilistInboxEnabled,
        anilistSocialEnabled: state.anilistSocialEnabled,
      ),
    );
  }

  Future<void> setAiringEnabled(bool v) async {
    await _persistAndSchedule(
      DeviceNotificationState(
        masterEnabled: state.masterEnabled,
        airingEnabled: v,
        anilistInboxEnabled: state.anilistInboxEnabled,
        anilistSocialEnabled: state.anilistSocialEnabled,
      ),
    );
  }

  Future<void> setAnilistInboxEnabled(bool v) async {
    await _persistAndSchedule(
      DeviceNotificationState(
        masterEnabled: state.masterEnabled,
        airingEnabled: state.airingEnabled,
        anilistInboxEnabled: v,
        anilistSocialEnabled: v ? state.anilistSocialEnabled : false,
      ),
    );
  }

  Future<void> setAnilistSocialEnabled(bool v) async {
    await _persistAndSchedule(
      DeviceNotificationState(
        masterEnabled: state.masterEnabled,
        airingEnabled: state.airingEnabled,
        anilistInboxEnabled: state.anilistInboxEnabled,
        anilistSocialEnabled: v,
      ),
    );
  }

  Future<void> applyDefaultsAfterPermissionGranted() async {
    await _persistAndSchedule(
      const DeviceNotificationState(
        masterEnabled: true,
        airingEnabled: true,
        anilistInboxEnabled: true,
        anilistSocialEnabled: true,
      ),
    );
  }
}
