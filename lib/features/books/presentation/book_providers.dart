import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/books/domain/models/book_edition.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/books/data/datasources/google_books_api_datasource.dart';

part 'book_providers.g.dart';

// ---------------------------------------------------------------------------
// Datasource singleton
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GoogleBooksApiDatasource googleBooksApi(GoogleBooksApiRef ref) {
  return GoogleBooksApiDatasource(ref.watch(dioProvider));
}

// ---------------------------------------------------------------------------
// Search
// ---------------------------------------------------------------------------

@riverpod
Future<List<Map<String, dynamic>>> bookSearch(
  BookSearchRef ref,
  String query,
) async {
  if (query.isEmpty) return [];
  final api = ref.watch(googleBooksApiProvider);
  return api.searchBooks(query);
}

// ---------------------------------------------------------------------------
// Trending / Discover
// ---------------------------------------------------------------------------

/// All home feed sections, fetched sequentially to avoid rate-limit 503.
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
}

@Riverpod(keepAlive: true)
Future<BooksHomeFeedData> booksHomeFeed(BooksHomeFeedRef ref) async {
  final api = ref.watch(googleBooksApiProvider);
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

  // Fetch sequentially with delays to avoid 503 rate-limit
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
Future<List<Map<String, dynamic>>> bookTrending(BookTrendingRef ref) async {
  try {
    final api = ref.watch(googleBooksApiProvider);
    return await api.fetchTrending(limit: 20);
  } catch (_) {
    return [];
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

// ---------------------------------------------------------------------------
// Work detail
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
Future<Map<String, dynamic>> bookWork(BookWorkRef ref, String workKey) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.fetchWork(workKey);
}

// ---------------------------------------------------------------------------
// Favorite books (local, SharedPreferences — same pattern as games / trakt)
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Subject browse (uses search endpoint for richer data + client-side sorting)
// ---------------------------------------------------------------------------

@riverpod
Future<List<Map<String, dynamic>>> bookSubjectBrowse(
  BookSubjectBrowseRef ref,
  String subject, {
  int limit = 50,
}) async {
  final api = ref.watch(googleBooksApiProvider);
  return api.searchBooksBySubject(subject, maxResults: limit);
}

// ---------------------------------------------------------------------------
// Editions for a work
// ---------------------------------------------------------------------------

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
