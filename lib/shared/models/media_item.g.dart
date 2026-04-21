// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MediaItemImpl _$$MediaItemImplFromJson(Map<String, dynamic> json) =>
    _$MediaItemImpl(
      localId: (json['localId'] as num?)?.toInt(),
      kind: $enumDecode(_$MediaKindEnumMap, json['kind']),
      externalId: json['externalId'] as String,
      title: json['title'] as String,
      posterUrl: json['posterUrl'] as String?,
      status: json['status'] as String? ?? 'planning',
      score: (json['score'] as num?)?.toInt(),
      progress: (json['progress'] as num?)?.toInt(),
      totalEpisodes: (json['totalEpisodes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$MediaItemImplToJson(_$MediaItemImpl instance) =>
    <String, dynamic>{
      'localId': instance.localId,
      'kind': _$MediaKindEnumMap[instance.kind]!,
      'externalId': instance.externalId,
      'title': instance.title,
      'posterUrl': instance.posterUrl,
      'status': instance.status,
      'score': instance.score,
      'progress': instance.progress,
      'totalEpisodes': instance.totalEpisodes,
      'notes': instance.notes,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$MediaKindEnumMap = {
  MediaKind.anime: 'anime',
  MediaKind.movie: 'movie',
  MediaKind.tv: 'tv',
  MediaKind.game: 'game',
  MediaKind.manga: 'manga',
  MediaKind.book: 'book',
};
