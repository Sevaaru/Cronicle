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
  String get googleSyncNow => 'Sync now';

  @override
  String get connectedWithGoogle => 'Connected with Google';

  @override
  String get googleDrivePermissionMissing =>
      'Google account is signed in, but Drive backup access was not granted. Try again and accept access to app data in Drive.';

  @override
  String get googleSignInCanceledTitle => 'Google could not finish sign-in';

  @override
  String get googleSignInCanceledBody =>
      'A “canceled” error usually means OAuth misconfiguration, not that you tapped cancel. In Google Cloud Console: 1) Android OAuth client with your app package and the SHA-1 of the keystore for this build (from the android folder: gradlew signingReport). 2) GOOGLE_SERVER_CLIENT_ID must be your Web client ID from the same project. 3) Optional: GOOGLE_ANDROID_CLIENT_ID with the Android client ID in your build defines. If you ship via Play, also add Play App Signing’s SHA-1.';

  @override
  String get googleSignInNotConfiguredTitle =>
      'Google is not configured in this build';

  @override
  String get googleSignInNotConfiguredHint =>
      'GOOGLE_SERVER_CLIENT_ID (Web OAuth client) is missing from your compile-time defines.';

  @override
  String get googleSignInNotConfiguredBody =>
      'At the project root, copy dart_defines.example.json to dart_defines.local.json and set GOOGLE_SERVER_CLIENT_ID to your Google Cloud OAuth client of type “Web application” (ends with .apps.googleusercontent.com). It is required on Android for Google Sign-In 7.x.\n\nIn the same Google Cloud project, create an Android OAuth client with package name com.cronicle.app.cronicle and the SHA-1 of the keystore used for the APK you install (debug, release, or Play App Signing). To print SHA-1 fingerprints: from the android folder run .\\gradlew.bat signingReport on Windows or ./gradlew signingReport on macOS/Linux. If you publish on the Play Store, also add Play’s “App signing” SHA-1 in Cloud Console.\n\nOptional: GOOGLE_ANDROID_CLIENT_ID with the Android client ID. After saving dart_defines.local.json, rebuild with flutter run or scripts/build_android.ps1.';

  @override
  String get backupTitle => 'Local backup';

  @override
  String get backupUpload => 'Upload';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupUploadSuccess => 'Backup uploaded successfully';

  @override
  String backupAnilistMergeFailed(Object error) {
    return 'Could not refresh from Anilist before backup; uploading on-device data. $error';
  }

  @override
  String get backupExportReady =>
      'Backup ready — use the share sheet to save it wherever you want.';

  @override
  String get backupRestored => 'Restored successfully';

  @override
  String backupRestoredCount(Object count) {
    return 'Restored $count items';
  }

  @override
  String get backupAutoGoogleTitle => 'Daily backup to Google Drive';

  @override
  String get backupAutoGoogleSubtitle =>
      'At most once per day when online, only if you stay signed in with Google (Accounts). No prompts in the background.';

  @override
  String get backupSectionSubtitle =>
      'Same JSON as a full export (library and on-device settings). Save it locally with Share, or—with Google signed in under Accounts—Upload also keeps a copy in your Drive app folder.';

  @override
  String get backupRestoreChooseSourceTitle => 'Backup source';

  @override
  String get backupRestoreChooseSourceBody =>
      'Restore from a JSON file or from the backup stored in Google Drive?';

  @override
  String get backupRestoreFromFile => 'File…';

  @override
  String get backupRestoreFromDrive => 'Google Drive';

  @override
  String get backupRestoreConfirmTitle => 'Restore backup';

  @override
  String backupRestoreConfirmBody(Object count) {
    return 'This will merge $count library entries and, if the backup includes them, local preferences and Anilist/Twitch sessions from the file.';
  }

  @override
  String get feedTitle => 'Home';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsLoginRequired =>
      'Sign in with Anilist in Settings to see notifications.';

  @override
  String get notifPermissionTitle => 'Enable notifications?';

  @override
  String get notifPermissionBody =>
      'Cronicle can notify you when a new episode or chapter airs for anime or manga you follow as in progress, and optionally mirror notifications from your Anilist inbox. You can change this later in Settings.';

  @override
  String get notifPermissionNotNow => 'Not now';

  @override
  String get notifPermissionAllow => 'Allow';

  @override
  String get gallerySaveUnavailableWeb =>
      'Saving is not available on the web build';

  @override
  String get gallerySaveSuccess => 'Image saved';

  @override
  String get gallerySaveErrorGeneric => 'Could not save image';

  @override
  String get gallerySavePermissionDenied =>
      'Gallery access is required to save images.';

  @override
  String get gallerySaveOpenSettings => 'Settings';

  @override
  String get settingsNotificationsTitle => 'On-device notifications';

  @override
  String get settingsNotificationsSubtitle =>
      'Requires an Anilist session. On Android background checks run about every 15 minutes when the OS allows; on iOS the system sets the schedule. A check also runs when you leave the app. The OS may still defer runs.';

  @override
  String get settingsNotificationsUnavailableWeb =>
      'System notifications are not available on the web build.';

  @override
  String get settingsNotifMaster => 'System notifications';

  @override
  String get settingsNotifAiring =>
      'New episodes/chapters (in progress + releasing)';

  @override
  String get settingsNotifAnilistInbox => 'Anilist inbox on this device';

  @override
  String get settingsNotifAnilistSocial =>
      'Include activity & social (forums, mentions, followers…)';

  @override
  String get settingsNotifAnilistSocialDesc =>
      'When off, only Anilist airing-style notifications are mirrored (alongside new-chapter checks above).';

  @override
  String get notificationNoLink => 'Open this notification on anilist.co';

  @override
  String get notificationTypeGeneric => 'Notification';

  @override
  String get notificationTypeAiring => 'New episode';

  @override
  String get notificationTypeActivityReply => 'Activity reply';

  @override
  String get notificationTypeActivityMention => 'Mention in activity';

  @override
  String get notificationTypeActivityMessage => 'Activity message';

  @override
  String get notificationTypeFollowing => 'New follower';

  @override
  String get notificationTypeRelatedMedia => 'Related media added';

  @override
  String get notificationTypeMediaDataChange => 'Media updated';

  @override
  String get notificationTypeMediaMerge => 'Media merged';

  @override
  String get notificationTypeMediaDeletion => 'Media removed from Anilist';

  @override
  String get notificationTypeThreadReply => 'Forum reply';

  @override
  String get notificationTypeThreadMention => 'Forum mention';

  @override
  String get notificationTypeThreadSubscribed => 'Forum thread update';

  @override
  String get notificationTypeThreadLike => 'Forum like';

  @override
  String get notificationTypeActivityLike => 'Activity liked';

  @override
  String get notificationTypeActivityReplyLike => 'Reply liked';

  @override
  String get notificationTypeActivityReplySubscribed =>
      'Reply on subscribed activity';

  @override
  String get notificationTypeThreadCommentLike => 'Forum comment liked';

  @override
  String get notificationTypeMediaSubmission => 'Media submission update';

  @override
  String get notificationTypeStaffSubmission => 'Staff submission update';

  @override
  String get notificationTypeCharacterSubmission =>
      'Character submission update';

  @override
  String get feedEmpty => 'No recent activity.';

  @override
  String get feedRetry => 'Retry';

  @override
  String feedComingSoon(Object label) {
    return '$label feed — coming soon';
  }

  @override
  String get feedBrowseActivity => 'Activity';

  @override
  String get feedBrowseSeasonal => 'Seasonal';

  @override
  String get feedBrowseTopRated => 'Top rated';

  @override
  String get feedBrowseUpcoming => 'Upcoming';

  @override
  String get feedBrowseRecentlyReleased => 'Recently released';

  @override
  String get feedBrowseEmpty => 'No titles in this list.';

  @override
  String get filterFollowing => 'Following';

  @override
  String get filterGlobal => 'Global';

  @override
  String get filterFeed => 'Feed';

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
  String get loginRequiredFavorite =>
      'Sign in with Anilist in Settings to use favourites';

  @override
  String get sectionFavGames => 'Favourite games';

  @override
  String get tooltipAddFavorite => 'Add to favourites';

  @override
  String get tooltipRemoveFavorite => 'Remove from favourites';

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
  String get librarySearchTitle => 'Search library';

  @override
  String get librarySearchHint => 'Search in library...';

  @override
  String get librarySearchPrompt => 'Type a title to search';

  @override
  String get librarySearchGlobalResults => 'Global results';

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
  String get removeFromLibrary => 'Remove from my library';

  @override
  String get removedFromLibrary => 'Removed from library';

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
  String get mediaGenresSection => 'Genres';

  @override
  String get mediaTagsSection => 'Tags';

  @override
  String get mediaBrowseSortScore => 'Score';

  @override
  String get mediaBrowseSortPopularity => 'Popularity';

  @override
  String get mediaBrowseSortName => 'Name';

  @override
  String get mediaBrowseInvalidParams => 'This link is missing a genre or tag.';

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
  String get addToListMovieProgress => 'Watched (0–1)';

  @override
  String get traktNotConfiguredHint =>
      'Add TRAKT_CLIENT_ID to your dart-defines to load movies and TV from Trakt (anime genre excluded to avoid duplicating AniList).';

  @override
  String get traktSectionTrending => 'Trending';

  @override
  String get traktSectionWatchingNow => 'Watching now';

  @override
  String get traktSectionAnticipatedMovies => 'Most anticipated';

  @override
  String get traktSectionPopular => 'Popular';

  @override
  String get traktTitle => 'Trakt.tv';

  @override
  String get traktSubtitle =>
      'Movies and TV (no anime). Connect your account to import watched history into the local library.';

  @override
  String traktConnectedAs(Object slug) {
    return 'Connected as $slug';
  }

  @override
  String get traktConnect => 'Connect Trakt';

  @override
  String get traktDisconnect => 'Disconnect Trakt';

  @override
  String get traktConnectSuccess => 'Trakt account linked.';

  @override
  String get traktDisconnected => 'Trakt account disconnected.';

  @override
  String get traktOAuthMissingCredentials =>
      'Set TRAKT_CLIENT_ID, TRAKT_CLIENT_SECRET, and TRAKT_REDIRECT_URI (registered at trakt.tv/oauth/applications).';

  @override
  String get traktOAuthWebUnavailable =>
      'Trakt sign-in from the browser is not available in this app; use Android, iOS, or desktop.';

  @override
  String get traktImportTitle => 'Import from Trakt';

  @override
  String get traktImportConfirm => 'Import';

  @override
  String get traktImportDesc =>
      'Bring watched movies and shows (no anime) into this device’s library.';

  @override
  String traktImportedCount(Object count) {
    return 'Imported $count titles from Trakt.';
  }

  @override
  String get traktDetailLinks => 'Links';

  @override
  String get traktLinkTrailer => 'Trailer';

  @override
  String get traktLinkHomepage => 'Website';

  @override
  String get traktDetailOnTrakt => 'Open on Trakt';

  @override
  String get traktEpisodeProgressTitle => 'Episode progress';

  @override
  String get traktEpisodeProgressHint =>
      'Add this show to your library to track how many episodes you’ve watched.';

  @override
  String get traktEpisodeProgressMarkComplete => 'Mark show completed';

  @override
  String get traktEpisodeMinusOne => 'One episode less';

  @override
  String get traktEpisodePlusOne => 'One episode more';

  @override
  String get traktDetailVotes => 'Votes';

  @override
  String get traktDetailLanguage => 'Language';

  @override
  String get traktDetailOriginalTitle => 'Original title';

  @override
  String get traktDetailSubgenres => 'Subgenres';

  @override
  String get traktDetailCountry => 'Country';

  @override
  String get traktDetailYear => 'Year';

  @override
  String get traktDetailNetwork => 'Network';

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
  String get settingsAccountsTitle => 'Accounts';

  @override
  String get settingsAccountsSubtitle =>
      'Anilist syncs anime/manga to the cloud. Trakt covers movies and TV (no anime). Google is for optional Drive backup. Games in Cronicle stay on your device.';

  @override
  String get twitchIgdbTitle => 'Twitch (IGDB)';

  @override
  String get twitchIgdbSubtitle =>
      'Sign in so search and game pages use your token with IGDB. That does not upload your library to igdb.com or import your igdb.com “Played” list—the public API does not expose personal collections.';

  @override
  String twitchConnectedAs(Object login) {
    return 'Connected as @$login';
  }

  @override
  String get twitchDisconnectAccount => 'Disconnect Twitch';

  @override
  String get twitchConnectOAuth => 'Connect with Twitch';

  @override
  String get twitchConnectSuccess =>
      'Twitch connected. IGDB requests will use your session.';

  @override
  String get twitchDisconnected => 'Twitch account disconnected.';

  @override
  String get twitchOAuthWebUnavailable =>
      'Twitch sign-in from the browser is not set up. Use the Android, iOS, or desktop app.';

  @override
  String get twitchOAuthMissingSecrets =>
      'Add TWITCH_CLIENT_ID and TWITCH_CLIENT_SECRET to build flags (see README).';

  @override
  String get twitchRedirectNotConfigured =>
      '(TWITCH_REDIRECT_URI not set: pass an https URL via --dart-define)';

  @override
  String get twitchRedirectMustBeHttps =>
      'TWITCH_REDIRECT_URI must be https://… Twitch’s console rejects cronicle://; host web/twitch_oauth_bridge.html over HTTPS and register that exact URL.';

  @override
  String get twitchSyncTitle => 'Sync games with Twitch';

  @override
  String twitchSyncWelcome(Object name) {
    return 'Hi, $name. How do you want to align your game library?';
  }

  @override
  String get twitchGameSyncMerge => 'Merge';

  @override
  String get twitchGameSyncMergeDesc =>
      'Keep games stored on this device and avoid duplicates when a remote source is connected.';

  @override
  String get twitchGameSyncOverwrite => 'Overwrite from the cloud';

  @override
  String get twitchGameSyncOverwriteDesc =>
      'Delete games stored only on this device, then import from the remote source (when available).';

  @override
  String get twitchSyncIgdbApiFootnote =>
      'IGDB’s public API cannot read or write your personal igdb.com collection (e.g. “Played”). Library entries you add here stay on-device until we integrate another source (e.g. Steam).';

  @override
  String twitchSyncImportedCount(Object count) {
    return 'Synced $count games from Twitch.';
  }

  @override
  String get twitchSyncImportedZeroWarning =>
      'Games on this device were cleared. There is still no remote import (IGDB’s API does not expose your igdb.com list). You can add games manually again.';

  @override
  String get googleAccountTitle => 'Google';

  @override
  String get googleAccountSubtitle =>
      'Optional: same backup JSON in Google Drive (manual upload or daily, see Local backup).';

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
  String get settingsFeedActivityScope => 'Default feed view';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Theme, language, and home & library bars.';

  @override
  String get settingsLayoutCustomizationTitle => 'Home & library bars';

  @override
  String get settingsLayoutCustomizationSubtitle =>
      'Choose which chips appear and in what order.';

  @override
  String get settingsCustomizeFeedFilters => 'Feed filter bar';

  @override
  String get settingsCustomizeFeedFiltersDesc =>
      'Reorder or hide Feed, Anime, etc. At least one filter must stay visible.';

  @override
  String get settingsCustomizeLibraryKinds => 'Library type bar';

  @override
  String get settingsCustomizeLibraryKindsDesc =>
      'Reorder or hide All, Anime, Movies, TV, Games, Manga. At least one option must stay visible.';

  @override
  String get settingsLayoutDragHint =>
      'Long-press the handle to drag and change order.';

  @override
  String get settingsLayoutReset => 'Reset';

  @override
  String get settingsLayoutResetDone => 'Order restored to defaults.';

  @override
  String get settingsLayoutShowInFeed => 'Show in feed';

  @override
  String get settingsLayoutShowInLibrary => 'Show in library';

  @override
  String get follow => 'Follow';

  @override
  String get following => 'Following';

  @override
  String get commentsTitle => 'Comments';

  @override
  String get noComments => 'No comments';

  @override
  String get activityOriginalPost => 'Original post';

  @override
  String get activityRepliesHeading => 'Replies';

  @override
  String get activityThreadLoadError => 'Could not load this thread';

  @override
  String get activityMessageActivity => 'Private message';

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

  @override
  String get writeReplyHint => 'Write a comment...';

  @override
  String get composeActivityHint => 'What\'s on your mind?';

  @override
  String get composeMarkdownTip => 'Supports markdown and images';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get postButton => 'Post';

  @override
  String get activityPosted => 'Posted successfully';

  @override
  String get settingsHideTextActivities => 'Hide text activities';

  @override
  String get settingsHideTextActivitiesDesc =>
      'Don\'t show text posts in the feed';

  @override
  String get statusCurrentGame => 'Playing';

  @override
  String get statusReplayingGame => 'Replaying';

  @override
  String get searchTrendingGames => 'Trending games';

  @override
  String get igdbWebNotSupported =>
      'IGDB is not available in the browser (IGDB does not allow requests from web apps). Use the Windows, Android, or iOS build to search games.';

  @override
  String get twitchSyncPromptTitle => 'Connect with Twitch';

  @override
  String get twitchSyncPromptBody =>
      'Connect your Twitch account to sync your games in the future.\n\nYou can also do this later from Settings.';

  @override
  String get twitchSyncPromptNoThanks => 'No, thanks';

  @override
  String get twitchConnect => 'Connect Twitch';

  @override
  String get gameDetailPlatforms => 'Platforms';

  @override
  String get gameDetailGenres => 'Genres';

  @override
  String get gameDetailSynopsis => 'Synopsis';

  @override
  String get gameDetailStoryline => 'Storyline';

  @override
  String get gameDetailModes => 'Game modes';

  @override
  String get gameDetailThemes => 'Themes';

  @override
  String get gameDetailDeveloper => 'Developer';

  @override
  String get gameDetailPublisher => 'Publisher';

  @override
  String get gameDetailReleaseDate => 'Release date';

  @override
  String get gameDetailRating => 'Rating';

  @override
  String get gameDetailSimilarGames => 'Similar games';

  @override
  String get gameDetailNoData => 'No game data found';

  @override
  String get gameDetailCompanies => 'Companies';

  @override
  String get addToListHoursPlayed => 'Hours played';

  @override
  String get gameDetailLinksSection => 'Links';

  @override
  String gameDetailLinksShowMore(Object remaining) {
    return 'Show $remaining more';
  }

  @override
  String get gameDetailLinksShowLess => 'Show less';

  @override
  String get gameDetailLinkOfficialSite => 'Website';

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
  String get gamesHomePopularNow => 'Popular right now';

  @override
  String get gamesHomeMostAnticipated => 'Most anticipated';

  @override
  String get gamesHomeRecentReviews => 'Recent reviews';

  @override
  String get gamesHomeCriticsReviews => 'Recent critics reviews';

  @override
  String get gamesHomeRecentlyReleased => 'Recently released';

  @override
  String get gamesHomeComingSoon => 'Coming soon';

  @override
  String get gamesHomeSectionExpand => 'Show more';

  @override
  String get gamesHomeSectionCollapse => 'Show less';

  @override
  String get gamesHomeNoItems => 'Nothing here yet';

  @override
  String get gamesHomeOpenGame => 'View game';

  @override
  String get igdbReviewNotFound => 'Review not found.';

  @override
  String get gameDetailOpenIgdb => 'Open on IGDB';

  @override
  String get gameDetailTimeToBeatSection => 'Time to beat (IGDB)';

  @override
  String get gameDetailTtbHastily => 'Main story (fast)';

  @override
  String get gameDetailTtbNormal => 'Main story (normal)';

  @override
  String get gameDetailTtbComplete => 'Completionist';

  @override
  String get gameDetailScreenshots => 'Screenshots';

  @override
  String get gameDetailReviewsSection => 'Reviews (IGDB)';

  @override
  String get gameDetailNoReviews => 'No IGDB reviews for this game yet.';

  @override
  String get gameDetailReviewUntitled => 'Review';

  @override
  String gameDetailReviewBy(Object name) {
    return 'By $name';
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
  String get gameDetailWebCatOfficial => 'Official website';

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
  String get gameDetailWebCatOther => 'Link';

  @override
  String get gameDetailExtCatSteam => 'Steam';

  @override
  String get gameDetailExtCatGog => 'GOG';

  @override
  String get gameDetailExtCatMicrosoft => 'Microsoft Store';

  @override
  String get gameDetailExtCatEpic => 'Epic Games';

  @override
  String get gameDetailExtCatOther => 'External store';
}
