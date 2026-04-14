import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cronicle/shared/models/media_kind.dart';

part 'feed_activity.freezed.dart';
part 'feed_activity.g.dart';

@freezed
class FeedActivity with _$FeedActivity {
  const factory FeedActivity({
    required String id,
    required MediaKind source,
    required String userName,
    int? userId,
    String? userAvatarUrl,
    required String action,
    required String mediaTitle,
    String? mediaPosterUrl,
    int? mediaId,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default(0) int replyCount,
    @Default(false) bool isLiked,
  }) = _FeedActivity;

  factory FeedActivity.fromJson(Map<String, dynamic> json) =>
      _$FeedActivityFromJson(json);
}
