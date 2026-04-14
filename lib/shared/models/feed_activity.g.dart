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
      userId: (json['userId'] as num?)?.toInt(),
      userAvatarUrl: json['userAvatarUrl'] as String?,
      action: json['action'] as String,
      mediaTitle: json['mediaTitle'] as String,
      mediaPosterUrl: json['mediaPosterUrl'] as String?,
      mediaId: (json['mediaId'] as num?)?.toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );

Map<String, dynamic> _$$FeedActivityImplToJson(_$FeedActivityImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source': _$MediaKindEnumMap[instance.source]!,
      'userName': instance.userName,
      'userId': instance.userId,
      'userAvatarUrl': instance.userAvatarUrl,
      'action': instance.action,
      'mediaTitle': instance.mediaTitle,
      'mediaPosterUrl': instance.mediaPosterUrl,
      'mediaId': instance.mediaId,
      'createdAt': instance.createdAt.toIso8601String(),
      'likeCount': instance.likeCount,
      'replyCount': instance.replyCount,
      'isLiked': instance.isLiked,
    };

const _$MediaKindEnumMap = {
  MediaKind.anime: 'anime',
  MediaKind.movie: 'movie',
  MediaKind.tv: 'tv',
  MediaKind.game: 'game',
  MediaKind.manga: 'manga',
};
