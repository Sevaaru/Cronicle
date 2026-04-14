import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/shared/models/media_kind.dart';

part 'library_providers.g.dart';

@riverpod
Stream<List<LibraryEntry>> libraryByKind(
  LibraryByKindRef ref,
  MediaKind kind, {
  String? status,
}) {
  final db = ref.watch(databaseProvider);
  return db.watchLibraryByKind(kind.code, status: status);
}

@riverpod
Stream<List<LibraryEntry>> libraryAll(LibraryAllRef ref, {String? status}) {
  final db = ref.watch(databaseProvider);
  return db.watchAllLibrary(status: status);
}

@riverpod
Stream<List<LibraryEntry>> libraryFiltered(
  LibraryFilteredRef ref,
  MediaKind? kind,
  String? status,
) {
  final db = ref.watch(databaseProvider);
  if (kind == null) {
    return db.watchAllLibrary(status: status);
  }
  return db.watchLibraryByKind(kind.code, status: status);
}

/// Default status filter for the library (stored in SharedPreferences).
@riverpod
class DefaultLibraryFilter extends _$DefaultLibraryFilter {
  static const _key = 'default_library_filter';

  @override
  String build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString(_key) ?? 'CURRENT';
  }

  Future<void> set(String status) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_key, status);
    state = status;
  }
}

class LibraryPageParams {
  const LibraryPageParams({
    this.kindCode,
    this.status,
    this.orderBy = 'updatedAt',
    this.ascending = false,
  });
  final int? kindCode;
  final String? status;
  final String orderBy;
  final bool ascending;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LibraryPageParams &&
          kindCode == other.kindCode &&
          status == other.status &&
          orderBy == other.orderBy &&
          ascending == other.ascending;

  @override
  int get hashCode => Object.hash(kindCode, status, orderBy, ascending);
}

@riverpod
class PaginatedLibrary extends _$PaginatedLibrary {
  static const _pageSize = 15;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  int _totalLoaded = 0;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<LibraryEntry>> build(LibraryPageParams params) async {
    _hasMore = true;
    _isLoadingMore = false;
    _totalLoaded = 0;
    return _fetchPage(0);
  }

  Future<List<LibraryEntry>> _fetchPage(int offset) async {
    final db = ref.read(databaseProvider);
    final results = await db.getLibraryPage(
      kindCode: params.kindCode,
      status: params.status,
      limit: _pageSize,
      offset: offset,
      orderBy: params.orderBy,
      ascending: params.ascending,
    );
    if (results.length < _pageSize) _hasMore = false;
    _totalLoaded = offset + results.length;
    return results;
  }

  Future<void> loadMore() async {
    if (!_hasMore || _isLoadingMore) return;
    _isLoadingMore = true;
    final prev = state.valueOrNull ?? [];
    try {
      final next = await _fetchPage(_totalLoaded);
      if (next.isEmpty) {
        _hasMore = false;
      } else {
        state = AsyncData([...prev, ...next]);
      }
    } finally {
      _isLoadingMore = false;
    }
  }

  void removeEntry(int entryId) {
    final list = state.valueOrNull;
    if (list == null) return;
    state = AsyncData(list.where((e) => e.id != entryId).toList());
  }
}
