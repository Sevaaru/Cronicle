import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages Anilist OAuth tokens via secure storage.
class AnilistAuthDatasource {
  AnilistAuthDatasource(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'anilist_access_token';
  static const _userNameKey = 'anilist_user_name';

  static const anilistClientId = '39257';

  /// Authorize URL — sin redirect_uri para que Anilist use el registrado.
  /// Si el redirect registrado es el callback, redirige automáticamente.
  /// Si es el de PIN, muestra la página para copiar el token.
  String get authorizeUrl =>
      'https://anilist.co/api/v2/oauth/authorize'
      '?client_id=$anilistClientId&response_type=token';

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
