// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Cronicle';

  @override
  String get navHome => 'Inicio';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navSearch => 'Búsqueda';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navAnime => 'Anime';

  @override
  String get navManga => 'Manga';

  @override
  String get navMovies => 'Películas';

  @override
  String get navTv => 'Series';

  @override
  String get navGames => 'Juegos';

  @override
  String get navAuth => 'Cuentas';

  @override
  String get homeSubtitle => 'Tu progreso y listas, offline primero.';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get language => 'Idioma';

  @override
  String get placeholderSoon => 'Próximamente';

  @override
  String get errorGeneric => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get errorNetwork => 'Sin conexión o error de red.';

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get errorVerifyingSession => 'Error al verificar sesión';

  @override
  String get errorVerifyingToken => 'Error al verificar token';

  @override
  String get errorLoadingProfile => 'Error al cargar perfil';

  @override
  String errorSyncMessage(Object message) {
    return 'Error al sincronizar: $message';
  }

  @override
  String get googleSignIn => 'Iniciar sesión con Google';

  @override
  String get googleSignOut => 'Cerrar sesión de Google';

  @override
  String get googleSyncNow => 'Sincronizar ahora';

  @override
  String get connectedWithGoogle => 'Conectado con Google';

  @override
  String get googleDrivePermissionMissing =>
      'La cuenta de Google está iniciada, pero no se concedió el acceso a la copia en Drive. Vuelve a intentarlo y acepta el permiso de datos de la app en Drive.';

  @override
  String get googleSignInCanceledTitle => 'Google no pudo completar el acceso';

  @override
  String get googleSignInCanceledBody =>
      'El mensaje «cancelado» suele indicar un fallo de OAuth, no que hayas cancelado tú. En Google Cloud Console: 1) Cliente Android con el package de la app y el SHA-1 del keystore de esta compilación (en la carpeta android: gradlew signingReport). 2) GOOGLE_SERVER_CLIENT_ID debe ser el ID del cliente Web del mismo proyecto. 3) Opcional: GOOGLE_ANDROID_CLIENT_ID con el ID del cliente Android en las definiciones de compilación. Si publicas por Play Store, añade también el SHA-1 de firma de Play.';

  @override
  String get googleSignInNotConfiguredTitle =>
      'Google no está configurado en esta compilación';

  @override
  String get googleSignInNotConfiguredHint =>
      'Falta GOOGLE_SERVER_CLIENT_ID (cliente OAuth Web) en las defines de compilación.';

  @override
  String get googleSignInNotConfiguredBody =>
      'En la raíz del proyecto, copia dart_defines.example.json a dart_defines.local.json y rellena GOOGLE_SERVER_CLIENT_ID con el ID del cliente OAuth tipo «Aplicación web» de Google Cloud Console (termina en .apps.googleusercontent.com). Es obligatorio en Android para Google Sign-In 7.x.\n\nEn el mismo proyecto crea un cliente OAuth tipo «Android» con el nombre de paquete com.cronicle.app.cronicle y el SHA-1 del keystore con el que firmas esta APK (debug, release o firma de Play). Para ver los SHA-1: en la carpeta android ejecuta .\\gradlew.bat signingReport (Windows) o ./gradlew signingReport (macOS/Linux). Si publicas en Play Store, añade también el SHA-1 de «App signing» de la consola de Play.\n\nOpcional: GOOGLE_ANDROID_CLIENT_ID con el ID del cliente Android. Después de guardar dart_defines.local.json, recompila con flutter run o scripts/build_android.ps1.';

  @override
  String get backupTitle => 'Copia de seguridad local';

  @override
  String get backupUpload => 'Subir';

  @override
  String get backupRestore => 'Restaurar';

  @override
  String get backupUploadSuccess => 'Backup subido correctamente';

  @override
  String backupAnilistMergeFailed(Object error) {
    return 'No se pudo actualizar desde Anilist antes de la copia; se usarán los datos del dispositivo. $error';
  }

  @override
  String get backupExportReady =>
      'Copia lista. Usa el menú compartir para guardarla donde quieras.';

  @override
  String get backupRestored => 'Restaurado correctamente';

  @override
  String backupRestoredCount(Object count) {
    return 'Restaurados $count elementos';
  }

  @override
  String get backupAutoGoogleTitle => 'Copia diaria en Google Drive';

  @override
  String get backupAutoGoogleSubtitle =>
      'Como mucho una vez al día con conexión, solo si mantienes la sesión de Google (Cuentas). Sin ventanas en segundo plano.';

  @override
  String get backupSectionSubtitle =>
      'Mismo JSON que una exportación completa (biblioteca y ajustes en el dispositivo). Guárdalo en local con Compartir; si tienes sesión en Google en Cuentas, Subir también deja una copia en la carpeta de la app en Drive.';

  @override
  String get backupRestoreChooseSourceTitle => 'Origen de la copia';

  @override
  String get backupRestoreChooseSourceBody =>
      '¿Desde un archivo JSON o desde la copia guardada en Google Drive?';

  @override
  String get backupRestoreFromFile => 'Archivo…';

  @override
  String get backupRestoreFromDrive => 'Google Drive';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar copia';

  @override
  String backupRestoreConfirmBody(Object count) {
    return 'Se fusionarán $count entradas de biblioteca y, si la copia es reciente, preferencias y sesiones (Anilist/Twitch) incluidas en el archivo.';
  }

  @override
  String get feedTitle => 'Inicio';

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsEmpty => 'Aún no hay notificaciones.';

  @override
  String get notificationsLoginRequired =>
      'Inicia sesión en Anilist en Ajustes para ver notificaciones.';

  @override
  String get notifPermissionTitle => '¿Activar notificaciones?';

  @override
  String get notifPermissionBody =>
      'Cronicle puede avisarte en el sistema cuando salga un nuevo capítulo de anime o manga que sigues en curso, y opcionalmente reenviar notificaciones de tu bandeja de Anilist. Puedes cambiarlo después en Ajustes.';

  @override
  String get notifPermissionNotNow => 'Ahora no';

  @override
  String get notifPermissionAllow => 'Permitir';

  @override
  String get gallerySaveUnavailableWeb => 'Descarga no disponible en web';

  @override
  String get gallerySaveSuccess => 'Imagen guardada';

  @override
  String get gallerySaveErrorGeneric => 'Error al guardar';

  @override
  String get gallerySavePermissionDenied =>
      'Sin permiso no se puede guardar en la galería.';

  @override
  String get gallerySaveOpenSettings => 'Ajustes';

  @override
  String get settingsNotificationsTitle => 'Notificaciones en el dispositivo';

  @override
  String get settingsNotificationsSubtitle =>
      'Requiere sesión de Anilist. En Android la recomprobación en segundo plano es aprox. cada 15 min cuando el sistema lo permite; en iOS la frecuencia la decide el sistema. También se comprueba al salir de la app. El SO puede retrasar ejecuciones.';

  @override
  String get settingsNotificationsUnavailableWeb =>
      'Las notificaciones del sistema no están disponibles en la versión web.';

  @override
  String get settingsNotifMaster => 'Notificaciones del sistema';

  @override
  String get settingsNotifAiring =>
      'Nuevos capítulos (lista «En curso» y en emisión)';

  @override
  String get settingsNotifAnilistInbox =>
      'Bandeja de Anilist en el dispositivo';

  @override
  String get settingsNotifAnilistSocial =>
      'Incluir actividad y social (foros, menciones, seguidores…)';

  @override
  String get settingsNotifAnilistSocialDesc =>
      'Si lo desactivas, solo se reenvían al sistema las notificaciones de emisión de Anilist (junto con las de nuevos capítulos de arriba, sin duplicar lógica).';

  @override
  String get notificationNoLink => 'Abre esta notificación en anilist.co';

  @override
  String get notificationTypeGeneric => 'Notificación';

  @override
  String get notificationTypeAiring => 'Nuevo episodio';

  @override
  String get notificationTypeActivityReply => 'Respuesta en actividad';

  @override
  String get notificationTypeActivityMention => 'Mención en actividad';

  @override
  String get notificationTypeActivityMessage => 'Mensaje de actividad';

  @override
  String get notificationTypeFollowing => 'Nuevo seguidor';

  @override
  String get notificationTypeRelatedMedia => 'Medio relacionado añadido';

  @override
  String get notificationTypeMediaDataChange => 'Medio actualizado';

  @override
  String get notificationTypeMediaMerge => 'Medios fusionados';

  @override
  String get notificationTypeMediaDeletion => 'Medio eliminado de Anilist';

  @override
  String get notificationTypeThreadReply => 'Respuesta en foro';

  @override
  String get notificationTypeThreadMention => 'Mención en foro';

  @override
  String get notificationTypeThreadSubscribed => 'Hilo del foro';

  @override
  String get notificationTypeThreadLike => 'Me gusta en foro';

  @override
  String get notificationTypeActivityLike => 'Me gusta en actividad';

  @override
  String get notificationTypeActivityReplyLike => 'Me gusta en respuesta';

  @override
  String get notificationTypeActivityReplySubscribed =>
      'Respuesta en actividad seguida';

  @override
  String get notificationTypeThreadCommentLike =>
      'Me gusta en comentario del foro';

  @override
  String get notificationTypeMediaSubmission => 'Envío de medio (Anilist)';

  @override
  String get notificationTypeStaffSubmission => 'Envío de staff (Anilist)';

  @override
  String get notificationTypeCharacterSubmission =>
      'Envío de personaje (Anilist)';

  @override
  String get feedEmpty => 'No hay actividad reciente.';

  @override
  String get feedRetry => 'Reintentar';

  @override
  String feedComingSoon(Object label) {
    return 'Feed de $label — próximamente';
  }

  @override
  String get feedBrowseActivity => 'Actividad';

  @override
  String get feedBrowseSeasonal => 'De temporada';

  @override
  String get feedBrowseTopRated => 'Mejor valorados';

  @override
  String get feedBrowseUpcoming => 'Próximos';

  @override
  String get feedBrowseRecentlyReleased => 'Recién estrenados';

  @override
  String get feedBrowseEmpty => 'No hay títulos en esta lista.';

  @override
  String get filterFollowing => 'Siguiendo';

  @override
  String get filterGlobal => 'Global';

  @override
  String get filterFeed => 'Feed';

  @override
  String get filterAnime => 'Anime';

  @override
  String get filterManga => 'Manga';

  @override
  String get filterMovies => 'Películas';

  @override
  String get filterTv => 'Series';

  @override
  String get filterGames => 'Juegos';

  @override
  String get filterAll => 'Todo';

  @override
  String get loginRequiredFollowing =>
      'Inicia sesión con Anilist para ver la actividad de las personas que sigues';

  @override
  String get loginRequiredLike => 'Inicia sesión en Anilist para dar like';

  @override
  String get loginRequiredFavorite =>
      'Inicia sesión en Anilist en Ajustes para usar favoritos';

  @override
  String get sectionFavGames => 'Juegos favoritos';

  @override
  String get tooltipAddFavorite => 'Añadir a favoritos';

  @override
  String get tooltipRemoveFavorite => 'Quitar de favoritos';

  @override
  String get loginRequiredFollow =>
      'Inicia sesión en Anilist para seguir usuarios';

  @override
  String get goToSettings => 'Ir a Ajustes';

  @override
  String get timeNow => 'ahora';

  @override
  String timeMinutes(Object count) {
    return '${count}m';
  }

  @override
  String timeHours(Object count) {
    return '${count}h';
  }

  @override
  String timeDays(Object count) {
    return '${count}d';
  }

  @override
  String timeWeeks(Object count) {
    return '${count}sem';
  }

  @override
  String get libraryTitle => 'Biblioteca';

  @override
  String get libraryEmpty => 'Tu lista está vacía.';

  @override
  String get libraryAddHint => 'Busca y añade contenido.';

  @override
  String get libraryNoResults => 'Sin resultados';

  @override
  String get libraryNoStatusResults => 'No hay títulos con este estado';

  @override
  String get librarySearchAndAdd => 'Busca y añade contenido';

  @override
  String get librarySearchTitle => 'Buscar en biblioteca';

  @override
  String get librarySearchHint => 'Buscar en biblioteca...';

  @override
  String get librarySearchPrompt => 'Escribe un título para buscar';

  @override
  String get librarySearchGlobalResults => 'Resultados globales';

  @override
  String get statusAll => 'Todo';

  @override
  String get statusCurrent => 'En progreso';

  @override
  String get statusCurrentAnime => 'Viendo';

  @override
  String get statusCurrentManga => 'Leyendo';

  @override
  String get statusPlanning => 'Planeado';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusPaused => 'Pausado';

  @override
  String get statusDropped => 'Abandonado';

  @override
  String get statusRepeating => 'Repitiendo';

  @override
  String get sortRecent => 'Recientes';

  @override
  String get sortName => 'Nombre';

  @override
  String get sortScore => 'Nota';

  @override
  String get sortProgress => 'Progreso';

  @override
  String get tooltipCompleted => 'Completado';

  @override
  String get tooltipIncrementProgress => '+1 capítulo/episodio';

  @override
  String get searchTitle => 'Búsqueda';

  @override
  String get searchHint => 'Buscar...';

  @override
  String get searchTrendingAnime => 'Anime en tendencia';

  @override
  String get searchTrendingManga => 'Manga en tendencia';

  @override
  String searchComingSoon(Object label) {
    return '$label — próximamente';
  }

  @override
  String get searchComingSoonApi => 'Próximamente — conecta TMDB / IGDB';

  @override
  String get searchSelectFilter => 'Selecciona un filtro';

  @override
  String searchErrorIn(Object section, Object error) {
    return 'Error en $section: $error';
  }

  @override
  String get addToLibrary => 'Añadir a biblioteca';

  @override
  String get editLibraryEntry => 'Editar entrada';

  @override
  String get addedToLibrary => 'Añadido a la biblioteca';

  @override
  String get entryUpdated => 'Entrada actualizada';

  @override
  String get removeFromLibrary => 'Eliminar de mi biblioteca';

  @override
  String get removedFromLibrary => 'Eliminado de la biblioteca';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileLocalUser => 'Usuario local';

  @override
  String get profileConnectHint =>
      'Conecta Anilist en Ajustes para ver tus estadísticas completas';

  @override
  String get profileLocalLibrary => 'Biblioteca local';

  @override
  String get profileLibraryEmpty => 'Tu biblioteca está vacía';

  @override
  String get profileNotFound => 'No se encontró el usuario';

  @override
  String get sectionAnime => 'Anime';

  @override
  String get sectionManga => 'Manga';

  @override
  String get sectionFavAnime => 'Anime favoritos';

  @override
  String get sectionFavManga => 'Manga favoritos';

  @override
  String get sectionRecentActivity => 'Actividad reciente';

  @override
  String get sectionConnectedAccounts => 'Cuentas conectadas';

  @override
  String get sectionTopGenresAnime => 'Top géneros anime';

  @override
  String get sectionTopGenresManga => 'Top géneros manga';

  @override
  String get statTitles => 'Títulos';

  @override
  String get statEpisodes => 'Episodios';

  @override
  String get statChapters => 'Capítulos';

  @override
  String get statVolumes => 'Volúmenes';

  @override
  String get statDaysWatching => 'Días viendo';

  @override
  String get statDays => 'Días';

  @override
  String get statMeanScore => 'Nota media';

  @override
  String get statPopularity => 'Popularidad';

  @override
  String get statFavourites => 'Favoritos';

  @override
  String get mediaInfo => 'Información';

  @override
  String get mediaSynopsis => 'Sinopsis';

  @override
  String get mediaEpisodes => 'Episodios';

  @override
  String get mediaChapters => 'Capítulos';

  @override
  String get mediaVolumes => 'Volúmenes';

  @override
  String get mediaDuration => 'Duración';

  @override
  String get mediaSeason => 'Temporada';

  @override
  String get mediaSource => 'Fuente';

  @override
  String get mediaStart => 'Inicio';

  @override
  String get mediaEnd => 'Fin';

  @override
  String get mediaStudio => 'Estudio: ';

  @override
  String get mediaWhere => 'Dónde ver';

  @override
  String get mediaRelated => 'Relacionados';

  @override
  String get mediaRecommendations => 'Recomendaciones';

  @override
  String get mediaScoreDistribution => 'Distribución de notas';

  @override
  String get mediaReviews => 'Reseñas';

  @override
  String get mediaNoData => 'No se encontraron datos';

  @override
  String get mediaAnonymous => 'Anónimo';

  @override
  String get mediaGenresSection => 'Géneros';

  @override
  String get mediaTagsSection => 'Etiquetas';

  @override
  String get mediaBrowseSortScore => 'Nota';

  @override
  String get mediaBrowseSortPopularity => 'Popularidad';

  @override
  String get mediaBrowseSortName => 'Nombre';

  @override
  String get mediaBrowseInvalidParams =>
      'Falta género o etiqueta en el enlace.';

  @override
  String mediaNextEp(Object episode, Object days, Object hours) {
    return 'Ep $episode en ${days}d ${hours}h';
  }

  @override
  String get addToListTitle => 'Añadir a tu lista';

  @override
  String get addToListStatus => 'Estado';

  @override
  String get addToListScore => 'Nota';

  @override
  String get addToListNoScore => 'Sin nota';

  @override
  String get addToListEpisodes => 'Episodios';

  @override
  String get addToListChapters => 'Capítulos';

  @override
  String addToListOf(Object total) {
    return 'de $total';
  }

  @override
  String get addToListMax => 'Máx';

  @override
  String get addToListNotes => 'Notas';

  @override
  String get addToListNotesHint => 'Notas personales (opcional)...';

  @override
  String get addToListSave => 'Guardar';

  @override
  String get addToListMovieProgress => 'Vista (0–1)';

  @override
  String get traktNotConfiguredHint =>
      'Añade TRAKT_CLIENT_ID a los dart-define para ver películas y series desde Trakt (sin género anime, para no duplicar AniList).';

  @override
  String get traktSectionTrending => 'Tendencias';

  @override
  String get traktSectionWatchingNow => 'Viendo ahora';

  @override
  String get traktSectionPopular => 'Popular';

  @override
  String get traktTitle => 'Trakt.tv';

  @override
  String get traktSubtitle =>
      'Películas y series (sin anime). Conecta tu cuenta para importar tu historial visto a la biblioteca local.';

  @override
  String traktConnectedAs(Object slug) {
    return 'Conectado como $slug';
  }

  @override
  String get traktConnect => 'Conectar Trakt';

  @override
  String get traktDisconnect => 'Desconectar Trakt';

  @override
  String get traktConnectSuccess => 'Cuenta Trakt vinculada.';

  @override
  String get traktDisconnected => 'Cuenta Trakt desvinculada.';

  @override
  String get traktOAuthMissingCredentials =>
      'Configura TRAKT_CLIENT_ID, TRAKT_CLIENT_SECRET y TRAKT_REDIRECT_URI (registrado en trakt.tv/oauth/applications).';

  @override
  String get traktOAuthWebUnavailable =>
      'Inicio de sesión Trakt no disponible en web desde esta app; usa Android, iOS o escritorio.';

  @override
  String get traktImportTitle => 'Importar desde Trakt';

  @override
  String get traktImportConfirm => 'Importar';

  @override
  String get traktImportDesc =>
      'Trae películas y series vistas (sin anime) a la biblioteca de este dispositivo.';

  @override
  String traktImportedCount(Object count) {
    return 'Importados $count títulos desde Trakt.';
  }

  @override
  String get syncTitle => 'Sincronizar con Anilist';

  @override
  String syncWelcome(Object name) {
    return '¡Bienvenido, $name! ¿Cómo quieres sincronizar tu biblioteca?';
  }

  @override
  String get syncImport => 'Importar de Anilist';

  @override
  String get syncImportDesc =>
      'Trae toda tu lista de Anilist aquí (recomendado)';

  @override
  String get syncMerge => 'Combinar';

  @override
  String get syncMergeDesc => 'Fusiona registros locales con Anilist';

  @override
  String get syncNotNow => 'Ahora no';

  @override
  String get syncLoading => 'Sincronizando...';

  @override
  String syncImportedCount(Object count) {
    return 'Importados $count títulos de Anilist';
  }

  @override
  String get syncPromptTitle => 'Sincroniza con Anilist';

  @override
  String get syncPromptBody =>
      'Conecta tu cuenta de Anilist para que tu lista de anime y manga se mantenga sincronizada automáticamente.\n\nTambién puedes hacerlo más tarde desde Ajustes.';

  @override
  String get syncPromptNoThanks => 'No, gracias';

  @override
  String get settingsAccountsTitle => 'Cuentas';

  @override
  String get settingsAccountsSubtitle =>
      'Anilist sincroniza anime/manga con la nube. Trakt aporta películas y series (sin anime). Google sirve para la copia opcional en Drive. Los juegos en Cronicle se guardan en el dispositivo.';

  @override
  String get twitchIgdbTitle => 'Twitch (IGDB)';

  @override
  String get twitchIgdbSubtitle =>
      'Inicia sesión para que búsquedas y fichas usen tu token con IGDB. Eso no sube tus juegos a igdb.com ni importa tu lista «Jugado» del sitio: esa colección no está en la API pública.';

  @override
  String twitchConnectedAs(Object login) {
    return 'Conectado como @$login';
  }

  @override
  String get twitchDisconnectAccount => 'Desvincular Twitch';

  @override
  String get twitchConnectOAuth => 'Conectar con Twitch';

  @override
  String get twitchConnectSuccess =>
      'Twitch conectado. Las peticiones a IGDB usarán tu sesión.';

  @override
  String get twitchDisconnected => 'Cuenta de Twitch desvinculada.';

  @override
  String get twitchOAuthWebUnavailable =>
      'El inicio de sesión con Twitch en el navegador no está configurado. Usa la app en Android, iOS o escritorio.';

  @override
  String get twitchOAuthMissingSecrets =>
      'Añade TWITCH_CLIENT_ID y TWITCH_CLIENT_SECRET a los flags de compilación (ver README).';

  @override
  String get twitchRedirectNotConfigured =>
      '(sin TWITCH_REDIRECT_URI: usa --dart-define con una URL https)';

  @override
  String get twitchRedirectMustBeHttps =>
      'TWITCH_REDIRECT_URI debe ser https://… La consola de Twitch no acepta cronicle://; despliega web/twitch_oauth_bridge.html y registra esa URL exacta.';

  @override
  String get twitchSyncTitle => 'Sincronizar juegos con Twitch';

  @override
  String twitchSyncWelcome(Object name) {
    return 'Hola, $name. ¿Cómo quieres alinear tu biblioteca de juegos?';
  }

  @override
  String get twitchGameSyncMerge => 'Combinar';

  @override
  String get twitchGameSyncMergeDesc =>
      'Mantiene los juegos guardados en este dispositivo y evita duplicados cuando exista una fuente remota conectada.';

  @override
  String get twitchGameSyncOverwrite => 'Sobreescribir con la nube';

  @override
  String get twitchGameSyncOverwriteDesc =>
      'Borra los juegos guardados solo en este dispositivo y luego importa desde la fuente remota (cuando esté disponible).';

  @override
  String get twitchSyncIgdbApiFootnote =>
      'La API pública de IGDB no permite leer ni escribir tu colección personal de igdb.com (p. ej. «Jugado»). Lo que añades en Biblioteca vive solo aquí hasta que integremos otra fuente (p. ej. Steam).';

  @override
  String twitchSyncImportedCount(Object count) {
    return 'Sincronizados $count juegos desde Twitch.';
  }

  @override
  String get twitchSyncImportedZeroWarning =>
      'Se borraron los juegos en este dispositivo. Aún no hay importación remota (la API de IGDB no expone tu lista de igdb.com). Puedes volver a añadir juegos a mano.';

  @override
  String get googleAccountTitle => 'Google';

  @override
  String get googleAccountSubtitle =>
      'Opcional: el mismo JSON de copia en Google Drive (subida manual o diaria; ve Copia de seguridad local).';

  @override
  String get anilistTitle => 'Anilist';

  @override
  String get anilistSubtitle => 'Sincroniza tu lista de anime y manga';

  @override
  String get anilistConnected => 'Conectado';

  @override
  String get anilistDisconnected => 'Desconectado de Anilist';

  @override
  String get anilistConnectSuccess => '¡Conectado con Anilist!';

  @override
  String get anilistConnectTitle => 'Conectar Anilist';

  @override
  String get anilistDisconnect => 'Desconectar Anilist';

  @override
  String get anilistConnect => 'Conectar Anilist';

  @override
  String get anilistTokenLabel => 'Token de Anilist';

  @override
  String get anilistTokenHint => 'Pega el token aquí';

  @override
  String get anilistPasteTooltip => 'Pegar del portapapeles';

  @override
  String get anilistStep1 => 'Autoriza Cronicle en la pestaña que se abrió';

  @override
  String get anilistStep2 => 'Copia el token que aparece en pantalla';

  @override
  String get anilistStep3 => 'Vuelve aquí y pégalo abajo';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connect => 'Conectar';

  @override
  String get settingsDefaultFilter => 'Filtro por defecto en Biblioteca';

  @override
  String get settingsDefaultFilterDesc =>
      'Al abrir la biblioteca se mostrará este estado';

  @override
  String get settingsDefaultsTitle => 'Pantalla y pestaña por defecto';

  @override
  String get settingsDefaultsDesc => 'Configura qué se muestra al abrir la app';

  @override
  String get settingsStartPage => 'Página de inicio';

  @override
  String get settingsStartFeed => 'Inicio (Feed)';

  @override
  String get settingsStartLibrary => 'Biblioteca';

  @override
  String get settingsFeedTab => 'Pestaña del feed por defecto';

  @override
  String get settingsFeedActivityScope => 'Vista por defecto del feed';

  @override
  String get settingsAppearanceTitle => 'Apariencia';

  @override
  String get settingsAppearanceSubtitle =>
      'Tema, idioma y barras del inicio y la biblioteca.';

  @override
  String get settingsLayoutCustomizationTitle =>
      'Barras de inicio y biblioteca';

  @override
  String get settingsLayoutCustomizationSubtitle =>
      'Elige qué pestañas mostrar y en qué orden.';

  @override
  String get settingsCustomizeFeedFilters => 'Barra de filtros del feed';

  @override
  String get settingsCustomizeFeedFiltersDesc =>
      'Reordena u oculta Feed, Anime, etc. Debe quedar al menos un filtro visible.';

  @override
  String get settingsCustomizeLibraryKinds => 'Barra de tipos en Biblioteca';

  @override
  String get settingsCustomizeLibraryKindsDesc =>
      'Reordena u oculta Todo, Anime, Películas, TV, Juegos, Manga. Debe quedar al menos una opción visible.';

  @override
  String get settingsLayoutDragHint =>
      'Mantén pulsada la barra de arrastre para mover y cambiar el orden.';

  @override
  String get settingsLayoutReset => 'Restablecer';

  @override
  String get settingsLayoutResetDone => 'Orden por defecto restaurado.';

  @override
  String get settingsLayoutShowInFeed => 'Mostrar en el feed';

  @override
  String get settingsLayoutShowInLibrary => 'Mostrar en biblioteca';

  @override
  String get follow => 'Seguir';

  @override
  String get following => 'Siguiendo';

  @override
  String get commentsTitle => 'Comentarios';

  @override
  String get noComments => 'Sin comentarios';

  @override
  String get activityOriginalPost => 'Publicación original';

  @override
  String get activityRepliesHeading => 'Respuestas';

  @override
  String get activityThreadLoadError => 'No se pudo cargar el hilo';

  @override
  String get activityMessageActivity => 'Mensaje privado';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get mediaKindAnime => 'Anime';

  @override
  String get mediaKindManga => 'Manga';

  @override
  String get mediaKindMovie => 'Películas';

  @override
  String get mediaKindTv => 'Series';

  @override
  String get mediaKindGame => 'Juegos';

  @override
  String get reviewTitle => 'Reseña';

  @override
  String reviewByUser(Object name) {
    return 'Por $name';
  }

  @override
  String get reviewHelpful => '¿Útil?';

  @override
  String get reviewUpVote => 'Sí';

  @override
  String get reviewDownVote => 'No';

  @override
  String get reviewLoginRequired => 'Inicia sesión en Anilist para votar';

  @override
  String reviewUsersFoundHelpful(Object count, Object total) {
    return '$count de $total encontraron útil esta reseña';
  }

  @override
  String get readMore => 'Leer más';

  @override
  String get writeReplyHint => 'Escribe un comentario...';

  @override
  String get composeActivityHint => '¿Qué estás pensando?';

  @override
  String get composeMarkdownTip => 'Soporta markdown e imágenes';

  @override
  String get cancelButton => 'Cancelar';

  @override
  String get postButton => 'Publicar';

  @override
  String get activityPosted => 'Publicado correctamente';

  @override
  String get settingsHideTextActivities => 'Ocultar actividades de texto';

  @override
  String get settingsHideTextActivitiesDesc =>
      'No mostrar publicaciones de texto en el feed';

  @override
  String get statusCurrentGame => 'Jugando';

  @override
  String get statusReplayingGame => 'Rejugando';

  @override
  String get searchTrendingGames => 'Juegos en tendencia';

  @override
  String get igdbWebNotSupported =>
      'IGDB no está disponible en el navegador (el sitio de IGDB no permite peticiones desde la web). Usa la app en Windows, Android o iOS para buscar juegos.';

  @override
  String get twitchSyncPromptTitle => 'Conecta con Twitch';

  @override
  String get twitchSyncPromptBody =>
      'Conecta tu cuenta de Twitch para sincronizar tus juegos en el futuro.\n\nTambién puedes hacerlo más tarde desde Ajustes.';

  @override
  String get twitchSyncPromptNoThanks => 'No, gracias';

  @override
  String get twitchConnect => 'Conectar Twitch';

  @override
  String get gameDetailPlatforms => 'Plataformas';

  @override
  String get gameDetailGenres => 'Géneros';

  @override
  String get gameDetailSynopsis => 'Sinopsis';

  @override
  String get gameDetailStoryline => 'Historia';

  @override
  String get gameDetailModes => 'Modos de juego';

  @override
  String get gameDetailThemes => 'Temas';

  @override
  String get gameDetailDeveloper => 'Desarrollador';

  @override
  String get gameDetailPublisher => 'Distribuidor';

  @override
  String get gameDetailReleaseDate => 'Fecha de lanzamiento';

  @override
  String get gameDetailRating => 'Puntuación';

  @override
  String get gameDetailSimilarGames => 'Juegos similares';

  @override
  String get gameDetailNoData => 'No se encontraron datos del juego';

  @override
  String get gameDetailCompanies => 'Empresas';

  @override
  String get addToListHoursPlayed => 'Horas jugadas';

  @override
  String get gameDetailLinksSection => 'Enlaces';

  @override
  String gameDetailLinksShowMore(Object remaining) {
    return 'Mostrar $remaining más';
  }

  @override
  String get gameDetailLinksShowLess => 'Mostrar menos';

  @override
  String get gameDetailLinkOfficialSite => 'Sitio web';

  @override
  String get gameDetailLinkKindPlayStation => 'PlayStation';

  @override
  String get gameDetailLinkKindNintendo => 'Nintendo';

  @override
  String get gameDetailLinkKindApple => 'App Store';

  @override
  String get gameDetailLinkKindGooglePlay => 'Google Play';

  @override
  String get gameDetailLinkKindAmazon => 'Amazon';

  @override
  String get gameDetailLinkKindOculus => 'Meta / Oculus';

  @override
  String get gameDetailLinkKindGameJolt => 'Game Jolt';

  @override
  String get gameDetailLinkKindHumble => 'Humble';

  @override
  String get gameDetailLinkKindUbisoft => 'Ubisoft';

  @override
  String get gameDetailLinkKindEa => 'EA';

  @override
  String get gameDetailLinkKindRockstar => 'Rockstar';

  @override
  String get gameDetailLinkKindBattlenet => 'Battle.net';

  @override
  String get gameDetailLinkKindTiktok => 'TikTok';

  @override
  String get gameDetailLinkKindBluesky => 'Bluesky';

  @override
  String get gamesHomePopularNow => 'Popular ahora';

  @override
  String get gamesHomeMostAnticipated => 'Más esperados';

  @override
  String get gamesHomeRecentReviews => 'Reseñas recientes';

  @override
  String get gamesHomeCriticsReviews => 'Reseñas de críticos';

  @override
  String get gamesHomeRecentlyReleased => 'Recién salidos';

  @override
  String get gamesHomeComingSoon => 'Próximamente';

  @override
  String get gamesHomeSectionExpand => 'Ver más';

  @override
  String get gamesHomeSectionCollapse => 'Ver menos';

  @override
  String get gamesHomeNoItems => 'Sin contenido';

  @override
  String get gamesHomeOpenGame => 'Ver juego';

  @override
  String get igdbReviewNotFound => 'No se encontró la reseña.';

  @override
  String get gameDetailOpenIgdb => 'Ver en IGDB';

  @override
  String get gameDetailTimeToBeatSection => 'Tiempo estimado (IGDB)';

  @override
  String get gameDetailTtbHastily => 'Historia principal (rápido)';

  @override
  String get gameDetailTtbNormal => 'Historia principal (normal)';

  @override
  String get gameDetailTtbComplete => 'Al 100%';

  @override
  String get gameDetailScreenshots => 'Capturas';

  @override
  String get gameDetailReviewsSection => 'Reseñas (IGDB)';

  @override
  String get gameDetailNoReviews => 'No hay reseñas en IGDB para este juego.';

  @override
  String get gameDetailReviewUntitled => 'Reseña';

  @override
  String gameDetailReviewBy(Object name) {
    return 'Por $name';
  }

  @override
  String gameDetailPlaytimeHoursMinutes(Object hours, Object minutes) {
    return '$hours h $minutes min';
  }

  @override
  String gameDetailPlaytimeHoursOnly(Object hours) {
    return '$hours h';
  }

  @override
  String gameDetailPlaytimeMinutesOnly(Object minutes) {
    return '$minutes min';
  }

  @override
  String get gameDetailWebCatOfficial => 'Web oficial';

  @override
  String get gameDetailWebCatWikia => 'Wikia';

  @override
  String get gameDetailWebCatWikipedia => 'Wikipedia';

  @override
  String get gameDetailWebCatFacebook => 'Facebook';

  @override
  String get gameDetailWebCatTwitter => 'Twitter / X';

  @override
  String get gameDetailWebCatTwitch => 'Twitch';

  @override
  String get gameDetailWebCatInstagram => 'Instagram';

  @override
  String get gameDetailWebCatYoutube => 'YouTube';

  @override
  String get gameDetailWebCatSteam => 'Steam';

  @override
  String get gameDetailWebCatReddit => 'Reddit';

  @override
  String get gameDetailWebCatItch => 'itch.io';

  @override
  String get gameDetailWebCatEpic => 'Epic Games';

  @override
  String get gameDetailWebCatGog => 'GOG';

  @override
  String get gameDetailWebCatDiscord => 'Discord';

  @override
  String get gameDetailWebCatOther => 'Enlace';

  @override
  String get gameDetailExtCatSteam => 'Steam';

  @override
  String get gameDetailExtCatGog => 'GOG';

  @override
  String get gameDetailExtCatMicrosoft => 'Microsoft Store';

  @override
  String get gameDetailExtCatEpic => 'Epic Games';

  @override
  String get gameDetailExtCatOther => 'Tienda externa';
}
