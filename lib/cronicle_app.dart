import 'dart:math' show max;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/app/global_messenger.dart';
import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/notification_lifecycle_sync.dart';
import 'package:cronicle/core/notifications/notification_permission_bootstrap.dart';
import 'package:cronicle/core/router/app_router.dart';
import 'package:cronicle/core/theme/app_theme.dart';
import 'package:cronicle/core/wear/wear_event_listener.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/settings/presentation/theme_mode_notifier.dart';
import 'package:cronicle/l10n/app_localizations.dart';

Widget _webClampViewInsets(Widget child) {
  if (!kIsWeb) return child;
  return Builder(
    builder: (context) {
      final mq = MediaQuery.maybeOf(context);
      if (mq == null) return child;
      final vi = mq.viewInsets;
      if (vi.left >= 0 && vi.top >= 0 && vi.right >= 0 && vi.bottom >= 0) {
        return child;
      }
      return MediaQuery(
        data: mq.copyWith(
          viewInsets: EdgeInsets.only(
            left: max(0.0, vi.left),
            top: max(0.0, vi.top),
            right: max(0.0, vi.right),
            bottom: max(0.0, vi.bottom),
          ),
        ),
        child: child,
      );
    },
  );
}

class CronicleApp extends ConsumerStatefulWidget {
  const CronicleApp({super.key});

  @override
  ConsumerState<CronicleApp> createState() => _CronicleAppState();
}

class _CronicleAppState extends ConsumerState<CronicleApp> {
  @override
  void initState() {
    super.initState();
    ref.read(wearEventListenerProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      CronicleLocalNotifications.consumePendingLaunchRoute(
        ref.read(appRouterProvider),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) {
        final content = NotificationPermissionBootstrap(
          child: NotificationLifecycleSync(
            child: child ?? const SizedBox.shrink(),
          ),
        );
        return _webClampViewInsets(content);
      },
    );
  }
}
