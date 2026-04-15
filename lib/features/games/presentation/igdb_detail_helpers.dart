import 'package:flutter/material.dart';

import 'package:cronicle/features/games/data/datasources/igdb_api_datasource.dart';
import 'package:cronicle/l10n/app_localizations.dart';

/// IGDB website category `1` = sitio oficial del juego (mostrar “Sitio web”).
const int igdbWebsiteCategoryOfficial = 1;

/// Resultado de inspeccionar el host/ruta de un enlace (tiendas, redes, etc.).
enum GameOutboundLinkKind {
  officialWebsite,
  discord,
  steam,
  playStation,
  xbox,
  nintendo,
  itchIo,
  epic,
  gog,
  humble,
  ubisoft,
  ea,
  rockstar,
  battlenet,
  youtube,
  twitch,
  twitter,
  facebook,
  instagram,
  reddit,
  tiktok,
  bluesky,
  apple,
  android,
  amazon,
  oculus,
  gamejolt,
  igdb,
  unknown,
}

/// Detecta tienda o servicio a partir de la URL (prioridad sobre categoría IGDB).
GameOutboundLinkKind detectGameOutboundLinkKind(String url) {
  final uri = Uri.tryParse(url);
  if (uri == null || uri.host.isEmpty) return GameOutboundLinkKind.unknown;
  final h = uri.host.toLowerCase();
  final path = '${uri.path} ${uri.query}'.toLowerCase();

  if (h.contains('discord.')) return GameOutboundLinkKind.discord;
  if (h.contains('steampowered') ||
      h.contains('steamcommunity') ||
      h.contains('steamdeck.com')) {
    return GameOutboundLinkKind.steam;
  }
  if (h.contains('playstation.') ||
      h.contains('playstationstore') ||
      h.contains('sonyentertainmentnetwork')) {
    return GameOutboundLinkKind.playStation;
  }
  if (h.contains('xbox.com') ||
      h.contains('xboxlive.com') ||
      h.contains('microsoftstore.com')) {
    return GameOutboundLinkKind.xbox;
  }
  if (h == 'microsoft.com' || h.endsWith('.microsoft.com')) {
    if (path.contains('/store/') ||
        path.contains('/games') ||
        path.contains('productid')) {
      return GameOutboundLinkKind.xbox;
    }
  }
  if (h.contains('nintendo.') ||
      h.contains('nintendoswitch') ||
      h.contains('ec.nintendo')) {
    return GameOutboundLinkKind.nintendo;
  }
  if (h.contains('itch.io')) return GameOutboundLinkKind.itchIo;
  if (h.contains('epicgames.com')) return GameOutboundLinkKind.epic;
  if (h.contains('gog.com')) return GameOutboundLinkKind.gog;
  if (h.contains('humblebundle.com')) return GameOutboundLinkKind.humble;
  if (h.contains('ubisoft.com') ||
      h.contains('ubisoftconnect.com') ||
      h.contains('uplay.')) {
    return GameOutboundLinkKind.ubisoft;
  }
  if (h.contains('ea.com') ||
      h.contains('origin.com') ||
      h.contains('electronicarts')) {
    return GameOutboundLinkKind.ea;
  }
  if (h.contains('rockstargames.com')) return GameOutboundLinkKind.rockstar;
  if (h.contains('battle.net') || h.contains('blizzard.com')) {
    return GameOutboundLinkKind.battlenet;
  }
  if (h.contains('youtube.com') || h.contains('youtu.be')) {
    return GameOutboundLinkKind.youtube;
  }
  if (h.contains('twitch.')) return GameOutboundLinkKind.twitch;
  if (h.contains('twitter.com') ||
      h.contains('x.com') ||
      h == 't.co') {
    return GameOutboundLinkKind.twitter;
  }
  if (h.contains('facebook.') || h.contains('fb.com')) {
    return GameOutboundLinkKind.facebook;
  }
  if (h.contains('instagram.com')) return GameOutboundLinkKind.instagram;
  if (h.contains('reddit.com')) return GameOutboundLinkKind.reddit;
  if (h.contains('tiktok.com')) return GameOutboundLinkKind.tiktok;
  if (h.contains('bsky.app')) return GameOutboundLinkKind.bluesky;
  if (h.contains('igdb.com')) return GameOutboundLinkKind.igdb;

  return GameOutboundLinkKind.unknown;
}

