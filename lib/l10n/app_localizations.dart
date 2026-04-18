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

  /// No description provided for @navSocial.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get navSocial;

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

  /// No description provided for @googleSyncNow.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar ahora'**
  String get googleSyncNow;

  /// No description provided for @never.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get never;

  /// No description provided for @googleLastSyncLine.
  ///
  /// In es, this message translates to:
  /// **'Última sincronización: {when}'**
  String googleLastSyncLine(Object when);

  /// No description provided for @backupSaveFileDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Guardar copia de seguridad'**
  String get backupSaveFileDialogTitle;

  /// No description provided for @connectedWithGoogle.
  ///
  /// In es, this message translates to:
  /// **'Conectado con Google'**
  String get connectedWithGoogle;

  /// No description provided for @googleDrivePermissionMissing.
  ///
  /// In es, this message translates to:
  /// **'La cuenta de Google está iniciada, pero no se concedió el acceso a la copia en Drive. Vuelve a intentarlo y acepta el permiso de datos de la app en Drive.'**
  String get googleDrivePermissionMissing;

  /// No description provided for @googleSignInCanceledTitle.
  ///
  /// In es, this message translates to:
  /// **'Google no pudo completar el acceso'**
  String get googleSignInCanceledTitle;

  /// No description provided for @googleSignInCanceledBody.
  ///
  /// In es, this message translates to:
  /// **'Algo salió mal al iniciar sesión con Google. Inténtalo más tarde.'**
  String get googleSignInCanceledBody;

  /// No description provided for @googleSignInNotConfiguredTitle.
  ///
  /// In es, this message translates to:
  /// **'Google no está configurado en esta compilación'**
  String get googleSignInNotConfiguredTitle;

  /// No description provided for @googleSignInNotConfiguredHint.
  ///
  /// In es, this message translates to:
  /// **'En esta versión no está activada la copia de seguridad con Google.'**
  String get googleSignInNotConfiguredHint;

  /// No description provided for @googleSignInNotConfiguredBody.
  ///
  /// In es, this message translates to:
  /// **'A esta compilación le faltan los datos para iniciar sesión con Google y usar Drive. Si compilas Cronicle tú mismo, consulta guide/CRONICLE_GUIDE.md (variables de entorno / Google Cloud).'**
  String get googleSignInNotConfiguredBody;

  /// No description provided for @backupTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad local'**
  String get backupTitle;

  /// No description provided for @backupUpload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get backupUpload;

  /// No description provided for @backupExportButton.
  ///
  /// In es, this message translates to:
  /// **'Guardar copia'**
  String get backupExportButton;

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

  /// No description provided for @backupAnilistMergeFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo sincronizar con Anilist antes; se guardó lo que hay en el dispositivo. {error}'**
  String backupAnilistMergeFailed(Object error);

  /// No description provided for @backupExportReady.
  ///
  /// In es, this message translates to:
  /// **'Copia lista. Usa el menú compartir para guardarla donde quieras.'**
  String get backupExportReady;

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

  /// No description provided for @backupAutoGoogleTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia diaria en Google Drive'**
  String get backupAutoGoogleTitle;

  /// No description provided for @backupAutoGoogleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Como mucho una vez al día con conexión, solo mientras mantengas la sesión de Google en Cuentas.'**
  String get backupAutoGoogleSubtitle;

  /// No description provided for @backupSectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Guarda tu biblioteca y preferencias en un archivo.'**
  String get backupSectionSubtitle;

  /// No description provided for @backupRestoreChooseSourceTitle.
  ///
  /// In es, this message translates to:
  /// **'Origen de la copia'**
  String get backupRestoreChooseSourceTitle;

  /// No description provided for @backupRestoreChooseSourceBody.
  ///
  /// In es, this message translates to:
  /// **'¿Restaurar desde un archivo guardado en el dispositivo o desde Google Drive?'**
  String get backupRestoreChooseSourceBody;

  /// No description provided for @backupRestoreFromFile.
  ///
  /// In es, this message translates to:
  /// **'Archivo…'**
  String get backupRestoreFromFile;

  /// No description provided for @backupRestoreFromDrive.
  ///
  /// In es, this message translates to:
  /// **'Google Drive'**
  String get backupRestoreFromDrive;

  /// No description provided for @backupRestoreConfirmTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get backupRestoreConfirmTitle;

  /// No description provided for @backupRestoreConfirmBody.
  ///
  /// In es, this message translates to:
  /// **'Se combinarán {count} elementos de la biblioteca. Se aplicarán preferencias y cuentas vinculadas si vienen en la copia.'**
  String backupRestoreConfirmBody(Object count);

  /// No description provided for @feedTitle.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get feedTitle;

  /// No description provided for @notificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay notificaciones.'**
  String get notificationsEmpty;

  /// No description provided for @notificationsLoginRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en Anilist en Ajustes para ver notificaciones.'**
  String get notificationsLoginRequired;

  /// No description provided for @notifPermissionTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Activar notificaciones?'**
  String get notifPermissionTitle;

  /// No description provided for @notifPermissionBody.
  ///
  /// In es, this message translates to:
  /// **'Cronicle puede avisarte en el sistema cuando salga un nuevo capítulo de anime o manga que sigues en curso, y opcionalmente reenviar notificaciones de tu bandeja de Anilist. Puedes cambiarlo después en Ajustes.'**
  String get notifPermissionBody;

  /// No description provided for @notifPermissionNotNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora no'**
  String get notifPermissionNotNow;

  /// No description provided for @notifPermissionAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get notifPermissionAllow;

  /// No description provided for @gallerySaveUnavailableWeb.
  ///
  /// In es, this message translates to:
  /// **'Descarga no disponible en web'**
  String get gallerySaveUnavailableWeb;

  /// No description provided for @gallerySaveSuccess.
  ///
  /// In es, this message translates to:
  /// **'Imagen guardada'**
  String get gallerySaveSuccess;

  /// No description provided for @gallerySaveErrorGeneric.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get gallerySaveErrorGeneric;

  /// No description provided for @gallerySavePermissionDenied.
  ///
  /// In es, this message translates to:
  /// **'Sin permiso no se puede guardar en la galería.'**
  String get gallerySavePermissionDenied;

  /// No description provided for @gallerySaveOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get gallerySaveOpenSettings;

  /// No description provided for @settingsNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones en el dispositivo'**
  String get settingsNotificationsTitle;

  /// No description provided for @settingsNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Necesitas cuenta de Anilist. Cada cuánto se comprueba en segundo plano lo decide el sistema.'**
  String get settingsNotificationsSubtitle;

  /// No description provided for @settingsNotificationsUnavailableWeb.
  ///
  /// In es, this message translates to:
  /// **'Las notificaciones del sistema no están disponibles en la versión web.'**
  String get settingsNotificationsUnavailableWeb;

  /// No description provided for @settingsNotifMaster.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones del sistema'**
  String get settingsNotifMaster;

  /// No description provided for @settingsNotifAiring.
  ///
  /// In es, this message translates to:
  /// **'Nuevos capítulos (lista «En curso» y en emisión)'**
  String get settingsNotifAiring;

  /// No description provided for @settingsNotifAnilistInbox.
  ///
  /// In es, this message translates to:
  /// **'Bandeja de Anilist en el dispositivo'**
  String get settingsNotifAnilistInbox;

  /// No description provided for @settingsNotifAnilistSocial.
  ///
  /// In es, this message translates to:
  /// **'Incluir actividad y social (foros, menciones, seguidores…)'**
  String get settingsNotifAnilistSocial;

  /// No description provided for @settingsNotifAnilistSocialDesc.
  ///
  /// In es, this message translates to:
  /// **'Si lo desactivas, en el dispositivo se muestran menos avisos sociales de Anilist.'**
  String get settingsNotifAnilistSocialDesc;

  /// No description provided for @notificationNoLink.
  ///
  /// In es, this message translates to:
  /// **'Abre esta notificación en anilist.co'**
  String get notificationNoLink;

  /// No description provided for @notificationTypeGeneric.
  ///
  /// In es, this message translates to:
  /// **'Notificación'**
  String get notificationTypeGeneric;

  /// No description provided for @notificationTypeAiring.
  ///
  /// In es, this message translates to:
  /// **'Nuevo episodio'**
  String get notificationTypeAiring;

  /// No description provided for @notificationTypeActivityReply.
  ///
  /// In es, this message translates to:
  /// **'Respuesta en actividad'**
  String get notificationTypeActivityReply;

  /// No description provided for @notificationTypeActivityMention.
  ///
  /// In es, this message translates to:
  /// **'Mención en actividad'**
  String get notificationTypeActivityMention;

  /// No description provided for @notificationTypeActivityMessage.
  ///
  /// In es, this message translates to:
  /// **'Mensaje de actividad'**
  String get notificationTypeActivityMessage;

  /// No description provided for @notificationTypeFollowing.
  ///
  /// In es, this message translates to:
  /// **'Nuevo seguidor'**
  String get notificationTypeFollowing;

  /// No description provided for @notificationTypeRelatedMedia.
  ///
  /// In es, this message translates to:
  /// **'Medio relacionado añadido'**
  String get notificationTypeRelatedMedia;

  /// No description provided for @notificationTypeMediaDataChange.
  ///
  /// In es, this message translates to:
  /// **'Medio actualizado'**
  String get notificationTypeMediaDataChange;

  /// No description provided for @notificationTypeMediaMerge.
  ///
  /// In es, this message translates to:
  /// **'Medios fusionados'**
  String get notificationTypeMediaMerge;

  /// No description provided for @notificationTypeMediaDeletion.
  ///
  /// In es, this message translates to:
  /// **'Medio eliminado de Anilist'**
  String get notificationTypeMediaDeletion;

  /// No description provided for @notificationTypeThreadReply.
  ///
  /// In es, this message translates to:
  /// **'Respuesta en foro'**
  String get notificationTypeThreadReply;

  /// No description provided for @notificationTypeThreadMention.
  ///
  /// In es, this message translates to:
  /// **'Mención en foro'**
  String get notificationTypeThreadMention;

  /// No description provided for @notificationTypeThreadSubscribed.
  ///
  /// In es, this message translates to:
  /// **'Hilo del foro'**
  String get notificationTypeThreadSubscribed;

  /// No description provided for @notificationTypeThreadLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta en foro'**
  String get notificationTypeThreadLike;

  /// No description provided for @notificationTypeActivityLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta en actividad'**
  String get notificationTypeActivityLike;

  /// No description provided for @notificationTypeActivityReplyLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta en respuesta'**
  String get notificationTypeActivityReplyLike;

  /// No description provided for @notificationTypeActivityReplySubscribed.
  ///
  /// In es, this message translates to:
  /// **'Respuesta en actividad seguida'**
  String get notificationTypeActivityReplySubscribed;

  /// No description provided for @notificationTypeThreadCommentLike.
  ///
  /// In es, this message translates to:
  /// **'Me gusta en comentario del foro'**
  String get notificationTypeThreadCommentLike;

  /// No description provided for @notificationTypeMediaSubmission.
  ///
  /// In es, this message translates to:
  /// **'Envío de medio (Anilist)'**
  String get notificationTypeMediaSubmission;

  /// No description provided for @notificationTypeStaffSubmission.
  ///
  /// In es, this message translates to:
  /// **'Envío de staff (Anilist)'**
  String get notificationTypeStaffSubmission;

  /// No description provided for @notificationTypeCharacterSubmission.
  ///
  /// In es, this message translates to:
  /// **'Envío de personaje (Anilist)'**
  String get notificationTypeCharacterSubmission;

  /// No description provided for @notificationAiringHeadlineAnime.
  ///
  /// In es, this message translates to:
  /// **'{title} · Episodio {episode}'**
  String notificationAiringHeadlineAnime(Object title, int episode);

  /// No description provided for @notificationAiringHeadlineManga.
  ///
  /// In es, this message translates to:
  /// **'{title} · Capítulo {episode}'**
  String notificationAiringHeadlineManga(Object title, int episode);

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

  /// No description provided for @feedBrowseActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get feedBrowseActivity;

  /// No description provided for @feedBrowseSeasonal.
  ///
  /// In es, this message translates to:
  /// **'De temporada'**
  String get feedBrowseSeasonal;

  /// No description provided for @feedBrowseTopRated.
  ///
  /// In es, this message translates to:
  /// **'Mejor valorados'**
  String get feedBrowseTopRated;

  /// No description provided for @feedBrowseUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próximos'**
  String get feedBrowseUpcoming;

  /// No description provided for @feedBrowseRecentlyReleased.
  ///
  /// In es, this message translates to:
  /// **'Recién estrenados'**
  String get feedBrowseRecentlyReleased;

  /// No description provided for @feedBrowseEmpty.
  ///
  /// In es, this message translates to:
  /// **'No hay títulos en esta lista.'**
  String get feedBrowseEmpty;

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

  /// No description provided for @filterFeed.
  ///
  /// In es, this message translates to:
  /// **'Feed'**
  String get filterFeed;

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

  /// No description provided for @loginRequiredFavorite.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en Anilist en Ajustes para usar favoritos'**
  String get loginRequiredFavorite;

  /// No description provided for @sectionFavGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos favoritos'**
  String get sectionFavGames;

  /// No description provided for @tooltipAddFavorite.
  ///
  /// In es, this message translates to:
  /// **'Añadir a favoritos'**
  String get tooltipAddFavorite;

  /// No description provided for @tooltipRemoveFavorite.
  ///
  /// In es, this message translates to:
  /// **'Quitar de favoritos'**
  String get tooltipRemoveFavorite;

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

  /// No description provided for @librarySearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Buscar en biblioteca'**
  String get librarySearchTitle;

  /// No description provided for @librarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar en biblioteca...'**
  String get librarySearchHint;

  /// No description provided for @librarySearchPrompt.
  ///
  /// In es, this message translates to:
  /// **'Escribe un título para buscar'**
  String get librarySearchPrompt;

  /// No description provided for @librarySearchGlobalResults.
  ///
  /// In es, this message translates to:
  /// **'Resultados globales'**
  String get librarySearchGlobalResults;

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

  /// No description provided for @editLibraryEntry.
  ///
  /// In es, this message translates to:
  /// **'Editar entrada'**
  String get editLibraryEntry;

  /// No description provided for @addedToLibrary.
  ///
  /// In es, this message translates to:
  /// **'Añadido a la biblioteca'**
  String get addedToLibrary;

  /// No description provided for @entryUpdated.
  ///
  /// In es, this message translates to:
  /// **'Entrada actualizada'**
  String get entryUpdated;

  /// No description provided for @removeFromLibrary.
  ///
  /// In es, this message translates to:
  /// **'Eliminar de mi biblioteca'**
  String get removeFromLibrary;

  /// No description provided for @removedFromLibrary.
  ///
  /// In es, this message translates to:
  /// **'Eliminado de la biblioteca'**
  String get removedFromLibrary;

  /// No description provided for @profileTitle.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profileTitle;

  /// No description provided for @profilePersonalStatsTitle.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas personales'**
  String get profilePersonalStatsTitle;

  /// No description provided for @profilePersonalStatsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Anime, manga, cine, series y juegos en el dispositivo'**
  String get profilePersonalStatsSubtitle;

  /// No description provided for @sectionProfileLocalGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos (en el dispositivo)'**
  String get sectionProfileLocalGames;

  /// No description provided for @profileLocalGamesHoursTotal.
  ///
  /// In es, this message translates to:
  /// **'Horas registradas'**
  String get profileLocalGamesHoursTotal;

  /// No description provided for @profileLocalGamesEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay juegos en tu biblioteca local.'**
  String get profileLocalGamesEmpty;

  /// No description provided for @profileLocalUser.
  ///
  /// In es, this message translates to:
  /// **'Usuario local'**
  String get profileLocalUser;

  /// No description provided for @profileFavoritesSectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get profileFavoritesSectionTitle;

  /// No description provided for @profileConnectHint.
  ///
  /// In es, this message translates to:
  /// **'Conecta AniList y Trakt en Ajustes para ver tus estadísticas completas'**
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

  /// No description provided for @profileSectionTrakt.
  ///
  /// In es, this message translates to:
  /// **'Cine y series (Trakt)'**
  String get profileSectionTrakt;

  /// No description provided for @profileTraktMoviesWatched.
  ///
  /// In es, this message translates to:
  /// **'Películas vistas'**
  String get profileTraktMoviesWatched;

  /// No description provided for @profileTraktShowsWatched.
  ///
  /// In es, this message translates to:
  /// **'Series vistas'**
  String get profileTraktShowsWatched;

  /// No description provided for @profileTraktEpisodesWatched.
  ///
  /// In es, this message translates to:
  /// **'Episodios vistos'**
  String get profileTraktEpisodesWatched;

  /// No description provided for @profileTraktHoursApprox.
  ///
  /// In es, this message translates to:
  /// **'Horas vistas (aprox.)'**
  String get profileTraktHoursApprox;

  /// No description provided for @sectionFavTraktMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas favoritas'**
  String get sectionFavTraktMovies;

  /// No description provided for @sectionFavTraktShows.
  ///
  /// In es, this message translates to:
  /// **'Series favoritas'**
  String get sectionFavTraktShows;

  /// No description provided for @profileTraktNotConnected.
  ///
  /// In es, this message translates to:
  /// **'Sin conectar'**
  String get profileTraktNotConnected;

  /// No description provided for @profileTraktSubMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get profileTraktSubMovies;

  /// No description provided for @profileTraktSubShows.
  ///
  /// In es, this message translates to:
  /// **'Series'**
  String get profileTraktSubShows;

  /// No description provided for @profileTraktSubEpisodes.
  ///
  /// In es, this message translates to:
  /// **'Episodios'**
  String get profileTraktSubEpisodes;

  /// No description provided for @profileTraktSubSeasons.
  ///
  /// In es, this message translates to:
  /// **'Temporadas'**
  String get profileTraktSubSeasons;

  /// No description provided for @profileTraktSubNetwork.
  ///
  /// In es, this message translates to:
  /// **'Red'**
  String get profileTraktSubNetwork;

  /// No description provided for @statTraktPlays.
  ///
  /// In es, this message translates to:
  /// **'Reproducciones'**
  String get statTraktPlays;

  /// No description provided for @statTraktWatched.
  ///
  /// In es, this message translates to:
  /// **'Vistos'**
  String get statTraktWatched;

  /// No description provided for @statTraktCollected.
  ///
  /// In es, this message translates to:
  /// **'En colección'**
  String get statTraktCollected;

  /// No description provided for @statTraktRatings.
  ///
  /// In es, this message translates to:
  /// **'Valoraciones'**
  String get statTraktRatings;

  /// No description provided for @statTraktComments.
  ///
  /// In es, this message translates to:
  /// **'Comentarios'**
  String get statTraktComments;

  /// No description provided for @statTraktWatchTimeHrs.
  ///
  /// In es, this message translates to:
  /// **'Tiempo visionado (h)'**
  String get statTraktWatchTimeHrs;

  /// No description provided for @statTraktFriends.
  ///
  /// In es, this message translates to:
  /// **'Amigos'**
  String get statTraktFriends;

  /// No description provided for @statTraktFollowers.
  ///
  /// In es, this message translates to:
  /// **'Seguidores'**
  String get statTraktFollowers;

  /// No description provided for @statTraktFollowing.
  ///
  /// In es, this message translates to:
  /// **'Siguiendo'**
  String get statTraktFollowing;

  /// No description provided for @profileTraktRatingsTotal.
  ///
  /// In es, this message translates to:
  /// **'Valoraciones (totales)'**
  String get profileTraktRatingsTotal;

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

  /// No description provided for @mediaGenresSection.
  ///
  /// In es, this message translates to:
  /// **'Géneros'**
  String get mediaGenresSection;

  /// No description provided for @mediaTagsSection.
  ///
  /// In es, this message translates to:
  /// **'Etiquetas'**
  String get mediaTagsSection;

  /// No description provided for @mediaBrowseSortScore.
  ///
  /// In es, this message translates to:
  /// **'Nota'**
  String get mediaBrowseSortScore;

  /// No description provided for @mediaBrowseSortPopularity.
  ///
  /// In es, this message translates to:
  /// **'Popularidad'**
  String get mediaBrowseSortPopularity;

  /// No description provided for @mediaBrowseSortName.
  ///
  /// In es, this message translates to:
  /// **'Nombre'**
  String get mediaBrowseSortName;

  /// No description provided for @mediaBrowseInvalidParams.
  ///
  /// In es, this message translates to:
  /// **'Falta género o etiqueta en el enlace.'**
  String get mediaBrowseInvalidParams;

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

  /// No description provided for @addToListMovieProgress.
  ///
  /// In es, this message translates to:
  /// **'Vista (0–1)'**
  String get addToListMovieProgress;

  /// No description provided for @traktNotConfiguredHint.
  ///
  /// In es, this message translates to:
  /// **'Añade TRAKT_CLIENT_ID a los dart-define para ver películas y series desde Trakt (sin género anime, para no duplicar AniList).'**
  String get traktNotConfiguredHint;

  /// No description provided for @traktSectionTrending.
  ///
  /// In es, this message translates to:
  /// **'Tendencias'**
  String get traktSectionTrending;

  /// No description provided for @traktSectionWatchingNow.
  ///
  /// In es, this message translates to:
  /// **'Viendo ahora'**
  String get traktSectionWatchingNow;

  /// No description provided for @traktSectionAnticipatedMovies.
  ///
  /// In es, this message translates to:
  /// **'Más esperadas'**
  String get traktSectionAnticipatedMovies;

  /// No description provided for @traktSectionPopular.
  ///
  /// In es, this message translates to:
  /// **'Popular'**
  String get traktSectionPopular;

  /// No description provided for @traktSectionMostPlayed.
  ///
  /// In es, this message translates to:
  /// **'Más reproducidas'**
  String get traktSectionMostPlayed;

  /// No description provided for @traktSectionMostWatched.
  ///
  /// In es, this message translates to:
  /// **'Más vistas'**
  String get traktSectionMostWatched;

  /// No description provided for @traktSectionMostCollected.
  ///
  /// In es, this message translates to:
  /// **'Más coleccionadas'**
  String get traktSectionMostCollected;

  /// No description provided for @traktSectionAnticipatedShows.
  ///
  /// In es, this message translates to:
  /// **'Series más esperadas'**
  String get traktSectionAnticipatedShows;

  /// No description provided for @traktTitle.
  ///
  /// In es, this message translates to:
  /// **'Trakt.tv'**
  String get traktTitle;

  /// No description provided for @traktSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Películas y series (sin anime). Conecta tu cuenta para importar tu historial visto a la biblioteca local.'**
  String get traktSubtitle;

  /// No description provided for @traktConnectedAs.
  ///
  /// In es, this message translates to:
  /// **'Conectado como {slug}'**
  String traktConnectedAs(Object slug);

  /// No description provided for @traktConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar Trakt'**
  String get traktConnect;

  /// No description provided for @traktDisconnect.
  ///
  /// In es, this message translates to:
  /// **'Desconectar Trakt'**
  String get traktDisconnect;

  /// No description provided for @traktConnectSuccess.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Trakt vinculada.'**
  String get traktConnectSuccess;

  /// No description provided for @traktDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Cuenta Trakt desvinculada.'**
  String get traktDisconnected;

  /// No description provided for @traktOAuthMissingCredentials.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión con Trakt no disponible en esta versión.'**
  String get traktOAuthMissingCredentials;

  /// No description provided for @traktOAuthWebUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Inicio de sesión Trakt no disponible en web desde esta app; usa Android, iOS o escritorio.'**
  String get traktOAuthWebUnavailable;

  /// No description provided for @traktImportTitle.
  ///
  /// In es, this message translates to:
  /// **'Importar desde Trakt'**
  String get traktImportTitle;

  /// No description provided for @traktImportConfirm.
  ///
  /// In es, this message translates to:
  /// **'Importar'**
  String get traktImportConfirm;

  /// No description provided for @traktImportDesc.
  ///
  /// In es, this message translates to:
  /// **'Trae películas y series vistas (sin anime) a la biblioteca de este dispositivo.'**
  String get traktImportDesc;

  /// No description provided for @traktImportedCount.
  ///
  /// In es, this message translates to:
  /// **'Importados {count} títulos desde Trakt.'**
  String traktImportedCount(Object count);

  /// No description provided for @traktDetailLinks.
  ///
  /// In es, this message translates to:
  /// **'Enlaces'**
  String get traktDetailLinks;

  /// No description provided for @traktLinkTrailer.
  ///
  /// In es, this message translates to:
  /// **'Tráiler'**
  String get traktLinkTrailer;

  /// No description provided for @traktLinkHomepage.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get traktLinkHomepage;

  /// No description provided for @traktDetailOnTrakt.
  ///
  /// In es, this message translates to:
  /// **'Abrir en Trakt'**
  String get traktDetailOnTrakt;

  /// No description provided for @traktEpisodeProgressTitle.
  ///
  /// In es, this message translates to:
  /// **'Progreso de episodios'**
  String get traktEpisodeProgressTitle;

  /// No description provided for @traktEpisodeProgressHint.
  ///
  /// In es, this message translates to:
  /// **'Añade esta serie a tu biblioteca para llevar la cuenta de episodios vistos.'**
  String get traktEpisodeProgressHint;

  /// No description provided for @traktEpisodeProgressMarkComplete.
  ///
  /// In es, this message translates to:
  /// **'Marcar serie como completada'**
  String get traktEpisodeProgressMarkComplete;

  /// No description provided for @traktEpisodeMinusOne.
  ///
  /// In es, this message translates to:
  /// **'Un episodio menos'**
  String get traktEpisodeMinusOne;

  /// No description provided for @traktEpisodePlusOne.
  ///
  /// In es, this message translates to:
  /// **'Un episodio más'**
  String get traktEpisodePlusOne;

  /// No description provided for @traktDetailVotes.
  ///
  /// In es, this message translates to:
  /// **'Votos'**
  String get traktDetailVotes;

  /// No description provided for @traktDetailLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get traktDetailLanguage;

  /// No description provided for @traktDetailOriginalTitle.
  ///
  /// In es, this message translates to:
  /// **'Título original'**
  String get traktDetailOriginalTitle;

  /// No description provided for @traktDetailSubgenres.
  ///
  /// In es, this message translates to:
  /// **'Subgéneros'**
  String get traktDetailSubgenres;

  /// No description provided for @traktDetailCountry.
  ///
  /// In es, this message translates to:
  /// **'País'**
  String get traktDetailCountry;

  /// No description provided for @traktDetailYear.
  ///
  /// In es, this message translates to:
  /// **'Año'**
  String get traktDetailYear;

  /// No description provided for @traktDetailNetwork.
  ///
  /// In es, this message translates to:
  /// **'Cadena'**
  String get traktDetailNetwork;

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

  /// No description provided for @settingsAccountsTitle.
  ///
  /// In es, this message translates to:
  /// **'Cuentas'**
  String get settingsAccountsTitle;

  /// No description provided for @settingsAccountsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Anilist para anime y manga, Trakt para cine y series, Google opcional para copia en la nube. Los juegos quedan en el dispositivo.'**
  String get settingsAccountsSubtitle;

  /// No description provided for @twitchIgdbTitle.
  ///
  /// In es, this message translates to:
  /// **'Twitch (IGDB)'**
  String get twitchIgdbTitle;

  /// No description provided for @twitchIgdbSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión para que búsquedas y fichas usen tu token con IGDB. Eso no sube tus juegos a igdb.com ni importa tu lista «Jugado» del sitio: esa colección no está en la API pública.'**
  String get twitchIgdbSubtitle;

  /// No description provided for @twitchConnectedAs.
  ///
  /// In es, this message translates to:
  /// **'Conectado como @{login}'**
  String twitchConnectedAs(Object login);

  /// No description provided for @twitchDisconnectAccount.
  ///
  /// In es, this message translates to:
  /// **'Desvincular Twitch'**
  String get twitchDisconnectAccount;

  /// No description provided for @twitchConnectOAuth.
  ///
  /// In es, this message translates to:
  /// **'Conectar con Twitch'**
  String get twitchConnectOAuth;

  /// No description provided for @twitchConnectSuccess.
  ///
  /// In es, this message translates to:
  /// **'Twitch conectado. Las peticiones a IGDB usarán tu sesión.'**
  String get twitchConnectSuccess;

  /// No description provided for @twitchDisconnected.
  ///
  /// In es, this message translates to:
  /// **'Cuenta de Twitch desvinculada.'**
  String get twitchDisconnected;

  /// No description provided for @twitchOAuthWebUnavailable.
  ///
  /// In es, this message translates to:
  /// **'El inicio de sesión con Twitch en el navegador no está configurado. Usa la app en Android, iOS o escritorio.'**
  String get twitchOAuthWebUnavailable;

  /// No description provided for @twitchOAuthMissingSecrets.
  ///
  /// In es, this message translates to:
  /// **'Añade TWITCH_CLIENT_ID y TWITCH_CLIENT_SECRET a los flags de compilación (ver README).'**
  String get twitchOAuthMissingSecrets;

  /// No description provided for @twitchRedirectNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'(sin TWITCH_REDIRECT_URI: usa --dart-define con una URL https)'**
  String get twitchRedirectNotConfigured;

  /// No description provided for @twitchRedirectMustBeHttps.
  ///
  /// In es, this message translates to:
  /// **'TWITCH_REDIRECT_URI debe ser https://… La consola de Twitch no acepta cronicle://; despliega web/twitch_oauth_bridge.html y registra esa URL exacta.'**
  String get twitchRedirectMustBeHttps;

  /// No description provided for @twitchSyncTitle.
  ///
  /// In es, this message translates to:
  /// **'Sincronizar juegos con Twitch'**
  String get twitchSyncTitle;

  /// No description provided for @twitchSyncWelcome.
  ///
  /// In es, this message translates to:
  /// **'Hola, {name}. ¿Cómo quieres alinear tu biblioteca de juegos?'**
  String twitchSyncWelcome(Object name);

  /// No description provided for @twitchGameSyncMerge.
  ///
  /// In es, this message translates to:
  /// **'Combinar'**
  String get twitchGameSyncMerge;

  /// No description provided for @twitchGameSyncMergeDesc.
  ///
  /// In es, this message translates to:
  /// **'Mantiene los juegos guardados en este dispositivo y evita duplicados cuando exista una fuente remota conectada.'**
  String get twitchGameSyncMergeDesc;

  /// No description provided for @twitchGameSyncOverwrite.
  ///
  /// In es, this message translates to:
  /// **'Sobreescribir con la nube'**
  String get twitchGameSyncOverwrite;

  /// No description provided for @twitchGameSyncOverwriteDesc.
  ///
  /// In es, this message translates to:
  /// **'Borra los juegos guardados solo en este dispositivo y luego importa desde la fuente remota (cuando esté disponible).'**
  String get twitchGameSyncOverwriteDesc;

  /// No description provided for @twitchSyncIgdbApiFootnote.
  ///
  /// In es, this message translates to:
  /// **'La API pública de IGDB no permite leer ni escribir tu colección personal de igdb.com (p. ej. «Jugado»). Lo que añades en Biblioteca vive solo aquí hasta que integremos otra fuente (p. ej. Steam).'**
  String get twitchSyncIgdbApiFootnote;

  /// No description provided for @twitchSyncImportedCount.
  ///
  /// In es, this message translates to:
  /// **'Sincronizados {count} juegos desde Twitch.'**
  String twitchSyncImportedCount(Object count);

  /// No description provided for @twitchSyncImportedZeroWarning.
  ///
  /// In es, this message translates to:
  /// **'Se borraron los juegos en este dispositivo. Aún no hay importación remota (la API de IGDB no expone tu lista de igdb.com). Puedes volver a añadir juegos a mano.'**
  String get twitchSyncImportedZeroWarning;

  /// No description provided for @googleAccountTitle.
  ///
  /// In es, this message translates to:
  /// **'Google'**
  String get googleAccountTitle;

  /// No description provided for @googleAccountSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Opcional: guarda la misma copia en Google Drive (subida manual o copia diaria automática).'**
  String get googleAccountSubtitle;

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

  /// No description provided for @anilistStep2Bridge.
  ///
  /// In es, this message translates to:
  /// **'Tras aceptar, copia el token largo de la página de Cronicle que se abre en el navegador.'**
  String get anilistStep2Bridge;

  /// No description provided for @anilistStep3Bridge.
  ///
  /// In es, this message translates to:
  /// **'Pégalo abajo y pulsa Conectar.'**
  String get anilistStep3Bridge;

  /// No description provided for @anilistOAuthWebUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Iniciar sesión en Anilist no está disponible en la versión web. Usa la app en móvil u ordenador.'**
  String get anilistOAuthWebUnavailable;

  /// No description provided for @anilistOAuthTimeout.
  ///
  /// In es, this message translates to:
  /// **'La autorización de Anilist tardó demasiado. Inténtalo de nuevo.'**
  String get anilistOAuthTimeout;

  /// No description provided for @anilistOAuthLaunchFailed.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el navegador.'**
  String get anilistOAuthLaunchFailed;

  /// No description provided for @anilistBridgeNotConfigured.
  ///
  /// In es, this message translates to:
  /// **'Define ANILIST_REDIRECT_URI con tu URL HTTPS (anilist_oauth_bridge.html) y regístrala igual en Anilist → Developer para entrar sin pegar token en el móvil.'**
  String get anilistBridgeNotConfigured;

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
  /// **'La biblioteca se abre con este filtro seleccionado.'**
  String get settingsDefaultFilterDesc;

  /// No description provided for @settingsDefaultsTitle.
  ///
  /// In es, this message translates to:
  /// **'Pantalla y pestaña por defecto'**
  String get settingsDefaultsTitle;

  /// No description provided for @settingsDefaultsDesc.
  ///
  /// In es, this message translates to:
  /// **'Elige la primera pantalla y pestaña al abrir la app.'**
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

  /// No description provided for @settingsFeedActivityScope.
  ///
  /// In es, this message translates to:
  /// **'Vista por defecto del feed'**
  String get settingsFeedActivityScope;

  /// No description provided for @settingsAppearanceTitle.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsAppearanceTitle;

  /// No description provided for @settingsAppearanceSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Tema, idioma y las barras de pestañas en Inicio y Biblioteca.'**
  String get settingsAppearanceSubtitle;

  /// No description provided for @settingsLayoutCustomizationTitle.
  ///
  /// In es, this message translates to:
  /// **'Barras de inicio y biblioteca'**
  String get settingsLayoutCustomizationTitle;

  /// No description provided for @settingsLayoutCustomizationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige qué pestañas se muestran y en qué orden.'**
  String get settingsLayoutCustomizationSubtitle;

  /// No description provided for @settingsCustomizeFeedFilters.
  ///
  /// In es, this message translates to:
  /// **'Barra de filtros del feed'**
  String get settingsCustomizeFeedFilters;

  /// No description provided for @settingsCustomizeFeedFiltersDesc.
  ///
  /// In es, this message translates to:
  /// **'Muestra, oculta o reordena las pestañas del feed. Al menos una debe quedar visible.'**
  String get settingsCustomizeFeedFiltersDesc;

  /// No description provided for @settingsCustomizeLibraryKinds.
  ///
  /// In es, this message translates to:
  /// **'Barra de tipos en Biblioteca'**
  String get settingsCustomizeLibraryKinds;

  /// No description provided for @settingsCustomizeLibraryKindsDesc.
  ///
  /// In es, this message translates to:
  /// **'Muestra, oculta o reordena los tipos de biblioteca. Al menos uno debe quedar visible.'**
  String get settingsCustomizeLibraryKindsDesc;

  /// No description provided for @settingsLayoutDragHint.
  ///
  /// In es, this message translates to:
  /// **'Mantén pulsada la barra de arrastre y arrastra para cambiar el orden.'**
  String get settingsLayoutDragHint;

  /// No description provided for @settingsLayoutReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get settingsLayoutReset;

  /// No description provided for @settingsLayoutResetDone.
  ///
  /// In es, this message translates to:
  /// **'Orden por defecto restaurado.'**
  String get settingsLayoutResetDone;

  /// No description provided for @settingsLayoutShowInFeed.
  ///
  /// In es, this message translates to:
  /// **'Mostrar en el feed'**
  String get settingsLayoutShowInFeed;

  /// No description provided for @settingsLayoutShowInLibrary.
  ///
  /// In es, this message translates to:
  /// **'Mostrar en biblioteca'**
  String get settingsLayoutShowInLibrary;

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

  /// No description provided for @activityOriginalPost.
  ///
  /// In es, this message translates to:
  /// **'Publicación original'**
  String get activityOriginalPost;

  /// No description provided for @activityRepliesHeading.
  ///
  /// In es, this message translates to:
  /// **'Respuestas'**
  String get activityRepliesHeading;

  /// No description provided for @activityThreadLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el hilo'**
  String get activityThreadLoadError;

  /// No description provided for @activityMessageActivity.
  ///
  /// In es, this message translates to:
  /// **'Mensaje privado'**
  String get activityMessageActivity;

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

  /// No description provided for @reviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Reseña'**
  String get reviewTitle;

  /// No description provided for @reviewByUser.
  ///
  /// In es, this message translates to:
  /// **'Por {name}'**
  String reviewByUser(Object name);

  /// No description provided for @reviewHelpful.
  ///
  /// In es, this message translates to:
  /// **'¿Útil?'**
  String get reviewHelpful;

  /// No description provided for @reviewUpVote.
  ///
  /// In es, this message translates to:
  /// **'Sí'**
  String get reviewUpVote;

  /// No description provided for @reviewDownVote.
  ///
  /// In es, this message translates to:
  /// **'No'**
  String get reviewDownVote;

  /// No description provided for @reviewLoginRequired.
  ///
  /// In es, this message translates to:
  /// **'Inicia sesión en Anilist para votar'**
  String get reviewLoginRequired;

  /// No description provided for @reviewUsersFoundHelpful.
  ///
  /// In es, this message translates to:
  /// **'{count} de {total} encontraron útil esta reseña'**
  String reviewUsersFoundHelpful(Object count, Object total);

  /// No description provided for @readMore.
  ///
  /// In es, this message translates to:
  /// **'Leer más'**
  String get readMore;

  /// No description provided for @writeReplyHint.
  ///
  /// In es, this message translates to:
  /// **'Escribe un comentario...'**
  String get writeReplyHint;

  /// No description provided for @composeActivityHint.
  ///
  /// In es, this message translates to:
  /// **'¿Qué estás pensando?'**
  String get composeActivityHint;

  /// No description provided for @composeMarkdownTip.
  ///
  /// In es, this message translates to:
  /// **'Soporta markdown e imágenes'**
  String get composeMarkdownTip;

  /// No description provided for @cancelButton.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelButton;

  /// No description provided for @postButton.
  ///
  /// In es, this message translates to:
  /// **'Publicar'**
  String get postButton;

  /// No description provided for @activityPosted.
  ///
  /// In es, this message translates to:
  /// **'Publicado correctamente'**
  String get activityPosted;

  /// No description provided for @settingsHideTextActivities.
  ///
  /// In es, this message translates to:
  /// **'Ocultar actividades de texto'**
  String get settingsHideTextActivities;

  /// No description provided for @settingsHideTextActivitiesDesc.
  ///
  /// In es, this message translates to:
  /// **'No mostrar publicaciones de texto en el feed'**
  String get settingsHideTextActivitiesDesc;

  /// No description provided for @statusCurrentGame.
  ///
  /// In es, this message translates to:
  /// **'Jugando'**
  String get statusCurrentGame;

  /// No description provided for @statusReplayingGame.
  ///
  /// In es, this message translates to:
  /// **'Rejugando'**
  String get statusReplayingGame;

  /// No description provided for @searchTrendingGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos en tendencia'**
  String get searchTrendingGames;

  /// No description provided for @igdbWebNotSupported.
  ///
  /// In es, this message translates to:
  /// **'IGDB no puede llamar a la API desde el navegador (sin CORS). Usa Android o escritorio, o ejecuta node scripts/dev_api_proxy.mjs y define DEV_API_PROXY en tus dart-defines (ver dart_defines.example.json).'**
  String get igdbWebNotSupported;

  /// No description provided for @twitchSyncPromptTitle.
  ///
  /// In es, this message translates to:
  /// **'Conecta con Twitch'**
  String get twitchSyncPromptTitle;

  /// No description provided for @twitchSyncPromptBody.
  ///
  /// In es, this message translates to:
  /// **'Conecta tu cuenta de Twitch para sincronizar tus juegos en el futuro.\n\nTambién puedes hacerlo más tarde desde Ajustes.'**
  String get twitchSyncPromptBody;

  /// No description provided for @twitchSyncPromptNoThanks.
  ///
  /// In es, this message translates to:
  /// **'No, gracias'**
  String get twitchSyncPromptNoThanks;

  /// No description provided for @twitchConnect.
  ///
  /// In es, this message translates to:
  /// **'Conectar Twitch'**
  String get twitchConnect;

  /// No description provided for @gameDetailPlatforms.
  ///
  /// In es, this message translates to:
  /// **'Plataformas'**
  String get gameDetailPlatforms;

  /// No description provided for @gameDetailGenres.
  ///
  /// In es, this message translates to:
  /// **'Géneros'**
  String get gameDetailGenres;

  /// No description provided for @gameDetailSynopsis.
  ///
  /// In es, this message translates to:
  /// **'Sinopsis'**
  String get gameDetailSynopsis;

  /// No description provided for @gameDetailStoryline.
  ///
  /// In es, this message translates to:
  /// **'Historia'**
  String get gameDetailStoryline;

  /// No description provided for @gameDetailModes.
  ///
  /// In es, this message translates to:
  /// **'Modos de juego'**
  String get gameDetailModes;

  /// No description provided for @gameDetailThemes.
  ///
  /// In es, this message translates to:
  /// **'Temas'**
  String get gameDetailThemes;

  /// No description provided for @gameDetailDeveloper.
  ///
  /// In es, this message translates to:
  /// **'Desarrollador'**
  String get gameDetailDeveloper;

  /// No description provided for @gameDetailPublisher.
  ///
  /// In es, this message translates to:
  /// **'Distribuidor'**
  String get gameDetailPublisher;

  /// No description provided for @gameDetailReleaseDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de lanzamiento'**
  String get gameDetailReleaseDate;

  /// No description provided for @gameDetailRating.
  ///
  /// In es, this message translates to:
  /// **'Puntuación'**
  String get gameDetailRating;

  /// No description provided for @gameDetailStatUserScore.
  ///
  /// In es, this message translates to:
  /// **'Usuarios'**
  String get gameDetailStatUserScore;

  /// No description provided for @gameDetailStatCriticScore.
  ///
  /// In es, this message translates to:
  /// **'Críticos (IGDB)'**
  String get gameDetailStatCriticScore;

  /// No description provided for @gameDetailStatRatingsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} valoraciones'**
  String gameDetailStatRatingsCount(Object count);

  /// No description provided for @gameDetailStatCriticReviewsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} reseñas'**
  String gameDetailStatCriticReviewsCount(Object count);

  /// No description provided for @gameDetailSimilarGames.
  ///
  /// In es, this message translates to:
  /// **'Juegos similares'**
  String get gameDetailSimilarGames;

  /// No description provided for @gameDetailNoData.
  ///
  /// In es, this message translates to:
  /// **'No se encontraron datos del juego'**
  String get gameDetailNoData;

  /// No description provided for @gameDetailCompanies.
  ///
  /// In es, this message translates to:
  /// **'Empresas'**
  String get gameDetailCompanies;

  /// No description provided for @addToListHoursPlayed.
  ///
  /// In es, this message translates to:
  /// **'Horas jugadas'**
  String get addToListHoursPlayed;

  /// No description provided for @gameDetailLinksSection.
  ///
  /// In es, this message translates to:
  /// **'Enlaces'**
  String get gameDetailLinksSection;

  /// No description provided for @gameDetailLinksShowMore.
  ///
  /// In es, this message translates to:
  /// **'Mostrar {remaining} más'**
  String gameDetailLinksShowMore(Object remaining);

  /// No description provided for @gameDetailLinksShowLess.
  ///
  /// In es, this message translates to:
  /// **'Mostrar menos'**
  String get gameDetailLinksShowLess;

  /// No description provided for @gameDetailLinkOfficialSite.
  ///
  /// In es, this message translates to:
  /// **'Sitio web'**
  String get gameDetailLinkOfficialSite;

  /// No description provided for @gameDetailLinkKindPlayStation.
  ///
  /// In es, this message translates to:
  /// **'PlayStation'**
  String get gameDetailLinkKindPlayStation;

  /// No description provided for @gameDetailLinkKindNintendo.
  ///
  /// In es, this message translates to:
  /// **'Nintendo'**
  String get gameDetailLinkKindNintendo;

  /// No description provided for @gameDetailLinkKindApple.
  ///
  /// In es, this message translates to:
  /// **'App Store'**
  String get gameDetailLinkKindApple;

  /// No description provided for @gameDetailLinkKindGooglePlay.
  ///
  /// In es, this message translates to:
  /// **'Google Play'**
  String get gameDetailLinkKindGooglePlay;

  /// No description provided for @gameDetailLinkKindAmazon.
  ///
  /// In es, this message translates to:
  /// **'Amazon'**
  String get gameDetailLinkKindAmazon;

  /// No description provided for @gameDetailLinkKindOculus.
  ///
  /// In es, this message translates to:
  /// **'Meta / Oculus'**
  String get gameDetailLinkKindOculus;

  /// No description provided for @gameDetailLinkKindGameJolt.
  ///
  /// In es, this message translates to:
  /// **'Game Jolt'**
  String get gameDetailLinkKindGameJolt;

  /// No description provided for @gameDetailLinkKindHumble.
  ///
  /// In es, this message translates to:
  /// **'Humble'**
  String get gameDetailLinkKindHumble;

  /// No description provided for @gameDetailLinkKindUbisoft.
  ///
  /// In es, this message translates to:
  /// **'Ubisoft'**
  String get gameDetailLinkKindUbisoft;

  /// No description provided for @gameDetailLinkKindEa.
  ///
  /// In es, this message translates to:
  /// **'EA'**
  String get gameDetailLinkKindEa;

  /// No description provided for @gameDetailLinkKindRockstar.
  ///
  /// In es, this message translates to:
  /// **'Rockstar'**
  String get gameDetailLinkKindRockstar;

  /// No description provided for @gameDetailLinkKindBattlenet.
  ///
  /// In es, this message translates to:
  /// **'Battle.net'**
  String get gameDetailLinkKindBattlenet;

  /// No description provided for @gameDetailLinkKindTiktok.
  ///
  /// In es, this message translates to:
  /// **'TikTok'**
  String get gameDetailLinkKindTiktok;

  /// No description provided for @gameDetailLinkKindBluesky.
  ///
  /// In es, this message translates to:
  /// **'Bluesky'**
  String get gameDetailLinkKindBluesky;

  /// No description provided for @gamesHomePopularNow.
  ///
  /// In es, this message translates to:
  /// **'Popular ahora'**
  String get gamesHomePopularNow;

  /// No description provided for @gamesHomeMostAnticipated.
  ///
  /// In es, this message translates to:
  /// **'Más esperados'**
  String get gamesHomeMostAnticipated;

  /// No description provided for @gamesHomeRecentReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas recientes'**
  String get gamesHomeRecentReviews;

  /// No description provided for @gamesHomeCriticsReviews.
  ///
  /// In es, this message translates to:
  /// **'Reseñas de críticos'**
  String get gamesHomeCriticsReviews;

  /// No description provided for @gamesHomeRecentlyReleased.
  ///
  /// In es, this message translates to:
  /// **'Recién salidos'**
  String get gamesHomeRecentlyReleased;

  /// No description provided for @gamesHomeComingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get gamesHomeComingSoon;

  /// No description provided for @gamesHomeBestRated.
  ///
  /// In es, this message translates to:
  /// **'Mejor valorados'**
  String get gamesHomeBestRated;

  /// No description provided for @gamesHomeIndiePicks.
  ///
  /// In es, this message translates to:
  /// **'Indie destacados'**
  String get gamesHomeIndiePicks;

  /// No description provided for @gamesHomeHorrorPicks.
  ///
  /// In es, this message translates to:
  /// **'Terror'**
  String get gamesHomeHorrorPicks;

  /// No description provided for @gamesHomeMultiplayer.
  ///
  /// In es, this message translates to:
  /// **'Multijugador'**
  String get gamesHomeMultiplayer;

  /// No description provided for @gamesHomeRpgSpotlight.
  ///
  /// In es, this message translates to:
  /// **'RPG destacados'**
  String get gamesHomeRpgSpotlight;

  /// No description provided for @gamesHomeSportsSpotlight.
  ///
  /// In es, this message translates to:
  /// **'Deportes'**
  String get gamesHomeSportsSpotlight;

  /// No description provided for @gamesHomeSectionExpand.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get gamesHomeSectionExpand;

  /// No description provided for @gamesHomeSectionCollapse.
  ///
  /// In es, this message translates to:
  /// **'Ver menos'**
  String get gamesHomeSectionCollapse;

  /// No description provided for @gamesHomeNoItems.
  ///
  /// In es, this message translates to:
  /// **'Sin contenido'**
  String get gamesHomeNoItems;

  /// No description provided for @gamesHomeOpenGame.
  ///
  /// In es, this message translates to:
  /// **'Ver juego'**
  String get gamesHomeOpenGame;

  /// No description provided for @igdbReviewNotFound.
  ///
  /// In es, this message translates to:
  /// **'No se encontró la reseña.'**
  String get igdbReviewNotFound;

  /// No description provided for @gameDetailOpenIgdb.
  ///
  /// In es, this message translates to:
  /// **'Ver en IGDB'**
  String get gameDetailOpenIgdb;

  /// No description provided for @gameDetailTimeToBeatSection.
  ///
  /// In es, this message translates to:
  /// **'Tiempo estimado (IGDB)'**
  String get gameDetailTimeToBeatSection;

  /// No description provided for @gameDetailTtbHastily.
  ///
  /// In es, this message translates to:
  /// **'Historia principal (rápido)'**
  String get gameDetailTtbHastily;

  /// No description provided for @gameDetailTtbNormal.
  ///
  /// In es, this message translates to:
  /// **'Historia principal (normal)'**
  String get gameDetailTtbNormal;

  /// No description provided for @gameDetailTtbComplete.
  ///
  /// In es, this message translates to:
  /// **'Al 100%'**
  String get gameDetailTtbComplete;

  /// No description provided for @gameDetailScreenshots.
  ///
  /// In es, this message translates to:
  /// **'Capturas'**
  String get gameDetailScreenshots;

  /// No description provided for @gameDetailReviewsSection.
  ///
  /// In es, this message translates to:
  /// **'Reseñas (IGDB)'**
  String get gameDetailReviewsSection;

  /// No description provided for @gameDetailNoReviews.
  ///
  /// In es, this message translates to:
  /// **'No hay reseñas en IGDB para este juego.'**
  String get gameDetailNoReviews;

  /// No description provided for @gameDetailReviewUntitled.
  ///
  /// In es, this message translates to:
  /// **'Reseña'**
  String get gameDetailReviewUntitled;

  /// No description provided for @gameDetailReviewBy.
  ///
  /// In es, this message translates to:
  /// **'Por {name}'**
  String gameDetailReviewBy(Object name);

  /// No description provided for @gameDetailOpenCriticSection.
  ///
  /// In es, this message translates to:
  /// **'Críticas (OpenCritic)'**
  String get gameDetailOpenCriticSection;

  /// No description provided for @gameDetailOpenCriticMeta.
  ///
  /// In es, this message translates to:
  /// **'Nota destacada: {score} · {count} reseñas'**
  String gameDetailOpenCriticMeta(Object score, Object count);

  /// No description provided for @gameDetailOpenCriticNoMatch.
  ///
  /// In es, this message translates to:
  /// **'No hay coincidencia en OpenCritic para este título.'**
  String get gameDetailOpenCriticNoMatch;

  /// No description provided for @gameDetailOpenCriticReadReview.
  ///
  /// In es, this message translates to:
  /// **'Leer reseña'**
  String get gameDetailOpenCriticReadReview;

  /// No description provided for @gameDetailOpenCriticOpenSite.
  ///
  /// In es, this message translates to:
  /// **'Abrir en OpenCritic'**
  String get gameDetailOpenCriticOpenSite;

  /// No description provided for @gameDetailPlaytimeHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String gameDetailPlaytimeHoursMinutes(Object hours, Object minutes);

  /// No description provided for @gameDetailPlaytimeHoursOnly.
  ///
  /// In es, this message translates to:
  /// **'{hours} h'**
  String gameDetailPlaytimeHoursOnly(Object hours);

  /// No description provided for @gameDetailPlaytimeMinutesOnly.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String gameDetailPlaytimeMinutesOnly(Object minutes);

  /// No description provided for @gameDetailWebCatOfficial.
  ///
  /// In es, this message translates to:
  /// **'Web oficial'**
  String get gameDetailWebCatOfficial;

  /// No description provided for @gameDetailWebCatWikia.
  ///
  /// In es, this message translates to:
  /// **'Wikia'**
  String get gameDetailWebCatWikia;

  /// No description provided for @gameDetailWebCatWikipedia.
  ///
  /// In es, this message translates to:
  /// **'Wikipedia'**
  String get gameDetailWebCatWikipedia;

  /// No description provided for @gameDetailWebCatFacebook.
  ///
  /// In es, this message translates to:
  /// **'Facebook'**
  String get gameDetailWebCatFacebook;

  /// No description provided for @gameDetailWebCatTwitter.
  ///
  /// In es, this message translates to:
  /// **'Twitter / X'**
  String get gameDetailWebCatTwitter;

  /// No description provided for @gameDetailWebCatTwitch.
  ///
  /// In es, this message translates to:
  /// **'Twitch'**
  String get gameDetailWebCatTwitch;

  /// No description provided for @gameDetailWebCatInstagram.
  ///
  /// In es, this message translates to:
  /// **'Instagram'**
  String get gameDetailWebCatInstagram;

  /// No description provided for @gameDetailWebCatYoutube.
  ///
  /// In es, this message translates to:
  /// **'YouTube'**
  String get gameDetailWebCatYoutube;

  /// No description provided for @gameDetailWebCatSteam.
  ///
  /// In es, this message translates to:
  /// **'Steam'**
  String get gameDetailWebCatSteam;

  /// No description provided for @gameDetailWebCatReddit.
  ///
  /// In es, this message translates to:
  /// **'Reddit'**
  String get gameDetailWebCatReddit;

  /// No description provided for @gameDetailWebCatItch.
  ///
  /// In es, this message translates to:
  /// **'itch.io'**
  String get gameDetailWebCatItch;

  /// No description provided for @gameDetailWebCatEpic.
  ///
  /// In es, this message translates to:
  /// **'Epic Games'**
  String get gameDetailWebCatEpic;

  /// No description provided for @gameDetailWebCatGog.
  ///
  /// In es, this message translates to:
  /// **'GOG'**
  String get gameDetailWebCatGog;

  /// No description provided for @gameDetailWebCatDiscord.
  ///
  /// In es, this message translates to:
  /// **'Discord'**
  String get gameDetailWebCatDiscord;

  /// No description provided for @gameDetailWebCatOther.
  ///
  /// In es, this message translates to:
  /// **'Enlace'**
  String get gameDetailWebCatOther;

  /// No description provided for @gameDetailExtCatSteam.
  ///
  /// In es, this message translates to:
  /// **'Steam'**
  String get gameDetailExtCatSteam;

  /// No description provided for @gameDetailExtCatGog.
  ///
  /// In es, this message translates to:
  /// **'GOG'**
  String get gameDetailExtCatGog;

  /// No description provided for @gameDetailExtCatMicrosoft.
  ///
  /// In es, this message translates to:
  /// **'Microsoft Store'**
  String get gameDetailExtCatMicrosoft;

  /// No description provided for @gameDetailExtCatEpic.
  ///
  /// In es, this message translates to:
  /// **'Epic Games'**
  String get gameDetailExtCatEpic;

  /// No description provided for @gameDetailExtCatOther.
  ///
  /// In es, this message translates to:
  /// **'Tienda externa'**
  String get gameDetailExtCatOther;

  /// No description provided for @onboardingTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Qué te interesa?'**
  String get onboardingTitle;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona al menos una categoría para personalizar tu experiencia'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get onboardingContinue;

  /// No description provided for @onboardingInterestAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get onboardingInterestAnime;

  /// No description provided for @onboardingInterestManga.
  ///
  /// In es, this message translates to:
  /// **'Manga'**
  String get onboardingInterestManga;

  /// No description provided for @onboardingInterestMovies.
  ///
  /// In es, this message translates to:
  /// **'Películas'**
  String get onboardingInterestMovies;

  /// No description provided for @onboardingInterestTv.
  ///
  /// In es, this message translates to:
  /// **'Series de TV'**
  String get onboardingInterestTv;

  /// No description provided for @onboardingInterestGames.
  ///
  /// In es, this message translates to:
  /// **'Videojuegos'**
  String get onboardingInterestGames;

  /// No description provided for @settingsCustomizeSearchFilters.
  ///
  /// In es, this message translates to:
  /// **'Filtros de búsqueda'**
  String get settingsCustomizeSearchFilters;

  /// No description provided for @settingsCustomizeSearchFiltersDesc.
  ///
  /// In es, this message translates to:
  /// **'Reordena u oculta los filtros en la pestaña de búsqueda'**
  String get settingsCustomizeSearchFiltersDesc;

  /// No description provided for @settingsInterests.
  ///
  /// In es, this message translates to:
  /// **'Tus intereses'**
  String get settingsInterests;

  /// No description provided for @settingsInterestsDesc.
  ///
  /// In es, this message translates to:
  /// **'Cambia los contenidos que ves en inicio, biblioteca y búsqueda'**
  String get settingsInterestsDesc;

  /// No description provided for @settingsInterestsChanged.
  ///
  /// In es, this message translates to:
  /// **'Intereses actualizados'**
  String get settingsInterestsChanged;

  /// No description provided for @socialTitle.
  ///
  /// In es, this message translates to:
  /// **'Social'**
  String get socialTitle;

  /// No description provided for @settingsScoringTitle.
  ///
  /// In es, this message translates to:
  /// **'Sistema de puntuación'**
  String get settingsScoringTitle;

  /// No description provided for @settingsScoringDesc.
  ///
  /// In es, this message translates to:
  /// **'Elige cómo puntuar tu contenido'**
  String get settingsScoringDesc;

  /// No description provided for @scoringPoint100.
  ///
  /// In es, this message translates to:
  /// **'100 puntos'**
  String get scoringPoint100;

  /// No description provided for @scoringPoint10Decimal.
  ///
  /// In es, this message translates to:
  /// **'10 puntos decimal'**
  String get scoringPoint10Decimal;

  /// No description provided for @scoringPoint10.
  ///
  /// In es, this message translates to:
  /// **'10 puntos'**
  String get scoringPoint10;

  /// No description provided for @scoringPoint5.
  ///
  /// In es, this message translates to:
  /// **'5 estrellas'**
  String get scoringPoint5;

  /// No description provided for @scoringPoint3.
  ///
  /// In es, this message translates to:
  /// **'3 caritas'**
  String get scoringPoint3;

  /// No description provided for @settingsAdvancedScoring.
  ///
  /// In es, this message translates to:
  /// **'Puntuación avanzada (Anilist)'**
  String get settingsAdvancedScoring;

  /// No description provided for @settingsAdvancedScoringDesc.
  ///
  /// In es, this message translates to:
  /// **'Puntúa por categorías: historia, personajes, visual, audio y disfrute'**
  String get settingsAdvancedScoringDesc;

  /// No description provided for @advScoringStory.
  ///
  /// In es, this message translates to:
  /// **'Historia'**
  String get advScoringStory;

  /// No description provided for @advScoringCharacters.
  ///
  /// In es, this message translates to:
  /// **'Personajes'**
  String get advScoringCharacters;

  /// No description provided for @advScoringVisuals.
  ///
  /// In es, this message translates to:
  /// **'Visual'**
  String get advScoringVisuals;

  /// No description provided for @advScoringAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio'**
  String get advScoringAudio;

  /// No description provided for @advScoringEnjoyment.
  ///
  /// In es, this message translates to:
  /// **'Disfrute'**
  String get advScoringEnjoyment;

  /// No description provided for @advScoringReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get advScoringReset;

  /// No description provided for @mediaStatusFinished.
  ///
  /// In es, this message translates to:
  /// **'Finalizado'**
  String get mediaStatusFinished;

  /// No description provided for @mediaStatusReleasing.
  ///
  /// In es, this message translates to:
  /// **'En emisión'**
  String get mediaStatusReleasing;

  /// No description provided for @mediaStatusNotYetReleased.
  ///
  /// In es, this message translates to:
  /// **'Sin estrenar'**
  String get mediaStatusNotYetReleased;

  /// No description provided for @mediaStatusCancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelado'**
  String get mediaStatusCancelled;

  /// No description provided for @mediaStatusHiatus.
  ///
  /// In es, this message translates to:
  /// **'En hiato'**
  String get mediaStatusHiatus;

  /// No description provided for @forumDiscussions.
  ///
  /// In es, this message translates to:
  /// **'Discusiones en el foro'**
  String get forumDiscussions;

  /// No description provided for @forumViewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver más'**
  String get forumViewAll;

  /// No description provided for @forumThread.
  ///
  /// In es, this message translates to:
  /// **'Hilo del foro'**
  String get forumThread;

  /// No description provided for @forumReplies.
  ///
  /// In es, this message translates to:
  /// **'{count} respuestas'**
  String forumReplies(int count);

  /// No description provided for @forumNoReplies.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay respuestas'**
  String get forumNoReplies;
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
