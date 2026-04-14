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

  /// Nombre de la aplicación
  ///
  /// In es, this message translates to:
  /// **'Cronicle'**
  String get appTitle;

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Feed'**
  String get navHome;

  /// No description provided for @navLibrary.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca'**
  String get navLibrary;

  /// No description provided for @navAnime.
  ///
  /// In es, this message translates to:
  /// **'Anime'**
  String get navAnime;

  /// No description provided for @navSearch.
  ///
  /// In es, this message translates to:
  /// **'Búsqueda'**
  String get navSearch;

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

  /// No description provided for @navSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get navSettings;

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

  /// No description provided for @backupTitle.
  ///
  /// In es, this message translates to:
  /// **'Copia en Google Drive'**
  String get backupTitle;

  /// No description provided for @backupStubMessage.
  ///
  /// In es, this message translates to:
  /// **'La copia completa a la carpeta de datos de la app estará disponible en una próxima versión.'**
  String get backupStubMessage;

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

  /// No description provided for @libraryEmpty.
  ///
  /// In es, this message translates to:
  /// **'Tu lista está vacía.'**
  String get libraryEmpty;

  /// No description provided for @libraryAddHint.
  ///
  /// In es, this message translates to:
  /// **'Busca y añade contenido desde Anime.'**
  String get libraryAddHint;

  /// No description provided for @searchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar anime...'**
  String get searchHint;

  /// No description provided for @addedToLibrary.
  ///
  /// In es, this message translates to:
  /// **'Añadido a la biblioteca'**
  String get addedToLibrary;

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

  /// No description provided for @connectAnilist.
  ///
  /// In es, this message translates to:
  /// **'Conectar Anilist'**
  String get connectAnilist;

  /// No description provided for @disconnectAnilist.
  ///
  /// In es, this message translates to:
  /// **'Desconectar Anilist'**
  String get disconnectAnilist;
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
