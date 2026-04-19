import 'package:cronicle/shared/models/media_kind.dart';

/// Episodios emitidos según metadatos de Anilist (anime en emisión).
abstract final class AnimeAiringProgress {
  /// Episodios ya emitidos: si el próximo en calendario es el 8, devuelve 7.
  /// [FINISHED] → `null` (usar total de episodios almacenado en la entrada).
  static int? releasedEpisodesFromAnilistMedia(Map<String, dynamic> media) {
    final status = media['status'] as String?;
    final total = (media['episodes'] as num?)?.toInt();
    final next = media['nextAiringEpisode'] as Map<String, dynamic>?;
    final nextEp = (next?['episode'] as num?)?.toInt();

    if (status == 'FINISHED' || status == 'CANCELLED') {
      return null;
    }
    if (status == 'RELEASING') {
      if (nextEp != null) {
        final aired = nextEp > 1 ? nextEp - 1 : 0;
        if (total != null && total > 0 && aired > total) return total;
        return aired;
      }
      return null;
    }
    return null;
  }

  /// Unix segundos del próximo estreno (`nextAiringEpisode.airingAt` en Anilist).
  static int? nextEpisodeAirsAtSecondsFromAnilistMedia(
    Map<String, dynamic> media,
  ) {
    final next = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (next == null) return null;
    return (next['airingAt'] as num?)?.toInt();
  }

  /// Vas al día con lo emitido (listo para el siguiente capítulo cuando salga).
  static bool isAnimeCaughtUpWithAiring({
    required int mediaKindCode,
    String? animeMediaStatus,
    int? releasedEpisodes,
    int? progress,
  }) {
    if (MediaKind.fromCode(mediaKindCode) != MediaKind.anime) return false;
    if ((animeMediaStatus ?? '').toUpperCase() != 'RELEASING') return false;
    final aired = releasedEpisodes;
    if (aired == null) return false;
    final p = progress ?? 0;
    return p >= aired;
  }

  /// Segundos restantes hasta el estreno; null si ya pasó o sin dato.
  static int? secondsUntilNextEpisodeAiring(int? airingAtUnixSeconds) {
    if (airingAtUnixSeconds == null) return null;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final left = airingAtUnixSeconds - nowSec;
    return left > 0 ? left : null;
  }

  /// Número del próximo capítulo para mostrar (p. ej. 8 si van 7 emitidos).
  static int? nextEpisodeLabelNumber({
    required int mediaKindCode,
    int? releasedEpisodes,
  }) {
    if (MediaKind.fromCode(mediaKindCode) != MediaKind.anime) return null;
    final aired = releasedEpisodes;
    if (aired == null) return null;
    return aired + 1;
  }

  /// Tope de progreso en episodios (no marcar más de lo emitido en emisión).
  static int? animeEpisodeProgressCap({
    required int mediaKindCode,
    int? totalEpisodes,
    int? releasedEpisodes,
  }) {
    if (MediaKind.fromCode(mediaKindCode) != MediaKind.anime) {
      return totalEpisodes;
    }
    final total = totalEpisodes;
    final rel = releasedEpisodes;
    if (rel != null) {
      if (total != null && total > 0) {
        return rel < total ? rel : total;
      }
      return rel;
    }
    return total;
  }

  /// Episodios de retraso respecto al último emitido (solo anime RELEASING con dato).
  static int? episodesBehind({
    required int mediaKindCode,
    String? animeMediaStatus,
    int? releasedEpisodes,
    int? progress,
  }) {
    if (MediaKind.fromCode(mediaKindCode) != MediaKind.anime) return null;
    if ((animeMediaStatus ?? '').toUpperCase() != 'RELEASING') return null;
    final aired = releasedEpisodes;
    if (aired == null) return null;
    final p = progress ?? 0;
    final b = aired - p;
    return b > 0 ? b : null;
  }

  /// Total mostrado en UI tipo `visto/total` (prioriza emitidos si hay cap de emisión).
  static int? displayEpisodeTotal({
    required int mediaKindCode,
    int? totalEpisodes,
    int? releasedEpisodes,
  }) {
    return animeEpisodeProgressCap(
      mediaKindCode: mediaKindCode,
      totalEpisodes: totalEpisodes,
      releasedEpisodes: releasedEpisodes,
    );
  }

  /// Tope al editar una entrada anime ya guardada (prioriza DB + API).
  static int? maxProgressForStoredAnime({
    required int? totalEpisodes,
    required int? releasedEpisodes,
  }) {
    return animeEpisodeProgressCap(
      mediaKindCode: MediaKind.anime.code,
      totalEpisodes: totalEpisodes,
      releasedEpisodes: releasedEpisodes,
    );
  }

  /// Máximo permitido al editar progreso en el sheet (anime).
  static int? maxProgressForAnimeItem(Map<String, dynamic> item) {
    final status = item['status'] as String?;
    final episodes = (item['episodes'] as num?)?.toInt();
    final next = item['nextAiringEpisode'] as Map<String, dynamic>?;
    final nextEp = (next?['episode'] as num?)?.toInt();

    if (status == 'RELEASING' && nextEp != null) {
      final aired = nextEp > 1 ? nextEp - 1 : 0;
      if (episodes != null && episodes > 0) {
        return aired < episodes ? aired : episodes;
      }
      return aired;
    }
    return episodes;
  }
}
