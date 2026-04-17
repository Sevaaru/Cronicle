import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:cronicle/core/config/env_config.dart';

/// OAuth2 Trakt (opcional). La API pública solo necesita [EnvConfig.traktClientId].
class TraktAuthDatasource {
  TraktAuthDatasource(this._storage, this._dio);

  final FlutterSecureStorage _storage;
  final Dio _dio;

  static const _accessKey = 'trakt_access_token';
  static const _refreshKey = 'trakt_refresh_token';
  static const _expiresKey = 'trakt_token_expires_at_ms';
  static const _userSlugKey = 'trakt_user_slug';
  static const _userNameKey = 'trakt_user_name';
  static const _userAvatarUrlKey = 'trakt_user_avatar_url';

  static const _tokenUrl = 'https://api.trakt.tv/oauth/token';

  Future<String?> getAccessToken() => _storage.read(key: _accessKey);

  Future<String?> getRefreshToken() => _storage.read(key: _refreshKey);

  Future<String?> getUserSlug() => _storage.read(key: _userSlugKey);

  Future<String?> getUserName() => _storage.read(key: _userNameKey);

  Future<String?> getUserAvatarUrl() => _storage.read(key: _userAvatarUrlKey);

  Future<bool> hasSession() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _accessKey);
    await _storage.delete(key: _refreshKey);
    await _storage.delete(key: _expiresKey);
    await _storage.delete(key: _userSlugKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userAvatarUrlKey);
  }

  /// Devuelve un access token válido o null si no hay sesión.
  Future<String?> getValidAccessToken() async {
    final access = await getAccessToken();
    if (access == null || access.isEmpty) return null;

    final expRaw = await _storage.read(key: _expiresKey);
    final exp = int.tryParse(expRaw ?? '') ?? 0;
    if (DateTime.now().millisecondsSinceEpoch < exp - 120_000) {
      return access;
    }

    return _tryRefresh();
  }

  Future<String?> _tryRefresh() async {
    final refresh = await getRefreshToken();
    if (refresh == null ||
        refresh.isEmpty ||
        EnvConfig.traktClientId.isEmpty ||
        EnvConfig.traktClientSecret.isEmpty) {
      await clearSession();
      return null;
    }
    final redirect = EnvConfig.traktRedirectUri.trim();
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        _tokenUrl,
        options: Options(
          contentType: Headers.jsonContentType,
          validateStatus: (_) => true,
        ),
        data: <String, dynamic>{
          'refresh_token': refresh,
          'client_id': EnvConfig.traktClientId,
          'client_secret': EnvConfig.traktClientSecret,
          'redirect_uri': redirect,
          'grant_type': 'refresh_token',
        },
      );
      final data = res.data;
      if (res.statusCode != 200 || data == null) {
        await clearSession();
        return null;
      }
      await _persistTokenResponse(data, refreshFallback: refresh);
      return data['access_token'] as String?;
    } catch (_) {
      await clearSession();
      return null;
    }
  }

  Future<void> exchangeAuthorizationCode(String code) async {
    if (EnvConfig.traktClientId.isEmpty ||
        EnvConfig.traktClientSecret.isEmpty) {
      throw StateError('TRAKT_CLIENT_ID / TRAKT_CLIENT_SECRET no configurados');
    }
    final redirect = EnvConfig.traktRedirectUri.trim();
    if (redirect.isEmpty) {
      throw StateError('TRAKT_REDIRECT_URI no configurado');
    }
    final res = await _dio.post<Map<String, dynamic>>(
      _tokenUrl,
      options: Options(
        contentType: Headers.jsonContentType,
        validateStatus: (_) => true,
      ),
      data: <String, dynamic>{
        'code': code,
        'client_id': EnvConfig.traktClientId,
        'client_secret': EnvConfig.traktClientSecret,
        'redirect_uri': redirect,
        'grant_type': 'authorization_code',
      },
    );
    final data = res.data;
    if (res.statusCode != 200 || data == null) {
      final map = data is Map<String, dynamic> ? data : null;
      final msg = map?['error_description'] as String? ??
          map?['error'] as String? ??
          res.statusMessage ??
          'OAuth';
      throw Exception('Trakt OAuth: $msg');
    }
    await _persistTokenResponse(data, refreshFallback: null);
  }

  Future<void> _persistTokenResponse(
    Map<String, dynamic> data, {
    required String? refreshFallback,
  }) async {
    final access = data['access_token'] as String?;
    final refresh =
        data['refresh_token'] as String? ?? refreshFallback ?? '';
    final expiresIn = (data['expires_in'] as num?)?.toInt() ?? 7884000;
    if (access == null) {
      throw Exception('Trakt OAuth: sin access_token');
    }
    final exp =
        DateTime.now().millisecondsSinceEpoch + (expiresIn * 1000);
    await _storage.write(key: _accessKey, value: access);
    if (refresh.isNotEmpty) {
      await _storage.write(key: _refreshKey, value: refresh);
    }
    await _storage.write(key: _expiresKey, value: exp.toString());
  }

  Future<void> saveUserFromSettings(Map<String, dynamic>? settings) async {
    if (settings == null) return;
    final user = settings['user'] as Map<String, dynamic>?;
    if (user == null) return;
    final ids = user['ids'] as Map<String, dynamic>?;
    final slug = ids?['slug'] as String? ?? user['username'] as String?;
    final name = user['name'] as String? ?? user['username'] as String?;
    if (slug != null && slug.isNotEmpty) {
      await _storage.write(key: _userSlugKey, value: slug);
    }
    if (name != null && name.isNotEmpty) {
      await _storage.write(key: _userNameKey, value: name);
    }
    final avatarUrl = _avatarUrlFromTraktUser(user);
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      await _storage.write(key: _userAvatarUrlKey, value: avatarUrl);
    }
  }

  static String? _avatarUrlFromTraktUser(Map<String, dynamic> user) {
    final images = user['images'] as Map<String, dynamic>?;
    if (images == null) return null;
    final av = images['avatar'];
    if (av is String && av.isNotEmpty) return av;
    if (av is Map<String, dynamic>) {
      final full = (av['full'] as String?)?.trim();
      if (full != null && full.isNotEmpty) return full;
      final medium = (av['medium'] as String?)?.trim();
      if (medium != null && medium.isNotEmpty) return medium;
    }
    return null;
  }

  Uri buildAuthorizeUri(String state) {
    final redirect = EnvConfig.traktRedirectUri.trim();
    return Uri.parse('https://trakt.tv/oauth/authorize').replace(
      queryParameters: <String, String>{
        'response_type': 'code',
        'client_id': EnvConfig.traktClientId,
        'redirect_uri': redirect,
        'state': state,
      },
    );
  }
}
