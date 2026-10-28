import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/notifications/notification_work_scheduler.dart';
import 'package:cronicle/core/router/app_router.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/onboarding/presentation/onboarding_notifier.dart';
import 'package:cronicle/features/settings/presentation/device_notifications_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

class NotificationPermissionBootstrap extends ConsumerStatefulWidget {
  const NotificationPermissionBootstrap({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationPermissionBootstrap> createState() =>
      _NotificationPermissionBootstrapState();
}

class _NotificationPermissionBootstrapState
    extends ConsumerState<NotificationPermissionBootstrap> {
  static bool _inFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alreadyDone = ref.read(onboardingCompletedProvider);
      if (alreadyDone) {
        _maybeRequestNotificationPermission();
      } else {
        ref.listenManual(
          onboardingCompletedProvider,
          (_, completed) {
            if (completed) _maybeRequestNotificationPermission();
          },
        );
      }
    });
  }

  Future<void> _maybeRequestNotificationPermission() async {
    if (kIsWeb) return;
    if (!(defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS)) {
      return;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    if (prefs.getBool(DeviceNotificationPrefs.permissionPrompted) == true) {
      return;
    }
    if (_inFlight) return;
    _inFlight = true;

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));

      await prefs.setBool(DeviceNotificationPrefs.permissionPrompted, true);

      final granted =
          await CronicleLocalNotifications.requestSystemPermission() ?? false;

      if (granted) {
        await ref
            .read(deviceNotificationSettingsProvider.notifier)
            .applyDefaultsAfterPermissionGranted();
      } else {
        final navCtx = cronicleRootNavigatorKey.currentContext;
        if (navCtx != null && navCtx.mounted) {
          final l10n = AppLocalizations.of(navCtx);
          if (l10n != null) {
            ScaffoldMessenger.of(navCtx).showSnackBar(
              SnackBar(content: Text(l10n.notifPermissionDeniedHint)),
            );
          }
        }
      }

      await NotificationWorkScheduler.applyFromPrefs(
        ref.read(sharedPreferencesProvider),
      );
    } finally {
      _inFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