IconData _iconForOutboundKind(GameOutboundLinkKind k) {
  return switch (k) {
    GameOutboundLinkKind.officialWebsite => Icons.public,
    GameOutboundLinkKind.discord => Icons.headset_mic_outlined,
    GameOutboundLinkKind.steam => Icons.store,
    GameOutboundLinkKind.playStation => Icons.play_circle_outline,
    GameOutboundLinkKind.xbox => Icons.window,
    GameOutboundLinkKind.nintendo => Icons.view_module_outlined,
    GameOutboundLinkKind.itchIo => Icons.videogame_asset_outlined,
    GameOutboundLinkKind.epic => Icons.shopping_cart_outlined,
    GameOutboundLinkKind.gog => Icons.storefront_outlined,
    GameOutboundLinkKind.humble => Icons.redeem_outlined,
    GameOutboundLinkKind.ubisoft => Icons.cloud_outlined,
    GameOutboundLinkKind.ea => Icons.sports_outlined,
    GameOutboundLinkKind.rockstar => Icons.star_border,
    GameOutboundLinkKind.battlenet => Icons.shield_outlined,
    GameOutboundLinkKind.youtube => Icons.play_circle_filled,
    GameOutboundLinkKind.twitch => Icons.live_tv,
    GameOutboundLinkKind.twitter => Icons.chat_bubble_outline,
    GameOutboundLinkKind.facebook => Icons.facebook,
    GameOutboundLinkKind.instagram => Icons.camera_alt,
    GameOutboundLinkKind.reddit => Icons.forum_outlined,
    GameOutboundLinkKind.tiktok => Icons.music_note,
    GameOutboundLinkKind.bluesky => Icons.cloud_outlined,
    GameOutboundLinkKind.apple => Icons.phone_iphone_outlined,
    GameOutboundLinkKind.android => Icons.android,
    GameOutboundLinkKind.amazon => Icons.shopping_bag_outlined,
    GameOutboundLinkKind.oculus => Icons.threed_rotation_outlined,
    GameOutboundLinkKind.gamejolt => Icons.bolt_outlined,
    GameOutboundLinkKind.igdb => Icons.sports_esports,
    GameOutboundLinkKind.unknown => Icons.link,
  };
}

Color? _accentForOutboundKind(GameOutboundLinkKind k) {
  return switch (k) {
    GameOutboundLinkKind.officialWebsite => null,
    GameOutboundLinkKind.discord => const Color(0xFF5865F2),
    GameOutboundLinkKind.steam => const Color(0xFF1B2838),
    GameOutboundLinkKind.playStation => const Color(0xFF0070D1),
    GameOutboundLinkKind.xbox => const Color(0xFF107C10),
    GameOutboundLinkKind.nintendo => const Color(0xFFE60012),
    GameOutboundLinkKind.itchIo => const Color(0xFFFA5C5C),
    GameOutboundLinkKind.epic => const Color(0xFF313131),
    GameOutboundLinkKind.gog => const Color(0xFF8639AA),
    GameOutboundLinkKind.humble => const Color(0xFFCC2929),
    GameOutboundLinkKind.ubisoft => const Color(0xFF0074C8),
    GameOutboundLinkKind.ea => const Color(0xFFFF4747),
    GameOutboundLinkKind.rockstar => const Color(0xFFFCAF17),
    GameOutboundLinkKind.battlenet => const Color(0xFF00AEFF),
    GameOutboundLinkKind.youtube => const Color(0xFFFF0033),
    GameOutboundLinkKind.twitch => const Color(0xFF9146FF),
    GameOutboundLinkKind.facebook => const Color(0xFF1877F2),
    GameOutboundLinkKind.instagram => const Color(0xFFE4405F),
    GameOutboundLinkKind.reddit => const Color(0xFFFF4500),
    GameOutboundLinkKind.apple => const Color(0xFF555555),
    GameOutboundLinkKind.android => const Color(0xFF3DDC84),
    GameOutboundLinkKind.amazon => const Color(0xFFFF9900),
    GameOutboundLinkKind.oculus => const Color(0xFF1877F2),
    GameOutboundLinkKind.gamejolt => const Color(0xFF00B050),
    GameOutboundLinkKind.igdb => const Color(0xFF6366F1),
    _ => null,
  };
}

