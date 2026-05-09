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
  String get navSocial => 'Social';

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
  String get settingsAboutApp => 'Acerca de esta aplicación';

  @override
  String settingsAboutCopyright(Object year) {
    return '© $year Todos los derechos reservados.';
  }

  @override
  String get settingsAboutCreator => 'Cronicle está creada por Sevaaru.';

  @override
  String get settingsWearTitle => 'Reloj (Wear OS)';

  @override
  String get settingsWearConnected => 'Reloj conectado';

  @override
  String get settingsWearCompanionInstalled => 'App companion instalada';

  @override
  String get settingsWearNoCompanion =>
      'Hay un reloj emparejado pero la app companion no está instalada.';

  @override
  String get settingsWearNoWatch =>
      '¿Tienes un reloj Wear OS? Instala la app companion de Cronicle para ver y actualizar tu progreso desde la muñeca.';

  @override
  String get settingsWearOpenPlayStore => 'Abrir Google Play';

  @override
  String get settingsWearRefresh => 'Comprobar de nuevo';

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
  String get errorAnilistRateLimit =>
      'AniList ha limitado las peticiones. Reintenta en unos segundos.';

  @override
  String errorAnilistRateLimitWithSeconds(int seconds) {
    return 'AniList ha limitado las peticiones. Reintenta en $seconds s.';
  }

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
  String get never => 'Nunca';

  @override
  String googleLastSyncLine(Object when) {
    return 'Última sincronización: $when';
  }

  @override
  String get backupSaveFileDialogTitle => 'Guardar copia de seguridad';

  @override
  String get connectedWithGoogle => 'Conectado con Google';

  @override
  String get googleDrivePermissionMissing =>
      'La cuenta de Google está iniciada, pero no se concedió el acceso a la copia en Drive. Vuelve a intentarlo y acepta el permiso de datos de la app en Drive.';

  @override
  String get googleSignInCanceledTitle => 'Google no pudo completar el acceso';

  @override
  String get googleSignInCanceledBody =>
      'Algo salió mal al iniciar sesión con Google. Inténtalo más tarde.';

  @override
  String get googleSignInNotConfiguredTitle =>
      'Google no está configurado en esta compilación';

  @override
  String get googleSignInNotConfiguredHint =>
      'En esta versión no está activada la copia de seguridad con Google.';

  @override
  String get googleSignInNotConfiguredBody =>
      'A esta compilación le faltan los datos para iniciar sesión con Google y usar Drive. Si compilas Cronicle tú mismo, consulta guide/CRONICLE_GUIDE.md (variables de entorno / Google Cloud).';

  @override
  String get backupTitle => 'Copia de seguridad local';

  @override
  String get backupUpload => 'Subir';

  @override
  String get backupExportButton => 'Guardar copia';

  @override
  String get backupRestore => 'Restaurar';

  @override
  String get backupUploadSuccess => 'Backup subido correctamente';

  @override
  String backupAnilistMergeFailed(Object error) {
    return 'No se pudo sincronizar con Anilist antes; se guardó lo que hay en el dispositivo. $error';
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
      'Como mucho una vez al día con conexión, solo mientras mantengas la sesión de Google en Cuentas.';

  @override
  String get backupSectionSubtitle =>
      'Guarda tu biblioteca y preferencias en un archivo.';

  @override
  String get backupRestoreChooseSourceTitle => 'Origen de la copia';

  @override
  String get backupRestoreChooseSourceBody =>
      '¿Restaurar desde un archivo guardado en el dispositivo o desde Google Drive?';

  @override
  String get backupRestoreFromFile => 'Archivo…';

  @override
  String get backupRestoreFromDrive => 'Google Drive';

  @override
  String get backupRestoreConfirmTitle => 'Restaurar copia';

  @override
  String backupRestoreConfirmBody(Object count) {
    return 'Se combinarán $count elementos de la biblioteca. Se aplicarán preferencias y cuentas vinculadas si vienen en la copia.';
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
  String get notifPermissionDeniedHint =>
      'Puedes activar las notificaciones en cualquier momento desde Ajustes.';

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
      'Necesitas cuenta de Anilist. Cada cuánto se comprueba en segundo plano lo decide el sistema.';

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
      'Si lo desactivas, en el dispositivo se muestran menos avisos sociales de Anilist.';

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
  String notificationAiringHeadlineAnime(Object title, int episode) {
    return '$title · Episodio $episode';
  }

  @override
  String notificationAiringHeadlineManga(Object title, int episode) {
    return '$title · Capítulo $episode';
  }

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
  String get feedBrowseTrending => 'Tendencias';

  @override
  String get feedBrowseTopRated => 'Mejor valorados';

  @override
  String get feedBrowseUpcoming => 'Próximos';

  @override
  String get feedBrowseRecentlyReleased => 'Recién estrenados';

  @override
  String get feedBrowseEmpty => 'No hay títulos en esta lista.';

  @override
  String get feedSummary => 'Descubrir';

  @override
  String get summaryTrendingAnime => 'Anime en tendencia';

  @override
  String get summaryTrendingManga => 'Manga en tendencia';

  @override
  String get summaryTrendingMovies => 'Películas en tendencia';

  @override
  String get summaryTrendingShows => 'Series en tendencia';

  @override
  String get summaryPopularGames => 'Juegos populares';

  @override
  String get summaryTrendingBooks => 'Libros en tendencia';

  @override
  String get summaryNewBooks => 'Novedades';

  @override
  String get summaryTopAnime => 'Anime mejor valorado';

  @override
  String get summaryTopManga => 'Manga mejor valorado';

  @override
  String get summaryAnticipatedMovies => 'Películas más esperadas';

  @override
  String get summaryAnticipatedShows => 'Series más esperadas';

  @override
  String get summaryAnticipatedGames => 'Juegos más esperados';

  @override
  String get summaryRandom => 'Descubre algo nuevo';

  @override
  String get summaryRandomButton => 'Título al azar';

  @override
  String get summaryRandomSub => 'Prueba algo de tus intereses';

  @override
  String get summarySeeAll => 'Ver todo';

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
  String get filterBooks => 'Libros';

  @override
  String get filterAll => 'Todo';

  @override
  String get filterStatus => 'Estado';

  @override
  String get loginRequiredFollowing =>
      'Inicia sesión con Anilist para ver la actividad de las personas que sigues';

  @override
  String get loginRequiredLike => 'Inicia sesión en Anilist para dar like';

  @override
  String get loginRequiredComment => 'Inicia sesión en Anilist para comentar';

  @override
  String get loginRequiredFavorite =>
      'Inicia sesión en Anilist en Ajustes para usar favoritos';

  @override
  String get sectionFavGames => 'Juegos';

  @override
  String get sectionFavBooks => 'Libros';

  @override
  String get sectionFavCharacters => 'Personajes';

  @override
  String get sectionFavStaff => 'Staff';

  @override
  String get loginRequiredFavoriteCharacter =>
      'Inicia sesión con Anilist en Ajustes para marcar personajes favoritos';

  @override
  String get loginRequiredFavoriteStaff =>
      'Inicia sesión con Anilist en Ajustes para marcar staff favorito';

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
  String searchShowMoreInCategory(Object category) {
    return 'Ver más — $category';
  }

  @override
  String get searchIdleAllTitle => 'Buscar en todo';

  @override
  String get searchIdleAllBody =>
      'Escribe para buscar en todas las categorías a la vez, o elige una categoría arriba para explorar tendencias y acotar la búsqueda.';

  @override
  String get searchBrowsePopularityAllTime => 'Por popularidad';

  @override
  String get searchBrowseByStartDate => 'Por fecha de estreno';

  @override
  String get searchBrowseByGenre => 'Por género';

  @override
  String get searchBrowseGenresAnime => 'Géneros de anime';

  @override
  String get searchBrowseGenresManga => 'Géneros de manga';

  @override
  String get searchBrowseGameThemes => 'Por temática';

  @override
  String get searchBrowseBookSubjects => 'Temas';

  @override
  String get searchReleaseDateHint =>
      'Elige el año y, si quieres, el mes para acotar.';

  @override
  String get searchReleaseDateYear => 'Año';

  @override
  String get searchReleaseDateMonth => 'Mes';

  @override
  String get searchReleaseDateAllMonths => 'Todo el año';

  @override
  String get searchReleaseDateEmpty => 'No hay resultados para este periodo.';

  @override
  String get searchOlSubjectFantasy => 'Fantasía';

  @override
  String get searchOlSubjectRomance => 'Romance';

  @override
  String get searchOlSubjectScienceFiction => 'Ciencia ficción';

  @override
  String get searchOlSubjectHorror => 'Terror';

  @override
  String get searchOlSubjectMystery => 'Misterio';

  @override
  String get searchOlSubjectFiction => 'Ficción';

  @override
  String get searchOlSubjectHistory => 'Historia';

  @override
  String get searchOlSubjectBiography => 'Biografía';

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
  String get profilePersonalStatsTitle => 'Estadísticas personales';

  @override
  String get profilePersonalStatsSubtitle =>
      'Anime, manga, cine, series y juegos en el dispositivo';

  @override
  String get sectionProfileLocalGames => 'Juegos (en el dispositivo)';

  @override
  String get profileLocalGamesHoursTotal => 'Horas registradas';

  @override
  String get profileLocalGamesEmpty =>
      'Aún no hay juegos en tu biblioteca local.';

  @override
  String get profileLocalUser => 'Usuario local';

  @override
  String get profileFavoritesSectionTitle => 'Favoritos';

  @override
  String get profileConnectHint =>
      'Conecta AniList y Trakt en Ajustes para ver tus estadísticas completas';

  @override
  String get profileLocalLibrary => 'Biblioteca local';

  @override
  String get profileLibraryEmpty => 'Tu biblioteca está vacía';

  @override
  String get profileNotFound => 'No se encontró el usuario';

  @override
  String get anilistProfileFollowers => 'Seguidores';

  @override
  String get anilistProfileFollowing => 'Siguiendo';

  @override
  String get anilistFollowListEmpty => 'Nadie aquí todavía.';

  @override
  String get sectionAnime => 'Anime';

  @override
  String get sectionManga => 'Manga';

  @override
  String get sectionFavAnime => 'Anime';

  @override
  String get sectionFavManga => 'Manga';

  @override
  String get sectionRecentActivity => 'Actividad reciente';

  @override
  String get sectionConnectedAccounts => 'Cuentas conectadas';

  @override
  String get profileSectionTrakt => 'Cine y series (Trakt)';

  @override
  String get profileTraktMoviesWatched => 'Películas vistas';

  @override
  String get profileTraktShowsWatched => 'Series vistas';

  @override
  String get profileTraktEpisodesWatched => 'Episodios vistos';

  @override
  String get profileTraktHoursApprox => 'Horas vistas (aprox.)';

  @override
  String get sectionFavTraktMovies => 'Películas';

  @override
  String get sectionFavTraktShows => 'Series';

  @override
  String get profileTraktNotConnected => 'Sin conectar';

  @override
  String get profileTraktSubMovies => 'Películas';

  @override
  String get profileTraktSubShows => 'Series';

  @override
  String get profileTraktSubEpisodes => 'Episodios';

  @override
  String get profileTraktSubSeasons => 'Temporadas';

  @override
  String get profileTraktSubNetwork => 'Red';

  @override
  String get statTraktPlays => 'Reproducciones';

  @override
  String get statTraktWatched => 'Vistos';

  @override
  String get statTraktCollected => 'En colección';

  @override
  String get statTraktRatings => 'Valoraciones';

  @override
  String get statTraktComments => 'Comentarios';

  @override
  String get statTraktWatchTimeHrs => 'Tiempo visionado (h)';

  @override
  String get statTraktFriends => 'Amigos';

  @override
  String get statTraktFollowers => 'Seguidores';

  @override
  String get statTraktFollowing => 'Siguiendo';

  @override
  String get profileTraktRatingsTotal => 'Valoraciones (totales)';

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
  String get mediaCharacters => 'Personajes';

  @override
  String get mediaStaff => 'Staff';

  @override
  String get mediaViewAll => 'Ver todo';

  @override
  String get characterRoleMain => 'Principal';

  @override
  String get characterRoleSupporting => 'Secundario';

  @override
  String get characterRoleBackground => 'Fondo';

  @override
  String get characterVoiceActors => 'Actores de voz';

  @override
  String get characterAppearances => 'Apariciones';

  @override
  String get characterDescription => 'Descripción';

  @override
  String get staffRoles => 'Roles de staff';

  @override
  String get staffCharacterRoles => 'Personajes interpretados';

  @override
  String get staffOccupations => 'Ocupaciones';

  @override
  String get staffYearsActive => 'Años activos';

  @override
  String get staffHomeTown => 'Ciudad natal';

  @override
  String get staffBloodType => 'Tipo de sangre';

  @override
  String get staffDateOfBirth => 'Fecha de nacimiento';

  @override
  String get staffDateOfDeath => 'Fecha de fallecimiento';

  @override
  String get staffAge => 'Edad';

  @override
  String get staffGender => 'Género';

  @override
  String get characterAge => 'Edad';

  @override
  String get characterGender => 'Género';

  @override
  String get characterDateOfBirth => 'Fecha de nacimiento';

  @override
  String get characterBloodType => 'Tipo de sangre';

  @override
  String get characterAlternativeNames => 'Nombres alternativos';

  @override
  String get characterAlternativeSpoiler => 'Nombres con spoiler';

  @override
  String get mediaScoreDistribution => 'Distribución de notas';

  @override
  String get mediaReviews => 'Reseñas';

  @override
  String get mediaNoData => 'No se encontraron datos';

  @override
  String get mediaAnonymous => 'Anónimo';

  @override
  String get mediaDetailChipsShowMore => 'Mostrar más';

  @override
  String get mediaDetailChipsShowLess => 'Mostrar menos';

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
  String get scoreSet => 'Aplicar';

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
  String get completionDialogTitle => '¡Lo has terminado!';

  @override
  String get completionDialogSubtitle => '¿Quieres dejar nota y comentarios?';

  @override
  String get completionDialogSkip => 'Omitir';

  @override
  String get traktNotConfiguredHint =>
      'Añade TRAKT_CLIENT_ID a los dart-define para ver películas y series desde Trakt (sin género anime, para no duplicar AniList).';

  @override
  String get traktSectionTrending => 'Tendencias';

  @override
  String get traktSectionWatchingNow => 'Viendo ahora';

  @override
  String get traktSectionAnticipatedMovies => 'Más esperadas';

  @override
  String get traktSectionPopular => 'Popular';

  @override
  String get traktSectionMostPlayed => 'Más reproducidas';

  @override
  String get traktSectionMostWatched => 'Más vistas';

  @override
  String get traktSectionMostCollected => 'Más coleccionadas';

  @override
  String get traktSectionAnticipatedShows => 'Series más esperadas';

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
      'Inicio de sesión con Trakt no disponible en esta versión.';

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
  String get traktDetailLinks => 'Enlaces';

  @override
  String get traktLinkTrailer => 'Tráiler';

  @override
  String get traktLinkHomepage => 'Sitio web';

  @override
  String get traktDetailOnTrakt => 'Abrir en Trakt';

  @override
  String get traktEpisodeProgressTitle => 'Progreso de episodios';

  @override
  String get traktEpisodeProgressHint =>
      'Añade esta serie a tu biblioteca para llevar la cuenta de episodios vistos.';

  @override
  String get traktEpisodeProgressMarkComplete => 'Marcar serie como completada';

  @override
  String get traktEpisodeMinusOne => 'Un episodio menos';

  @override
  String get traktEpisodePlusOne => 'Un episodio más';

  @override
  String get traktDetailVotes => 'Votos';

  @override
  String get traktDetailLanguage => 'Idioma';

  @override
  String get traktDetailOriginalTitle => 'Título original';

  @override
  String get traktDetailSubgenres => 'Subgéneros';

  @override
  String get traktDetailCountry => 'País';

  @override
  String get traktDetailYear => 'Año';

  @override
  String get traktDetailNetwork => 'Cadena';

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
      'Anilist para anime y manga, Trakt para cine y series, Google opcional para copia en la nube. Los juegos quedan en el dispositivo.';

  @override
  String get settingsNotificationsCategoryDesc =>
      'Alertas del dispositivo e integración con Wear OS';

  @override
  String get settingsDataTitle => 'Datos y copia de seguridad';

  @override
  String get settingsDataCategorySubtitle =>
      'Exportar e importar datos de tu biblioteca';

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
      'Opcional: guarda la misma copia en Google Drive (subida manual o copia diaria automática).';

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
  String get anilistStep2Bridge =>
      'Tras aceptar, copia el token largo de la página de Cronicle que se abre en el navegador.';

  @override
  String get anilistStep3Bridge => 'Pégalo abajo y pulsa Conectar.';

  @override
  String get anilistOAuthWebUnavailable =>
      'Iniciar sesión en Anilist no está disponible en la versión web. Usa la app en móvil u ordenador.';

  @override
  String get anilistOAuthTimeout =>
      'La autorización de Anilist tardó demasiado. Inténtalo de nuevo.';

  @override
  String get anilistOAuthLaunchFailed => 'No se pudo abrir el navegador.';

  @override
  String get anilistBridgeNotConfigured =>
      'Define ANILIST_REDIRECT_URI con tu URL HTTPS (anilist_oauth_bridge.html) y regístrala igual en Anilist → Developer para entrar sin pegar token en el móvil.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get connect => 'Conectar';

  @override
  String get settingsDefaultFilter => 'Filtro por defecto en Biblioteca';

  @override
  String get settingsDefaultFilterDesc =>
      'La biblioteca se abre con este filtro seleccionado.';

  @override
  String get settingsDefaultsTitle => 'Pantalla y pestaña por defecto';

  @override
  String get settingsDefaultsDesc =>
      'Elige la primera pantalla y pestaña al abrir la app.';

  @override
  String get settingsStartPage => 'Página de inicio';

  @override
  String get settingsStartFeed => 'Inicio';

  @override
  String get settingsStartLibrary => 'Biblioteca';

  @override
  String get settingsFeedTab => 'Pestaña de inicio por defecto';

  @override
  String get settingsFeedActivityScope => 'Vista por defecto del feed';

  @override
  String get settingsAppearanceTitle => 'Apariencia';

  @override
  String get settingsAppearanceSubtitle =>
      'Tema, idioma y las barras de pestañas en Inicio y Biblioteca.';

  @override
  String get settingsLayoutCustomizationTitle =>
      'Barras de inicio y biblioteca';

  @override
  String get settingsLayoutCustomizationSubtitle =>
      'Elige qué pestañas se muestran y en qué orden.';

  @override
  String get settingsCustomizeFeedFilters => 'Barra de filtros del feed';

  @override
  String get settingsCustomizeFeedFiltersDesc =>
      'Muestra, oculta o reordena las pestañas del feed. Al menos una debe quedar visible.';

  @override
  String get settingsCustomizeLibraryKinds => 'Barra de tipos en Biblioteca';

  @override
  String get settingsCustomizeLibraryKindsDesc =>
      'Muestra, oculta o reordena los tipos de biblioteca. Al menos uno debe quedar visible.';

  @override
  String get settingsLayoutDragHint =>
      'Mantén pulsada la barra de arrastre y arrastra para cambiar el orden.';

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
  String get mediaKindBook => 'Libros';

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
  String get statusCurrentBook => 'Leyendo';

  @override
  String get statusPlayedGame => 'Jugado';

  @override
  String get statusReplayingGame => 'Rejugando';

  @override
  String get statusRereadingBook => 'Releyendo';

  @override
  String get searchTrendingGames => 'Juegos en tendencia';

  @override
  String get searchTrendingBooks => 'Libros en tendencia';

  @override
  String get igdbWebNotSupported =>
      'IGDB no puede llamar a la API desde el navegador (sin CORS). Usa Android o escritorio, o ejecuta node scripts/dev_api_proxy.mjs y define DEV_API_PROXY en tus dart-defines (ver dart_defines.example.json).';

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
  String get gameDetailStatUserScore => 'Usuarios';

  @override
  String get gameDetailStatCriticScore => 'Críticos (IGDB)';

  @override
  String gameDetailStatRatingsCount(Object count) {
    return '$count valoraciones';
  }

  @override
  String gameDetailStatCriticReviewsCount(Object count) {
    return '$count reseñas';
  }

  @override
  String get gameDetailSimilarGames => 'Juegos similares';

  @override
  String get gameDetailNoData => 'No se encontraron datos del juego';

  @override
  String get gameDetailCompanies => 'Empresas';

  @override
  String get addToListHoursPlayed => 'Horas jugadas';

  @override
  String get addToListPagesRead => 'Páginas leídas';

  @override
  String libraryPagesRemaining(Object count) {
    return '$count pág. restantes';
  }

  @override
  String libraryChaptersRemaining(Object count) {
    return '$count capítulos restantes';
  }

  @override
  String libraryAnimeAiringBehind(Object count) {
    return '$count atrasados';
  }

  @override
  String bookProgressPageOf(Object current, Object total, Object pct) {
    return 'Página $current de $total ($pct%)';
  }

  @override
  String bookProgressPageSimple(Object current) {
    return 'Página $current';
  }

  @override
  String bookProgressChapterOf(Object current, Object total, Object pct) {
    return 'Capítulo $current de $total ($pct%)';
  }

  @override
  String bookProgressChapterSimple(Object current) {
    return 'Capítulo $current';
  }

  @override
  String bookPercentRemaining(Object count) {
    return '$count% restantes';
  }

  @override
  String bookLibraryProgressChaptersShort(Object current, Object total) {
    return '$current/$total cap.';
  }

  @override
  String bookLibraryProgressChapterOnly(Object current) {
    return '$current cap.';
  }

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
  String get gamesHomeBestRated => 'Mejor valorados';

  @override
  String get gamesHomeIndiePicks => 'Indie destacados';

  @override
  String get gamesHomeHorrorPicks => 'Terror';

  @override
  String get gamesHomeMultiplayer => 'Multijugador';

  @override
  String get gamesHomeRpgSpotlight => 'RPG destacados';

  @override
  String get gamesHomeSportsSpotlight => 'Deportes';

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
  String get gameDetailOpenCriticSection => 'Críticas (OpenCritic)';

  @override
  String gameDetailOpenCriticMeta(Object score, Object count) {
    return 'Nota destacada: $score · $count reseñas';
  }

  @override
  String get gameDetailOpenCriticNoMatch =>
      'No hay coincidencia en OpenCritic para este título.';

  @override
  String get gameDetailOpenCriticReadReview => 'Leer reseña';

  @override
  String get gameDetailOpenCriticOpenSite => 'Abrir en OpenCritic';

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

  @override
  String get bookDetailSubjects => 'Temas';

  @override
  String get bookDetailAuthors => 'Autores';

  @override
  String get bookDetailPublishDate => 'Primera publicación';

  @override
  String bookDetailPages(Object count) {
    return '$count páginas';
  }

  @override
  String get bookDetailDescription => 'Descripción';

  @override
  String get bookDetailNoData => 'No se encontraron datos del libro';

  @override
  String get bookDetailOpenOnGoogleBooks => 'Abrir en Google Books';

  @override
  String get bookDetailEditions => 'Ediciones';

  @override
  String get bookDetailPublisher => 'Editorial';

  @override
  String get bookDetailLanguage => 'Idioma';

  @override
  String get bookDetailPrintType => 'Tipo';

  @override
  String get bookDetailMaturity => 'Clasificación';

  @override
  String get bookDetailPreview => 'Vista previa';

  @override
  String get bookDetailFormats => 'Formatos';

  @override
  String get bookDetailAvailability => 'Disponibilidad';

  @override
  String get bookDetailIdentifiers => 'Identificadores';

  @override
  String get bookActionPreview => 'Vista previa';

  @override
  String get bookActionReadOnline => 'Leer online';

  @override
  String get bookActionBuy => 'Comprar';

  @override
  String get bookActionReviews => 'Reseñas';

  @override
  String get booksHomePopularNow => 'Popular ahora';

  @override
  String get booksHomeNewReleases => 'Novedades';

  @override
  String get booksHomeTrending => 'Tendencias';

  @override
  String get booksHomeClassics => 'Clásicos';

  @override
  String get booksHomeMystery => 'Misterio';

  @override
  String get onboardingWelcomeTitle => 'Bienvenido a Cronicle';

  @override
  String get onboardingWelcomeBody =>
      'Registra tu progreso en anime, manga, películas, series, juegos y libros en un solo lugar. Organiza tus listas, anota tu avance y mantén todo sincronizado con tus servicios favoritos.';

  @override
  String get onboardingNext => 'Siguiente';

  @override
  String get onboardingTitle => '¿Qué te interesa?';

  @override
  String get onboardingSubtitle =>
      'Selecciona al menos una categoría para personalizar tu experiencia';

  @override
  String get onboardingContinue => 'Continuar';

  @override
  String get onboardingInterestAnime => 'Anime';

  @override
  String get onboardingInterestManga => 'Manga';

  @override
  String get onboardingInterestMovies => 'Películas';

  @override
  String get onboardingInterestTv => 'Series de TV';

  @override
  String get onboardingInterestGames => 'Videojuegos';

  @override
  String get onboardingInterestBooks => 'Libros';

  @override
  String get onboardingAccountsTitle => 'Conecta tus cuentas';

  @override
  String get onboardingAccountsSubtitle =>
      'Es recomendable iniciar sesión para tener tus datos sincronizados en la nube. Google sincroniza todos los datos y cuentas conectadas.';

  @override
  String get onboardingConnectAnilist => 'Conectar Anilist';

  @override
  String get onboardingConnectAnilistDesc =>
      'Sincroniza tus listas de anime y manga';

  @override
  String get onboardingConnectTrakt => 'Conectar Trakt';

  @override
  String get onboardingConnectTraktDesc => 'Sincroniza tus películas y series';

  @override
  String get onboardingConnectGoogle => 'Iniciar sesión con Google';

  @override
  String get onboardingConnectGoogleDesc =>
      'Copia de seguridad en la nube de todos tus datos y cuentas';

  @override
  String get onboardingSkip => 'Usar sin cuentas';

  @override
  String get onboardingFinish => 'Finalizar configuración';

  @override
  String get onboardingConnected => 'Conectado';

  @override
  String get onboardingAccountSynced => 'Sincronizado';

  @override
  String get onboardingSyncing => 'Sincronizando tus datos…';

  @override
  String get onboardingSyncingAllAccounts => 'Sincronizando todas tus cuentas…';

  @override
  String get onboardingWelcomeReadyTitle => 'Bienvenido a Cronicle';

  @override
  String get onboardingWelcomeReadySubtitle => 'Tu crónica empieza ahora';

  @override
  String get settingsCustomizeSearchFilters => 'Filtros de búsqueda';

  @override
  String get settingsCustomizeSearchFiltersDesc =>
      'Reordena u oculta los filtros en la pestaña de búsqueda';

  @override
  String get settingsInterests => 'Tus intereses';

  @override
  String get settingsInterestsDesc =>
      'Cambia los contenidos que ves en inicio, biblioteca y búsqueda';

  @override
  String get settingsInterestsChanged => 'Intereses actualizados';

  @override
  String get socialTitle => 'Social';

  @override
  String get settingsScoringTitle => 'Sistema de puntuación';

  @override
  String get settingsScoringDesc =>
      'Cambia cómo se muestran e ingresan las puntuaciones en toda la app. Se sincroniza automáticamente con tu cuenta de AniList';

  @override
  String get scoringPoint100 => '100 puntos';

  @override
  String get scoringPoint10Decimal => '10 puntos decimal';

  @override
  String get scoringPoint10 => '10 puntos';

  @override
  String get scoringPoint5 => '5 estrellas';

  @override
  String get scoringPoint3 => '3 caritas';

  @override
  String get settingsAdvancedScoring => 'Puntuación avanzada (Anilist)';

  @override
  String get settingsAdvancedScoringDesc =>
      'Puntúa por categorías: historia, personajes, visual, audio y disfrute';

  @override
  String get advScoringStory => 'Historia';

  @override
  String get advScoringCharacters => 'Personajes';

  @override
  String get advScoringVisuals => 'Visual';

  @override
  String get advScoringAudio => 'Audio';

  @override
  String get advScoringEnjoyment => 'Disfrute';

  @override
  String get advScoringReset => 'Restablecer';

  @override
  String get mediaStatusFinished => 'Finalizado';

  @override
  String get mediaStatusReleasing => 'En emisión';

  @override
  String get mediaStatusNotYetReleased => 'Sin estrenar';

  @override
  String get mediaStatusCancelled => 'Cancelado';

  @override
  String get mediaStatusHiatus => 'En hiato';

  @override
  String get forumDiscussions => 'Discusiones en el foro';

  @override
  String get forumViewAll => 'Ver más';

  @override
  String get forumThread => 'Hilo del foro';

  @override
  String forumReplies(int count) {
    return '$count respuestas';
  }

  @override
  String get forumNoReplies => 'Aún no hay respuestas';

  @override
  String get forumReplyButton => 'Responder';

  @override
  String forumReplyingTo(String name) {
    return 'Respondiendo a @$name';
  }

  @override
  String get socialFeedTab => 'Feed';

  @override
  String get socialForumTab => 'Foro';

  @override
  String get forumPinnedThreads => 'Hilos fijados';

  @override
  String get forumRecentlyReplied => 'Con actividad reciente';

  @override
  String get forumNewlyCreated => 'Recién creados';

  @override
  String get forumReleaseDiscussions => 'Discusiones de estrenos';

  @override
  String get bookTrackingModeLabel => 'Modo de seguimiento';

  @override
  String get bookTrackingModePages => 'Páginas';

  @override
  String get bookTrackingModePercent => '%';

  @override
  String get bookTrackingModeChapters => 'Capítulos';

  @override
  String get bookPercentageRead => 'Porcentaje leído';

  @override
  String get bookChapterProgress => 'Capítulo actual';

  @override
  String get bookOverrideTotalsLabel => 'Configura tus totales';

  @override
  String get bookOverrideTotalsHint =>
      'Tu valor manual tiene prioridad sobre la API.';

  @override
  String get bookTotalPagesOverride => 'Total de páginas';

  @override
  String get bookTotalChaptersOverride => 'Total de capítulos';

  @override
  String get bookReadingProgress => 'Progreso de lectura';

  @override
  String get bookEditionLabel => 'Edición';

  @override
  String get bookEditionUnknownPages => 'Cantidad de páginas desconocida';

  @override
  String get bookEditionNoPageHint =>
      'Si no hay páginas en la API, puedes definir tu total manualmente.';

  @override
  String get steamTitle => 'Steam';

  @override
  String get steamSubtitle =>
      'Inicia sesión con Steam para importar tus juegos, horas jugadas y logros.';

  @override
  String get steamConnect => 'Conectar Steam';

  @override
  String get steamDisconnect => 'Desconectar Steam';

  @override
  String steamConnectedAs(Object name) {
    return 'Conectado como $name';
  }

  @override
  String get steamConnectSuccess => 'Cuenta de Steam vinculada.';

  @override
  String get steamDisconnected => 'Cuenta de Steam desconectada.';

  @override
  String get steamMissingCredentials =>
      'El inicio de sesión con Steam no está disponible en esta build.';

  @override
  String get steamWebUnavailable =>
      'El inicio de sesión con Steam desde el navegador no está disponible; usa Android, iOS o escritorio.';

  @override
  String get steamOpenLibrary => 'Ver biblioteca de Steam';

  @override
  String get steamLibraryTitle => 'Biblioteca de Steam';

  @override
  String get steamProfileSection => 'Steam';

  @override
  String get steamProfileHint => 'Explora tus juegos y logros de Steam';

  @override
  String get steamNotConnectedHint =>
      'Aún no has conectado Steam. Vincula tu cuenta desde Ajustes.';

  @override
  String get steamNoGames => 'No se han encontrado juegos.';

  @override
  String get steamSearchHint => 'Buscar juego…';

  @override
  String get steamSortPlaytime => 'Horas';

  @override
  String get steamSortLastPlayed => 'Reciente';

  @override
  String get steamSortName => 'Nombre';

  @override
  String get steamRefresh => 'Actualizar';

  @override
  String steamHoursPlayed(Object hours) {
    return '$hours h jugadas';
  }

  @override
  String get steamPlaytime => 'Tiempo total';

  @override
  String get steamLastPlayed => 'Última partida';

  @override
  String get steamAddToLibrary => 'Añadir a mi biblioteca';

  @override
  String steamNoIgdbMatch(Object name) {
    return 'No se encontró equivalente en IGDB para $name.';
  }

  @override
  String get steamAchievements => 'Logros';

  @override
  String get steamNoAchievements =>
      'Este juego no tiene logros (o tu perfil de Steam es privado).';

  @override
  String steamAchievementsProgress(int unlocked, int total) {
    return '$unlocked de $total desbloqueados';
  }

  @override
  String get steamAchievementHidden => 'Logro oculto';

  @override
  String steamAchievementUnlockedOn(Object date) {
    return 'Desbloqueado $date';
  }

  @override
  String get steamAbout => 'Acerca de';

  @override
  String get steamMetacritic => 'Metacritic';

  @override
  String steamCurrentPlayers(Object count) {
    return '$count jugando ahora';
  }

  @override
  String get steamFriendsActivity => 'Actividad de amigos';

  @override
  String steamFriendsOwnThis(int count) {
    return '$count amigos tuyos tienen este juego';
  }

  @override
  String get steamFriendsNoneOwn =>
      'Ninguno de tus amigos revisados tiene este juego';

  @override
  String get steamNotConnected => 'Sin conectar';

  @override
  String get steamViewOnStore => 'Ver en Steam';

  @override
  String get steamUserReviews => 'Reseñas de usuarios';

  @override
  String steamReviewsStats(int percent, Object total) {
    return '$percent% positivas · $total reseñas';
  }

  @override
  String get steamNewsAndEvents => 'Eventos y anuncios recientes';

  @override
  String get steamNewsEmpty => 'Sin anuncios recientes';

  @override
  String get steamNewsReadMore => 'Leer más';

  @override
  String get steamCommunityLinks => 'Comunidad';

  @override
  String get steamLinkCommunityHub => 'Centro de la comunidad';

  @override
  String get steamLinkGuides => 'Guías';

  @override
  String get steamLinkDiscussions => 'Discusiones';

  @override
  String get steamLinkWorkshop => 'Workshop';

  @override
  String get steamLinkAnnouncements => 'Anuncios';

  @override
  String get steamLinkUpdateHistory => 'Historial de actualizaciones';

  @override
  String get steamLinkPointsShop => 'Tienda de puntos';

  @override
  String get steamExternalLinks => 'Enlaces externos';

  @override
  String get steamLinkOfficialSite => 'Sitio web oficial';

  @override
  String get steamLinkSupport => 'Soporte';

  @override
  String get steamPopularTags => 'Etiquetas populares';

  @override
  String get steamSystemRequirements => 'Requisitos del sistema';

  @override
  String get steamSysReqMinimum => 'Mínimos';

  @override
  String get steamSysReqRecommended => 'Recomendados';

  @override
  String get steamSimilarGames => 'Juegos similares';
}
