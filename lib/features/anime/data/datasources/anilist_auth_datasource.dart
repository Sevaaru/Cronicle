import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Manages Anilist OAuth tokens via secure storage.
class AnilistAuthDatasource {
  AnilistAuthDatasource(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'anilist_access_token';
  static const _userNameKey = 'anilist_user_name';

  /// OAuth authorize URL for Anilist implicit grant.
  String get authorizeUrl {
    final clientId = EnvConfig.anilistClientId;
    return 'https://anilist.co/api/v2/oauth/authorize'
        '?client_id=$clientId&response_type=token';
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
