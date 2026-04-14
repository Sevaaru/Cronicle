// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cronicle';

  @override
  String get navHome => 'Feed';

  @override
  String get navLibrary => 'Library';

  @override
  String get navAnime => 'Anime';

  @override
  String get navSearch => 'Search';

  @override
  String get navManga => 'Manga';

  @override
  String get navMovies => 'Movies';

  @override
  String get navTv => 'TV';

  @override
  String get navGames => 'Games';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAuth => 'Accounts';

  @override
  String get homeSubtitle => 'Your progress and lists, offline first.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get placeholderSoon => 'Coming soon';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork => 'No connection or network error.';

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get googleSignOut => 'Sign out of Google';

  @override
  String get backupTitle => 'Google Drive backup';

  @override
  String get backupStubMessage =>
      'Full backup to the app data folder will be available in a future version.';

  @override
  String get feedTitle => 'Global Activity';

  @override
  String get feedEmpty => 'No recent activity.';

  @override
  String get feedRetry => 'Retry';

  @override
  String get libraryEmpty => 'Your list is empty.';

  @override
  String get libraryAddHint => 'Search and add content from Anime.';

  @override
  String get searchHint => 'Search anime...';

  @override
  String get addedToLibrary => 'Added to library';

  @override
  String get backupUploadSuccess => 'Backup uploaded successfully';

  @override
  String get backupRestored => 'Restored successfully';

  @override
  String get connectAnilist => 'Connect Anilist';

  @override
  String get disconnectAnilist => 'Disconnect Anilist';
}