/// Mapea categoría de [ExternalGame](https://api-docs.igdb.com/#external-game-enums) a [GameOutboundLinkKind].
GameOutboundLinkKind kindFromIgdbExternalCategory(int? category) {
  if (category == null) return GameOutboundLinkKind.unknown;
  return switch (category) {
    1 => GameOutboundLinkKind.steam,
    5 => GameOutboundLinkKind.gog,
    10 => GameOutboundLinkKind.youtube,
    11 => GameOutboundLinkKind.xbox,
    13 => GameOutboundLinkKind.apple,
    14 => GameOutboundLinkKind.twitch,
    15 => GameOutboundLinkKind.android,
    20 => GameOutboundLinkKind.amazon,
    22 => GameOutboundLinkKind.amazon,
    23 => GameOutboundLinkKind.amazon,
    26 => GameOutboundLinkKind.epic,
    28 => GameOutboundLinkKind.oculus,
    29 => GameOutboundLinkKind.unknown,
    30 => GameOutboundLinkKind.itchIo,
    31 => GameOutboundLinkKind.xbox,
    32 => GameOutboundLinkKind.unknown,
    36 => GameOutboundLinkKind.playStation,
    37 => GameOutboundLinkKind.unknown,
    54 => GameOutboundLinkKind.xbox,
    55 => GameOutboundLinkKind.gamejolt,
    _ => GameOutboundLinkKind.unknown,
  };
}

/// Mapea categoría de web IGDB a [GameOutboundLinkKind] (cuando la URL no basta).
GameOutboundLinkKind kindFromIgdbWebsiteCategory(int? category) {
  if (category == null) return GameOutboundLinkKind.unknown;
  return switch (category) {
    4 => GameOutboundLinkKind.facebook,
    5 => GameOutboundLinkKind.twitter,
    6 => GameOutboundLinkKind.twitch,
    8 => GameOutboundLinkKind.instagram,
    9 => GameOutboundLinkKind.youtube,
    13 => GameOutboundLinkKind.steam,
    14 => GameOutboundLinkKind.reddit,
    16 => GameOutboundLinkKind.itchIo,
    17 => GameOutboundLinkKind.epic,
    18 => GameOutboundLinkKind.gog,
    19 => GameOutboundLinkKind.discord,
    _ => GameOutboundLinkKind.unknown,
  };
}

/// Icono / color: URL primero, luego categoría externa, luego categoría de web.
GameOutboundLinkKind resolveGameOutboundLinkKind({
  required String url,
  bool isIgdbPage = false,
  int? websiteCategory,
  int? externalCategory,
}) {
  if (isIgdbPage) return GameOutboundLinkKind.igdb;
  if (websiteCategory == igdbWebsiteCategoryOfficial) {
    return GameOutboundLinkKind.officialWebsite;
  }

  final fromUrl = detectGameOutboundLinkKind(url);
  if (fromUrl != GameOutboundLinkKind.unknown) return fromUrl;

  if (externalCategory != null) {
    final e = kindFromIgdbExternalCategory(externalCategory);
    if (e != GameOutboundLinkKind.unknown) return e;
  }

  if (websiteCategory != null) {
    final w = kindFromIgdbWebsiteCategory(websiteCategory);
    if (w != GameOutboundLinkKind.unknown) return w;
  }

  return GameOutboundLinkKind.unknown;
}

