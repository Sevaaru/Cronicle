abstract final class DeviceNotificationPrefs {
  static const permissionPrompted = 'notif_permission_prompted';

  static const masterEnabled = 'dev_notif_master';

  static const airingEnabled = 'dev_notif_airing';

  static const anilistInboxEnabled = 'dev_notif_anilist';

  static const anilistSocialEnabled = 'dev_notif_anilist_social';

  static const anilistBackfillDone = 'dev_notif_anilist_backfill_done';

  static const anilistSeenIdsJson = 'dev_notif_anilist_seen_ids_json';

  static String airingDedupeKey(int mediaId, int episode) =>
      'dev_airing_shown_${mediaId}_$episode';
}
