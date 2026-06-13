/// Third-party accounts whose session can be synced to the Cronicle Supabase user.
enum ConnectedAccountKind {
  anilist('anilist'),
  trakt('trakt'),
  steam('steam'),
  twitch('twitch');

  const ConnectedAccountKind(this.id);
  final String id;

  static ConnectedAccountKind? fromId(String? raw) {
    if (raw == null) return null;
    for (final k in ConnectedAccountKind.values) {
      if (k.id == raw) return k;
    }
    return null;
  }
}

/// Secure-storage keys per provider (same as Google Drive backup).
const Map<ConnectedAccountKind, List<String>> connectedAccountSecretKeys = {
  ConnectedAccountKind.anilist: [
    'anilist_access_token',
    'anilist_user_name',
  ],
  ConnectedAccountKind.trakt: [
    'trakt_access_token',
    'trakt_refresh_token',
    'trakt_token_expires_at_ms',
    'trakt_user_slug',
    'trakt_user_name',
    'trakt_user_avatar_url',
  ],
  ConnectedAccountKind.steam: [
    'steam_steamid64',
    'steam_persona_name',
    'steam_avatar_url',
    'steam_profile_url',
  ],
  ConnectedAccountKind.twitch: [
    'twitch_user_access_token',
    'twitch_user_refresh_token',
    'twitch_user_token_expires_ms',
    'twitch_user_login',
  ],
};

/// Primary secure key that indicates an active local session.
const Map<ConnectedAccountKind, String> connectedAccountPrimarySecretKey = {
  ConnectedAccountKind.anilist: 'anilist_access_token',
  ConnectedAccountKind.trakt: 'trakt_access_token',
  ConnectedAccountKind.steam: 'steam_steamid64',
  ConnectedAccountKind.twitch: 'twitch_user_access_token',
};
