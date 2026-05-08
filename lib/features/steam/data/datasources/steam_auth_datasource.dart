import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Manages Steam OpenID 2.0 "Sign in through Steam" flow + persistence.
///
/// Steam doesn't expose OAuth: clients send the user to a hosted bridge that
/// redirects to Steam's OpenID endpoint, then sends the resolved SteamID64
/// back via `cronicle://steam-oauth?openid.claimed_id=...`.
class SteamAuthDatasource {
  SteamAuthDatasource(this._storage);

  final FlutterSecureStorage _storage;

  static const _steamIdKey = 'steam_steamid64';
  static const _personaKey = 'steam_persona_name';
  static const _avatarKey = 'steam_avatar_url';
  static const _profileUrlKey = 'steam_profile_url';

  Future<String?> getSteamId() => _storage.read(key: _steamIdKey);
  Future<String?> getPersonaName() => _storage.read(key: _personaKey);
  Future<String?> getAvatarUrl() => _storage.read(key: _avatarKey);
  Future<String?> getProfileUrl() => _storage.read(key: _profileUrlKey);

  Future<bool> hasSession() async {
    final id = await getSteamId();
    return id != null && id.isNotEmpty;
  }

  Future<void> saveSteamId(String steamId) =>
      _storage.write(key: _steamIdKey, value: steamId);

  Future<void> savePlayerSummary({
    String? personaName,
    String? avatarUrl,
    String? profileUrl,
  }) async {
    if (personaName != null && personaName.isNotEmpty) {
      await _storage.write(key: _personaKey, value: personaName);
    }
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await _storage.write(key: _avatarKey, value: avatarUrl);
    }
    if (profileUrl != null && profileUrl.isNotEmpty) {
      await _storage.write(key: _profileUrlKey, value: profileUrl);
    }
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _steamIdKey);
    await _storage.delete(key: _personaKey);
    await _storage.delete(key: _avatarKey);
    await _storage.delete(key: _profileUrlKey);
  }

  /// Launches the Steam OpenID flow via the hosted web bridge.
  ///
  /// Returns the resolved SteamID64 once Steam redirects back through the
  /// bridge to `cronicle://steam-oauth?...`.
  Future<String> connectViaBridge() async {
    if (kIsWeb) {
      throw UnsupportedError('web');
    }
    final bridge = EnvConfig.steamRedirectUri.trim();
    if (bridge.isEmpty) {
      throw StateError('no_redirect_uri');
    }

    final bridgeUri = Uri.parse(bridge);
    final String result;
    if (defaultTargetPlatform == TargetPlatform.android) {
      result = await _openIdAndroidExternalBrowser(bridgeUri);
    } else {
      result = await FlutterWebAuth2.authenticate(
        url: bridgeUri.toString(),
        callbackUrlScheme: 'cronicle',
        options: const FlutterWebAuth2Options(
          intentFlags: ephemeralIntentFlags,
        ),
      );
    }

    final returned = Uri.parse(result);
    final claimed = returned.queryParameters['openid.claimed_id'] ?? '';
    final match = RegExp(r'/openid/id/(\d+)').firstMatch(claimed);
    final steamId = match?.group(1) ?? '';
    if (steamId.isEmpty) {
      throw StateError('no_steamid');
    }
    return steamId;
  }
}

Future<String> _openIdAndroidExternalBrowser(Uri bridgeUri) async {
  final appLinks = AppLinks();
  final completer = Completer<String>();

  bool matches(Uri u) =>
      u.scheme == 'cronicle' && u.host == 'steam-oauth';

  void completeIfMatch(Uri u) {
    if (matches(u) && !completer.isCompleted) {
      completer.complete(u.toString());
    }
  }

  final initial = await appLinks.getInitialLink();
  if (initial != null) {
    completeIfMatch(initial);
  }

  late final StreamSubscription<Uri> sub;
  sub = appLinks.uriLinkStream.listen(completeIfMatch);

  if (completer.isCompleted) {
    await sub.cancel();
    return completer.future;
  }

  final launched =
      await launchUrl(bridgeUri, mode: LaunchMode.externalApplication);
  if (!launched) {
    await sub.cancel();
    throw StateError('launch_failed');
  }

  try {
    return await completer.future.timeout(
      const Duration(minutes: 10),
      onTimeout: () => throw StateError('oauth_timeout'),
    );
  } finally {
    await sub.cancel();
  }
}
