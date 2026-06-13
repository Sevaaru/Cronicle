import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cronicle/core/connected_accounts/connected_account_kind.dart';
import 'package:cronicle/features/identity/presentation/connected_accounts_sync.dart';
import 'package:cronicle/core/utils/pending_oauth.dart';
import 'package:cronicle/core/utils/pending_token.dart';
import 'package:cronicle/features/anime/data/datasources/anilist_auth_datasource.dart';
import 'package:cronicle/features/steam/data/datasources/steam_auth_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_api_datasource.dart';
import 'package:cronicle/features/trakt/data/datasources/trakt_auth_datasource.dart';

/// Completes OAuth flows that return to the Flutter web app via localStorage.
Future<void> completePendingWebOAuthCallbacks() async {
  if (!kIsWeb) return;

  await _completePendingTraktOAuth();
  await _completePendingSteamOAuth();
}

/// Reads AniList OAuth callback data from localStorage and exchanges the code
/// for an access token (proxied on web to avoid CORS on the token endpoint).
Future<String?> takePendingAnilistAccessToken(
  AnilistAuthDatasource auth,
) async {
  if (!kIsWeb) return null;

  final pendingCode = await getPendingAnilistCode();
  String? token = await getPendingAnilistToken();

  if (pendingCode != null && pendingCode.isNotEmpty) {
    try {
      token = await auth.exchangeAuthorizationCode(pendingCode);
      if (kDebugMode) {
        debugPrint('[Cronicle] AniList authorization code exchanged.');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[Cronicle] AniList code exchange failed: $e');
      }
      rethrow;
    } finally {
      await clearPendingAnilistCode();
    }
  }

  if (token != null && token.isNotEmpty) {
    await clearPendingAnilistToken();
  }
  return token;
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
    schedulePushConnectedAccount(ConnectedAccountKind.trakt);
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
    schedulePushConnectedAccount(ConnectedAccountKind.steam);
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[Cronicle] Steam OAuth web callback failed: $e');
    }
    await clearPendingSteamOAuth();
  }
}
