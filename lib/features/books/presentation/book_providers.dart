import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/network/dio_provider.dart';
import 'package:cronicle/features/books/domain/models/book_edition.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/features/books/data/datasources/openlibrary_api_datasource.dart';

part 'book_providers.g.dart';

// ---------------------------------------------------------------------------
// Datasource singleton
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
OpenLibraryApiDatasource openLibraryApi(OpenLibraryApiRef ref) {
  return OpenLibraryApiDatasource(ref.watch(dioProvider));
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
  final api = ref.watch(openLibraryApiProvider);
  return api.searchBooks(query, limit: 25);
}

// ---------------------------------------------------------------------------
// Trending / Discover
// ---------------------------------------------------------------------------

@riverpod
Future<List<Map<String, dynamic>>> bookTrending(BookTrendingRef ref) async {
  final api = ref.watch(openLibraryApiProvider);
  return api.fetchTrending(limit: 20);
}

@riverpod
Future<List<Map<String, dynamic>>> bookSubject(
  BookSubjectRef ref,
  String subject,
) async {
  final api = ref.watch(openLibraryApiProvider);
  return api.fetchSubject(subject, limit: 20);
}

// ---------------------------------------------------------------------------
// Work detail
// ---------------------------------------------------------------------------

@riverpod
Future<Map<String, dynamic>> bookWork(BookWorkRef ref, String workKey) async {
  final api = ref.watch(openLibraryApiProvider);
  return api.fetchWork(workKey);
}

// ---------------------------------------------------------------------------
// User reading log
// ---------------------------------------------------------------------------

@riverpod
Future<List<Map<String, dynamic>>> bookUserReadingLog(
  BookUserReadingLogRef ref,
  String username,
  String shelf,
) async {
  final api = ref.watch(openLibraryApiProvider);
  return api.fetchUserReadingLog(username, shelf, limit: 100);
}

// ---------------------------------------------------------------------------
// OpenLibrary username (stored locally)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class OpenLibraryUsername extends _$OpenLibraryUsername {
  @override
  String? build() => null;

  void set(String? username) => state = username;
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
  final api = ref.watch(openLibraryApiProvider);
  return api.searchBooksBySubject(subject, limit: limit);
}

// ---------------------------------------------------------------------------
// Editions for a work
// ---------------------------------------------------------------------------

@riverpod
Future<List<Map<String, dynamic>>> bookWorkEditions(
  BookWorkEditionsRef ref,
  String workKey,
) async {
  final api = ref.watch(openLibraryApiProvider);
  return api.fetchWorkEditions(workKey, limit: 50);
}

@riverpod
Future<Map<String, dynamic>> bookEdition(
  BookEditionRef ref,
  String editionKey,
) async {
  final api = ref.watch(openLibraryApiProvider);
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
