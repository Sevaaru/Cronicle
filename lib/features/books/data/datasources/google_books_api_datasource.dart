import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/api_endpoints.dart';

/// REST datasource for the Google Books API v1.
///
/// Public endpoints use `key=` query param for quota tracking.
/// https://developers.google.com/books/docs/v1/reference/volumes
class GoogleBooksApiDatasource {
  GoogleBooksApiDatasource(this._dio, {String? apiKey})
      : _apiKey = apiKey ?? EnvConfig.googleBooksApiKey;

  final Dio _dio;
  final String _apiKey;

  static const _base = ApiEndpoints.googleBooksV1;

  /// Google Books categories that indicate manga / Japanese comics
  /// (already covered by AniList).
  static bool categoriesIndicateManga(Iterable<String> categories) {
    for (final c in categories) {
      final t = c.toLowerCase().trim();
      if (t.isEmpty) continue;
      if (t.contains('manga')) return true;
      if (t.contains('japanese comic')) return true;
      if (t == 'comics & graphic novels / manga') return true;
    }
    return false;
  }

  static bool _volumeLooksLikeManga(Map<String, dynamic> volumeInfo) {
    final cats =
        (volumeInfo['categories'] as List?)?.cast<String>() ?? const [];
    return categoriesIndicateManga(cats);
  }

  Map<String, String> get _keyParam =>
      _apiKey.isNotEmpty ? {'key': _apiKey} : {};

