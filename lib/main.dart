import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/core/utils/pending_token.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/cronicle_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _handleAnilistOAuthCallback();

  try {
    await GoogleSignIn.instance.initialize();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] Google Sign-In init skipped: $e');
    }
  }

  final prefs = await SharedPreferences.getInstance();

  // Normalizar status de entries guardados con lowercase
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
  await clearPendingAnilistToken();

  if (kDebugMode) {
    debugPrint('[Cronicle] Anilist token guardado automáticamente');
  }
}
