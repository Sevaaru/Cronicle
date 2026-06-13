import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/config/web_dev_config.dart';

class AnilistAuthDatasource {
  AnilistAuthDatasource(this._storage, [Dio? dio]) : _dio = dio ?? Dio();

  final FlutterSecureStorage _storage;
  final Dio _dio;
  static const _tokenKey = 'anilist_access_token';
  static const _userNameKey = 'anilist_user_name';

  static const String defaultAnilistClientId = '39257';

  static String get effectiveClientId {
    final e = EnvConfig.anilistClientId.trim();
    return e.isNotEmpty ? e : defaultAnilistClientId;
  }

  static bool get hasClientSecret =>
      EnvConfig.anilistClientSecret.trim().isNotEmpty;

  /// Redirect URI registered in AniList → Developer settings.
  static String? get registeredRedirectUri {
    if (kIsWeb) {
      final origin = WebDevConfig.effectiveOrigin.trim();
      if (origin.isEmpty) return null;
      return '$origin/auth_callback.html';
    }
    final raw = EnvConfig.anilistRedirectUri.trim();
    if (raw.isEmpty || raw.contains('api/v2/oauth/pin')) return null;
    final u = Uri.tryParse(raw);
    if (u == null || u.scheme != 'https') return null;
    return raw;
  }

  static bool get usesHttpsImplicitBridge => registeredRedirectUri != null;

  /// Web + client secret → authorization code; otherwise implicit grant.
  static bool get usesWebAuthorizationCodeFlow =>
      kIsWeb && hasClientSecret && registeredRedirectUri != null;

  String get authorizeUrl {
    if (usesWebAuthorizationCodeFlow) {
      return Uri.https('anilist.co', '/api/v2/oauth/authorize', {
        'client_id': effectiveClientId,
        'response_type': 'code',
        'redirect_uri': registeredRedirectUri!,
      }).toString();
    }
    return Uri.https('anilist.co', '/api/v2/oauth/authorize', {
      'client_id': effectiveClientId,
      'response_type': 'token',
    }).toString();
  }

  static String? get redirectUriForDeveloperConsole =>
      registeredRedirectUri;

  Future<String> exchangeAuthorizationCode(String code) async {
    final redirect = registeredRedirectUri;
    if (redirect == null || redirect.isEmpty) {
      throw StateError('no_redirect');
    }
    if (!hasClientSecret) {
      throw StateError('no_client_secret');
    }

    final res = await _dio.post<Map<String, dynamic>>(
      'https://anilist.co/api/v2/oauth/token',
      options: Options(
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (_) => true,
      ),
      data: {
        'grant_type': 'authorization_code',
        'client_id': effectiveClientId,
        'client_secret': EnvConfig.anilistClientSecret.trim(),
        'redirect_uri': redirect,
        'code': code,
      },
    );

    final data = res.data;
    if (res.statusCode != 200 || data == null) {
      final msg = data?['message'] ?? data?['error'] ?? res.statusMessage;
      throw Exception('AniList token: $msg');
    }

    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('AniList token: sin access_token');
    }
    return token;
  }

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userNameKey);
  }

  Future<String?> getUserName() => _storage.read(key: _userNameKey);

  Future<void> saveUserName(String name) =>
      _storage.write(key: _userNameKey, value: name);
}
