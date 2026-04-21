import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

class AnilistAuthDatasource {
  AnilistAuthDatasource(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'anilist_access_token';
  static const _userNameKey = 'anilist_user_name';

  static const String defaultAnilistClientId = '39257';

  static String get effectiveClientId {
    final e = EnvConfig.anilistClientId.trim();
    return e.isNotEmpty ? e : defaultAnilistClientId;
  }

  static bool get usesHttpsImplicitBridge {
    final raw = EnvConfig.anilistRedirectUri.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('api/v2/oauth/pin')) return false;
    final u = Uri.tryParse(raw);
    return u != null && u.scheme == 'https';
  }

  String get authorizeUrl {
    return Uri.https('anilist.co', '/api/v2/oauth/authorize', {
      'client_id': effectiveClientId,
      'response_type': 'token',
    }).toString();
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
