import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';


abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  String get appTitle;

  String get navHome;

  String get navLibrary;

  String get navSearch;

  String get navProfile;

  String get navSocial;

  String get navSettings;

  String get navAnime;

  String get navManga;

  String get navMovies;

  String get navTv;

  String get navGames;

  String get navAuth;

  String get homeSubtitle;

  String get settingsTitle;

  String get settingsAboutApp;

  String settingsAboutCopyright(Object year);

  String get settingsAboutCreator;

  String get settingsWearTitle;

  String get settingsWearConnected;

  String get settingsWearCompanionInstalled;

  String get settingsWearNoCompanion;

  String get settingsWearNoWatch;

  String get settingsWearOpenPlayStore;

  String get settingsWearRefresh;

  String get themeMode;

  String get themeSystem;

  String get themeLight;

  String get themeDark;

  String get language;

  String get placeholderSoon;

  String get errorGeneric;

  String get errorNetwork;

  String get errorAnilistRateLimit;

  String errorAnilistRateLimitWithSeconds(int seconds);

  String errorWithMessage(Object message);

  String get errorVerifyingSession;

  String get errorVerifyingToken;

  String get errorLoadingProfile;

  String errorSyncMessage(Object message);

  String get googleSignIn;

  String get googleSignOut;

  String get googleSyncNow;

  String get never;

  String googleLastSyncLine(Object when);

  String get backupSaveFileDialogTitle;

  String get connectedWithGoogle;

  String get googleDrivePermissionMissing;

  String get googleSignInCanceledTitle;

  String get googleSignInCanceledBody;

  String get googleSignInNotConfiguredTitle;

  String get googleSignInNotConfiguredHint;

  String get googleSignInNotConfiguredBody;

  String get backupTitle;

  String get backupUpload;

  String get backupExportButton;

  String get backupRestore;

  String get backupUploadSuccess;

  String backupAnilistMergeFailed(Object error);

  String get backupExportReady;

  String get backupRestored;

  String backupRestoredCount(Object count);

  String get backupAutoGoogleTitle;

  String get backupAutoGoogleSubtitle;

  String get backupSectionSubtitle;

  String get backupRestoreChooseSourceTitle;

  String get backupRestoreChooseSourceBody;

  String get backupRestoreFromFile;

  String get backupRestoreFromDrive;

  String get backupRestoreConfirmTitle;

  String backupRestoreConfirmBody(Object count);

  String get feedTitle;

  String get notificationsTitle;

  String get notificationsEmpty;

  String get notificationsLoginRequired;

  String get notifPermissionDeniedHint;

  String get gallerySaveUnavailableWeb;

  String get gallerySaveSuccess;

  String get gallerySaveErrorGeneric;

  String get gallerySavePermissionDenied;

  String get gallerySaveOpenSettings;

  String get settingsNotificationsTitle;

  String get settingsNotificationsSubtitle;

  String get settingsNotificationsUnavailableWeb;

  String get settingsNotifMaster;

  String get settingsNotifAiring;

  String get settingsNotifAnilistInbox;

  String get settingsNotifAnilistSocial;

  String get settingsNotifAnilistSocialDesc;

  String get notificationNoLink;

  String get notificationTypeGeneric;

  String get notificationTypeAiring;

  String get notificationTypeActivityReply;

  String get notificationTypeActivityMention;

  String get notificationTypeActivityMessage;

  String get notificationTypeFollowing;

  String get notificationTypeRelatedMedia;

  String get notificationTypeMediaDataChange;

  String get notificationTypeMediaMerge;

  String get notificationTypeMediaDeletion;

  String get notificationTypeThreadReply;

  String get notificationTypeThreadMention;

  String get notificationTypeThreadSubscribed;

  String get notificationTypeThreadLike;

  String get notificationTypeActivityLike;

  String get notificationTypeActivityReplyLike;

  String get notificationTypeActivityReplySubscribed;

  String get notificationTypeThreadCommentLike;

  String get notificationTypeMediaSubmission;

  String get notificationTypeStaffSubmission;

  String get notificationTypeCharacterSubmission;

  String notificationAiringHeadlineAnime(Object title, int episode);

  String notificationAiringHeadlineManga(Object title, int episode);

  String get feedEmpty;

  String get feedRetry;

  String feedComingSoon(Object label);

  String get feedBrowseActivity;

  String get feedBrowseSeasonal;

  String get feedBrowseTrending;

  String get feedBrowseTopRated;

  String get feedBrowseUpcoming;

  String get feedBrowseRecentlyReleased;

  String get feedBrowseEmpty;

  String get feedSummary;

  String get summaryTrendingAnime;

  String get summaryTrendingManga;

  String get summaryTrendingMovies;

  String get summaryTrendingShows;

  String get summaryPopularGames;

  String get summaryTrendingBooks;

  String get summaryNewBooks;

  String get summaryTopAnime;

  String get summaryTopManga;

  String get summaryAnticipatedMovies;

  String get summaryAnticipatedShows;

  String get summaryAnticipatedGames;

  String get summaryRandom;

  String get summaryRandomButton;

  String get summaryRandomSub;

  String get summarySeeAll;

  String get filterFollowing;

  String get filterGlobal;

  String get filterFeed;

  String get filterAnime;

  String get filterManga;

  String get filterMovies;

  String get filterTv;

  String get filterGames;

  String get filterBooks;

  String get filterAll;

  String get filterStatus;

  String get loginRequiredFollowing;

  String get loginRequiredLike;

  String get loginRequiredComment;

  String get loginRequiredFavorite;

  String get sectionFavGames;

  String get sectionFavBooks;

  String get sectionFavCharacters;

  String get sectionFavStaff;

  String get loginRequiredFavoriteCharacter;

  String get loginRequiredFavoriteStaff;

  String get tooltipAddFavorite;

  String get tooltipRemoveFavorite;

  String get loginRequiredFollow;

  String get goToSettings;

  String get timeNow;

  String timeMinutes(Object count);

  String timeHours(Object count);

  String timeDays(Object count);

  String timeWeeks(Object count);

  String get libraryTitle;

  String get libraryEmpty;

  String get libraryAddHint;

  String get libraryNoResults;

  String get libraryNoStatusResults;

  String get librarySearchAndAdd;

  String get librarySearchTitle;

  String get librarySearchHint;

  String get librarySearchPrompt;

  String get librarySearchGlobalResults;

  String get statusAll;

  String get statusCurrent;

  String get statusCurrentAnime;

  String get statusCurrentManga;

  String get statusPlanning;

  String get statusCompleted;

  String get statusPaused;

  String get statusDropped;

  String get statusRepeating;

  String get sortRecent;

  String get sortName;

  String get sortScore;

  String get sortProgress;

  String get tooltipCompleted;

  String get tooltipIncrementProgress;

  String get searchTitle;

  String get searchHint;

  String get searchTrendingAnime;

  String get searchTrendingManga;

  String searchComingSoon(Object label);

  String get searchComingSoonApi;

  String get searchSelectFilter;

  String searchErrorIn(Object section, Object error);

  String searchShowMoreInCategory(Object category);

  String get searchIdleAllTitle;

  String get searchIdleAllBody;

  String get searchBrowsePopularityAllTime;

  String get searchBrowseByStartDate;

  String get searchBrowseByGenre;

  String get searchBrowseGenresAnime;

  String get searchBrowseGenresManga;

  String get searchBrowseGameThemes;

  String get searchBrowseBookSubjects;

  String get searchReleaseDateHint;

  String get searchReleaseDateYear;

  String get searchReleaseDateMonth;

  String get searchReleaseDateAllMonths;

  String get searchReleaseDateEmpty;

  String get searchOlSubjectFantasy;

  String get searchOlSubjectRomance;

  String get searchOlSubjectScienceFiction;

  String get searchOlSubjectHorror;

  String get searchOlSubjectMystery;

  String get searchOlSubjectFiction;

  String get searchOlSubjectHistory;

  String get searchOlSubjectBiography;

  String get addToLibrary;

  String get editLibraryEntry;

  String get addedToLibrary;

  String get entryUpdated;

  String get removeFromLibrary;

  String get removedFromLibrary;

  String get profileTitle;

  String get profilePersonalStatsTitle;

  String get profilePersonalStatsSubtitle;

  String get sectionProfileLocalGames;

  String get profileLocalGamesHoursTotal;

  String get profileLocalGamesEmpty;

  String get profileLocalUser;

  String get profileFavoritesSectionTitle;

  String get profileConnectHint;

  String get profileLocalLibrary;

  String get profileLibraryEmpty;

  String get profileNotFound;

  String get anilistProfileFollowers;

  String get anilistProfileFollowing;

  String get anilistFollowListEmpty;

  String get sectionAnime;

  String get sectionManga;

  String get sectionFavAnime;

  String get sectionFavManga;

  String get sectionRecentActivity;

  String get sectionConnectedAccounts;

  String get profileSectionTrakt;

  String get profileTraktMoviesWatched;

  String get profileTraktShowsWatched;

  String get profileTraktEpisodesWatched;

  String get profileTraktHoursApprox;

  String get sectionFavTraktMovies;

  String get sectionFavTraktShows;

  String get profileTraktNotConnected;

  String get profileTraktSubMovies;

  String get profileTraktSubShows;

  String get profileTraktSubEpisodes;

  String get profileTraktSubSeasons;

  String get profileTraktSubNetwork;

  String get statTraktPlays;

  String get statTraktWatched;

  String get statTraktCollected;

  String get statTraktRatings;

  String get statTraktComments;

  String get statTraktWatchTimeHrs;

  String get statTraktFriends;

  String get statTraktFollowers;

  String get statTraktFollowing;

  String get profileTraktRatingsTotal;

  String get sectionTopGenresAnime;

  String get sectionTopGenresManga;

  String get statTitles;

  String get statEpisodes;

  String get statChapters;

  String get statVolumes;

  String get statDaysWatching;

  String get statDays;

  String get statMeanScore;

  String get statPopularity;

  String get statFavourites;

  String get mediaInfo;

  String get mediaSynopsis;

  String get mediaEpisodes;

  String get mediaChapters;

  String get mediaVolumes;

  String get mediaDuration;

  String get mediaSeason;

  String get mediaSource;

  String get mediaStart;

  String get mediaEnd;

  String get mediaStudio;

  String get mediaWhere;

  String get mediaRelated;

  String get mediaRecommendations;

  String get mediaCharacters;

  String get mediaStaff;

  String get mediaViewAll;

  String get characterRoleMain;

  String get characterRoleSupporting;

  String get characterRoleBackground;

  String get characterVoiceActors;

  String get characterAppearances;

  String get characterDescription;

  String get staffRoles;

  String get staffCharacterRoles;

  String get staffOccupations;

  String get staffYearsActive;

  String get staffHomeTown;

  String get staffBloodType;

  String get staffDateOfBirth;

  String get staffDateOfDeath;

  String get staffAge;

  String get staffGender;

  String get characterAge;

  String get characterGender;

  String get characterDateOfBirth;

  String get characterBloodType;

  String get characterAlternativeNames;

  String get characterAlternativeSpoiler;

  String get mediaScoreDistribution;

  String get mediaReviews;

  String get mediaNoData;

  String get mediaAnonymous;

  String get mediaDetailChipsShowMore;

  String get mediaDetailChipsShowLess;

  String get mediaGenresSection;

  String get mediaTagsSection;

  String get mediaBrowseSortScore;

  String get mediaBrowseSortPopularity;

  String get mediaBrowseSortName;

  String get mediaBrowseInvalidParams;

  String mediaNextEp(Object episode, Object days, Object hours);

  String get addToListTitle;

  String get addToListStatus;

  String get addToListScore;

  String get addToListNoScore;

  String get addToListEpisodes;

  String get addToListChapters;

  String addToListOf(Object total);

  String get addToListMax;

  String get addToListNotes;

  String get addToListNotesHint;

  String get addToListSave;

  String get addToListMovieProgress;

  String get traktNotConfiguredHint;

  String get traktSectionTrending;

  String get traktSectionWatchingNow;

  String get traktSectionAnticipatedMovies;

  String get traktSectionPopular;

  String get traktSectionMostPlayed;

  String get traktSectionMostWatched;

  String get traktSectionMostCollected;

  String get traktSectionAnticipatedShows;

  String get traktTitle;

  String get traktSubtitle;

  String traktConnectedAs(Object slug);

  String get traktConnect;

  String get traktDisconnect;

  String get traktConnectSuccess;

  String get traktDisconnected;

  String get traktOAuthMissingCredentials;

  String get traktOAuthWebUnavailable;

  String get traktImportTitle;

  String get traktImportConfirm;

  String get traktImportDesc;

  String traktImportedCount(Object count);

  String get traktDetailLinks;

  String get traktLinkTrailer;

  String get traktLinkHomepage;

  String get traktDetailOnTrakt;

  String get traktEpisodeProgressTitle;

  String get traktEpisodeProgressHint;

  String get traktEpisodeProgressMarkComplete;

  String get traktEpisodeMinusOne;

  String get traktEpisodePlusOne;

  String get traktDetailVotes;

  String get traktDetailLanguage;

  String get traktDetailOriginalTitle;

  String get traktDetailSubgenres;

  String get traktDetailCountry;

  String get traktDetailYear;

  String get traktDetailNetwork;

  String get syncTitle;

  String syncWelcome(Object name);

  String get syncImport;

  String get syncImportDesc;

  String get syncMerge;

  String get syncMergeDesc;

  String get syncNotNow;

  String get syncLoading;

  String syncImportedCount(Object count);

  String get syncPromptTitle;

  String get syncPromptBody;

  String get syncPromptNoThanks;

  String get settingsAccountsTitle;

  String get settingsAccountsSubtitle;

  String get twitchIgdbTitle;

  String get twitchIgdbSubtitle;

  String twitchConnectedAs(Object login);

  String get twitchDisconnectAccount;

  String get twitchConnectOAuth;

  String get twitchConnectSuccess;

  String get twitchDisconnected;

  String get twitchOAuthWebUnavailable;

  String get twitchOAuthMissingSecrets;

  String get twitchRedirectNotConfigured;

  String get twitchRedirectMustBeHttps;

  String get twitchSyncTitle;

  String twitchSyncWelcome(Object name);

  String get twitchGameSyncMerge;

  String get twitchGameSyncMergeDesc;

  String get twitchGameSyncOverwrite;

  String get twitchGameSyncOverwriteDesc;

  String get twitchSyncIgdbApiFootnote;

  String twitchSyncImportedCount(Object count);

  String get twitchSyncImportedZeroWarning;

  String get googleAccountTitle;

  String get googleAccountSubtitle;

  String get anilistTitle;

  String get anilistSubtitle;

  String get anilistConnected;

  String get anilistDisconnected;

  String get anilistConnectSuccess;

  String get anilistConnectTitle;

  String get anilistDisconnect;

  String get anilistConnect;

  String get anilistTokenLabel;

  String get anilistTokenHint;

  String get anilistPasteTooltip;

  String get anilistStep1;

  String get anilistStep2;

  String get anilistStep3;

  String get anilistStep2Bridge;

  String get anilistStep3Bridge;

  String get anilistOAuthWebUnavailable;

  String get anilistOAuthTimeout;

  String get anilistOAuthLaunchFailed;

  String get anilistBridgeNotConfigured;

  String get cancel;

  String get connect;

  String get settingsDefaultFilter;

  String get settingsDefaultFilterDesc;

  String get settingsDefaultsTitle;

  String get settingsDefaultsDesc;

  String get settingsStartPage;

  String get settingsStartFeed;

  String get settingsStartLibrary;

  String get settingsFeedTab;

  String get settingsFeedActivityScope;

  String get settingsAppearanceTitle;

  String get settingsAppearanceSubtitle;

  String get settingsLayoutCustomizationTitle;

  String get settingsLayoutCustomizationSubtitle;

  String get settingsCustomizeFeedFilters;

  String get settingsCustomizeFeedFiltersDesc;

  String get settingsCustomizeLibraryKinds;

  String get settingsCustomizeLibraryKindsDesc;

  String get settingsLayoutDragHint;

  String get settingsLayoutReset;

  String get settingsLayoutResetDone;

  String get settingsLayoutShowInFeed;

  String get settingsLayoutShowInLibrary;

  String get follow;

  String get following;

  String get commentsTitle;

  String get noComments;

  String get activityOriginalPost;

  String get activityRepliesHeading;

  String get activityThreadLoadError;

  String get activityMessageActivity;

  String get comingSoon;

  String get mediaKindAnime;

  String get mediaKindManga;

  String get mediaKindMovie;

  String get mediaKindTv;

  String get mediaKindGame;

  String get mediaKindBook;

  String get reviewTitle;

  String reviewByUser(Object name);

  String get reviewHelpful;

  String get reviewUpVote;

  String get reviewDownVote;

  String get reviewLoginRequired;

  String reviewUsersFoundHelpful(Object count, Object total);

  String get readMore;

  String get writeReplyHint;

  String get composeActivityHint;

  String get composeMarkdownTip;

  String get cancelButton;

  String get postButton;

  String get activityPosted;

  String get settingsHideTextActivities;

  String get settingsHideTextActivitiesDesc;

  String get statusCurrentGame;

  String get statusCurrentBook;

  String get statusReplayingGame;

  String get statusRereadingBook;

  String get searchTrendingGames;

  String get searchTrendingBooks;

  String get igdbWebNotSupported;

  String get twitchConnect;

  String get gameDetailPlatforms;

  String get gameDetailGenres;

  String get gameDetailSynopsis;

  String get gameDetailStoryline;

  String get gameDetailModes;

  String get gameDetailThemes;

  String get gameDetailDeveloper;

  String get gameDetailPublisher;

  String get gameDetailReleaseDate;

  String get gameDetailRating;

  String get gameDetailStatUserScore;

  String get gameDetailStatCriticScore;

  String gameDetailStatRatingsCount(Object count);

  String gameDetailStatCriticReviewsCount(Object count);

  String get gameDetailSimilarGames;

  String get gameDetailNoData;

  String get gameDetailCompanies;

  String get addToListHoursPlayed;

  String get addToListPagesRead;

  String libraryPagesRemaining(Object count);

  String libraryChaptersRemaining(Object count);

  String libraryAnimeAiringBehind(Object count);

  String bookProgressPageOf(Object current, Object total, Object pct);

  String bookProgressPageSimple(Object current);

  String bookProgressChapterOf(Object current, Object total, Object pct);

  String bookProgressChapterSimple(Object current);

  String bookPercentRemaining(Object count);

  String bookLibraryProgressChaptersShort(Object current, Object total);

  String bookLibraryProgressChapterOnly(Object current);

  String get gameDetailLinksSection;

  String gameDetailLinksShowMore(Object remaining);

  String get gameDetailLinksShowLess;

  String get gameDetailLinkOfficialSite;

  String get gameDetailLinkKindPlayStation;

  String get gameDetailLinkKindNintendo;

  String get gameDetailLinkKindApple;

  String get gameDetailLinkKindGooglePlay;

  String get gameDetailLinkKindAmazon;

  String get gameDetailLinkKindOculus;

  String get gameDetailLinkKindGameJolt;

  String get gameDetailLinkKindHumble;

  String get gameDetailLinkKindUbisoft;

  String get gameDetailLinkKindEa;

  String get gameDetailLinkKindRockstar;

  String get gameDetailLinkKindBattlenet;

  String get gameDetailLinkKindTiktok;

  String get gameDetailLinkKindBluesky;

  String get gamesHomePopularNow;

  String get gamesHomeMostAnticipated;

  String get gamesHomeRecentReviews;

  String get gamesHomeCriticsReviews;

  String get gamesHomeRecentlyReleased;

  String get gamesHomeComingSoon;

  String get gamesHomeBestRated;

  String get gamesHomeIndiePicks;

  String get gamesHomeHorrorPicks;

  String get gamesHomeMultiplayer;

  String get gamesHomeRpgSpotlight;

  String get gamesHomeSportsSpotlight;

  String get gamesHomeSectionExpand;

  String get gamesHomeSectionCollapse;

  String get gamesHomeNoItems;

  String get gamesHomeOpenGame;

  String get igdbReviewNotFound;

  String get gameDetailOpenIgdb;

  String get gameDetailTimeToBeatSection;

  String get gameDetailTtbHastily;

  String get gameDetailTtbNormal;

  String get gameDetailTtbComplete;

  String get gameDetailScreenshots;

  String get gameDetailReviewsSection;

  String get gameDetailNoReviews;

  String get gameDetailReviewUntitled;

  String gameDetailReviewBy(Object name);

  String get gameDetailOpenCriticSection;

  String gameDetailOpenCriticMeta(Object score, Object count);

  String get gameDetailOpenCriticNoMatch;

  String get gameDetailOpenCriticReadReview;

  String get gameDetailOpenCriticOpenSite;

  String gameDetailPlaytimeHoursMinutes(Object hours, Object minutes);

  String gameDetailPlaytimeHoursOnly(Object hours);

  String gameDetailPlaytimeMinutesOnly(Object minutes);

  String get gameDetailWebCatOfficial;

  String get gameDetailWebCatWikia;

  String get gameDetailWebCatWikipedia;

  String get gameDetailWebCatFacebook;

  String get gameDetailWebCatTwitter;

  String get gameDetailWebCatTwitch;

  String get gameDetailWebCatInstagram;

  String get gameDetailWebCatYoutube;

  String get gameDetailWebCatSteam;

  String get gameDetailWebCatReddit;

  String get gameDetailWebCatItch;

  String get gameDetailWebCatEpic;

  String get gameDetailWebCatGog;

  String get gameDetailWebCatDiscord;

  String get gameDetailWebCatOther;

  String get gameDetailExtCatSteam;

  String get gameDetailExtCatGog;

  String get gameDetailExtCatMicrosoft;

  String get gameDetailExtCatEpic;

  String get gameDetailExtCatOther;

  String get bookDetailSubjects;

  String get bookDetailAuthors;

  String get bookDetailPublishDate;

  String bookDetailPages(Object count);

  String get bookDetailDescription;

  String get bookDetailNoData;

  String get bookDetailOpenOnGoogleBooks;

  String get bookDetailEditions;

  String get bookDetailPublisher;

  String get bookDetailLanguage;

  String get bookDetailPrintType;

  String get bookDetailMaturity;

  String get bookDetailPreview;

  String get bookDetailFormats;

  String get bookDetailAvailability;

  String get bookDetailIdentifiers;

  String get bookActionPreview;

  String get bookActionReadOnline;

  String get bookActionBuy;

  String get bookActionReviews;

  String get booksHomePopularNow;

  String get booksHomeNewReleases;

  String get booksHomeTrending;

  String get booksHomeClassics;

  String get booksHomeMystery;

  String get onboardingWelcomeTitle;

  String get onboardingWelcomeBody;

  String get onboardingNext;

  String get onboardingTitle;

  String get onboardingSubtitle;

  String get onboardingContinue;

  String get onboardingInterestAnime;

  String get onboardingInterestManga;

  String get onboardingInterestMovies;

  String get onboardingInterestTv;

  String get onboardingInterestGames;

  String get onboardingInterestBooks;

  String get onboardingAccountsTitle;

  String get onboardingAccountsSubtitle;

  String get onboardingConnectAnilist;

  String get onboardingConnectAnilistDesc;

  String get onboardingConnectTrakt;

  String get onboardingConnectTraktDesc;

  String get onboardingConnectGoogle;

  String get onboardingConnectGoogleDesc;

  String get onboardingSkip;

  String get onboardingFinish;

  String get onboardingConnected;

  String get onboardingAccountSynced;

  String get onboardingSyncing;

  String get settingsCustomizeSearchFilters;

  String get settingsCustomizeSearchFiltersDesc;

  String get settingsInterests;

  String get settingsInterestsDesc;

  String get settingsInterestsChanged;

  String get socialTitle;

  String get settingsScoringTitle;

  String get settingsScoringDesc;

  String get scoringPoint100;

  String get scoringPoint10Decimal;

  String get scoringPoint10;

  String get scoringPoint5;

  String get scoringPoint3;

  String get settingsAdvancedScoring;

  String get settingsAdvancedScoringDesc;

  String get advScoringStory;

  String get advScoringCharacters;

  String get advScoringVisuals;

  String get advScoringAudio;

  String get advScoringEnjoyment;

  String get advScoringReset;

  String get mediaStatusFinished;

  String get mediaStatusReleasing;

  String get mediaStatusNotYetReleased;

  String get mediaStatusCancelled;

  String get mediaStatusHiatus;

  String get forumDiscussions;

  String get forumViewAll;

  String get forumThread;

  String forumReplies(int count);

  String get forumNoReplies;

  String get forumReplyButton;

  String forumReplyingTo(String name);

  String get socialFeedTab;

  String get socialForumTab;

  String get forumPinnedThreads;

  String get forumRecentlyReplied;

  String get forumNewlyCreated;

  String get forumReleaseDiscussions;

  String get bookTrackingModeLabel;

  String get bookTrackingModePages;

  String get bookTrackingModePercent;

  String get bookTrackingModeChapters;

  String get bookPercentageRead;

  String get bookChapterProgress;

  String get bookOverrideTotalsLabel;

  String get bookOverrideTotalsHint;

  String get bookTotalPagesOverride;

  String get bookTotalChaptersOverride;

  String get bookReadingProgress;

  String get bookEditionLabel;

  String get bookEditionUnknownPages;

  String get bookEditionNoPageHint;
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
