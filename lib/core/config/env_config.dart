abstract final class EnvConfig {
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

  /// URL **HTTPS** registrada en Twitch (la consola no acepta `cronicle://`).
  /// Debe servir el HTML puente `web/twitch_oauth_bridge.html` (o equivalente) que redirija a `cronicle://twitch-oauth`.
  static const String twitchRedirectUri = String.fromEnvironment(
    'TWITCH_REDIRECT_URI',
    defaultValue: '',
  );

  /// Cliente OAuth **Web** de Google Cloud (termina en `.apps.googleusercontent.com`).
  /// **Obligatorio en Android** para `GoogleSignIn` 7.x (`serverClientId` en [GoogleSignIn.initialize]).
  static const String googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
    defaultValue: '',
  );

  /// Cliente OAuth **Android** (tipo *Android* en Credenciales). Si lo defines, pásalo como
  /// `clientId` en [GoogleSignIn.initialize] solo en Android; no uses aquí el ID del cliente iOS.
  static const String googleAndroidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  /// Cliente OAuth **iOS** (opcional si no va en `Info.plist` como `GIDClientID`).
  static const String googleIosClientId = String.fromEnvironment(
    'GOOGLE_IOS_CLIENT_ID',
    defaultValue: '',
  );

  /// API key de la app Trakt (cabecera `trakt-api-key`). Obligatoria para películas/TV.
  static const String traktClientId = String.fromEnvironment(
    'TRAKT_CLIENT_ID',
    defaultValue: '',
  );

  /// Secreto OAuth Trakt (solo importa para conectar cuenta / sync).
  static const String traktClientSecret = String.fromEnvironment(
    'TRAKT_CLIENT_SECRET',
    defaultValue: '',
  );

  /// Debe coincidir con el redirect registrado en trakt.tv/oauth/applications (p. ej.
  /// `cronicle://trakt-oauth` o una URL https puente).
  static const String traktRedirectUri = String.fromEnvironment(
    'TRAKT_REDIRECT_URI',
    defaultValue: '',
  );
}
