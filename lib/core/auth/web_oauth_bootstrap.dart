import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/utils/pending_oauth.dart';
import 'package:cronicle/features/steam/data/datasources/steam_auth_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';

/// Completes OAuth flows that return to the Flutter web app via localStorage.
Future<void> completePendingWebOAuthCallbacks() async {
  if (!kIsWeb) return;

  await _completePendingTraktOAuth();
  await _completePendingSteamOAuth();
}

Future<void> _completePendingTraktOAuth() async {
  final pending = await getPendingTraktOAuth();
  if (pending == null) return;

  try {
    final prefs = await SharedPreferences.getInstance();
    const stateKey = 'trakt_oauth_state';
    final expected = prefs.getString(stateKey);
    if (expected == null || expected != pending.state) {
      if (kDebugMode) {
        debugPrint('[Cronicle] Trakt OAuth state mismatch; ignoring callback.');
      }
      return;
    }

    final auth = TraktAuthDatasource(const FlutterSecureStorage(), Dio());
    await auth.exchangeAuthorizationCode(pending.code);
    final token = await auth.getValidAccessToken();
    if (token != null) {
      final api = TraktApiDatasource(Dio());
      final settings = await api.fetchUserSettings(token);
      await auth.saveUserFromSettings(settings);
    }
    await prefs.remove(stateKey);
    await clearPendingTraktOAuth();

    if (kDebugMode) {
      debugPrint('[Cronicle] Trakt OAuth completed from web callback.');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] Trakt OAuth web callback failed: $e');
    }
    await clearPendingTraktOAuth();
  }
}

Future<void> _completePendingSteamOAuth() async {
  final query = await getPendingSteamOAuthQuery();
  if (query == null || query.isEmpty) return;

  try {
    final returned = Uri.parse('http://local$query');
    final claimed = returned.queryParameters['openid.claimed_id'] ?? '';
    final match = RegExp(r'/openid/id/(\d+)').firstMatch(claimed);
    final steamId = match?.group(1) ?? '';
    if (steamId.isEmpty) {
      await clearPendingSteamOAuth();
      return;
    }

    final auth = SteamAuthDatasource(const FlutterSecureStorage());
    await auth.saveSteamId(steamId);
    await clearPendingSteamOAuth();

    if (kDebugMode) {
      debugPrint('[Cronicle] Steam OAuth completed from web callback.');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] Steam OAuth web callback failed: $e');
    }
    await clearPendingSteamOAuth();
  }
}
