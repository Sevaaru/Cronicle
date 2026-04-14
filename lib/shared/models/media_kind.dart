enum MediaKind {
  anime(0),
  movie(1),
  tv(2),
  game(3),
  manga(4);

  const MediaKind(this.code);
  final int code;

  static MediaKind fromCode(int code) =>
      MediaKind.values.firstWhere((e) => e.code == code);

  String get label => switch (this) {
        MediaKind.anime => 'Anime',
        MediaKind.movie => 'Películas',
        MediaKind.tv => 'Series',
        MediaKind.game => 'Juegos',
        MediaKind.manga => 'Manga',
      };

  String get labelEn => switch (this) {
        MediaKind.anime => 'Anime',
        MediaKind.movie => 'Movies',
        MediaKind.tv => 'TV',
        MediaKind.game => 'Games',
        MediaKind.manga => 'Manga',
      };
}