  /// Convert an internal slug or a Google Books BISAC category into a safe
  /// `subject:` query value.
  ///
  /// Google Books rejects (HTTP 400) values containing reserved characters
  /// like `/`, `:`, `&`, etc. Categories returned by the API often look like
  /// `"Fiction / Fantasy / Epic"`, so we keep only the first segment and
  /// strip anything that isn't alphanumeric / space / underscore.
  static String _normalizeSubject(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
    // Take the first segment of multi-level BISAC categories.
    final slash = s.indexOf('/');
    if (slash > 0) s = s.substring(0, slash);
    s = s
        .replaceAll('_', ' ')
        .replaceAll(RegExp(r'[^A-Za-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .toLowerCase();
    return s;
  }

  /// Build a `subject:` query fragment, quoting multi-word values so that
  /// Google Books treats them as a single phrase instead of multiple terms.
  static String _subjectQuery(String raw) {
    final s = _normalizeSubject(raw);
    if (s.isEmpty) return '';
    return s.contains(' ') ? 'subject:"$s"' : 'subject:$s';
  }

  /// Options that bypass Dio's strict UTF-8 JSON transformer.
  /// We download raw bytes and decode them ourselves with `allowMalformed: true`
  /// because Google Books responses sometimes contain invalid UTF-8 sequences
  /// in book descriptions (e.g. broken Spanish accents in user-uploaded data).
  static final _bytesOptions = Options(responseType: ResponseType.bytes);

  // ---------------------------------------------------------------------------
  // Concurrency limiter (process-wide).
  //
  // Google Books rate-limits aggressive bursts (HTTP 503). Limiting in-flight
  // requests to 2 keeps things parallel-ish while staying under the limit and
  // is much faster than the previous strictly sequential approach.
  // ---------------------------------------------------------------------------

  static const _maxConcurrent = 2;
  static int _inFlight = 0;
  static final List<Completer<void>> _waiters = [];

  static Future<void> _acquireSlot() async {
    if (_inFlight < _maxConcurrent) {
      _inFlight++;
      return;
    }
    final c = Completer<void>();
    _waiters.add(c);
    await c.future;
    _inFlight++;
  }

  static void _releaseSlot() {
    _inFlight--;
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    }
  }

  /// Decode raw bytes from a Google Books response into a JSON map,
  /// tolerating malformed UTF-8 by substituting U+FFFD.
  static Map<String, dynamic> _decodeJsonBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

  /// GET that downloads bytes and decodes JSON leniently.
  /// Retries up to 3 times on HTTP 429 / 503 (rate-limit / server overload)
  /// with exponential backoff. Throttled by [_acquireSlot].
  Future<Map<String, dynamic>> _getJson(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    await _acquireSlot();
    try {
      const delays = [900, 2000];
      DioException? lastErr;
      for (var attempt = 0; attempt <= delays.length; attempt++) {
        try {
          final res = await _dio.get<List<int>>(
            path,
            queryParameters: queryParameters,
            options: _bytesOptions,
          );
          final bytes = res.data;
          if (bytes == null || bytes.isEmpty) return const {};
          return _decodeJsonBytes(bytes);
        } on DioException catch (e) {
          final code = e.response?.statusCode;
          final retriable = code == 503 || code == 429 || code == 500;
          if (retriable && attempt < delays.length) {
            lastErr = e;
            await Future<void>.delayed(
              Duration(milliseconds: delays[attempt]),
            );
            continue;
          }
          rethrow;
        }
      }
      throw lastErr!;
    } finally {
      _releaseSlot();
    }
  }

  // ---------------------------------------------------------------------------
  // Search
  // ---------------------------------------------------------------------------

  /// General search for books by free-text query.
  Future<List<Map<String, dynamic>>> searchBooks(
    String query, {
    int maxResults = 20,
    int startIndex = 0,
  }) async {
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': query,
        'printType': 'books',
        'maxResults': maxResults.clamp(1, 40),
        'startIndex': startIndex,
        'orderBy': 'relevance',
        ..._keyParam,
      },
    );
    return _extractAndNormalize(data);
  }

  /// Search books by subject/category.
  Future<List<Map<String, dynamic>>> searchBooksBySubject(
    String subject, {
    int maxResults = 40,
  }) async {
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': _subjectQuery(subject),
        'printType': 'books',
        'maxResults': maxResults.clamp(1, 40),
        'orderBy': 'relevance',
        ..._keyParam,
      },
    );
    return _extractAndNormalize(data);
  }

  /// Search books published in a specific year (and optionally month).
  Future<List<Map<String, dynamic>>> searchBooksByPublishYear({
    required int year,
    int? month,
    int limit = 40,
    int offset = 0,
  }) async {
    // Google Books doesn't have date-range filters, but we can approximate
    // using inpublisher-date isn't available; use free query instead.
    final dateQuery =
        month != null ? '$year-${month.toString().padLeft(2, '0')}' : '$year';
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': '+inpublisher:$dateQuery',
        'printType': 'books',
        'maxResults': limit.clamp(1, 40),
        'startIndex': offset,
        'orderBy': 'newest',
        ..._keyParam,
      },
    );
    return _extractAndNormalize(data);
  }

  // ---------------------------------------------------------------------------
  // Trending / Popular
  // ---------------------------------------------------------------------------

  /// Fetch popular/best-selling books for a subject.
  /// Google Books has no explicit "trending" endpoint, so we query
  /// a popular subject sorted by relevance.
  Future<List<Map<String, dynamic>>> fetchSubject(
    String subject, {
    int limit = 20,
  }) async {
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': _subjectQuery(subject),
        'printType': 'books',
        'maxResults': limit.clamp(1, 40),
        'orderBy': 'relevance',
        ..._keyParam,
      },
    );
    return _extractAndNormalize(data);
  }

  /// "Trending" substitute: best-selling fiction, newest releases, etc.
  Future<List<Map<String, dynamic>>> fetchTrending({
    int limit = 20,
  }) async {
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': 'subject:fiction',
        'printType': 'books',
        'maxResults': limit.clamp(1, 40),
        'orderBy': 'newest',
        ..._keyParam,
      },
    );
    return _extractAndNormalize(data);
  }

  // ---------------------------------------------------------------------------
  // Volume detail
  // ---------------------------------------------------------------------------

  /// Fetch full volume detail by ID (e.g. "zyTCAlFPjgYC").
  Future<Map<String, dynamic>> fetchWork(String volumeId) async {
    final data = await _getJson(
      '$_base/volumes/$volumeId',
      queryParameters: _keyParam,
    );
    return _normalizeVolume(data);
  }

  // ---------------------------------------------------------------------------
  // Editions (Google Books: same volume in different formats)
  // ---------------------------------------------------------------------------

  /// Fetch a single "edition" – in Google Books this is just another volume.
  Future<Map<String, dynamic>> fetchEdition(String volumeId) async {
    final data = await _getJson(
      '$_base/volumes/$volumeId',
      queryParameters: _keyParam,
    );
    return _normalizeEdition(data);
  }

  /// Search for related editions of a volume by title + first author.
  /// Google Books doesn't have a works→editions hierarchy like OL,
  /// so we approximate by searching the same title.
  Future<List<Map<String, dynamic>>> fetchWorkEditions(
    String volumeId, {
    int limit = 20,
  }) async {
    // First fetch the volume to get its title/author.
    final vol = await _getJson(
      '$_base/volumes/$volumeId',
      queryParameters: _keyParam,
    );
    final info = (vol['volumeInfo'] as Map<String, dynamic>?) ?? {};
    final title = info['title'] as String? ?? '';
    final authors =
        (info['authors'] as List?)?.cast<String>() ?? const [];
    final firstAuthor = authors.isNotEmpty ? authors.first : '';
    if (title.isEmpty) return [];

    final q =
        firstAuthor.isNotEmpty ? 'intitle:$title+inauthor:$firstAuthor' : 'intitle:$title';
    final data = await _getJson(
      '$_base/volumes',
      queryParameters: {
        'q': q,
        'printType': 'books',
        'maxResults': limit.clamp(1, 40),
        ..._keyParam,
      },
    );
    final items = (data['items'] as List?) ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .where((v) => v['id'] != volumeId) // exclude self
        .map((v) => _normalizeEdition(Map<String, dynamic>.from(v)))
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Helpers – image URL
  // ---------------------------------------------------------------------------

  /// Upgrade thumbnail URL: force HTTPS and request a better resolution.
  static String? _imageUrl(String? raw, {bool large = false}) {
    if (raw == null || raw.isEmpty) return null;
    var url = raw.replaceFirst('http://', 'https://');
    // Remove default zoom=1 and set a larger one for better quality.
    url = url.replaceAll(RegExp(r'&?zoom=\d'), '');
    url = url.replaceAll(RegExp(r'&?edge=curl'), '');
    if (large) {
      url += '&zoom=2';
    }
    return url;
  }

  // ---------------------------------------------------------------------------
  // Extraction + normalization
  // ---------------------------------------------------------------------------

  List<Map<String, dynamic>> _extractAndNormalize(Map<String, dynamic>? data) {
    if (data == null) return [];
    final items = (data['items'] as List?) ?? [];
    return items
        .cast<Map<String, dynamic>>()
        .where((v) {
          final info =
              (v['volumeInfo'] as Map<String, dynamic>?) ?? const {};
          return !_volumeLooksLikeManga(info);
        })
        .map(_normalizeVolume)
        .toList();
  }

  /// Normalize a Google Books volume to the same shape the app expects
  /// (compatible with `BrowseResultCard`, `BookWorkData`, etc.).
  Map<String, dynamic> _normalizeVolume(Map<String, dynamic> volume) {
    final id = volume['id'] as String? ?? '';
    final info =
        (volume['volumeInfo'] as Map<String, dynamic>?) ?? const {};
    final saleInfo =
        (volume['saleInfo'] as Map<String, dynamic>?) ?? const {};
    final accessInfo =
        (volume['accessInfo'] as Map<String, dynamic>?) ?? const {};
    final searchInfo =
        (volume['searchInfo'] as Map<String, dynamic>?) ?? const {};

    final title = info['title'] as String? ?? '';
    final subtitle = info['subtitle'] as String?;
    final fullTitle =
        subtitle != null && subtitle.isNotEmpty ? '$title: $subtitle' : title;
    final authors =
        (info['authors'] as List?)?.cast<String>() ?? const [];
    final categories =
        (info['categories'] as List?)?.cast<String>() ?? const [];
    final images =
        (info['imageLinks'] as Map<String, dynamic>?) ?? const {};
    final thumbnail = images['thumbnail'] as String? ??
        images['smallThumbnail'] as String?;
    final largeImg = images['large'] as String? ??
        images['medium'] as String? ??
        thumbnail;
    final rating = (info['averageRating'] as num?)?.toDouble();
    final ratingsCount = (info['ratingsCount'] as num?)?.toInt();

    // Description: plain text preferred, fall back to snippet.
    final description = info['description'] as String? ??
        searchInfo['textSnippet'] as String?;

    // Publish date → year
    final publishedDate = info['publishedDate'] as String?;
    int? year;
    if (publishedDate != null && publishedDate.length >= 4) {
      year = int.tryParse(publishedDate.substring(0, 4));
    }

    // Identifiers split by type
    String? isbn10;
    String? isbn13;
    final isbns = <String>[];
    final identifiers = (info['industryIdentifiers'] as List?) ?? const [];
    for (final raw in identifiers) {
      if (raw is! Map) continue;
      final type = raw['type'] as String?;
      final ident = raw['identifier'] as String?;
      if (ident == null) continue;
      isbns.add(ident);
      if (type == 'ISBN_10') isbn10 = ident;
      if (type == 'ISBN_13') isbn13 = ident;
    }

    // Sale info
    final saleability = saleInfo['saleability'] as String?;
    final isEbook = saleInfo['isEbook'] as bool? ?? false;
    final buyLink = saleInfo['buyLink'] as String?;
    final retail = saleInfo['retailPrice'] as Map<String, dynamic>?;
    final list = saleInfo['listPrice'] as Map<String, dynamic>?;
    final price = retail ?? list;
    final priceAmount = (price?['amount'] as num?)?.toDouble();
    final priceCurrency = price?['currencyCode'] as String?;

    // Access info
    final viewability = accessInfo['viewability'] as String?;
    final publicDomain = accessInfo['publicDomain'] as bool? ?? false;
    final epubAvailable =
        (accessInfo['epub'] as Map?)?['isAvailable'] as bool? ?? false;
    final pdfAvailable =
        (accessInfo['pdf'] as Map?)?['isAvailable'] as bool? ?? false;
    final webReaderLink = accessInfo['webReaderLink'] as String?;

    // Reading modes
    final readingModes =
        (info['readingModes'] as Map<String, dynamic>?) ?? const {};

    return {
      'id': id.hashCode,
      'workKey': id, // volumeId as workKey for compatibility
      'title': {
        'english': fullTitle,
        'romaji': fullTitle,
      },
      'subtitle': subtitle,
      'coverImage': {
        'large': _imageUrl(thumbnail),
        'extraLarge': _imageUrl(largeImg, large: true),
      },
      'averageScore':
          rating != null ? (rating * 20).round().clamp(0, 100) : null,
      'rawRating': rating, // 0..5
      'ratingsCount': ratingsCount,
      'genres': categories,
      'format': 'Book',
      'authors': authors,
      'year': year,
      'pages': (info['pageCount'] as num?)?.toInt(),
      'description': description,
      'publishDate': publishedDate,
      'editionCount': null,
      'isbn': isbns.isNotEmpty ? isbns.first : null,
      'isbn10': isbn10,
      'isbn13': isbn13,
      'language': info['language'] as String?,
      'publisher': info['publisher'] as String?,
      'previewLink': info['previewLink'] as String?,
      'infoLink': info['infoLink'] as String?,
      'canonicalVolumeLink': info['canonicalVolumeLink'] as String?,
      'webReaderLink': webReaderLink,
      'printType': info['printType'] as String?,
      'maturityRating': info['maturityRating'] as String?,
      'textSnippet': searchInfo['textSnippet'] as String?,
      // Sale
      'saleability': saleability,
      'isEbook': isEbook,
      'buyLink': buyLink,
      'priceAmount': priceAmount,
      'priceCurrency': priceCurrency,
      // Access
      'viewability': viewability,
      'publicDomain': publicDomain,
      'epubAvailable': epubAvailable,
      'pdfAvailable': pdfAvailable,
      // Reading modes
      'hasTextMode': readingModes['text'] as bool? ?? false,
      'hasImageMode': readingModes['image'] as bool? ?? false,
    };
  }

  /// Normalize a volume as an "edition" shape for the editions list.
  Map<String, dynamic> _normalizeEdition(Map<String, dynamic> volume) {
    final id = volume['id'] as String? ?? '';
    final info =
        (volume['volumeInfo'] as Map<String, dynamic>?) ?? const {};
    final images =
        (info['imageLinks'] as Map<String, dynamic>?) ?? const {};
    final thumbnail = images['thumbnail'] as String?;
    final isbns = (info['industryIdentifiers'] as List?)
            ?.cast<Map<String, dynamic>>()
            .map((i) => i['identifier'] as String?)
            .whereType<String>()
            .toList() ??
        [];
    final publishers = <String>[
      if (info['publisher'] != null) info['publisher'] as String,
    ];

    return {
      'editionKey': id,
      'isbn': isbns.isNotEmpty ? isbns.first : null,
      'title': info['title'] as String? ?? '',
      'pages': (info['pageCount'] as num?)?.toInt(),
      'chapters': null,
      'publishers': publishers,
      'publishDate': info['publishedDate'] as String?,
      'coverUrl': _imageUrl(thumbnail),
    };
  }
}
