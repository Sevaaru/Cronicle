import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:cronicle/core/network/api_endpoints.dart';

/// REST datasource for the Open Library API.
///
/// Rate limits: favour ≤ 1 req/s (≤ 3 with User-Agent).
/// https://openlibrary.org/developers/api
class OpenLibraryApiDatasource {
  OpenLibraryApiDatasource(this._dio);

  final Dio _dio;

  static const _base = ApiEndpoints.openLibraryBase;
  static const _covers = ApiEndpoints.openLibraryCovers;

  // Browsers forbid setting User-Agent via XMLHttpRequest.
  Options get _opts => Options(headers: {
        if (!kIsWeb) 'User-Agent': 'Cronicle/1.0 (https://github.com/cronicle)',
      });

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// Search books. Returns a list of normalized maps.
  Future<List<Map<String, dynamic>>> searchBooks(
    String query, {
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/search.json',
      queryParameters: {
        'q': query,
        'limit': limit,
        'fields':
            'key,title,author_name,first_publish_year,cover_i,number_of_pages_median,subject,ratings_average,ratings_count,edition_count',
      },
      options: _opts,
    );
    final docs = (res.data?['docs'] as List?) ?? [];
    return docs.cast<Map<String, dynamic>>().map(_normalizeSearch).toList();
  }

  /// Search books by subject using the search API (richer data: score, pages).
  Future<List<Map<String, dynamic>>> searchBooksBySubject(
    String subject, {
    int limit = 50,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/search.json',
      queryParameters: {
        'q': 'subject:$subject',
        'limit': limit,
        'fields':
            'key,title,author_name,first_publish_year,cover_i,number_of_pages_median,subject,ratings_average,ratings_count,edition_count',
      },
      options: _opts,
    );
    final docs = (res.data?['docs'] as List?) ?? [];
    return docs.cast<Map<String, dynamic>>().map(_normalizeSearch).toList();
  }

  // ---------------------------------------------------------------------------
  // Trending / Subjects
  // ---------------------------------------------------------------------------

  /// Fetch trending books for a subject (e.g. "popular", "love", "fantasy").
  Future<List<Map<String, dynamic>>> fetchSubject(
    String subject, {
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/subjects/$subject.json',
      queryParameters: {'limit': limit},
      options: _opts,
    );
    final works = (res.data?['works'] as List?) ?? [];
    return works.cast<Map<String, dynamic>>().map(_normalizeSubjectWork).toList();
  }

  /// Fetch the trending list from Open Library.
  Future<List<Map<String, dynamic>>> fetchTrending({
    int limit = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/trending/daily.json',
      queryParameters: {'limit': limit},
      options: _opts,
    );
    final works = (res.data?['works'] as List?) ?? [];
    return works.cast<Map<String, dynamic>>().map(_normalizeTrending).toList();
  }

  // ---------------------------------------------------------------------------
  // Work detail
  // ---------------------------------------------------------------------------

  /// Fetch full work detail by key (e.g. "OL27448W" or "/works/OL27448W").
  Future<Map<String, dynamic>> fetchWork(String workKey) async {
    final key = workKey.startsWith('/works/') ? workKey : '/works/$workKey';
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base$key.json',
      options: _opts,
    );
    final data = res.data ?? {};

    // Fetch editions (first entry for pages) + ratings in parallel
    final futures = await Future.wait([
      _dio.get<Map<String, dynamic>>(
        '$_base$key/editions.json',
        queryParameters: {'limit': 1},
        options: _opts,
      ),
      _dio.get<Map<String, dynamic>>(
        '$_base$key/ratings.json',
        options: _opts,
      ),
    ]);

    final editionsData = futures[0].data ?? {};
    final editionCount = (editionsData['size'] as num?)?.toInt() ?? 0;
    final editionEntries = (editionsData['entries'] as List?) ?? [];
    int? pages;
    if (editionEntries.isNotEmpty) {
      final firstEdition = editionEntries.first as Map<String, dynamic>;
      pages = (firstEdition['number_of_pages'] as num?)?.toInt();
    }
    final ratingsData = futures[1].data ?? {};

    // Resolve author names
    final authorKeys = (data['authors'] as List?)
            ?.map((a) {
              if (a is Map) return (a['author']?['key'] ?? a['key']) as String?;
              return null;
            })
            .whereType<String>()
            .toList() ??
        [];
    final authorNames = await _resolveAuthors(authorKeys);

