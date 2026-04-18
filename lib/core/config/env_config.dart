abstract final class EnvConfig {
  /// **Solo desarrollo / Flutter Web.** Origen HTTP del proxy CORS (sin barra final),
  /// p. ej. `http://127.0.0.1:8787`. Las APIs de Twitch e IGDB no permiten orígenes web
  /// directos; ejecuta `node scripts/dev_api_proxy.mjs` y pasa
  /// `--dart-define=DEV_API_PROXY=http://127.0.0.1:8787` junto con tus credenciales.
  static const String devApiProxyOrigin = String.fromEnvironment(
    'DEV_API_PROXY',
    defaultValue: '',
  );

  static bool get hasDevApiProxy => devApiProxyOrigin.trim().isNotEmpty;

  /// Base `…/v4` de IGDB (directa o vía [devApiProxyOrigin]).
  static String get igdbApiV4BaseUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/v4'
      : 'https://api.igdb.com/v4';

  /// Token client_credentials / refresh (Twitch).
  static String get twitchOAuthTokenUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/oauth2/token'
      : 'https://id.twitch.tv/oauth2/token';

  /// Helix `GET /users` (login tras OAuth).
  static String get twitchHelixUsersUrl => hasDevApiProxy
      ? '${devApiProxyOrigin.trim()}/helix/users'
      : 'https://api.twitch.tv/helix/users';

  static const String anilistClientId = String.fromEnvironment(
    'ANILIST_CLIENT_ID',
    defaultValue: '',
  );
  /// Por defecto la página PIN (copiar token). Para OAuth en móvil vía puente, pon aquí la misma URL **HTTPS**
  /// que en Anilist → Developer (sirve `web/anilist_oauth_bridge.html`). No se añade a la URL de autorización:
  /// el implícito solo usa `client_id` + `response_type=token`; el redirect lo aplica Anilist según tu app.
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

  /// Cabecera `X-RapidAPI-Key` para [OpenCritic en RapidAPI](https://rapidapi.com/opencritic-opencritic-default/api/opencritic-api).
  /// Sin esto, la sección de críticos OpenCritic en el detalle de juego no se rellena.
  static const String openCriticRapidApiKey = String.fromEnvironment(
    'OPENCRITIC_RAPIDAPI_KEY',
    defaultValue: '',
  );

  /// Debe coincidir con el redirect registrado en trakt.tv/oauth/applications (p. ej.
  /// `cronicle://trakt-oauth` o una URL https puente).
  static const String traktRedirectUri = String.fromEnvironment(
    'TRAKT_REDIRECT_URI',
    defaultValue: '',
  );
}
