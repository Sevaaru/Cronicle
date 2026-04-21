// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_edition.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$BookEditionImpl _$$BookEditionImplFromJson(Map<String, dynamic> json) =>
    _$BookEditionImpl(
      editionKey: json['editionKey'] as String,
      isbn: json['isbn'] as String?,
      title: json['title'] as String? ?? '',
      pages: (json['pages'] as num?)?.toInt(),
      chapters: (json['chapters'] as num?)?.toInt(),
      publishers:
          (json['publishers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      publishDate: json['publishDate'] as String?,
      coverUrl: json['coverUrl'] as String?,
    );

Map<String, dynamic> _$$BookEditionImplToJson(_$BookEditionImpl instance) =>
    <String, dynamic>{
      'editionKey': instance.editionKey,
      'isbn': instance.isbn,
      'title': instance.title,
      'pages': instance.pages,
      'chapters': instance.chapters,
      'publishers': instance.publishers,
      'publishDate': instance.publishDate,
      'coverUrl': instance.coverUrl,
    };