/// Texto corto del chip según el tipo resuelto (alineado con iconos).
String gameDetailOutboundKindLabel(
    GameOutboundLinkKind k, AppLocalizations l10n) {
  return switch (k) {
    GameOutboundLinkKind.officialWebsite => l10n.gameDetailLinkOfficialSite,
    GameOutboundLinkKind.discord => l10n.gameDetailWebCatDiscord,
    GameOutboundLinkKind.steam => l10n.gameDetailExtCatSteam,
    GameOutboundLinkKind.playStation => l10n.gameDetailLinkKindPlayStation,
    GameOutboundLinkKind.xbox => l10n.gameDetailExtCatMicrosoft,
    GameOutboundLinkKind.nintendo => l10n.gameDetailLinkKindNintendo,
    GameOutboundLinkKind.itchIo => l10n.gameDetailWebCatItch,
    GameOutboundLinkKind.epic => l10n.gameDetailWebCatEpic,
    GameOutboundLinkKind.gog => l10n.gameDetailExtCatGog,
    GameOutboundLinkKind.humble => l10n.gameDetailLinkKindHumble,
    GameOutboundLinkKind.ubisoft => l10n.gameDetailLinkKindUbisoft,
    GameOutboundLinkKind.ea => l10n.gameDetailLinkKindEa,
    GameOutboundLinkKind.rockstar => l10n.gameDetailLinkKindRockstar,
    GameOutboundLinkKind.battlenet => l10n.gameDetailLinkKindBattlenet,
    GameOutboundLinkKind.youtube => l10n.gameDetailWebCatYoutube,
    GameOutboundLinkKind.twitch => l10n.gameDetailWebCatTwitch,
    GameOutboundLinkKind.twitter => l10n.gameDetailWebCatTwitter,
    GameOutboundLinkKind.facebook => l10n.gameDetailWebCatFacebook,
    GameOutboundLinkKind.instagram => l10n.gameDetailWebCatInstagram,
    GameOutboundLinkKind.reddit => l10n.gameDetailWebCatReddit,
    GameOutboundLinkKind.tiktok => l10n.gameDetailLinkKindTiktok,
    GameOutboundLinkKind.bluesky => l10n.gameDetailLinkKindBluesky,
    GameOutboundLinkKind.apple => l10n.gameDetailLinkKindApple,
    GameOutboundLinkKind.android => l10n.gameDetailLinkKindGooglePlay,
    GameOutboundLinkKind.amazon => l10n.gameDetailLinkKindAmazon,
    GameOutboundLinkKind.oculus => l10n.gameDetailLinkKindOculus,
    GameOutboundLinkKind.gamejolt => l10n.gameDetailLinkKindGameJolt,
    GameOutboundLinkKind.igdb => l10n.gameDetailOpenIgdb,
    GameOutboundLinkKind.unknown => l10n.gameDetailWebCatOther,
  };
}

/// Etiqueta del chip para enlaces de la tabla `websites` de IGDB.
String gameDetailWebsiteChipLabel(
  int? websiteCategory,
  String resolvedUrl,
  AppLocalizations l10n,
) {
  if (websiteCategory == igdbWebsiteCategoryOfficial) {
    return l10n.gameDetailLinkOfficialSite;
  }
  final fromUrl = detectGameOutboundLinkKind(resolvedUrl);
  if (fromUrl != GameOutboundLinkKind.unknown) {
    return gameDetailOutboundKindLabel(fromUrl, l10n);
  }
  final fromCat = kindFromIgdbWebsiteCategory(websiteCategory);
  if (fromCat != GameOutboundLinkKind.unknown) {
    return gameDetailOutboundKindLabel(fromCat, l10n);
  }
  return igdbWebsiteCategoryLabel(websiteCategory, l10n);
}

/// Etiqueta del chip para `external_games` (nombre IGDB + URL + categoría).
String gameDetailExternalGameChipLabel(
  Map<String, dynamic> eg,
  String resolvedUrl,
  AppLocalizations l10n,
) {
  final src = eg['external_game_source'];
  if (src is Map<String, dynamic>) {
    final n = src['name'] as String?;
    if (n != null && n.trim().isNotEmpty) return n.trim();
  }
  final rowName = eg['name'] as String?;
  if (rowName != null && rowName.trim().isNotEmpty) return rowName.trim();

  final fromUrl = detectGameOutboundLinkKind(resolvedUrl);
  if (fromUrl != GameOutboundLinkKind.unknown) {
    return gameDetailOutboundKindLabel(fromUrl, l10n);
  }

  final cat = eg['category'] as int?;
  final fromCat = kindFromIgdbExternalCategory(cat);
  if (fromCat != GameOutboundLinkKind.unknown) {
    return gameDetailOutboundKindLabel(fromCat, l10n);
  }

  return igdbExternalGameCategoryLabel(cat, l10n);
}

