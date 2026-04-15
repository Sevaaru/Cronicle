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
  String get connectedWithGoogle => 'Conectado con Google';

  @override
  String get backupTitle => 'Copia en Google Drive';

  @override
  String get backupUpload => 'Subir';

  @override
  String get backupRestore => 'Restaurar';

  @override
  String get backupUploadSuccess => 'Backup subido correctamente';

  @override
  String get backupRestored => 'Restaurado correctamente';

  @override
  String backupRestoredCount(Object count) {
    return 'Restaurados $count elementos';
  }

  @override
  String get feedTitle => 'Inicio';

  @override
  String get feedEmpty => 'No hay actividad reciente.';

  @override
  String get feedRetry => 'Reintentar';

  @override
  String feedComingSoon(Object label) {
    return 'Feed de $label — próximamente';
  }

  @override
  String get filterFollowing => 'Siguiendo';

  @override
  String get filterGlobal => 'Global';

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
  String get follow => 'Seguir';

  @override
  String get following => 'Siguiendo';

  @override
  String get commentsTitle => 'Comentarios';

  @override
  String get noComments => 'Sin comentarios';

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
}
