import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/backup/google_drive_backup_scheduler.dart';
import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/notifications/cronicle_local_notifications.dart';
import 'package:cronicle/core/notifications/notification_background.dart';
import 'package:cronicle/core/notifications/notification_work_scheduler.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/core/storage/fresh_install_guard.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/core/utils/pending_token.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/cronicle_app.dart';
import 'package:cronicle/wear_sync_entry.dart';

String? _trimOrNull(String value) {
  final t = value.trim();
  return t.isEmpty ? null : t;
}

Future<void> _migrateUnifiedFeedPreferences(SharedPreferences p) async {
  final tab = p.getString('default_feed_tab');
  if (tab == 'following') {
    await p.setString('default_feed_tab', 'feed');
    await p.setString('default_feed_activity_scope', 'following');
  } else if (tab == 'all') {
    await p.setString('default_feed_tab', 'feed');
    if (!p.containsKey('default_feed_activity_scope')) {
      await p.setString('default_feed_activity_scope', 'global');
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Detect fresh install / cloud-restored install and wipe stale credentials
  // BEFORE anything reads from secure storage (including the OAuth callback).
  await ensureFreshInstallCleanup();

  await _handleAnilistOAuthCallback();

  if (!kIsWeb) {
    try {
      final server = EnvConfig.googleServerClientId.trim();
      final String? clientId = switch (defaultTargetPlatform) {
        TargetPlatform.android =>
          _trimOrNull(EnvConfig.googleAndroidClientId),
        TargetPlatform.iOS => _trimOrNull(EnvConfig.googleIosClientId),
        _ => null,
      };
      await GoogleSignIn.instance.initialize(
        serverClientId: server.isEmpty ? null : server,
        clientId: clientId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Cronicle] Google Sign-In init: $e');
        if (EnvConfig.googleServerClientId.trim().isEmpty) {
          debugPrint(
            '[Cronicle] Android: define GOOGLE_SERVER_CLIENT_ID (cliente Web) y el SHA-1 '
            'de debug/release en el cliente OAuth Android. Opcional: GOOGLE_ANDROID_CLIENT_ID.',
          );
        }
      }
    }
  }

  final prefs = await SharedPreferences.getInstance();
  await _migrateUnifiedFeedPreferences(prefs);

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await CronicleLocalNotifications.init();
    await ensureNotificationWorkmanagerInitialized();
    await NotificationWorkScheduler.applyFromPrefs(prefs);
    await GoogleDriveBackupScheduler.applyFromPrefs(prefs);
  }

  try {
    await AppDatabase().normalizeStatuses();
  } catch (_) {}

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CronicleApp(),
    ),
  );
}

Future<void> _handleAnilistOAuthCallback() async {
  final pendingToken = await getPendingAnilistToken();
  if (pendingToken == null || pendingToken.isEmpty) return;

  final auth = AnilistAuthDatasource(const FlutterSecureStorage());
  await auth.saveToken(pendingToken);
  try {
    final gql = AnilistGraphqlDatasource(Dio());
    final viewer = await gql.fetchViewer(pendingToken);
    final name = viewer?['name'] as String?;
    if (name != null && name.isNotEmpty) {
      await auth.saveUserName(name);
    }
    final opts = viewer?['mediaListOptions'] as Map<String, dynamic>?;
    final fmt = opts?['scoreFormat'] as String?;
    if (fmt != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('scoring_system', fmt);
    }
  } catch (_) {}
  await clearPendingAnilistToken();

  if (kDebugMode) {
    debugPrint('[Cronicle] Anilist token saved automatically');
  }
}
