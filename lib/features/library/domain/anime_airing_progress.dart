import 'package:cronicle/shared/models/media_kind.dart';

abstract final class AnimeAiringProgress {
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

  static int? nextEpisodeAirsAtSecondsFromAnilistMedia(
    Map<String, dynamic> media,
  ) {
    final next = media['nextAiringEpisode'] as Map<String, dynamic>?;
    if (next == null) return null;
    return (next['airingAt'] as num?)?.toInt();
  }

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

  static int? secondsUntilNextEpisodeAiring(int? airingAtUnixSeconds) {
    if (airingAtUnixSeconds == null) return null;
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final left = airingAtUnixSeconds - nowSec;
    return left > 0 ? left : null;
  }

  static int? nextEpisodeLabelNumber({
    required int mediaKindCode,
    int? releasedEpisodes,
  }) {
    if (MediaKind.fromCode(mediaKindCode) != MediaKind.anime) return null;
    final aired = releasedEpisodes;
    if (aired == null) return null;
    return aired + 1;
  }

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
