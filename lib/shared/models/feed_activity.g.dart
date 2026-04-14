// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feed_activity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FeedActivityImpl _$$FeedActivityImplFromJson(Map<String, dynamic> json) =>
    _$FeedActivityImpl(
      id: json['id'] as String,
      source: $enumDecode(_$MediaKindEnumMap, json['source']),
      userName: json['userName'] as String,
      userAvatarUrl: json['userAvatarUrl'] as String?,
      action: json['action'] as String,
      mediaTitle: json['mediaTitle'] as String,
      mediaPosterUrl: json['mediaPosterUrl'] as String?,
      mediaId: (json['mediaId'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$FeedActivityImplToJson(_$FeedActivityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$MediaKindEnumMap[instance.source]!,
      'userName': instance.userName,
      'userAvatarUrl': instance.userAvatarUrl,
      'action': instance.action,
      'mediaTitle': instance.mediaTitle,
      'mediaPosterUrl': instance.mediaPosterUrl,
      'mediaId': instance.mediaId,
      'createdAt': instance.createdAt.toIso8601String(),
    };

const _$MediaKindEnumMap = {
  MediaKind.anime: 'anime',
  MediaKind.movie: 'movie',
  MediaKind.tv: 'tv',
  MediaKind.game: 'game',
  MediaKind.manga: 'manga',
};
