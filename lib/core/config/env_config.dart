abstract final class EnvConfig {
  static const String devApiProxyOrigin = String.fromEnvironment(
    'DEV_API_PROXY',
    defaultValue: '',
  );

  static bool get hasDevApiProxy => devApiProxyOrigin.trim().isNotEmpty;

  static String get igdbApiV4BaseUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/v4'
      : 'https://api.igdb.com/v4';

  static String get twitchOAuthTokenUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/oauth2/token'
      : 'https://id.twitch.tv/oauth2/token';

  static String get twitchHelixUsersUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/helix/users'
      : 'https://api.twitch.tv/helix/users';

  static const String anilistClientId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
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
}
