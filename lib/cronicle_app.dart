import 'dart:async';
import 'dart:math' show max;

import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/app/cronicle_quick_actions.dart';
import 'package:cronicle/core/app/global_messenger.dart';
import 'package:cronicle/core/auth/web_oauth_bootstrap.dart';
import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/notification_lifecycle_sync.dart';
import 'package:cronicle/core/notifications/notification_permission_bootstrap.dart';
import 'package:cronicle/core/router/app_router.dart';
import 'package:cronicle/core/theme/app_theme.dart';
import 'package:cronicle/core/wear/wear_event_listener.dart';
import 'package:cronicle/features/achievements/presentation/achievement_overlay.dart';
import 'package:cronicle/features/achievements/presentation/achievements_bootstrap.dart';
import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/identity/presentation/connected_accounts_sync.dart';
import 'package:cronicle/features/identity/presentation/cronicle_auth_providers.dart';
import 'package:cronicle/features/settings/presentation/locale_notifier.dart';
import 'package:cronicle/features/steam/presentation/steam_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
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
      final router = ref.read(appRouterProvider);
      CronicleLocalNotifications.consumePendingLaunchRoute(router);
      // Conecta el router a los Quick Actions y consume cualquier
      // shortcut pendiente del cold start.
      CronicleQuickActions.bindRouter(router);
      unawaited(_bootstrapConnectedAccounts());
      if (kIsWeb) {
        ref.invalidate(traktSessionProvider);
        ref.invalidate(steamSessionProvider);
        unawaited(_completePendingAnilistWebOAuth());
      }
    });
  }

  Future<void> _bootstrapConnectedAccounts() async {
    if (ref.read(cronicleAuthSessionProvider).valueOrNull == null) return;
    await restoreConnectedAccounts(ref);
    await ref.read(connectedAccountsRepositoryProvider)?.pushAllConnected();
  }

  Future<void> _completePendingAnilistWebOAuth() async {
    try {
      final auth = ref.read(anilistAuthProvider);
      final token = await takePendingAnilistAccessToken(auth);
      if (token == null || token.isEmpty || !mounted) return;

      await ref.read(anilistTokenProvider.notifier).setToken(token);

      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null || !mounted) return;
      final l10n = AppLocalizations.of(context);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n?.anilistConnectSuccess ?? 'AniList connected'),
        ),
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Cronicle] AniList web OAuth bootstrap failed: $e');
      }
      final saved = await ref.read(anilistAuthProvider).getToken();
      if (saved != null && saved.isNotEmpty) {
        ref.invalidate(anilistTokenProvider);
        final messenger = rootScaffoldMessengerKey.currentState;
        if (messenger != null && mounted) {
          final l10n = AppLocalizations.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(l10n?.anilistConnectSuccess ?? 'AniList connected'),
            ),
          );
        }
        return;
      }
      final messenger = rootScaffoldMessengerKey.currentState;
      if (messenger == null || !mounted) return;
      final text = e.toString().contains('dev_api_proxy') ||
              e.toString().contains('Proxy local desactualizado')
          ? 'AniList: reinicia el proxy con .\\scripts\\run_web.ps1 (puerto 8787)'
          : 'AniList: no se pudo completar la conexión ($e)';
      messenger.showSnackBar(
        SnackBar(
          content: Text(text),
          duration: const Duration(seconds: 10),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeNotifierProvider);
    final locale = ref.watch(localeNotifierProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      scrollBehavior: kIsWeb
          ? const MaterialScrollBehavior().copyWith(
              dragDevices: {
                PointerDeviceKind.touch,
                PointerDeviceKind.mouse,
                PointerDeviceKind.stylus,
                PointerDeviceKind.trackpad,
              },
            )
          : null,
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
            child: AchievementsBootstrap(
              child: AchievementOverlayHost(
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          ),
        );
        return _webClampViewInsets(content);
      },
    );
  }
}