    return _normalizeWork(data, authorNames, editionCount, ratingsData, pages);
  }

  // ---------------------------------------------------------------------------
  // Editions
  // ---------------------------------------------------------------------------

  /// Fetch a single edition by key (e.g. "OL123M" or "/books/OL123M").
  /// Returns `{editionKey, isbn, title, pages, publishers, publishDate, coverUrl}`.
  Future<Map<String, dynamic>> fetchEdition(String editionKey) async {
    final key = editionKey.startsWith('/books/') ? editionKey : '/books/$editionKey';
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base$key.json',
      options: _opts,
    );
    final data = res.data ?? {};
    return _normalizeEdition(data);
  }

  /// Fetch all editions of a work. Returns a list of normalized edition maps.
  Future<List<Map<String, dynamic>>> fetchWorkEditions(
    String workKey, {
    int limit = 50,
  }) async {
    final key = workKey.startsWith('/works/') ? workKey : '/works/$workKey';
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base$key/editions.json',
      queryParameters: {'limit': limit},
      options: _opts,
    );
    final entries = (res.data?['entries'] as List?) ?? [];
    return entries
        .cast<Map<String, dynamic>>()
        .map(_normalizeEdition)
        .toList();
  }

  Map<String, dynamic> _normalizeEdition(Map<String, dynamic> data) {
    final key = (data['key'] as String? ?? '').replaceFirst('/books/', '');
    final isbns = (data['isbn_13'] as List?)?.cast<String>() ??
        (data['isbn_10'] as List?)?.cast<String>() ??
        [];
    final coverId = (data['covers'] as List?)?.cast<int>().firstOrNull;
    final publishers = (data['publishers'] as List?)?.cast<String>() ?? [];
    return {
      'editionKey': key,
      'isbn': isbns.isNotEmpty ? isbns.first : null,
      'title': data['title'] as String? ?? '',
      'pages': (data['number_of_pages'] as num?)?.toInt(),
      'chapters': (data['table_of_contents'] as List?)?.length,
      'publishers': publishers,
      'publishDate': data['publish_date'] as String?,
      'coverUrl': coverUrl(coverId, size: 'M'),
    };
  }

  // ---------------------------------------------------------------------------
  // User reading log (public, no auth needed)
  // ---------------------------------------------------------------------------

  /// Fetch a user's public reading log.
  /// [shelf] = "want-to-read" | "currently-reading" | "already-read"
  Future<List<Map<String, dynamic>>> fetchUserReadingLog(
    String username,
    String shelf, {
    int limit = 50,
    int page = 1,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_base/people/$username/books/$shelf.json',
      queryParameters: {'limit': limit, 'page': page},
      options: _opts,
    );
    final entries = (res.data?['reading_log_entries'] as List?) ?? [];
    return entries.cast<Map<String, dynamic>>().map((e) {
      final work = e['work'] as Map<String, dynamic>? ?? {};
      return _normalizeReadingLogEntry(work);
    }).toList();
  }

  /// Check if a username exists by trying to fetch page 1 with limit 1.
  Future<bool> usernameExists(String username) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '$_base/people/$username/books/want-to-read.json',
        queryParameters: {'limit': 1},
        options: Options(
          headers: _opts.headers,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<List<String>> _resolveAuthors(List<String> authorKeys) async {
    if (authorKeys.isEmpty) return [];
    final names = <String>[];
    for (final key in authorKeys.take(5)) {
      try {
        final res = await _dio.get<Map<String, dynamic>>(
          '$_base$key.json',
          options: _opts,
        );
        final name = res.data?['name'] as String?;
        if (name != null) names.add(name);
      } catch (_) {
        // skip unresolvable authors
      }
    }
    return names;
  }

  /// Build cover URL from cover ID.
  static String? coverUrl(int? coverId, {String size = 'M'}) {
    if (coverId == null) return null;
    return '$_covers/b/id/$coverId-$size.jpg';
  }

  /// Extract work key from "/works/OL123W" format.
  static String extractWorkKey(String key) {
    return key.replaceFirst('/works/', '');
  }

  // ---------------------------------------------------------------------------
  // Normalization (to BrowseResultCard-compatible shape)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _normalizeSearch(Map<String, dynamic> doc) {
    final key = extractWorkKey(doc['key'] as String? ?? '');
    final coverId = doc['cover_i'] as int?;
    final cover = coverUrl(coverId, size: 'M');
    final coverLarge = coverUrl(coverId, size: 'L');
    final authors = (doc['author_name'] as List?)?.cast<String>() ?? [];
    final rating = (doc['ratings_average'] as num?)?.toDouble();

    return {
      'id': key.hashCode,
      'workKey': key,
      'title': {
        'english': doc['title'] as String? ?? '',
        'romaji': doc['title'] as String? ?? '',
      },
      'coverImage': {
        'large': cover,
        'extraLarge': coverLarge,
      },
      'averageScore': rating != null ? (rating * 20).round().clamp(0, 100) : null,
      'genres': ((doc['subject'] as List?) ?? []).cast<String>().take(5).toList(),
      'format': 'Book',
      'pages': (doc['number_of_pages_median'] as num?)?.toInt(),
      'authors': authors,
      'year': doc['first_publish_year'] as int?,
      'editionCount': doc['edition_count'] as int?,
    };
  }

  Map<String, dynamic> _normalizeSubjectWork(Map<String, dynamic> work) {
    final key = extractWorkKey(work['key'] as String? ?? '');
    final coverId = work['cover_id'] as int?;
    final cover = coverUrl(coverId, size: 'M');
    final coverLarge = coverUrl(coverId, size: 'L');
    final authors = (work['authors'] as List?)
            ?.map((a) => (a as Map?)?['name'] as String?)
            .whereType<String>()
            .toList() ??
        [];

    return {
      'id': key.hashCode,
      'workKey': key,
      'title': {
        'english': work['title'] as String? ?? '',
        'romaji': work['title'] as String? ?? '',
      },
      'coverImage': {
        'large': cover,
        'extraLarge': coverLarge,
      },
      'averageScore': null,
      'genres': ((work['subject'] as List?) ?? []).cast<String>().take(5).toList(),
      'format': 'Book',
      'authors': authors,
      'year': work['first_publish_year'] as int?,
    };
  }

  Map<String, dynamic> _normalizeTrending(Map<String, dynamic> work) {
    final key = extractWorkKey(work['key'] as String? ?? '');
    final coverId = work['cover_i'] as int? ?? work['cover_id'] as int?;
    final cover = coverUrl(coverId, size: 'M');
    final coverLarge = coverUrl(coverId, size: 'L');

    return {
      'id': key.hashCode,
      'workKey': key,
      'title': {
        'english': work['title'] as String? ?? '',
        'romaji': work['title'] as String? ?? '',
      },
      'coverImage': {
        'large': cover,
        'extraLarge': coverLarge,
      },
      'averageScore': null,
      'genres': <String>[],
      'format': 'Book',
      'year': work['first_publish_year'] as int?,
    };
  }

  Map<String, dynamic> _normalizeWork(
    Map<String, dynamic> data,
    List<String> authorNames,
    int editionCount,
    Map<String, dynamic> ratingsData,
    int? pages,
  ) {
    final key = extractWorkKey(data['key'] as String? ?? '');
    final covers = (data['covers'] as List?)?.cast<int>() ?? [];
    final coverId = covers.isNotEmpty ? covers.first : null;
    final cover = coverUrl(coverId, size: 'M');
    final coverLarge = coverUrl(coverId, size: 'L');
    final rating = (ratingsData['summary']?['average'] as num?)?.toDouble();

    // Description can be a string or a map with 'value'.
    String? description;
    final desc = data['description'];
    if (desc is String) {
      description = desc;
    } else if (desc is Map) {
      description = desc['value'] as String?;
    }

    final subjects = (data['subjects'] as List?)?.cast<String>() ?? [];

    return {
      'id': key.hashCode,
      'workKey': key,
      'title': {
        'english': data['title'] as String? ?? '',
        'romaji': data['title'] as String? ?? '',
      },
      'coverImage': {
        'large': cover,
        'extraLarge': coverLarge,
      },
      'averageScore': rating != null ? (rating * 20).round().clamp(0, 100) : null,
      'genres': subjects.take(8).toList(),
      'format': 'Book',
      'authors': authorNames,
      'description': description,
      'editionCount': editionCount,
      'pages': pages,
      'firstPublishDate': data['first_publish_date'] as String?,
      'ratingsCount': (ratingsData['summary']?['count'] as num?)?.toInt(),
      'links': (data['links'] as List?)?.cast<Map<String, dynamic>>(),
    };
  }

  Map<String, dynamic> _normalizeReadingLogEntry(Map<String, dynamic> work) {
    final key = extractWorkKey(work['key'] as String? ?? '');
    final coverId = work['cover_id'] as int?;
    final cover = coverUrl(coverId, size: 'M');
    final coverLarge = coverUrl(coverId, size: 'L');
    final authors = (work['author_names'] as List?)?.cast<String>() ?? [];

    return {
      'id': key.hashCode,
      'workKey': key,
      'title': {
        'english': work['title'] as String? ?? '',
        'romaji': work['title'] as String? ?? '',
      },
      'coverImage': {
        'large': cover,
        'extraLarge': coverLarge,
      },
      'averageScore': null,
      'genres': <String>[],
      'format': 'Book',
      'authors': authors,
      'year': work['first_publish_year'] as int?,
    };
  }
}
