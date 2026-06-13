import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cronicle/core/config/web_dev_config.dart';

abstract final class EnvConfig {
  static const String devApiProxyOrigin = String.fromEnvironment(
    'DEV_API_PROXY',
    defaultValue: '',
  );

  /// CORS proxy base URL (no trailing slash). On web defaults to the local dev
  /// proxy (`127.0.0.1:8787`) or same-origin Netlify redirects in production.
  static String get apiProxyOrigin {
    final explicit = devApiProxyOrigin.trim();
    if (explicit.isNotEmpty) return explicit;
    if (!kIsWeb) return '';
    if (WebDevConfig.isLocalhost) return 'http://127.0.0.1:8787';
    return Uri.base.origin;
  }

  static bool get hasApiProxy => apiProxyOrigin.isNotEmpty;

  @Deprecated('Use hasApiProxy')
  static bool get hasDevApiProxy => hasApiProxy;

  static String get _proxyBase =>
      apiProxyOrigin.replaceAll(RegExp(r'/+$'), '');

  static String get igdbApiV4BaseUrl => hasApiProxy
      ? '$_proxyBase/v4'
      : 'https://api.igdb.com/v4';

  static String get twitchOAuthTokenUrl => hasApiProxy
      ? '$_proxyBase/oauth2/token'
      : 'https://id.twitch.tv/oauth2/token';

  static String get twitchHelixUsersUrl => hasApiProxy
      ? '$_proxyBase/helix/users'
      : 'https://api.twitch.tv/helix/users';

  /// AniList token exchange (authorization code). Proxied on web to avoid CORS.
  static String get anilistOAuthTokenUrl => hasApiProxy
      ? '$_proxyBase/anilist-oauth/api/v2/oauth/token'
      : 'https://anilist.co/api/v2/oauth/token';

  static const String anilistClientId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
    defaultValue: '',
  );
  static const String anilistClientSecret = String.fromEnvironment(
    'ANILIST_CLIENT_SECRET',
    defaultValue: '',
  );
  static const String anilistRedirectUri = String.fromEnvironment(
    'ANILIST_REDIRECT_URI',
    defaultValue: 'https://anilist.co/api/v2/oauth/pin',
  );

  static const String twitchClientId = String.fromEnvironment(
    'TWITCH_CLIENT_ID',
    defaultValue: '',
  );
  static const String twitchClientSecret = String.fromEnvironment(
    'TWITCH_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String twitchRedirectUri = String.fromEnvironment(
    'TWITCH_REDIRECT_URI',
    defaultValue: '',
  );

  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  static const String traktClientId = String.fromEnvironment(
    'TRAKT_CLIENT_ID',
    defaultValue: '',
  );

  static const String traktClientSecret = String.fromEnvironment(
    'TRAKT_CLIENT_SECRET',
    defaultValue: '',
  );

  static const String openCriticRapidApiKey = String.fromEnvironment(
    'OPENCRITIC_RAPIDAPI_KEY',
    defaultValue: '',
  );

  static const String googleBooksApiKey = String.fromEnvironment(
    'GOOGLE_BOOKS_API_KEY',
    defaultValue: '',
  );

  static const String traktRedirectUri = String.fromEnvironment(
    'TRAKT_REDIRECT_URI',
    defaultValue: '',
  );

  static const String steamApiKey = String.fromEnvironment(
    'STEAM_API_KEY',
    defaultValue: '',
  );

  static const String steamRedirectUri = String.fromEnvironment(
    'STEAM_REDIRECT_URI',
    defaultValue: '',
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: '',
  );

  static bool get hasSupabase =>
      supabaseUrl.trim().isNotEmpty &&
      supabasePublishableKey.trim().isNotEmpty;

  /// `https://PROJECT.supabase.co/auth/v1/callback` for Google Cloud redirect URIs.
  static String get supabaseAuthCallbackUrl {
    final base = supabaseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return '';
    return '$base/auth/v1/callback';
  }
}
