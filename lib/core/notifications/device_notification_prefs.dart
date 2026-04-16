/// Claves de [SharedPreferences] para notificaciones en el dispositivo.
abstract final class DeviceNotificationPrefs {
  static const permissionPrompted = 'notif_permission_prompted';

  /// Maestro: el usuario quiere notificaciones locales (tras permiso).
  static const masterEnabled = 'dev_notif_master';

  /// Nuevos capítulos (lista CURRENT + medio RELEASING).
  static const airingEnabled = 'dev_notif_airing';

  /// Espejo de la bandeja de Anilist en el sistema.
  static const anilistInboxEnabled = 'dev_notif_anilist';

  /// Dentro de Anilist: incluir actividad/foros/seguimientos (no solo emisiones).
  static const anilistSocialEnabled = 'dev_notif_anilist_social';

  /// Tras el primer fetch de inbox, solo marcamos IDs vistos sin notificar.
  static const anilistBackfillDone = 'dev_notif_anilist_backfill_done';

  /// JSON array de int (ids de notificación Anilist ya procesados).
  static const anilistSeenIdsJson = 'dev_notif_anilist_seen_ids_json';

  static String airingDedupeKey(int mediaId, int episode) =>
      'dev_airing_shown_${mediaId}_$episode';
}
