import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_edition.freezed.dart';
part 'book_edition.g.dart';

@freezed
class BookEdition with _$BookEdition {
  const factory BookEdition({
    required String editionKey,
    String? isbn,
    @Default('') String title,
    int? pages,
    int? chapters,
    @Default(<String>[]) List<String> publishers,
    String? publishDate,
    String? coverUrl,
  }) = _BookEdition;

  factory BookEdition.fromJson(Map<String, dynamic> json) =>
      _$BookEditionFromJson(json);

  factory BookEdition.fromApiMap(Map<String, dynamic> map) {
    return BookEdition(
      editionKey: map['editionKey'] as String? ?? '',
      isbn: map['isbn'] as String?,
      title: map['title'] as String? ?? '',
      pages: (map['pages'] as num?)?.toInt(),
      chapters: (map['chapters'] as num?)?.toInt(),
      publishers:
          ((map['publishers'] as List?) ?? []).whereType<String>().toList(),
      publishDate: map['publishDate'] as String?,
      coverUrl: map['coverUrl'] as String?,
    );
  }
}
