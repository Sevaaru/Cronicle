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
  String get navSocial => 'Social';

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
  String get settingsAboutApp => 'About this app';

  @override
  String settingsAboutCopyright(Object year) {
    return '© $year All rights reserved.';
  }

  @override
  String get settingsAboutCreator => 'Cronicle is created by Sevaaru.';

  @override
  String get settingsWearTitle => 'Watch (Wear OS)';

  @override
  String get settingsWearConnected => 'Watch connected';

  @override
  String get settingsWearCompanionInstalled => 'Companion app installed';

  @override
  String get settingsWearNoCompanion =>
      'A watch is paired but the Cronicle companion app isn\'t installed on it.';

  @override
  String get settingsWearNoWatch =>
      'Got a Wear OS watch? Install the Cronicle companion app to view and update your progress from your wrist.';

  @override
  String get settingsWearOpenPlayStore => 'Open Google Play';

  @override
  String get settingsWearRefresh => 'Check again';

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
  String get errorAnilistRateLimit =>
      'AniList rate-limited the requests. Try again in a few seconds.';

  @override
  String errorAnilistRateLimitWithSeconds(int seconds) {
    return 'AniList rate-limited the requests. Try again in ${seconds}s.';
  }

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
  String get never => 'Never';

  @override
  String googleLastSyncLine(Object when) {
    return 'Last sync: $when';
  }

  @override
  String get backupSaveFileDialogTitle => 'Save backup file';

  @override
  String get connectedWithGoogle => 'Connected with Google';

  @override
  String get googleDrivePermissionMissing =>
      'Google account is signed in, but Drive backup access was not granted. Try again and accept access to app data in Drive.';

  @override
  String get googleSignInCanceledTitle => 'Google could not finish sign-in';

  @override
  String get googleSignInCanceledBody =>
      'Something went wrong with Google sign-in. Please try again later.';

  @override
  String get googleSignInNotConfiguredTitle =>
      'Google is not configured in this build';

  @override
  String get googleSignInNotConfiguredHint =>
      'Google Drive backup is not enabled in this version of the app.';

  @override
  String get googleSignInNotConfiguredBody =>
      'This build is missing Google sign-in settings for Drive backup. If you compile Cronicle yourself, see guide/CRONICLE_GUIDE.md for the required environment variables (dart_defines / Google Cloud).';

  @override
  String get backupTitle => 'Local backup';

  @override
  String get backupUpload => 'Upload';

  @override
  String get backupExportButton => 'Save backup';

  @override
  String get backupRestore => 'Restore';

  @override
  String get backupUploadSuccess => 'Backup uploaded successfully';

  @override
  String backupAnilistMergeFailed(Object error) {
    return 'Could not sync with Anilist first; saved what is on this device. $error';
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
      'Up to once a day when online, only while you stay signed in with Google in Accounts.';

  @override
  String get backupSectionSubtitle =>
      'Save your library and preferences to a file.';

  @override
  String get backupRestoreChooseSourceTitle => 'Backup source';

  @override
  String get backupRestoreChooseSourceBody =>
      'Restore from a saved file on this device or from Google Drive?';

  @override
  String get backupRestoreFromFile => 'File…';

  @override
  String get backupRestoreFromDrive => 'Google Drive';

  @override
  String get backupRestoreConfirmTitle => 'Restore backup';

  @override
  String backupRestoreConfirmBody(Object count) {
    return 'This will merge $count library items. Preferences and linked accounts from the backup are applied when present.';
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
  String get notifPermissionDeniedHint =>
      'You can enable notifications anytime from Settings.';

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
      'You need an Anilist account. How often the device checks in the background is decided by the system.';

  @override
  String get settingsNotificationsUnavailableWeb =>
      'System notifications are not available in the web version.';

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
      'When off, fewer social alerts from Anilist are shown on the device.';

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
  String notificationAiringHeadlineAnime(Object title, int episode) {
    return '$title · Episode $episode';
  }

  @override
  String notificationAiringHeadlineManga(Object title, int episode) {
    return '$title · Chapter $episode';
  }

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
  String get feedBrowseTrending => 'Trending';

  @override
  String get feedBrowseTopRated => 'Top rated';

  @override
  String get feedBrowseUpcoming => 'Upcoming';

  @override
  String get feedBrowseRecentlyReleased => 'Recently released';

  @override
  String get feedBrowseEmpty => 'No titles in this list.';

  @override
  String get feedSummary => 'Discover';

  @override
  String get summaryTrendingAnime => 'Trending Anime';

  @override
  String get summaryTrendingManga => 'Trending Manga';

  @override
  String get summaryTrendingMovies => 'Trending Movies';

  @override
  String get summaryTrendingShows => 'Trending Shows';

  @override
  String get summaryPopularGames => 'Popular Games';

  @override
  String get summaryTrendingBooks => 'Trending Books';

  @override
  String get summaryNewBooks => 'New Releases';

  @override
  String get summaryTopAnime => 'Top Rated Anime';

  @override
  String get summaryTopManga => 'Top Rated Manga';

  @override
  String get summaryAnticipatedMovies => 'Most Anticipated Movies';

  @override
  String get summaryAnticipatedShows => 'Most Anticipated Shows';

  @override
  String get summaryAnticipatedGames => 'Most Anticipated Games';

  @override
  String get summaryRandom => 'Discover something new';

  @override
  String get summaryRandomButton => 'Random pick';

  @override
  String get summaryRandomSub => 'Try something from your interests';

  @override
  String get summarySeeAll => 'See all';

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
  String get filterBooks => 'Books';

  @override
  String get filterAll => 'All';

  @override
  String get filterStatus => 'Status';

  @override
  String get loginRequiredFollowing =>
      'Sign in with Anilist to see activity from people you follow';

  @override
  String get loginRequiredLike => 'Sign in with Anilist to like';

  @override
  String get loginRequiredComment => 'Sign in with Anilist to comment';

  @override
  String get loginRequiredFavorite =>
      'Sign in with Anilist in Settings to use favourites';

  @override
  String get sectionFavGames => 'Favourite games';

  @override
  String get sectionFavBooks => 'Favourite books';

  @override
  String get sectionFavCharacters => 'Favourite characters';

  @override
  String get sectionFavStaff => 'Favourite staff';

  @override
  String get loginRequiredFavoriteCharacter =>
      'Sign in with Anilist in Settings to favourite characters';

  @override
  String get loginRequiredFavoriteStaff =>
      'Sign in with Anilist in Settings to favourite staff';

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
  String searchShowMoreInCategory(Object category) {
    return 'Show more — $category';
  }

  @override
  String get searchIdleAllTitle => 'Search everywhere';

  @override
  String get searchIdleAllBody =>
      'Type something to search all categories at once, or select a category above to browse and search only in that section.';

  @override
  String get searchBrowsePopularityAllTime => 'By popularity';

  @override
  String get searchBrowseByStartDate => 'By release date';

  @override
  String get searchBrowseByGenre => 'By genre';

  @override
  String get searchBrowseGenresAnime => 'Anime genres';

  @override
  String get searchBrowseGenresManga => 'Manga genres';

  @override
  String get searchBrowseGameThemes => 'By theme';

  @override
  String get searchBrowseBookSubjects => 'Topics';

  @override
  String get searchReleaseDateHint =>
      'Pick a year, then optionally a month to narrow results.';

  @override
  String get searchReleaseDateYear => 'Year';

  @override
  String get searchReleaseDateMonth => 'Month';

  @override
  String get searchReleaseDateAllMonths => 'Whole year';

  @override
  String get searchReleaseDateEmpty => 'No results for this period.';

  @override
  String get searchOlSubjectFantasy => 'Fantasy';

  @override
  String get searchOlSubjectRomance => 'Romance';

  @override
  String get searchOlSubjectScienceFiction => 'Science fiction';

  @override
  String get searchOlSubjectHorror => 'Horror';

  @override
  String get searchOlSubjectMystery => 'Mystery';

  @override
  String get searchOlSubjectFiction => 'Fiction';

  @override
  String get searchOlSubjectHistory => 'History';

  @override
  String get searchOlSubjectBiography => 'Biography';

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
  String get profilePersonalStatsTitle => 'Personal stats';

  @override
  String get profilePersonalStatsSubtitle =>
      'Anime, manga, movies, TV and games on this device';

  @override
  String get sectionProfileLocalGames => 'Games (this device)';

  @override
  String get profileLocalGamesHoursTotal => 'Hours logged';

  @override
  String get profileLocalGamesEmpty => 'No games in your local library yet.';

  @override
  String get profileLocalUser => 'Local user';

  @override
  String get profileFavoritesSectionTitle => 'Favorites';

  @override
  String get profileConnectHint =>
      'Connect AniList and Trakt in Settings to see your full statistics';

  @override
  String get profileLocalLibrary => 'Local library';

  @override
  String get profileLibraryEmpty => 'Your library is empty';

  @override
  String get profileNotFound => 'User not found';

  @override
  String get anilistProfileFollowers => 'Followers';

  @override
  String get anilistProfileFollowing => 'Following';

  @override
  String get anilistFollowListEmpty => 'No one here yet.';

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
  String get profileSectionTrakt => 'Movies & TV (Trakt)';

  @override
  String get profileTraktMoviesWatched => 'Movies watched';

  @override
  String get profileTraktShowsWatched => 'Shows watched';

  @override
  String get profileTraktEpisodesWatched => 'Episodes watched';

  @override
  String get profileTraktHoursApprox => 'Hours watched (approx.)';

  @override
  String get sectionFavTraktMovies => 'Favourite movies';

  @override
  String get sectionFavTraktShows => 'Favourite shows';

  @override
  String get profileTraktNotConnected => 'Not connected';

  @override
  String get profileTraktSubMovies => 'Movies';

  @override
  String get profileTraktSubShows => 'Shows';

  @override
  String get profileTraktSubEpisodes => 'Episodes';

  @override
  String get profileTraktSubSeasons => 'Seasons';

  @override
  String get profileTraktSubNetwork => 'Network';

  @override
  String get statTraktPlays => 'Plays';

  @override
  String get statTraktWatched => 'Watched';

  @override
  String get statTraktCollected => 'Collected';

  @override
  String get statTraktRatings => 'Ratings';

  @override
  String get statTraktComments => 'Comments';

  @override
  String get statTraktWatchTimeHrs => 'Watch time (h)';

  @override
  String get statTraktFriends => 'Friends';

  @override
  String get statTraktFollowers => 'Followers';

  @override
  String get statTraktFollowing => 'Following';

  @override
  String get profileTraktRatingsTotal => 'Ratings (all types)';

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
  String get mediaCharacters => 'Characters';

  @override
  String get mediaStaff => 'Staff';

  @override
  String get mediaViewAll => 'View all';

  @override
  String get characterRoleMain => 'Main';

  @override
  String get characterRoleSupporting => 'Supporting';

  @override
  String get characterRoleBackground => 'Background';

  @override
  String get characterVoiceActors => 'Voice actors';

  @override
  String get characterAppearances => 'Appearances';

  @override
  String get characterDescription => 'Description';

  @override
  String get staffRoles => 'Staff roles';

  @override
  String get staffCharacterRoles => 'Character roles';

  @override
  String get staffOccupations => 'Occupations';

  @override
  String get staffYearsActive => 'Years active';

  @override
  String get staffHomeTown => 'Home town';

  @override
  String get staffBloodType => 'Blood type';

  @override
  String get staffDateOfBirth => 'Date of birth';

  @override
  String get staffDateOfDeath => 'Date of death';

  @override
  String get staffAge => 'Age';

  @override
  String get staffGender => 'Gender';

  @override
  String get characterAge => 'Age';

  @override
  String get characterGender => 'Gender';

  @override
  String get characterDateOfBirth => 'Date of birth';

  @override
  String get characterBloodType => 'Blood type';

  @override
  String get characterAlternativeNames => 'Alternative names';

  @override
  String get characterAlternativeSpoiler => 'Spoiler names';

  @override
  String get mediaScoreDistribution => 'Score distribution';

  @override
  String get mediaReviews => 'Reviews';

  @override
  String get mediaNoData => 'No data found';

  @override
  String get mediaAnonymous => 'Anonymous';

  @override
  String get mediaDetailChipsShowMore => 'Show more';

  @override
  String get mediaDetailChipsShowLess => 'Show less';

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
  String get traktSectionMostPlayed => 'Most Played';

  @override
  String get traktSectionMostWatched => 'Most Watched';

  @override
  String get traktSectionMostCollected => 'Most Collected';

  @override
  String get traktSectionAnticipatedShows => 'Most Anticipated Shows';

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
      'Trakt sign-in is not available in this build.';

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
      'Anilist for anime and manga, Trakt for films and TV, optional Google for cloud backup. Games stay on this device.';

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
      'Optional: keep the same backup in Google Drive (upload from here or daily automatic copy).';

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
  String get anilistStep2Bridge =>
      'After you approve, copy the long access token from the Cronicle page shown in the browser.';

  @override
  String get anilistStep3Bridge => 'Paste it below and tap Connect.';

  @override
  String get anilistOAuthWebUnavailable =>
      'Anilist sign-in from the web build isn’t supported. Use the mobile or desktop app.';

  @override
  String get anilistOAuthTimeout =>
      'Anilist authorization timed out. Try again.';

  @override
  String get anilistOAuthLaunchFailed => 'Could not open the browser.';

  @override
  String get anilistBridgeNotConfigured =>
      'Set ANILIST_REDIRECT_URI to your HTTPS page (anilist_oauth_bridge.html) and register the same URL in Anilist → Developer for automatic login on phones.';

  @override
  String get cancel => 'Cancel';

  @override
  String get connect => 'Connect';

  @override
  String get settingsDefaultFilter => 'Default library filter';

  @override
  String get settingsDefaultFilterDesc =>
      'The library opens with this filter selected.';

  @override
  String get settingsDefaultsTitle => 'Default screen and tab';

  @override
  String get settingsDefaultsDesc =>
      'Choose the first screen and tab when you open the app.';

  @override
  String get settingsStartPage => 'Start page';

  @override
  String get settingsStartFeed => 'Home';

  @override
  String get settingsStartLibrary => 'Library';

  @override
  String get settingsFeedTab => 'Default home tab';

  @override
  String get settingsFeedActivityScope => 'Default feed view';

  @override
  String get settingsAppearanceTitle => 'Appearance';

  @override
  String get settingsAppearanceSubtitle =>
      'Theme, language, and the tab bars on Home and Library.';

  @override
  String get settingsLayoutCustomizationTitle => 'Home & library bars';

  @override
  String get settingsLayoutCustomizationSubtitle =>
      'Choose which tabs show and their order.';

  @override
  String get settingsCustomizeFeedFilters => 'Feed filter bar';

  @override
  String get settingsCustomizeFeedFiltersDesc =>
      'Show, hide, or reorder feed tabs. At least one must stay visible.';

  @override
  String get settingsCustomizeLibraryKinds => 'Library type bar';

  @override
  String get settingsCustomizeLibraryKindsDesc =>
      'Show, hide, or reorder library types. At least one must stay visible.';

  @override
  String get settingsLayoutDragHint =>
      'Long-press the handle, then drag to reorder.';

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
  String get mediaKindBook => 'Books';

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
  String get statusCurrentBook => 'Reading';

  @override
  String get statusReplayingGame => 'Replaying';

  @override
  String get statusRereadingBook => 'Rereading';

  @override
  String get searchTrendingGames => 'Trending games';

  @override
  String get searchTrendingBooks => 'Trending books';

  @override
  String get igdbWebNotSupported =>
      'IGDB cannot call the API from the browser (no CORS). Use Android or desktop, or run node scripts/dev_api_proxy.mjs and set DEV_API_PROXY in your dart-defines (see dart_defines.example.json).';

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
  String get gameDetailStatUserScore => 'User score';

  @override
  String get gameDetailStatCriticScore => 'Critics (IGDB)';

  @override
  String gameDetailStatRatingsCount(Object count) {
    return '$count ratings';
  }

  @override
  String gameDetailStatCriticReviewsCount(Object count) {
    return '$count reviews';
  }

  @override
  String get gameDetailSimilarGames => 'Similar games';

  @override
  String get gameDetailNoData => 'No game data found';

  @override
  String get gameDetailCompanies => 'Companies';

  @override
  String get addToListHoursPlayed => 'Hours played';

  @override
  String get addToListPagesRead => 'Pages read';

  @override
  String libraryPagesRemaining(Object count) {
    return '$count pages left';
  }

  @override
  String libraryChaptersRemaining(Object count) {
    return '$count chapters left';
  }

  @override
  String libraryAnimeAiringBehind(Object count) {
    return '$count behind';
  }

  @override
  String bookProgressPageOf(Object current, Object total, Object pct) {
    return 'Page $current of $total ($pct%)';
  }

  @override
  String bookProgressPageSimple(Object current) {
    return 'Page $current';
  }

  @override
  String bookProgressChapterOf(Object current, Object total, Object pct) {
    return 'Chapter $current of $total ($pct%)';
  }

  @override
  String bookProgressChapterSimple(Object current) {
    return 'Chapter $current';
  }

  @override
  String bookPercentRemaining(Object count) {
    return '$count% left';
  }

  @override
  String bookLibraryProgressChaptersShort(Object current, Object total) {
    return '$current/$total ch';
  }

  @override
  String bookLibraryProgressChapterOnly(Object current) {
    return '$current ch';
  }

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
  String get gamesHomeBestRated => 'Top rated';

  @override
  String get gamesHomeIndiePicks => 'Indie spotlight';

  @override
  String get gamesHomeHorrorPicks => 'Horror';

  @override
  String get gamesHomeMultiplayer => 'Multiplayer';

  @override
  String get gamesHomeRpgSpotlight => 'RPG spotlight';

  @override
  String get gamesHomeSportsSpotlight => 'Sports picks';

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
  String get gameDetailOpenCriticSection => 'Critic reviews (OpenCritic)';

  @override
  String gameDetailOpenCriticMeta(Object score, Object count) {
    return 'Top critic score: $score · $count reviews';
  }

  @override
  String get gameDetailOpenCriticNoMatch =>
      'No OpenCritic match for this title.';

  @override
  String get gameDetailOpenCriticReadReview => 'Read review';

  @override
  String get gameDetailOpenCriticOpenSite => 'Open on OpenCritic';

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

  @override
  String get bookDetailSubjects => 'Subjects';

  @override
  String get bookDetailAuthors => 'Authors';

  @override
  String get bookDetailPublishDate => 'First published';

  @override
  String bookDetailPages(Object count) {
    return '$count pages';
  }

  @override
  String get bookDetailDescription => 'Description';

  @override
  String get bookDetailNoData => 'No book data found';

  @override
  String get bookDetailOpenOnGoogleBooks => 'Open on Google Books';

  @override
  String get bookDetailEditions => 'Editions';

  @override
  String get bookDetailPublisher => 'Publisher';

  @override
  String get bookDetailLanguage => 'Language';

  @override
  String get bookDetailPrintType => 'Type';

  @override
  String get bookDetailMaturity => 'Maturity';

  @override
  String get bookDetailPreview => 'Preview';

  @override
  String get bookDetailFormats => 'Formats';

  @override
  String get bookDetailAvailability => 'Availability';

  @override
  String get bookDetailIdentifiers => 'Identifiers';

  @override
  String get bookActionPreview => 'Preview';

  @override
  String get bookActionReadOnline => 'Read online';

  @override
  String get bookActionBuy => 'Buy';

  @override
  String get bookActionReviews => 'Reviews';

  @override
  String get booksHomePopularNow => 'Popular now';

  @override
  String get booksHomeNewReleases => 'New releases';

  @override
  String get booksHomeTrending => 'Trending';

  @override
  String get booksHomeClassics => 'Classics';

  @override
  String get booksHomeMystery => 'Mystery';

  @override
  String get onboardingWelcomeTitle => 'Welcome to Cronicle';

  @override
  String get onboardingWelcomeBody =>
      'Track your anime, manga, movies, TV shows, games and books all in one place. Organize your lists, log your progress and keep everything synced across your favorite services.';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingTitle => 'What are you into?';

  @override
  String get onboardingSubtitle =>
      'Pick at least one category to personalize your experience';

  @override
  String get onboardingContinue => 'Continue';

  @override
  String get onboardingInterestAnime => 'Anime';

  @override
  String get onboardingInterestManga => 'Manga';

  @override
  String get onboardingInterestMovies => 'Movies';

  @override
  String get onboardingInterestTv => 'TV Shows';

  @override
  String get onboardingInterestGames => 'Games';

  @override
  String get onboardingInterestBooks => 'Books';

  @override
  String get onboardingAccountsTitle => 'Connect your accounts';

  @override
  String get onboardingAccountsSubtitle =>
      'Signing in is recommended to keep your data synced in the cloud. Google syncs all data and connected accounts.';

  @override
  String get onboardingConnectAnilist => 'Connect Anilist';

  @override
  String get onboardingConnectAnilistDesc => 'Sync your anime and manga lists';

  @override
  String get onboardingConnectTrakt => 'Connect Trakt';

  @override
  String get onboardingConnectTraktDesc => 'Sync your movies and TV shows';

  @override
  String get onboardingConnectGoogle => 'Sign in with Google';

  @override
  String get onboardingConnectGoogleDesc =>
      'Cloud backup of all your data and accounts';

  @override
  String get onboardingSkip => 'Use without accounts';

  @override
  String get onboardingFinish => 'Finish setup';

  @override
  String get onboardingConnected => 'Connected';

  @override
  String get onboardingAccountSynced => 'Synced';

  @override
  String get onboardingSyncing => 'Syncing your data…';

  @override
  String get settingsCustomizeSearchFilters => 'Search filters';

  @override
  String get settingsCustomizeSearchFiltersDesc =>
      'Reorder or hide filters in the search tab';

  @override
  String get settingsInterests => 'Your interests';

  @override
  String get settingsInterestsDesc =>
      'Change the content you see in home, library, and search';

  @override
  String get settingsInterestsChanged => 'Interests updated';

  @override
  String get socialTitle => 'Social';

  @override
  String get settingsScoringTitle => 'Scoring system';

  @override
  String get settingsScoringDesc =>
      'Changes how scores are displayed and entered across the app. Syncs automatically with your AniList account';

  @override
  String get scoringPoint100 => '100 Point';

  @override
  String get scoringPoint10Decimal => '10 Point Decimal';

  @override
  String get scoringPoint10 => '10 Point';

  @override
  String get scoringPoint5 => '5 Star';

  @override
  String get scoringPoint3 => '3 Point Smiley';

  @override
  String get settingsAdvancedScoring => 'Advanced scoring (Anilist)';

  @override
  String get settingsAdvancedScoringDesc =>
      'Score by category: story, characters, visuals, audio, and enjoyment';

  @override
  String get advScoringStory => 'Story';

  @override
  String get advScoringCharacters => 'Characters';

  @override
  String get advScoringVisuals => 'Visuals';

  @override
  String get advScoringAudio => 'Audio';

  @override
  String get advScoringEnjoyment => 'Enjoyment';

  @override
  String get advScoringReset => 'Reset';

  @override
  String get mediaStatusFinished => 'Finished';

  @override
  String get mediaStatusReleasing => 'Releasing';

  @override
  String get mediaStatusNotYetReleased => 'Not Yet Released';

  @override
  String get mediaStatusCancelled => 'Cancelled';

  @override
  String get mediaStatusHiatus => 'On Hiatus';

  @override
  String get forumDiscussions => 'Forum discussions';

  @override
  String get forumViewAll => 'View more';

  @override
  String get forumThread => 'Forum thread';

  @override
  String forumReplies(int count) {
    return '$count replies';
  }

  @override
  String get forumNoReplies => 'No replies yet';

  @override
  String get forumReplyButton => 'Reply';

  @override
  String forumReplyingTo(String name) {
    return 'Replying to @$name';
  }

  @override
  String get socialFeedTab => 'Feed';

  @override
  String get socialForumTab => 'Forum';

  @override
  String get forumPinnedThreads => 'Pinned threads';

  @override
  String get forumRecentlyReplied => 'Recently active';

  @override
  String get forumNewlyCreated => 'Newly created';

  @override
  String get forumReleaseDiscussions => 'Release discussions';

  @override
  String get bookTrackingModeLabel => 'Tracking mode';

  @override
  String get bookTrackingModePages => 'Pages';

  @override
  String get bookTrackingModePercent => '%';

  @override
  String get bookTrackingModeChapters => 'Chapters';

  @override
  String get bookPercentageRead => 'Percentage read';

  @override
  String get bookChapterProgress => 'Current chapter';

  @override
  String get bookOverrideTotalsLabel => 'Set your own totals';

  @override
  String get bookOverrideTotalsHint =>
      'Your override has priority over API values.';

  @override
  String get bookTotalPagesOverride => 'Total pages';

  @override
  String get bookTotalChaptersOverride => 'Total chapters';

  @override
  String get bookReadingProgress => 'Reading progress';

  @override
  String get bookEditionLabel => 'Edition';

  @override
  String get bookEditionUnknownPages => 'Unknown page count';

  @override
  String get bookEditionNoPageHint =>
      'If no page count is available, you can set your own total manually.';
}
