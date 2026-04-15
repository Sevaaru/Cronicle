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
  String get navHome => 'Home';

  @override
  String get navLibrary => 'Library';

  @override
  String get navSearch => 'Search';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navAnime => 'Anime';

  @override
  String get navManga => 'Manga';

  @override
  String get navMovies => 'Movies';

  @override
  String get navTv => 'TV Shows';

  @override
  String get navGames => 'Games';

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
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get errorVerifyingSession => 'Error verifying session';

  @override
  String get errorVerifyingToken => 'Error verifying token';

  @override
  String get errorLoadingProfile => 'Error loading profile';

  @override
  String errorSyncMessage(Object message) {
    return 'Sync error: $message';
  }

  @override
  String get googleSignIn => 'Sign in with Google';

  @override
  String get googleSignOut => 'Sign out of Google';

  @override
  String get connectedWithGoogle => 'Connected with Google';

  @override
  String get backupTitle => 'Google Drive backup';

  @override
  String get backupUpload => 'Upload';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupUploadSuccess => 'Backup uploaded successfully';

  @override
  String get backupRestored => 'Restored successfully';

  @override
  String backupRestoredCount(Object count) {
    return 'Restored $count items';
  }

  @override
  String get feedTitle => 'Home';

  @override
  String get feedEmpty => 'No recent activity.';

  @override
  String get feedRetry => 'Retry';

  @override
  String feedComingSoon(Object label) {
    return '$label feed — coming soon';
  }

  @override
  String get filterFollowing => 'Following';

  @override
  String get filterGlobal => 'Global';

  @override
  String get filterAnime => 'Anime';

  @override
  String get filterManga => 'Manga';

  @override
  String get filterMovies => 'Movies';

  @override
  String get filterTv => 'TV Shows';

  @override
  String get filterGames => 'Games';

  @override
  String get filterAll => 'All';

  @override
  String get loginRequiredFollowing =>
      'Sign in with Anilist to see activity from people you follow';

  @override
  String get loginRequiredLike => 'Sign in with Anilist to like';

  @override
  String get loginRequiredFollow => 'Sign in with Anilist to follow users';

  @override
  String get goToSettings => 'Go to Settings';

  @override
  String get timeNow => 'now';

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
    return '${count}w';
  }

  @override
  String get libraryTitle => 'Library';

  @override
  String get libraryEmpty => 'Your list is empty.';

  @override
  String get libraryAddHint => 'Search and add content.';

  @override
  String get libraryNoResults => 'No results';

  @override
  String get libraryNoStatusResults => 'No titles with this status';

  @override
  String get librarySearchAndAdd => 'Search and add content';

  @override
  String get statusAll => 'All';

  @override
  String get statusCurrent => 'In progress';

  @override
  String get statusCurrentAnime => 'Watching';

  @override
  String get statusCurrentManga => 'Reading';

  @override
  String get statusPlanning => 'Planned';

  @override
  String get statusCompleted => 'Completed';

  @override
  String get statusPaused => 'Paused';

  @override
  String get statusDropped => 'Dropped';

  @override
  String get statusRepeating => 'Repeating';

  @override
  String get sortRecent => 'Recent';

  @override
  String get sortName => 'Name';

  @override
  String get sortScore => 'Score';

  @override
  String get sortProgress => 'Progress';

  @override
  String get tooltipCompleted => 'Completed';

  @override
  String get tooltipIncrementProgress => '+1 chapter/episode';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchHint => 'Search...';

  @override
  String get searchTrendingAnime => 'Trending anime';

  @override
  String get searchTrendingManga => 'Trending manga';

  @override
  String searchComingSoon(Object label) {
    return '$label — coming soon';
  }

  @override
  String get searchComingSoonApi => 'Coming soon — connect TMDB / IGDB';

  @override
  String get searchSelectFilter => 'Select a filter';

  @override
  String searchErrorIn(Object section, Object error) {
    return 'Error in $section: $error';
  }

  @override
  String get addToLibrary => 'Add to library';

  @override
  String get editLibraryEntry => 'Edit entry';

  @override
  String get addedToLibrary => 'Added to library';

  @override
  String get entryUpdated => 'Entry updated';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileLocalUser => 'Local user';

  @override
  String get profileConnectHint =>
      'Connect Anilist in Settings to see your full statistics';

  @override
  String get profileLocalLibrary => 'Local library';

  @override
  String get profileLibraryEmpty => 'Your library is empty';

  @override
  String get profileNotFound => 'User not found';

  @override
  String get sectionAnime => 'Anime';

  @override
  String get sectionManga => 'Manga';

  @override
  String get sectionFavAnime => 'Favourite anime';

  @override
  String get sectionFavManga => 'Favourite manga';

  @override
  String get sectionRecentActivity => 'Recent activity';

  @override
  String get sectionConnectedAccounts => 'Connected accounts';

  @override
  String get sectionTopGenresAnime => 'Top anime genres';

  @override
  String get sectionTopGenresManga => 'Top manga genres';

  @override
  String get statTitles => 'Titles';

  @override
  String get statEpisodes => 'Episodes';

  @override
  String get statChapters => 'Chapters';

  @override
  String get statVolumes => 'Volumes';

  @override
  String get statDaysWatching => 'Days watching';

  @override
  String get statDays => 'Days';

  @override
  String get statMeanScore => 'Mean score';

  @override
  String get statPopularity => 'Popularity';

  @override
  String get statFavourites => 'Favourites';

  @override
  String get mediaInfo => 'Information';

  @override
  String get mediaSynopsis => 'Synopsis';

  @override
  String get mediaEpisodes => 'Episodes';

  @override
  String get mediaChapters => 'Chapters';

  @override
  String get mediaVolumes => 'Volumes';

  @override
  String get mediaDuration => 'Duration';

  @override
  String get mediaSeason => 'Season';

  @override
  String get mediaSource => 'Source';

  @override
  String get mediaStart => 'Start';

  @override
  String get mediaEnd => 'End';

  @override
  String get mediaStudio => 'Studio: ';

  @override
  String get mediaWhere => 'Where to watch';

  @override
  String get mediaRelated => 'Related';

  @override
  String get mediaRecommendations => 'Recommendations';

  @override
  String get mediaScoreDistribution => 'Score distribution';

  @override
  String get mediaReviews => 'Reviews';

  @override
  String get mediaNoData => 'No data found';

  @override
  String get mediaAnonymous => 'Anonymous';

  @override
  String mediaNextEp(Object episode, Object days, Object hours) {
    return 'Ep $episode in ${days}d ${hours}h';
  }

  @override
  String get addToListTitle => 'Add to your list';

  @override
  String get addToListStatus => 'Status';

  @override
  String get addToListScore => 'Score';

  @override
  String get addToListNoScore => 'No score';

  @override
  String get addToListEpisodes => 'Episodes';

  @override
  String get addToListChapters => 'Chapters';

  @override
  String addToListOf(Object total) {
    return 'of $total';
  }

  @override
  String get addToListMax => 'Max';

  @override
  String get addToListNotes => 'Notes';

  @override
  String get addToListNotesHint => 'Personal notes (optional)...';

  @override
  String get addToListSave => 'Save';

  @override
  String get syncTitle => 'Sync with Anilist';

  @override
  String syncWelcome(Object name) {
    return 'Welcome, $name! How do you want to sync your library?';
  }

  @override
  String get syncImport => 'Import from Anilist';

  @override
  String get syncImportDesc =>
      'Bring your full Anilist list here (recommended)';

  @override
  String get syncMerge => 'Merge';

  @override
  String get syncMergeDesc => 'Merge local records with Anilist';

  @override
  String get syncNotNow => 'Not now';

  @override
  String get syncLoading => 'Syncing...';

  @override
  String syncImportedCount(Object count) {
    return 'Imported $count titles from Anilist';
  }

  @override
  String get syncPromptTitle => 'Sync with Anilist';

  @override
  String get syncPromptBody =>
      'Connect your Anilist account so your anime and manga list stays automatically synced.\n\nYou can also do this later from Settings.';

  @override
  String get syncPromptNoThanks => 'No, thanks';

  @override
  String get anilistTitle => 'Anilist';

  @override
  String get anilistSubtitle => 'Sync your anime and manga list';

  @override
  String get anilistConnected => 'Connected';

  @override
  String get anilistDisconnected => 'Disconnected from Anilist';

  @override
  String get anilistConnectSuccess => 'Connected to Anilist!';

  @override
  String get anilistConnectTitle => 'Connect Anilist';

  @override
  String get anilistDisconnect => 'Disconnect Anilist';

  @override
  String get anilistConnect => 'Connect Anilist';

  @override
  String get anilistTokenLabel => 'Anilist token';

  @override
  String get anilistTokenHint => 'Paste the token here';

  @override
  String get anilistPasteTooltip => 'Paste from clipboard';

  @override
  String get anilistStep1 => 'Authorize Cronicle in the tab that opened';

  @override
  String get anilistStep2 => 'Copy the token shown on screen';

  @override
  String get anilistStep3 => 'Come back here and paste it below';

  @override
  String get cancel => 'Cancel';

  @override
  String get connect => 'Connect';

  @override
  String get settingsDefaultFilter => 'Default library filter';

  @override
  String get settingsDefaultFilterDesc =>
      'The library will open showing this status';

  @override
  String get settingsDefaultsTitle => 'Default screen and tab';

  @override
  String get settingsDefaultsDesc => 'Configure what shows when the app opens';

  @override
  String get settingsStartPage => 'Start page';

  @override
  String get settingsStartFeed => 'Home (Feed)';

  @override
  String get settingsStartLibrary => 'Library';

  @override
  String get settingsFeedTab => 'Default feed tab';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get noComments => 'No comments';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get mediaKindAnime => 'Anime';

  @override
  String get mediaKindManga => 'Manga';

  @override
  String get mediaKindMovie => 'Movies';

  @override
  String get mediaKindTv => 'TV Shows';

  @override
  String get mediaKindGame => 'Games';

  @override
  String get reviewTitle => 'Review';

  @override
  String reviewByUser(Object name) {
    return 'By $name';
  }

  @override
  String get reviewHelpful => 'Helpful?';

  @override
  String get reviewUpVote => 'Yes';

  @override
  String get reviewDownVote => 'No';

  @override
  String get reviewLoginRequired => 'Sign in to Anilist to vote';

  @override
  String reviewUsersFoundHelpful(Object count, Object total) {
    return '$count of $total found this review helpful';
  }

  @override
  String get readMore => 'Read more';
}
