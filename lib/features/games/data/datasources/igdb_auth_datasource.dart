import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Manages IGDB access via Twitch client-credentials tokens.
class IgdbAuthDatasource {
  IgdbAuthDatasource(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _tokenKey = 'igdb_access_token';
  static const _expiresKey = 'igdb_token_expires_at';

  static const _tokenUrl = 'https://id.twitch.tv/oauth2/token';

  String get clientId => EnvConfig.twitchClientId;

  /// Returns a valid app-level access token, refreshing if needed.
  Future<String> getValidToken() async {
    final stored = await _storage.read(key: _tokenKey);
    final expiresRaw = await _storage.read(key: _expiresKey);

    if (stored != null && expiresRaw != null) {
      final expiresAt = int.tryParse(expiresRaw) ?? 0;
      if (DateTime.now().millisecondsSinceEpoch < expiresAt) return stored;
    }

    return _refreshToken();
  }

  Future<String> _refreshToken() async {
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

    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _expiresKey, value: expiresAt.toString());

    return token;
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _expiresKey);
  }
}