/// IGDB [WebsiteCategory](https://api-docs.igdb.com/#website-enums) (subset).
String igdbWebsiteCategoryLabel(int? category, AppLocalizations l10n) {
  return switch (category) {
    1 => l10n.gameDetailWebCatOfficial,
    2 => l10n.gameDetailWebCatWikia,
    3 => l10n.gameDetailWebCatWikipedia,
    4 => l10n.gameDetailWebCatFacebook,
    5 => l10n.gameDetailWebCatTwitter,
    6 => l10n.gameDetailWebCatTwitch,
    8 => l10n.gameDetailWebCatInstagram,
    9 => l10n.gameDetailWebCatYoutube,
    13 => l10n.gameDetailWebCatSteam,
    14 => l10n.gameDetailWebCatReddit,
    16 => l10n.gameDetailWebCatItch,
    17 => l10n.gameDetailWebCatEpic,
    18 => l10n.gameDetailWebCatGog,
    19 => l10n.gameDetailWebCatDiscord,
    _ => l10n.gameDetailWebCatOther,
  };
}

/// External game source category (IGDB [ExternalGameCategory](https://api-docs.igdb.com/#external-game-enums)).
String igdbExternalGameCategoryLabel(int? category, AppLocalizations l10n) {
  final k = kindFromIgdbExternalCategory(category);
  if (k != GameOutboundLinkKind.unknown) {
    return gameDetailOutboundKindLabel(k, l10n);
  }
  return l10n.gameDetailExtCatOther;
}

String formatIgdbPlaytimeSeconds(int? seconds, AppLocalizations l10n) {
  if (seconds == null || seconds <= 0) return '—';
  final d = Duration(seconds: seconds);
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0 && m > 0) {
    return l10n.gameDetailPlaytimeHoursMinutes(h, m);
  }
  if (h > 0) return l10n.gameDetailPlaytimeHoursOnly(h);
  return l10n.gameDetailPlaytimeMinutesOnly(m);
}

int? readTimeToBeatSeconds(Map<String, dynamic>? ttb, String primaryKey, String altKey) {
  if (ttb == null) return null;
  final a = ttb[primaryKey];
  if (a is num) return a.toInt();
  final b = ttb[altKey];
  if (b is num) return b.toInt();
  return null;
}

/// Steam / other stores when [url] is missing but [uid] is present.
String? externalStoreLaunchUrl(Map<String, dynamic> eg) {
  final abs = IgdbApiDatasource.absoluteHttpUrl(eg['url'] as String?);
  if (abs != null) return abs;
  final cat = eg['category'];
  final uid = eg['uid'];
  final uidStr = uid is int ? '$uid' : uid is String ? uid : null;
  if (uidStr == null || uidStr.isEmpty) return null;
  if (cat == 1 || cat == 28 || cat == 13) {
    return 'https://store.steampowered.com/app/$uidStr';
  }
  return null;
}

String stripSimpleHtml(String s) {
  return s.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll('&nbsp;', ' ').trim();
}

/// Texto corto para chips de enlace (misma idea que nombres cortos en anime).
String gameDetailLinkChipTitle(String fullLabel, {int maxChars = 18}) {
  final t = fullLabel.trim();
  if (t.length <= maxChars) return t;
  if (maxChars < 2) return t;
  return '${t.substring(0, maxChars - 1)}…';
}

IconData gameDetailLinkIcon({
  required String url,
  bool isIgdbPage = false,
  int? websiteCategory,
  int? externalCategory,
}) {
  final kind = resolveGameOutboundLinkKind(
    url: url,
    isIgdbPage: isIgdbPage,
    websiteCategory: websiteCategory,
    externalCategory: externalCategory,
  );
  return _iconForOutboundKind(kind);
}

/// Color de acento opcional para chips (como [color] en enlaces de AniList).
Color? gameDetailLinkAccentColor({
  required String url,
  bool isIgdbPage = false,
  int? websiteCategory,
  int? externalCategory,
}) {
  final kind = resolveGameOutboundLinkKind(
    url: url,
    isIgdbPage: isIgdbPage,
    websiteCategory: websiteCategory,
    externalCategory: externalCategory,
  );
  return _accentForOutboundKind(kind);
}
