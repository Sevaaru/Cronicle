import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Tokens para IGDB vía Twitch.
///
/// - **App (client_credentials)**: token de aplicación guardado en `igdb_access_token` (comportamiento previo).
/// - **Usuario (OAuth)**: token de Twitch del usuario; IGDB acepta también Bearer de usuario.
class IgdbAuthDatasource {
  IgdbAuthDatasource(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _appTokenKey = 'igdb_access_token';
  static const _appExpiresKey = 'igdb_token_expires_at';

  static const _userAccessKey = 'twitch_user_access_token';
  static const _userRefreshKey = 'twitch_user_refresh_token';
  static const _userExpiresKey = 'twitch_user_token_expires_ms';
  static const _userLoginKey = 'twitch_user_login';

  static const _tokenUrl = 'https://id.twitch.tv/oauth2/token';
  static const _helixUsersUrl = 'https://api.twitch.tv/helix/users';

  String get clientId => EnvConfig.twitchClientId;

  bool get _hasClientCredentials =>
      EnvConfig.twitchClientId.isNotEmpty && EnvConfig.twitchClientSecret.isNotEmpty;

  /// Hay sesión OAuth de usuario (Twitch) guardada.
  Future<bool> hasUserSession() async {
    final t = await _storage.read(key: _userAccessKey);
    return t != null && t.isNotEmpty;
  }

  Future<String?> getUserLogin() => _storage.read(key: _userLoginKey);

  /// Devuelve un token válido para la API IGDB: prioriza OAuth de usuario; si no, client_credentials.
  Future<String> getValidToken() async {
    final user = await _getValidUserAccessToken();
    if (user != null) return user;

    final stored = await _storage.read(key: _appTokenKey);
    final expiresRaw = await _storage.read(key: _appExpiresKey);
    if (stored != null && expiresRaw != null) {
      final expiresAt = int.tryParse(expiresRaw) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < expiresAt) return stored;
    }
    return _refreshAppToken();
  }

  Future<String?> _getValidUserAccessToken() async {
    final stored = await _storage.read(key: _userAccessKey);
    final expiresRaw = await _storage.read(key: _userExpiresKey);
    if (stored == null || stored.isEmpty) return null;

    if (expiresRaw != null) {
      final expiresAt = int.tryParse(expiresRaw) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < expiresAt - 60_000) {
        return stored;
      }
    }

    return _tryRefreshUserToken();
  }

  Future<String?> _tryRefreshUserToken() async {
    final refresh = await _storage.read(key: _userRefreshKey);
    if (refresh == null || refresh.isEmpty || !_hasClientCredentials) {
      await clearUserSession();
      return null;
    }
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _tokenUrl,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (_) => true,
        ),
        data:
            'grant_type=refresh_token&refresh_token=${Uri.encodeQueryComponent(refresh)}'
            '&client_id=${Uri.encodeQueryComponent(EnvConfig.twitchClientId)}'
            '&client_secret=${Uri.encodeQueryComponent(EnvConfig.twitchClientSecret)}',
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) {
        await clearUserSession();
        return null;
      }
      final token = data['access_token'] as String?;
      final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 3600;
      final newRefresh = data['refresh_token'] as String? ?? refresh;
      if (token == null) {
        await clearUserSession();
        return null;
      }
      final expiresAt =
          DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
      await _storage.write(key: _userAccessKey, value: token);
      await _storage.write(key: _userRefreshKey, value: newRefresh);
      await _storage.write(key: _userExpiresKey, value: expiresAt.toString());
      return token;
    } catch (_) {
      await clearUserSession();
      return null;
    }
  }

  Future<String> _refreshAppToken() async {
    if (!_hasClientCredentials) {
      throw StateError('TWITCH_CLIENT_ID / TWITCH_CLIENT_SECRET no configurados');
    }
    final res = await _dio.post<Map<String, dynamic>>(
      _tokenUrl,
      queryParameters: {
        'client_id': EnvConfig.twitchClientId,
        'client_secret': EnvConfig.twitchClientSecret,
        'grant_type': 'client_credentials',
      },
    );

    final data = res.data!;
    final token = data['access_token'] as String;
    final expiresIn = data['expires_in'] as int;
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);

    await _storage.write(key: _appTokenKey, value: token);
    await _storage.write(key: _appExpiresKey, value: expiresAt.toString());

    return token;
  }

  /// Intercambia el `code` del redirect OAuth por tokens de usuario y los guarda.
  Future<void> exchangeAuthorizationCode(String code) async {
    if (!_hasClientCredentials) {
      throw StateError('TWITCH_CLIENT_ID / TWITCH_CLIENT_SECRET no configurados');
    }
    final redirect = EnvConfig.twitchRedirectUri;
    final res = await _dio.post<Map<String, dynamic>>(
      _tokenUrl,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        validateStatus: (_) => true,
      ),
      data:
          'client_id=${Uri.encodeQueryComponent(EnvConfig.twitchClientId)}'
          '&client_secret=${Uri.encodeQueryComponent(EnvConfig.twitchClientSecret)}'
          '&code=${Uri.encodeQueryComponent(code)}'
          '&grant_type=authorization_code'
          '&redirect_uri=${Uri.encodeQueryComponent(redirect)}',
    );
    final data = res.data;
    if (res.statusCode != 200 || data == null) {
      final msg = data != null
          ? (data['message'] as String? ?? res.statusMessage ?? 'OAuth')
          : (res.statusMessage ?? 'OAuth');
      throw Exception('Twitch OAuth: $msg');
    }
    final access = data['access_token'] as String?;
    final refresh = data['refresh_token'] as String?;
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 14400;
    if (access == null) {
      throw Exception('Twitch OAuth: sin access_token');
    }
    final expiresAt =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await _storage.write(key: _userAccessKey, value: access);
    if (refresh != null) {
      await _storage.write(key: _userRefreshKey, value: refresh);
    }
    await _storage.write(key: _userExpiresKey, value: expiresAt.toString());

    final login = await _fetchHelixLogin(access);
    if (login != null) {
      await _storage.write(key: _userLoginKey, value: login);
    }
  }

  Future<String?> _fetchHelixLogin(String userAccess) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        _helixUsersUrl,
        options: Options(
          headers: {
            'Client-ID': EnvConfig.twitchClientId,
            'Authorization': 'Bearer $userAccess',
          },
          validateStatus: (_) => true,
        ),
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) return null;
      final list = data['data'] as List?;
      if (list == null || list.isEmpty) return null;
      final u = list.first as Map<String, dynamic>?;
      return u?['login'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearUserSession() async {
    await _storage.delete(key: _userAccessKey);
    await _storage.delete(key: _userRefreshKey);
    await _storage.delete(key: _userExpiresKey);
    await _storage.delete(key: _userLoginKey);
  }

  /// URL de autorización Twitch (response_type=code).
  Uri buildAuthorizeUri(String state) {
    final redirect = EnvConfig.twitchRedirectUri;
    const scope = 'user:read:email';
    return Uri.parse('https://id.twitch.tv/oauth2/authorize').replace(
      queryParameters: <String, String>{
        'client_id': EnvConfig.twitchClientId,
        'redirect_uri': redirect,
        'response_type': 'code',
        'scope': scope,
        'state': state,
        'force_verify': 'false',
      },
    );
  }

  /// Borra tokens de app (client_credentials) y de usuario.
  Future<void> deleteToken() async {
    await _storage.delete(key: _appTokenKey);
    await _storage.delete(key: _appExpiresKey);
    await clearUserSession();
  }
}
