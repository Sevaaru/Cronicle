import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/device_notification_prefs.dart';
import 'package:cronicle/core/notifications/notification_work_scheduler.dart';
import 'package:cronicle/core/router/app_router.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/settings/presentation/device_notifications_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

/// Colgar bajo [MaterialApp] para que [showDialog] use un contexto con
/// [Navigator] (el de [cronicleRootNavigatorKey]) y se muestren el aviso
/// inicial y el permiso del sistema en Android 13+ / iOS.
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
      _maybeRequestNotificationPermission();
    });
  }

  Future<BuildContext?> _waitForNavigatorContext() async {
    for (var i = 0; i < 30; i++) {
      final ctx = cronicleRootNavigatorKey.currentContext;
      if (ctx != null && ctx.mounted) return ctx;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return null;
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
      final navCtx = await _waitForNavigatorContext();
      if (navCtx == null || !navCtx.mounted) return;

      final l10n = AppLocalizations.of(navCtx)!;
      final accept = await showDialog<bool>(
        context: navCtx,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.notifPermissionTitle),
          content: Text(l10n.notifPermissionBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.notifPermissionNotNow),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.notifPermissionAllow),
            ),
          ],
        ),
      );

      await prefs.setBool(DeviceNotificationPrefs.permissionPrompted, true);

      if (!navCtx.mounted) return;
      if (accept == true) {
        await CronicleLocalNotifications.requestSystemPermission();
        await ref
            .read(deviceNotificationSettingsProvider.notifier)
            .applyDefaultsAfterPermissionGranted();
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
