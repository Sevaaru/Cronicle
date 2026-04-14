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
  String get navHome => 'Feed';

  @override
  String get navLibrary => 'Biblioteca';

  @override
  String get navAnime => 'Anime';

  @override
  String get navSearch => 'Búsqueda';

  @override
  String get navManga => 'Manga';

  @override
  String get navMovies => 'Películas';

  @override
  String get navTv => 'Series';

  @override
  String get navGames => 'Juegos';

  @override
  String get navSettings => 'Ajustes';

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
  String get googleSignIn => 'Iniciar sesión con Google';

  @override
  String get googleSignOut => 'Cerrar sesión de Google';

  @override
  String get backupTitle => 'Copia en Google Drive';

  @override
  String get backupStubMessage =>
      'La copia completa a la carpeta de datos de la app estará disponible en una próxima versión.';

  @override
  String get feedTitle => 'Inicio';

  @override
  String get feedEmpty => 'No hay actividad reciente.';

  @override
  String get feedRetry => 'Reintentar';

  @override
  String get libraryEmpty => 'Tu lista está vacía.';

  @override
  String get libraryAddHint => 'Busca y añade contenido desde Anime.';

  @override
  String get searchHint => 'Buscar anime...';

  @override
  String get addedToLibrary => 'Añadido a la biblioteca';

  @override
  String get backupUploadSuccess => 'Backup subido correctamente';

  @override
  String get backupRestored => 'Restaurado correctamente';

  @override
  String get connectAnilist => 'Conectar Anilist';

  @override
  String get disconnectAnilist => 'Desconectar Anilist';
}
