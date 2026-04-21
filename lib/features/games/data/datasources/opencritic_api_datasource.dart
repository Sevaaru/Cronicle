import 'package:dio/dio.dart';

import 'package:cronicle/core/config/env_config.dart';

/// Reseña de medio / crítico (OpenCritic).
class OpenCriticCriticReview {
  const OpenCriticCriticReview({
    required this.outletName,
    required this.headline,
    required this.snippet,
    required this.score,
    required this.reviewUrl,
    this.authorName,
  });

  final String outletName;
  final String headline;
  final String snippet;
  final int? score;
  final String? reviewUrl;
  final String? authorName;
}

/// Agregado + lista breve para la ficha de juego.
class OpenCriticGameInsights {
  const OpenCriticGameInsights({
    required this.openCriticGameId,
    required this.name,
    required this.numReviews,
    required this.reviews,
    this.topCriticScore,
    this.medianScore,
    this.percentRecommended,
    this.pageUrl,
  });

  final int openCriticGameId;
  final String name;
  final int? topCriticScore;
  final int? medianScore;
  final int numReviews;
  final double? percentRecommended;
  final String? pageUrl;
  final List<OpenCriticCriticReview> reviews;
}

/// Cliente OpenCritic vía RapidAPI (la API pública `api.opencritic.com` exige clave).
class OpenCriticApiDatasource {
  OpenCriticApiDatasource(this._dio);

  final Dio _dio;

  static const _rapidHost = 'opencritic-api.p.rapidapi.com';
  static const _base = 'https://$_rapidHost';

  static Map<String, dynamic>? _asMap(Object? v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }

  static List<Map<String, dynamic>> _asMapList(Object? v) {
    if (v is! List) return [];
    return v
        .map((e) => _asMap(e))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  static int? _readInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.round();
    return int.tryParse(v.toString());
  }

  static double? _readDouble(Object? v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  static String _readString(Object? v) => v?.toString().trim() ?? '';

  static Object? _pick(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      if (m.containsKey(k) && m[k] != null) return m[k];
    }
    return null;
  }

  Options _options() => Options(
        headers: {
          'Accept': 'application/json',
          'X-RapidAPI-Key': EnvConfig.openCriticRapidApiKey,
          'X-RapidAPI-Host': _rapidHost,
        },
        validateStatus: (s) => s != null && s < 500,
      );

  /// `true` si hay clave compilada (puede seguir fallando por suscripción RapidAPI).
  bool get isConfigured => EnvConfig.openCriticRapidApiKey.isNotEmpty;

  Future<dynamic> _get(String path, {Map<String, dynamic>? query}) async {
    final res = await _dio.get<dynamic>(
      '$_base$path',
      queryParameters: query,
      options: _options(),
    );
    final code = res.statusCode ?? 0;
    if (code >= 400) return null;
    return res.data;
  }

  /// Busca por nombre y devuelve insights + reseñas de aterrizaje (si hay match).
  Future<OpenCriticGameInsights?> fetchInsightsForTitle(String rawName) async {
    if (!isConfigured) return null;
    final q = rawName.trim();
    if (q.isEmpty) return null;

    final searchData = await _get(
      '/meta/search',
      query: {'criteria': q},
    );
    final rows = _asMapList(searchData);
    if (rows.isEmpty) return null;

    rows.sort((a, b) {
      final da = _readDouble(_pick(a, ['dist', 'Dist'])) ?? 999;
      final db = _readDouble(_pick(b, ['dist', 'Dist'])) ?? 999;
      return da.compareTo(db);
    });

    const maxDist = 0.42;
    Map<String, dynamic>? chosen;
    for (final row in rows) {
      final dist = _readDouble(_pick(row, ['dist', 'Dist'])) ?? 999;
      if (dist <= maxDist) {
        chosen = row;
        break;
      }
    }
    if (chosen == null) return null;

    final id = _readInt(_pick(chosen, ['id', 'Id']));
    if (id == null) return null;

    final gameJson = await _get('/game/$id');
    final game = _asMap(gameJson);
    if (game == null) return null;

    final reviewsRaw = await _get('/review/game/$id/landing');
    final reviewMaps = _asMapList(reviewsRaw);

    final reviews = <OpenCriticCriticReview>[];
    for (final r in reviewMaps.take(14)) {
      final outlet = _asMap(r['Outlet']) ?? _asMap(r['outlet']);
      final outletName = _readString(outlet?['name']);
      final authors = r['Authors'] ?? r['authors'];
      String? author;
      if (authors is List && authors.isNotEmpty) {
        final a0 = _asMap(authors.first);
        final an = _readString(a0?['name']);
        if (an.isNotEmpty) author = an;
      }
      final alias = _readString(r['alias']);
      if (author == null && alias.isNotEmpty) author = alias;
      final title = _readString(r['title']);
      final snippet = _readString(r['snippet']);
      final url = _readString(r['externalUrl']);
      final score = _readInt(r['score']);
      if (outletName.isEmpty && title.isEmpty && snippet.isEmpty) continue;
      reviews.add(
        OpenCriticCriticReview(
          outletName: outletName.isEmpty ? '—' : outletName,
          headline: title.isEmpty ? outletName : title,
          snippet: snippet,
          score: score,
          reviewUrl: url.isEmpty ? null : url,
          authorName: author,
        ),
      );
    }

    final name = _readString(_pick(game, ['name', 'Name']));
    final pageUrl = _readString(_pick(game, ['url', 'Url']));
    final top = _readInt(_pick(game, ['topCriticScore', 'TopCriticScore']));
    final median = _readInt(_pick(game, ['medianScore', 'MedianScore']));
    final numRev = _readInt(_pick(game, ['numReviews', 'NumReviews'])) ??
        reviews.length;
    final pct = _readDouble(
      _pick(game, ['percentRecommended', 'PercentRecommended']),
    );

    return OpenCriticGameInsights(
      openCriticGameId: id,
      name: name.isEmpty ? q : name,
      topCriticScore: top,
      medianScore: median,
      numReviews: numRev,
      percentRecommended: pct,
      pageUrl: pageUrl.isEmpty ? null : pageUrl,
      reviews: reviews,
    );
  }
}
