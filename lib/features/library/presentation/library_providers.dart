import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:cronicle/core/database/app_database.dart';
import 'package:cronicle/core/database/database_provider.dart';
import 'package:cronicle/shared/models/media_kind.dart';

part 'library_providers.g.dart';

@riverpod
Stream<List<LibraryEntry>> libraryByKind(
  LibraryByKindRef ref,
  MediaKind kind,
) {
  final db = ref.watch(databaseProvider);
  return db.watchLibraryByKind(kind.code);
}

@riverpod
Stream<List<LibraryEntry>> libraryAll(LibraryAllRef ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllLibrary();
}
