import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Manages Anilist OAuth tokens via secure storage.
class AnilistAuthDatasource {
  AnilistAuthDatasource(this._storage);

  final FlutterSecureStorage _storage;
  static const _tokenKey = 'anilist_access_token';
  static const _userNameKey = 'anilist_user_name';

  /// ID público de Cronicle en Anilist; sustituye con `--dart-define=ANILIST_CLIENT_ID=…` si usas otra app.
  static const String defaultAnilistClientId = '39257';

  static String get effectiveClientId {
    final e = EnvConfig.anilistClientId.trim();
    return e.isNotEmpty ? e : defaultAnilistClientId;
  }

  /// `true` si [EnvConfig.anilistRedirectUri] es HTTPS y no es la página PIN por defecto
  /// (entonces Anilist redirige al hash `#access_token=…` y el HTML puente abre la app).
  static bool get usesHttpsImplicitBridge {
    final raw = EnvConfig.anilistRedirectUri.trim();
    if (raw.isEmpty) return false;
    if (raw.contains('api/v2/oauth/pin')) return false;
    final u = Uri.tryParse(raw);
    return u != null && u.scheme == 'https';
  }

  /// URL de autorización (flujo **implícito**: `response_type=token`).
  ///
  /// No incluir `redirect_uri` aquí: la documentación de Anilist solo usa `client_id` + `response_type`;
  /// si se manda `redirect_uri` junto con `token`, el servidor responde con `unsupported_grant_type`.
  /// El destino tras autorizar es el que tengas registrado en anilist.co/settings/developer.
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
