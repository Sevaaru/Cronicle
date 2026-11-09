import 'package:cronicle/l10n/app_localizations.dart';

enum MediaKind {
  anime(0),
  movie(1),
  tv(2),
  game(3),
  manga(4),
  book(5);

  const MediaKind(this.code);
  final int code;

  static MediaKind fromCode(int code) =>
      MediaKind.values.firstWhere((e) => e.code == code);
}

String mediaKindLabel(MediaKind kind, AppLocalizations l10n) => switch (kind) {
      MediaKind.anime => l10n.mediaKindAnime,
      MediaKind.movie => l10n.mediaKindMovie,
      MediaKind.tv => l10n.mediaKindTv,
      MediaKind.game => l10n.mediaKindGame,
      MediaKind.manga => l10n.mediaKindManga,
      MediaKind.book => l10n.mediaKindBook,
    };
