import 'package:cronicle/features/library/domain/anime_airing_progress.dart';
import 'package:cronicle/shared/models/media_kind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el contador usa el total de la serie aunque haya episodios atrasados', () {
    final label = AnimeAiringProgress.watchedProgressLabel(
      progress: 4,
      totalEpisodes: 12,
      releasedEpisodes: 8,
      mediaKindCode: MediaKind.anime.code,
    );

    expect(label, '4/12');
    expect(
      AnimeAiringProgress.episodesBehind(
        mediaKindCode: MediaKind.anime.code,
        animeMediaStatus: 'RELEASING',
        releasedEpisodes: 8,
        progress: 4,
      ),
      4,
    );
  });

  test('sin total de serie, el contador usa los episodios ya emitidos', () {
    expect(
      AnimeAiringProgress.watchedProgressLabel(
        progress: 4,
        totalEpisodes: null,
        releasedEpisodes: 8,
        mediaKindCode: MediaKind.anime.code,
      ),
      '4/8',
    );
  });

  test('sin totales, el contador muestra solo el progreso', () {
    expect(
      AnimeAiringProgress.watchedProgressLabel(
        progress: 3,
        totalEpisodes: null,
        releasedEpisodes: null,
        mediaKindCode: MediaKind.anime.code,
      ),
      '3',
    );
  });

  test('sin progreso no hay contador', () {
    expect(
      AnimeAiringProgress.watchedProgressLabel(
        progress: null,
        totalEpisodes: 12,
        releasedEpisodes: 8,
        mediaKindCode: MediaKind.anime.code,
      ),
      isNull,
    );
  });
}
