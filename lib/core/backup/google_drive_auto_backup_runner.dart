import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/backup/app_backup_bundle.dart';
import 'package:cronicle/core/backup/data/drive_backup_repository.dart';
import 'package:cronicle/core/backup/google_drive_backup_prefs.dart';
import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_graphql_datasource.dart';
import 'package:cronicle/features/library/presentation/anilist_sync_service.dart';
import 'package:cronicle/features/library/presentation/trakt_sync_service.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';

String? _trimOrNull(String value) {
  final t = value.trim();
  return t.isEmpty ? null : t;
}

Future<void> _ensureGoogleSignInInitialized() async {
  if (kIsWeb) return;
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final server = EnvConfig.googleServerClientId.trim();
  final String? clientId = switch (defaultTargetPlatform) {
    TargetPlatform.android => _trimOrNull(EnvConfig.googleAndroidClientId),
    TargetPlatform.iOS => _trimOrNull(EnvConfig.googleIosClientId),
    _ => null,
  };
  await GoogleSignIn.instance.initialize(
    serverClientId: server.isEmpty ? null : server,
    clientId: clientId,
  );
}

Future<bool> runGoogleDriveAutoBackupTask() async {
  if (kIsWeb) return true;
  if (!Platform.isAndroid && !Platform.isIOS) return true;

  try {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(GoogleDriveBackupPrefs.autoEnabled) ?? false)) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final last = prefs.getInt(GoogleDriveBackupPrefs.lastRunMs) ?? 0;
    const minGapMs = 22 * 60 * 60 * 1000;
    if (last != 0 && (now - last) < minGapMs) {
      return true;
    }

    await _ensureGoogleSignInInitialized();

    const scope = 'https://www.googleapis.com/auth/drive.appdata';
    final auth = await GoogleSignIn.instance.authorizationClient
        .authorizationForScopes([scope]);
    if (auth == null) {
      return true;
    }

    final db = AppDatabase();
    const secure = FlutterSecureStorage();
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    try {
      final graphql = AnilistGraphqlDatasource(dio);
      await mergeAnilistLibraryIntoLocalIfSignedIn(
        graphql: graphql,
        db: db,
        auth: AnilistAuthDatasource(secure),
        prefs: prefs,
      );
    } catch (_) {}
    try {
      final traktAuth = TraktAuthDatasource(secure, dio);
      final traktApi = TraktApiDatasource(dio);
      await mergeTraktLibraryIntoLocalIfSignedIn(
        api: traktApi,
        db: db,
        getValidAccessToken: () => traktAuth.getValidAccessToken(),
      );
    } catch (_) {}
    final payload = await AppBackupBundle.build(
      db: db,
      prefs: prefs,
      secure: secure,
    );
    final bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );

    final repo = DriveBackupRepository(GoogleSignIn.instance);
    final res = await repo.uploadBackupWithoutUserInteraction(bytes);
    var uploaded = false;
    res.fold((_) => null, (_) {
      uploaded = true;
    });
    if (uploaded) {
      await prefs.setInt(GoogleDriveBackupPrefs.lastRunMs, now);
    }
    return uploaded;
  } catch (_) {
    return false;
  }
}
