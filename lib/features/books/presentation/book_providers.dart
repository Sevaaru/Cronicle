import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/cache/json_cache.dart';
import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/books/domain/models/book_edition.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/books/data/datasources/google_books_api_datasource.dart';

part 'book_providers.g.dart';

const String _booksHomeFeedCacheKey = 'books_home_feed';
const String _bookTrendingCacheKey = 'books_trending';


@Riverpod(keepAlive: true)
GoogleBooksApiDatasource googleBooksApi(GoogleBooksApiRef ref) {
  return GoogleBooksApiDatasource(ref.watch(dioProvider));
}


@riverpod
Future<List<Map<String, dynamic>>> bookSearch(
  BookSearchRef ref,
  String query,
) async {
  if (query.isEmpty) return [];
  final api = ref.watch(googleBooksApiProvider);
  return api.searchBooks(query);
}


class BooksHomeFeedData {
  const BooksHomeFeedData({
    required this.trending,
    required this.love,
    required this.fantasy,
    required this.scienceFiction,
    required this.classics,
    required this.mystery,
  });

  final List<Map<String, dynamic>> trending;
  final List<Map<String, dynamic>> love;
  final List<Map<String, dynamic>> fantasy;
  final List<Map<String, dynamic>> scienceFiction;
  final List<Map<String, dynamic>> classics;
  final List<Map<String, dynamic>> mystery;

  Map<String, dynamic> toJson() => {
        'trending': trending,
        'love': love,
        'fantasy': fantasy,
        'scienceFiction': scienceFiction,
        'classics': classics,
        'mystery': mystery,
      };

  factory BooksHomeFeedData.fromJson(Map<String, dynamic> json) {
    return BooksHomeFeedData(
      trending: jsonListAsMaps(json['trending']),
      love: jsonListAsMaps(json['love']),
      fantasy: jsonListAsMaps(json['fantasy']),
      scienceFiction: jsonListAsMaps(json['scienceFiction']),
      classics: jsonListAsMaps(json['classics']),
      mystery: jsonListAsMaps(json['mystery']),
    );
  }
}

Future<BooksHomeFeedData> _fetchBooksHomeFeed(
  GoogleBooksApiDatasource api,
) async {
  const delay = Duration(milliseconds: 350);

  Future<List<Map<String, dynamic>>> safe(
    Future<List<Map<String, dynamic>>> Function() fn,
  ) async {
    try {
      return await fn();
    } catch (_) {
      return [];
    }
  }

  final trending = await safe(() => api.fetchTrending(limit: 20));
  await Future<void>.delayed(delay);
  final love = await safe(() => api.fetchSubject('love', limit: 20));
  await Future<void>.delayed(delay);
  final fantasy = await safe(() => api.fetchSubject('fantasy', limit: 20));
  await Future<void>.delayed(delay);
  final sciFi = await safe(() => api.fetchSubject('science_fiction', limit: 20));
  await Future<void>.delayed(delay);
  final classics = await safe(() => api.fetchSubject('classics', limit: 20));
  await Future<void>.delayed(delay);
  final mystery = await safe(() => api.fetchSubject('mystery', limit: 20));

  return BooksHomeFeedData(
    trending: trending,
    love: love,
    fantasy: fantasy,
    scienceFiction: sciFi,
    classics: classics,
    mystery: mystery,
  );
}

@Riverpod(keepAlive: true)
class BooksHomeFeed extends _$BooksHomeFeed {
  @override
  Future<BooksHomeFeedData> build() async {
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_booksHomeFeedCacheKey);
    final api = ref.watch(googleBooksApiProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final data = await _fetchBooksHomeFeed(api);
          await cache.write(_booksHomeFeedCacheKey, data.toJson());
          state = AsyncData(data);
        } catch (_) {}
      });
      return BooksHomeFeedData.fromJson(cached.data);
    }

    final data = await _fetchBooksHomeFeed(api);
    await cache.write(_booksHomeFeedCacheKey, data.toJson());
    return data;
  }
}

@Riverpod(keepAlive: true)
class BookTrending extends _$BookTrending {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final cache = ref.read(jsonCacheProvider);
    final cached = cache.read(_bookTrendingCacheKey);
    final api = ref.watch(googleBooksApiProvider);

    if (cached != null) {
      Future<void>.microtask(() async {
        try {
          final fresh = await api.fetchTrending(limit: 20);
          await cache.write(_bookTrendingCacheKey, {'items': fresh});
          state = AsyncData(fresh);
        } catch (_) {}
      });
      return jsonListAsMaps(cached.data['items']);
    }

    try {
      final fresh = await api.fetchTrending(limit: 20);
      await cache.write(_bookTrendingCacheKey, {'items': fresh});
      return fresh;
    } catch (_) {
      return const [];
    }
  }
}

@Riverpod(keepAlive: true)
Future<List<Map<String, dynamic>>> bookSubject(
  BookSubjectRef ref,
  String subject,
) async {
  try {
    final api = ref.watch(googleBooksApiProvider);
    return await api.fetchSubject(subject, limit: 20);
  } catch (_) {
    return [];
  }
}


@Riverpod(keepAlive: true)
Future<Map<String, dynamic>> bookWork(BookWorkRef ref, String workKey) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.fetchWork(workKey);
}


const _favoriteBooksPrefsKey = 'favorite_books_v1';

List<Map<String, dynamic>> _decodeFavoriteBooksJson(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _snapshotBookForFavorites(Map<String, dynamic> book) {
  final title = book['title'] as Map<String, dynamic>? ?? {};
  final cover = book['coverImage'] as Map<String, dynamic>? ?? {};
  return {
    'id': book['id'],
    'workKey': book['workKey'],
    'title': {
      'english': title['english'],
      'romaji': title['romaji'],
    },
    'coverImage': {
      'large': cover['large'] ?? cover['extraLarge'],
    },
  };
}

@Riverpod(keepAlive: true)
class FavoriteBooks extends _$FavoriteBooks {
  @override
  List<Map<String, dynamic>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return _decodeFavoriteBooksJson(prefs.getString(_favoriteBooksPrefsKey));
  }

  Future<void> toggleFavorite(Map<String, dynamic> book) async {
    final prefs = ref.read(sharedPreferencesProvider);
    final workKey = book['workKey'] as String?;
    if (workKey == null) return;
    final next = List<Map<String, dynamic>>.from(state);
    final i = next.indexWhere((e) => e['workKey'] == workKey);
    if (i >= 0) {
      next.removeAt(i);
    } else {
      next.add(_snapshotBookForFavorites(book));
    }
    await prefs.setString(_favoriteBooksPrefsKey, jsonEncode(next));
    state = next;
  }
}


@riverpod
Future<List<Map<String, dynamic>>> bookSubjectBrowse(
  BookSubjectBrowseRef ref,
  String subject, {
  int limit = 50,
}) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.searchBooksBySubject(subject, maxResults: limit);
}


@riverpod
Future<List<Map<String, dynamic>>> bookWorkEditions(
  BookWorkEditionsRef ref,
  String workKey,
) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.fetchWorkEditions(workKey, limit: 20);
}

@riverpod
Future<Map<String, dynamic>> bookEdition(
  BookEditionRef ref,
  String editionKey,
) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.fetchEdition(editionKey);
}

@riverpod
Future<List<BookEdition>> bookWorkEditionModels(
  BookWorkEditionModelsRef ref,
  String workKey,
) async {
  final editions = await ref.watch(bookWorkEditionsProvider(workKey).future);
  return editions.map(BookEdition.fromApiMap).toList();
}
