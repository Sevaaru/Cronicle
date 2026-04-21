import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/network/api_endpoints.dart';

class GoogleBooksApiDatasource {
  GoogleBooksApiDatasource(this._dio, {String? apiKey})
      : _apiKey = apiKey ?? EnvConfig.googleBooksApiKey;

  final Dio _dio;
  final String _apiKey;

  static const _base = ApiEndpoints.googleBooksV1;

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

  static String _normalizeSubject(String raw) {
    var s = raw.trim();
    if (s.isEmpty) return s;
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

  static String _subjectQuery(String raw) {
    final s = _normalizeSubject(raw);
    if (s.isEmpty) return '';
    return s.contains(' ') ? 'subject:"$s"' : 'subject:$s';
  }

  static final _bytesOptions = Options(responseType: ResponseType.bytes);


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

  static Map<String, dynamic> _decodeJsonBytes(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return const {};
  }

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

  Future<List<Map<String, dynamic>>> searchBooksByPublishYear({
    required int year,
    int? month,
    int limit = 40,
    int offset = 0,
  }) async {
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


  Future<Map<String, dynamic>> fetchWork(String volumeId) async {
    final data = await _getJson(
      '$_base/volumes/$volumeId',
      queryParameters: _keyParam,
    );
    return _normalizeVolume(data);
  }


  Future<Map<String, dynamic>> fetchEdition(String volumeId) async {
    final data = await _getJson(
      '$_base/volumes/$volumeId',
      queryParameters: _keyParam,
    );
    return _normalizeEdition(data);
  }

  Future<List<Map<String, dynamic>>> fetchWorkEditions(
    String volumeId, {
    int limit = 20,
  }) async {
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


  static String? _bestCoverUrl(
    Map<String, dynamic> imageLinks,
    String volumeId, {
    int width = 512,
  }) {
    final raw = (imageLinks['extraLarge'] ??
            imageLinks['large'] ??
            imageLinks['medium'] ??
            imageLinks['small'] ??
            imageLinks['thumbnail'] ??
            imageLinks['smallThumbnail'])
        as String?;

    if (raw != null && raw.isNotEmpty) {
      var url = raw.replaceFirst('http://', 'https://');
      url = url.replaceAll(RegExp(r'&?edge=curl'), '');
      url = url.replaceAll(RegExp(r'&?zoom=\d+'), '');
      final sep = url.contains('?') ? '&' : '?';
      url = '$url${sep}fife=w$width';
      return url;
    }

    if (volumeId.isEmpty) return null;
    return 'https://books.google.com/books/content'
        '?id=$volumeId'
        '&printsec=frontcover'
        '&img=1'
        '&zoom=1'
        '&fife=w$width';
  }


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
    final coverSmall = _bestCoverUrl(images, id, width: 256);
    final coverLarge = _bestCoverUrl(images, id, width: 768);
    final rating = (info['averageRating'] as num?)?.toDouble();
    final ratingsCount = (info['ratingsCount'] as num?)?.toInt();

    final description = info['description'] as String? ??
        searchInfo['textSnippet'] as String?;

    final publishedDate = info['publishedDate'] as String?;
    int? year;
    if (publishedDate != null && publishedDate.length >= 4) {
      year = int.tryParse(publishedDate.substring(0, 4));
    }

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

    final saleability = saleInfo['saleability'] as String?;
    final isEbook = saleInfo['isEbook'] as bool? ?? false;
    final buyLink = saleInfo['buyLink'] as String?;
    final retail = saleInfo['retailPrice'] as Map<String, dynamic>?;
    final list = saleInfo['listPrice'] as Map<String, dynamic>?;
    final price = retail ?? list;
    final priceAmount = (price?['amount'] as num?)?.toDouble();
    final priceCurrency = price?['currencyCode'] as String?;

    final viewability = accessInfo['viewability'] as String?;
    final publicDomain = accessInfo['publicDomain'] as bool? ?? false;
    final epubAvailable =
        (accessInfo['epub'] as Map?)?['isAvailable'] as bool? ?? false;
    final pdfAvailable =
        (accessInfo['pdf'] as Map?)?['isAvailable'] as bool? ?? false;
    final webReaderLink = accessInfo['webReaderLink'] as String?;

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
        'large': coverSmall,
        'extraLarge': coverLarge,
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
      'saleability': saleability,
      'isEbook': isEbook,
      'buyLink': buyLink,
      'priceAmount': priceAmount,
      'priceCurrency': priceCurrency,
      'viewability': viewability,
      'publicDomain': publicDomain,
      'epubAvailable': epubAvailable,
      'pdfAvailable': pdfAvailable,
      'hasTextMode': readingModes['text'] as bool? ?? false,
      'hasImageMode': readingModes['image'] as bool? ?? false,
    };
  }

  Map<String, dynamic> _normalizeEdition(Map<String, dynamic> volume) {
    final id = volume['id'] as String? ?? '';
    final info =
        (volume['volumeInfo'] as Map<String, dynamic>?) ?? const {};
    final images =
        (info['imageLinks'] as Map<String, dynamic>?) ?? const {};
    final coverUrl = _bestCoverUrl(images, id, width: 256);
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
      'coverUrl': coverUrl,
    };
  }
}
