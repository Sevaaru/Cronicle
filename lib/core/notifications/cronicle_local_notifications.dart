import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

import 'package:cronicle/core/router/app_router.dart';

const String kCronicleChannelAiring = 'cronicle_airing_v2';
const String kCronicleChannelAnilist = 'cronicle_anilist_v2';

const String kCronicleNotifWorkName = 'cronicle_notif_sync';

const String kCronicleDriveBackupWorkName = 'cronicle_drive_auto_backup';

const String kAndroidNotificationGroupCronicle =
    'com.cronicle.app.notifications';

const String kNotificationPayloadAnilistInbox = '/notifications';

const String kNotificationPayloadFeed = '/feed';

final FlutterLocalNotificationsPlugin _fln = FlutterLocalNotificationsPlugin();

bool _cronicleNotifInited = false;

String? _pendingRouteFromNotification;

bool get _isAndroidOrIos =>
    !kIsWeb &&
    (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS);

void _onNotificationResponse(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || !payload.startsWith('/')) return;

  void navigate() {
    final ctx = cronicleRootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(payload);
    } else {
      _pendingRouteFromNotification = payload;
    }
  }

  WidgetsBinding.instance.addPostFrameCallback((_) => navigate());
}

class CronicleLocalNotifications {
  CronicleLocalNotifications._();

  static void consumePendingLaunchRoute(GoRouter router) {
    final route = _pendingRouteFromNotification;
    _pendingRouteFromNotification = null;
    if (route == null || route.isEmpty) return;
    router.go(route);
  }

  static Future<void> init() async {
    if (kIsWeb || _cronicleNotifInited) return;
    if (!_isAndroidOrIos) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    await _fln.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: darwinInit,
        macOS: darwinInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final launch = await _fln.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      final p = launch!.notificationResponse?.payload;
      if (p != null && p.startsWith('/')) {
        _pendingRouteFromNotification = p;
      }
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final android = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kCronicleChannelAiring,
          'Nuevos capítulos',
          description: 'Avisos cuando sale un capítulo de algo que sigues.',
          importance: Importance.high,
        ),
      );
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          kCronicleChannelAnilist,
          'Anilist',
          description: 'Notificaciones sincronizadas desde tu bandeja de Anilist.',
          importance: Importance.high,
        ),
      );
    }

    _cronicleNotifInited = true;
  }

  static Future<bool?> requestSystemPermission() async {
    if (kIsWeb) return false;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final impl = _fln.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      return impl?.requestNotificationsPermission();
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final impl = _fln.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return impl?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final impl = _fln.resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin>();
      return impl?.requestPermissions(alert: true, badge: true, sound: true);
    }
    return null;
  }

  static Future<void> showAiringNewEpisode({
    required int notificationId,
    required String title,
    required String body,
    String? expandedBody,
    Uint8List? largeIconBytes,
  }) async {
    if (!_cronicleNotifInited) await init();
    if (kIsWeb || !_isAndroidOrIos) return;

    final AndroidBitmap<Object>? largeIcon =
        largeIconBytes != null ? ByteArrayAndroidBitmap(largeIconBytes) : null;

    await _fln.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kCronicleChannelAiring,
          'Nuevos capítulos',
          channelDescription:
              'Avisos cuando sale un capítulo de anime o manga que sigues.',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: kAndroidNotificationGroupCronicle,
          largeIcon: largeIcon,
          styleInformation: BigTextStyleInformation(expandedBody ?? body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: kNotificationPayloadFeed,
    );
  }

  static Future<void> showAnilistMirror({
    required int notificationId,
    required String title,
    required String body,
    Uint8List? largeIconBytes,
  }) async {
    if (!_cronicleNotifInited) await init();
    if (kIsWeb || !_isAndroidOrIos) return;

    final AndroidBitmap<Object>? largeIcon =
        largeIconBytes != null ? ByteArrayAndroidBitmap(largeIconBytes) : null;

    await _fln.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          kCronicleChannelAnilist,
          'Anilist',
          channelDescription: 'Bandeja de Anilist en el dispositivo.',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: kAndroidNotificationGroupCronicle,
          largeIcon: largeIcon,
          styleInformation: BigTextStyleInformation(body),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: kNotificationPayloadAnilistInbox,
    );
  }
}
