import 'dart:convert';

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

  static bool get hasConfiguredClientId =>
      EnvConfig.anilistClientId.trim().isNotEmpty;

  static bool get hasClientSecret =>
      EnvConfig.anilistClientSecret.trim().isNotEmpty;

  /// Web OAuth ready when dart-defines include client id + secret (authorization code).
  static bool get isWebOAuthConfigured =>
      kIsWeb &&
      registeredRedirectUri != null &&
      hasConfiguredClientId &&
      hasClientSecret;

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

    final res = await _dio.post<String>(
      EnvConfig.anilistOAuthTokenUrl,
      options: Options(
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        responseType: ResponseType.plain,
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

    final data = _parseTokenResponseBody(res.data);
    if (res.statusCode != 200 || data == null) {
      final plain = res.data?.trim();
      if (plain != null && plain.contains('dev_api_proxy:')) {
        throw Exception(
          'Proxy local desactualizado. Cierra node en el puerto 8787 y ejecuta .\\scripts\\run_web.ps1',
        );
      }
      final msg = data?['message'] ??
          data?['error'] ??
          plain ??
          res.statusMessage;
      throw Exception('AniList token (${res.statusCode}): $msg');
    }

    final token = data['access_token'] as String?;
    if (token == null || token.isEmpty) {
      throw Exception('AniList token: sin access_token');
    }
    return token;
  }

  Map<String, dynamic>? _parseTokenResponseBody(dynamic body) {
    if (body is Map<String, dynamic>) return body;
    if (body is Map) return Map<String, dynamic>.from(body);
    if (body is String && body.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(body);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
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
