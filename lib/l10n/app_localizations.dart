import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// App name
  ///
  /// In es, this message translates to:
  /// **'Cronicle'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get navLibrary;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get navSearch;

  /// No description provided for @navProfile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get navProfile;

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

  /// No description provided for @navAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get navAnime;

  /// No description provided for @navManga.
  ///
  /// In es, this message translates to:
  /// **'Manga'**
  String get navManga;

  /// No description provided for @navMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get navMovies;

  /// No description provided for @navTv.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get navTv;

  /// No description provided for @navGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get navGames;

  /// No description provided for @navAuth.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get navAuth;

  /// No description provided for @homeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso y listas, offline primero.'**
  String get homeSubtitle;

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @themeMode.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @placeholderSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get placeholderSoon;

  /// No description provided for @errorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal. Inténtalo de nuevo.'**
  String get errorGeneric;

  /// No description provided for @errorNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión o error de red.'**
  String get errorNetwork;

  /// No description provided for @errorWithMessage.
  ///
  /// In es, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @errorVerifyingSession.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar sesión'**
  String get errorVerifyingSession;

  /// No description provided for @errorVerifyingToken.
  ///
  /// In es, this message translates to:
  /// **'Error al verificar token'**
  String get errorVerifyingToken;

  /// No description provided for @errorLoadingProfile.
  ///
  /// In es, this message translates to:
  /// **'Error al cargar perfil'**
  String get errorLoadingProfile;

  /// No description provided for @errorSyncMessage.
  ///
  /// In es, this message translates to:
  /// **'Error al sincronizar: {message}'**
  String errorSyncMessage(Object message);

  /// No description provided for @googleSignIn.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión con Google'**
  String get googleSignIn;

  /// No description provided for @googleSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión de Google'**
  String get googleSignOut;

  /// No description provided for @connectedWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Conectado con Google'**
  String get connectedWithGoogle;

  /// No description provided for @backupTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia en Google Drive'**
  String get backupTitle;

  /// No description provided for @backupUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get backupUpload;

  /// No description provided for @backupRestore.
  ///
  /// In es, this message translates to:
  /// **'Restaurar'**
  String get backupRestore;

  /// No description provided for @backupUploadSuccess.
  ///
  /// In es, this message translates to:
  /// **'Backup subido correctamente'**
  String get backupUploadSuccess;

  /// No description provided for @backupRestored.
  ///
  /// In es, this message translates to:
  /// **'Restaurado correctamente'**
  String get backupRestored;

  /// No description provided for @backupRestoredCount.
  ///
  /// In es, this message translates to:
  /// **'Restaurados {count} elementos'**
  String backupRestoredCount(Object count);

  /// No description provided for @feedTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get feedTitle;

  /// No description provided for @feedEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay actividad reciente.'**
  String get feedEmpty;

  /// No description provided for @feedRetry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get feedRetry;

  /// No description provided for @feedComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Feed de {label} — próximamente'**
  String feedComingSoon(Object label);

  /// No description provided for @filterFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get filterFollowing;

  /// No description provided for @filterGlobal.
  ///
  /// In es, this message translates to:
  /// **'Global'**
  String get filterGlobal;

  /// No description provided for @filterAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get filterAnime;

  /// No description provided for @filterManga.
  ///
  /// In es, this message translates to:
  /// **'Manga'**
  String get filterManga;

  /// No description provided for @filterMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get filterMovies;

  /// No description provided for @filterTv.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get filterTv;

  /// No description provided for @filterGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get filterGames;

  /// No description provided for @filterAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get filterAll;

  /// No description provided for @loginRequiredFollowing.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión con Anilist para ver la actividad de las personas que sigues'**
  String get loginRequiredFollowing;

  /// No description provided for @loginRequiredLike.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en Anilist para dar like'**
  String get loginRequiredLike;

  /// No description provided for @loginRequiredFollow.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en Anilist para seguir usuarios'**
  String get loginRequiredFollow;

  /// No description provided for @goToSettings.
  ///
  /// In es, this message translates to:
  /// **'Ir a Ajustes'**
  String get goToSettings;

  /// No description provided for @timeNow.
  ///
  /// In es, this message translates to:
  /// **'ahora'**
  String get timeNow;

  /// No description provided for @timeMinutes.
  ///
  /// In es, this message translates to:
  /// **'{count}m'**
  String timeMinutes(Object count);

  /// No description provided for @timeHours.
  ///
  /// In es, this message translates to:
  /// **'{count}h'**
  String timeHours(Object count);

  /// No description provided for @timeDays.
  ///
  /// In es, this message translates to:
  /// **'{count}d'**
  String timeDays(Object count);

  /// No description provided for @timeWeeks.
  ///
  /// In es, this message translates to:
  /// **'{count}sem'**
  String timeWeeks(Object count);

  /// No description provided for @libraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get libraryTitle;

  /// No description provided for @libraryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu lista está vacía.'**
  String get libraryEmpty;

  /// No description provided for @libraryAddHint.
  ///
  /// In es, this message translates to:
  /// **'Busca y añade contenido.'**
  String get libraryAddHint;

  /// No description provided for @libraryNoResults.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados'**
  String get libraryNoResults;

  /// No description provided for @libraryNoStatusResults.
  ///
  /// In es, this message translates to:
  /// **'No hay títulos con este estado'**
  String get libraryNoStatusResults;

  /// No description provided for @librarySearchAndAdd.
  ///
  /// In es, this message translates to:
  /// **'Busca y añade contenido'**
  String get librarySearchAndAdd;

  /// No description provided for @statusAll.
  ///
  /// In es, this message translates to:
  /// **'Todo'**
  String get statusAll;

  /// No description provided for @statusCurrent.
  ///
  /// In es, this message translates to:
  /// **'En progreso'**
  String get statusCurrent;

  /// No description provided for @statusCurrentAnime.
  ///
  /// In es, this message translates to:
  /// **'Viendo'**
  String get statusCurrentAnime;

  /// No description provided for @statusCurrentManga.
  ///
  /// In es, this message translates to:
  /// **'Leyendo'**
  String get statusCurrentManga;

  /// No description provided for @statusPlanning.
  ///
  /// In es, this message translates to:
  /// **'Planeado'**
  String get statusPlanning;

  /// No description provided for @statusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get statusCompleted;

  /// No description provided for @statusPaused.
  ///
  /// In es, this message translates to:
  /// **'Pausado'**
  String get statusPaused;

  /// No description provided for @statusDropped.
  ///
  /// In es, this message translates to:
  /// **'Abandonado'**
  String get statusDropped;

  /// No description provided for @statusRepeating.
  ///
  /// In es, this message translates to:
  /// **'Repitiendo'**
  String get statusRepeating;

  /// No description provided for @sortRecent.
  ///
  /// In es, this message translates to:
  /// **'Recientes'**
  String get sortRecent;

  /// No description provided for @sortName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get sortName;

  /// No description provided for @sortScore.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get sortScore;

  /// No description provided for @sortProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso'**
  String get sortProgress;

  /// No description provided for @tooltipCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get tooltipCompleted;

  /// No description provided for @tooltipIncrementProgress.
  ///
  /// In es, this message translates to:
  /// **'+1 capítulo/episodio'**
  String get tooltipIncrementProgress;

  /// No description provided for @searchTitle.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get searchTitle;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar...'**
  String get searchHint;

  /// No description provided for @searchTrendingAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime en tendencia'**
  String get searchTrendingAnime;

  /// No description provided for @searchTrendingManga.
  ///
  /// In es, this message translates to:
  /// **'Manga en tendencia'**
  String get searchTrendingManga;

  /// No description provided for @searchComingSoon.
  ///
  /// In es, this message translates to:
  /// **'{label} — próximamente'**
  String searchComingSoon(Object label);

  /// No description provided for @searchComingSoonApi.
  ///
  /// In es, this message translates to:
  /// **'Próximamente — conecta TMDB / IGDB'**
  String get searchComingSoonApi;

  /// No description provided for @searchSelectFilter.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un filtro'**
  String get searchSelectFilter;

  /// No description provided for @searchErrorIn.
  ///
  /// In es, this message translates to:
  /// **'Error en {section}: {error}'**
  String searchErrorIn(Object section, Object error);

  /// No description provided for @addToLibrary.
  ///
  /// In es, this message translates to:
  /// **'Añadir a biblioteca'**
  String get addToLibrary;

  /// No description provided for @addedToLibrary.
  ///
  /// In es, this message translates to:
  /// **'Añadido a la biblioteca'**
  String get addedToLibrary;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profileLocalUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario local'**
  String get profileLocalUser;

  /// No description provided for @profileConnectHint.
  ///
  /// In es, this message translates to:
  /// **'Conecta Anilist en Ajustes para ver tus estadísticas completas'**
  String get profileConnectHint;

  /// No description provided for @profileLocalLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca local'**
  String get profileLocalLibrary;

  /// No description provided for @profileLibraryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu biblioteca está vacía'**
  String get profileLibraryEmpty;

  /// No description provided for @profileNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró el usuario'**
  String get profileNotFound;

  /// No description provided for @sectionAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get sectionAnime;

  /// No description provided for @sectionManga.
  ///
  /// In es, this message translates to:
  /// **'Manga'**
  String get sectionManga;

  /// No description provided for @sectionFavAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime favoritos'**
  String get sectionFavAnime;

  /// No description provided for @sectionFavManga.
  ///
  /// In es, this message translates to:
  /// **'Manga favoritos'**
  String get sectionFavManga;

  /// No description provided for @sectionRecentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get sectionRecentActivity;

  /// No description provided for @sectionConnectedAccounts.
  ///
  /// In es, this message translates to:
  /// **'Cuentas conectadas'**
  String get sectionConnectedAccounts;

  /// No description provided for @sectionTopGenresAnime.
  ///
  /// In es, this message translates to:
  /// **'Top géneros anime'**
  String get sectionTopGenresAnime;

  /// No description provided for @sectionTopGenresManga.
  ///
  /// In es, this message translates to:
  /// **'Top géneros manga'**
  String get sectionTopGenresManga;

  /// No description provided for @statTitles.
  ///
  /// In es, this message translates to:
  /// **'Títulos'**
  String get statTitles;

  /// No description provided for @statEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Episodios'**
  String get statEpisodes;

  /// No description provided for @statChapters.
  ///
  /// In es, this message translates to:
  /// **'Capítulos'**
  String get statChapters;

  /// No description provided for @statVolumes.
  ///
  /// In es, this message translates to:
  /// **'Volúmenes'**
  String get statVolumes;

  /// No description provided for @statDaysWatching.
  ///
  /// In es, this message translates to:
  /// **'Días viendo'**
  String get statDaysWatching;

  /// No description provided for @statDays.
  ///
  /// In es, this message translates to:
  /// **'Días'**
  String get statDays;

  /// No description provided for @statMeanScore.
  ///
  /// In es, this message translates to:
  /// **'Nota media'**
  String get statMeanScore;

  /// No description provided for @statPopularity.
  ///
  /// In es, this message translates to:
  /// **'Popularidad'**
  String get statPopularity;

  /// No description provided for @statFavourites.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get statFavourites;

  /// No description provided for @mediaInfo.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get mediaInfo;

  /// No description provided for @mediaSynopsis.
  ///
  /// In es, this message translates to:
  /// **'Sinopsis'**
  String get mediaSynopsis;

  /// No description provided for @mediaEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Episodios'**
  String get mediaEpisodes;

  /// No description provided for @mediaChapters.
  ///
  /// In es, this message translates to:
  /// **'Capítulos'**
  String get mediaChapters;

  /// No description provided for @mediaVolumes.
  ///
  /// In es, this message translates to:
  /// **'Volúmenes'**
  String get mediaVolumes;

  /// No description provided for @mediaDuration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get mediaDuration;

  /// No description provided for @mediaSeason.
  ///
  /// In es, this message translates to:
  /// **'Temporada'**
  String get mediaSeason;

  /// No description provided for @mediaSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente'**
  String get mediaSource;

  /// No description provided for @mediaStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get mediaStart;

  /// No description provided for @mediaEnd.
  ///
  /// In es, this message translates to:
  /// **'Fin'**
  String get mediaEnd;

  /// No description provided for @mediaStudio.
  ///
  /// In es, this message translates to:
  /// **'Estudio: '**
  String get mediaStudio;

  /// No description provided for @mediaWhere.
  ///
  /// In es, this message translates to:
  /// **'Dónde ver'**
  String get mediaWhere;

  /// No description provided for @mediaRelated.
  ///
  /// In es, this message translates to:
  /// **'Relacionados'**
  String get mediaRelated;

  /// No description provided for @mediaRecommendations.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get mediaRecommendations;

  /// No description provided for @mediaScoreDistribution.
  ///
  /// In es, this message translates to:
  /// **'Distribución de notas'**
  String get mediaScoreDistribution;

  /// No description provided for @mediaReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas'**
  String get mediaReviews;

  /// No description provided for @mediaNoData.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron datos'**
  String get mediaNoData;

  /// No description provided for @mediaAnonymous.
  ///
  /// In es, this message translates to:
  /// **'Anónimo'**
  String get mediaAnonymous;

  /// No description provided for @mediaNextEp.
  ///
  /// In es, this message translates to:
  /// **'Ep {episode} en {days}d {hours}h'**
  String mediaNextEp(Object episode, Object days, Object hours);

  /// No description provided for @addToListTitle.
  ///
  /// In es, this message translates to:
  /// **'Añadir a tu lista'**
  String get addToListTitle;

  /// No description provided for @addToListStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get addToListStatus;

  /// No description provided for @addToListScore.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get addToListScore;

  /// No description provided for @addToListNoScore.
  ///
  /// In es, this message translates to:
  /// **'Sin nota'**
  String get addToListNoScore;

  /// No description provided for @addToListEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Episodios'**
  String get addToListEpisodes;

  /// No description provided for @addToListChapters.
  ///
  /// In es, this message translates to:
  /// **'Capítulos'**
  String get addToListChapters;

  /// No description provided for @addToListOf.
  ///
  /// In es, this message translates to:
  /// **'de {total}'**
  String addToListOf(Object total);

  /// No description provided for @addToListMax.
  ///
  /// In es, this message translates to:
  /// **'Máx'**
  String get addToListMax;

  /// No description provided for @addToListNotes.
  ///
  /// In es, this message translates to:
  /// **'Notas'**
  String get addToListNotes;

  /// No description provided for @addToListNotesHint.
  ///
  /// In es, this message translates to:
  /// **'Notas personales (opcional)...'**
  String get addToListNotesHint;

  /// No description provided for @addToListSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get addToListSave;

  /// No description provided for @syncTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar con Anilist'**
  String get syncTitle;

  /// No description provided for @syncWelcome.
  ///
  /// In es, this message translates to:
  /// **'¡Bienvenido, {name}! ¿Cómo quieres sincronizar tu biblioteca?'**
  String syncWelcome(Object name);

  /// No description provided for @syncImport.
  ///
  /// In es, this message translates to:
  /// **'Importar de Anilist'**
  String get syncImport;

  /// No description provided for @syncImportDesc.
  ///
  /// In es, this message translates to:
  /// **'Trae toda tu lista de Anilist aquí (recomendado)'**
  String get syncImportDesc;

  /// No description provided for @syncMerge.
  ///
  /// In es, this message translates to:
  /// **'Combinar'**
  String get syncMerge;

  /// No description provided for @syncMergeDesc.
  ///
  /// In es, this message translates to:
  /// **'Fusiona registros locales con Anilist'**
  String get syncMergeDesc;

  /// No description provided for @syncNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get syncNotNow;

  /// No description provided for @syncLoading.
  ///
  /// In es, this message translates to:
  /// **'Sincronizando...'**
  String get syncLoading;

  /// No description provided for @syncImportedCount.
  ///
  /// In es, this message translates to:
  /// **'Importados {count} títulos de Anilist'**
  String syncImportedCount(Object count);

  /// No description provided for @syncPromptTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincroniza con Anilist'**
  String get syncPromptTitle;

  /// No description provided for @syncPromptBody.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu cuenta de Anilist para que tu lista de anime y manga se mantenga sincronizada automáticamente.\n\nTambién puedes hacerlo más tarde desde Ajustes.'**
  String get syncPromptBody;

  /// No description provided for @syncPromptNoThanks.
  ///
  /// In es, this message translates to:
  /// **'No, gracias'**
  String get syncPromptNoThanks;

  /// No description provided for @anilistTitle.
  ///
  /// In es, this message translates to:
  /// **'Anilist'**
  String get anilistTitle;

  /// No description provided for @anilistSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sincroniza tu lista de anime y manga'**
  String get anilistSubtitle;

  /// No description provided for @anilistConnected.
  ///
  /// In es, this message translates to:
  /// **'Conectado'**
  String get anilistConnected;

  /// No description provided for @anilistDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Desconectado de Anilist'**
  String get anilistDisconnected;

  /// No description provided for @anilistConnectSuccess.
  ///
  /// In es, this message translates to:
  /// **'¡Conectado con Anilist!'**
  String get anilistConnectSuccess;

  /// No description provided for @anilistConnectTitle.
  ///
  /// In es, this message translates to:
  /// **'Conectar Anilist'**
  String get anilistConnectTitle;

  /// No description provided for @anilistDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar Anilist'**
  String get anilistDisconnect;

  /// No description provided for @anilistConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar Anilist'**
  String get anilistConnect;

  /// No description provided for @anilistTokenLabel.
  ///
  /// In es, this message translates to:
  /// **'Token de Anilist'**
  String get anilistTokenLabel;

  /// No description provided for @anilistTokenHint.
  ///
  /// In es, this message translates to:
  /// **'Pega el token aquí'**
  String get anilistTokenHint;

  /// No description provided for @anilistPasteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Pegar del portapapeles'**
  String get anilistPasteTooltip;

  /// No description provided for @anilistStep1.
  ///
  /// In es, this message translates to:
  /// **'Autoriza Cronicle en la pestaña que se abrió'**
  String get anilistStep1;

  /// No description provided for @anilistStep2.
  ///
  /// In es, this message translates to:
  /// **'Copia el token que aparece en pantalla'**
  String get anilistStep2;

  /// No description provided for @anilistStep3.
  ///
  /// In es, this message translates to:
  /// **'Vuelve aquí y pégalo abajo'**
  String get anilistStep3;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @connect.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get connect;

  /// No description provided for @settingsDefaultFilter.
  ///
  /// In es, this message translates to:
  /// **'Filtro por defecto en Biblioteca'**
  String get settingsDefaultFilter;

  /// No description provided for @settingsDefaultFilterDesc.
  ///
  /// In es, this message translates to:
  /// **'Al abrir la biblioteca se mostrará este estado'**
  String get settingsDefaultFilterDesc;

  /// No description provided for @settingsDefaultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pantalla y pestaña por defecto'**
  String get settingsDefaultsTitle;

  /// No description provided for @settingsDefaultsDesc.
  ///
  /// In es, this message translates to:
  /// **'Configura qué se muestra al abrir la app'**
  String get settingsDefaultsDesc;

  /// No description provided for @settingsStartPage.
  ///
  /// In es, this message translates to:
  /// **'Página de inicio'**
  String get settingsStartPage;

  /// No description provided for @settingsStartFeed.
  ///
  /// In es, this message translates to:
  /// **'Inicio (Feed)'**
  String get settingsStartFeed;

  /// No description provided for @settingsStartLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get settingsStartLibrary;

  /// No description provided for @settingsFeedTab.
  ///
  /// In es, this message translates to:
  /// **'Pestaña del feed por defecto'**
  String get settingsFeedTab;

  /// No description provided for @follow.
  ///
  /// In es, this message translates to:
  /// **'Seguir'**
  String get follow;

  /// No description provided for @following.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get following;

  /// No description provided for @commentsTitle.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get commentsTitle;

  /// No description provided for @noComments.
  ///
  /// In es, this message translates to:
  /// **'Sin comentarios'**
  String get noComments;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoon;

  /// No description provided for @mediaKindAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get mediaKindAnime;

  /// No description provided for @mediaKindManga.
  ///
  /// In es, this message translates to:
  /// **'Manga'**
  String get mediaKindManga;

  /// No description provided for @mediaKindMovie.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get mediaKindMovie;

  /// No description provided for @mediaKindTv.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get mediaKindTv;

  /// No description provided for @mediaKindGame.
  ///
  /// In es, this message translates to:
  /// **'Juegos'**
  String get mediaKindGame;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
