// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feed_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

FeedActivity _$FeedActivityFromJson(Map<String, dynamic> json) {
  return _FeedActivity.fromJson(json);
}

/// @nodoc
mixin _$FeedActivity {
  String get id => throw _privateConstructorUsedError;
  MediaKind get source => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  int? get userId => throw _privateConstructorUsedError;
  String? get userAvatarUrl => throw _privateConstructorUsedError;
  String get action => throw _privateConstructorUsedError;
  String get mediaTitle => throw _privateConstructorUsedError;
  String? get mediaPosterUrl => throw _privateConstructorUsedError;
  int? get mediaId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;
  int get likeCount => throw _privateConstructorUsedError;
  int get replyCount => throw _privateConstructorUsedError;
  bool get isLiked => throw _privateConstructorUsedError;
  bool get isTextActivity => throw _privateConstructorUsedError;

  /// Serializes this FeedActivity to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FeedActivity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FeedActivityCopyWith<FeedActivity> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FeedActivityCopyWith<$Res> {
  factory $FeedActivityCopyWith(
    FeedActivity value,
    $Res Function(FeedActivity) then,
  ) = _$FeedActivityCopyWithImpl<$Res, FeedActivity>;
  @useResult
  $Res call({
    String id,
    MediaKind source,
    String userName,
    int? userId,
    String? userAvatarUrl,
    String action,
    String mediaTitle,
    String? mediaPosterUrl,
    int? mediaId,
    DateTime createdAt,
    int likeCount,
    int replyCount,
    bool isLiked,
    bool isTextActivity,
  });
}

/// @nodoc
class _$FeedActivityCopyWithImpl<$Res, $Val extends FeedActivity>
    implements $FeedActivityCopyWith<$Res> {
  _$FeedActivityCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FeedActivity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? userName = null,
    Object? userId = freezed,
    Object? userAvatarUrl = freezed,
    Object? action = null,
    Object? mediaTitle = null,
    Object? mediaPosterUrl = freezed,
    Object? mediaId = freezed,
    Object? createdAt = null,
    Object? likeCount = null,
    Object? replyCount = null,
    Object? isLiked = null,
    Object? isTextActivity = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as MediaKind,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            userId: freezed == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as int?,
            userAvatarUrl: freezed == userAvatarUrl
                ? _value.userAvatarUrl
                : userAvatarUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            action: null == action
                ? _value.action
                : action // ignore: cast_nullable_to_non_nullable
                      as String,
            mediaTitle: null == mediaTitle
                ? _value.mediaTitle
                : mediaTitle // ignore: cast_nullable_to_non_nullable
                      as String,
            mediaPosterUrl: freezed == mediaPosterUrl
                ? _value.mediaPosterUrl
                : mediaPosterUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            mediaId: freezed == mediaId
                ? _value.mediaId
                : mediaId // ignore: cast_nullable_to_non_nullable
                      as int?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            likeCount: null == likeCount
                ? _value.likeCount
                : likeCount // ignore: cast_nullable_to_non_nullable
                      as int,
            replyCount: null == replyCount
                ? _value.replyCount
                : replyCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isLiked: null == isLiked
                ? _value.isLiked
                : isLiked // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTextActivity: null == isTextActivity
                ? _value.isTextActivity
                : isTextActivity // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$FeedActivityImplCopyWith<$Res>
    implements $FeedActivityCopyWith<$Res> {
  factory _$$FeedActivityImplCopyWith(
    _$FeedActivityImpl value,
    $Res Function(_$FeedActivityImpl) then,
  ) = __$$FeedActivityImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    MediaKind source,
    String userName,
    int? userId,
    String? userAvatarUrl,
    String action,
    String mediaTitle,
    String? mediaPosterUrl,
    int? mediaId,
    DateTime createdAt,
    int likeCount,
    int replyCount,
    bool isLiked,
    bool isTextActivity,
  });
}

/// @nodoc
class __$$FeedActivityImplCopyWithImpl<$Res>
    extends _$FeedActivityCopyWithImpl<$Res, _$FeedActivityImpl>
    implements _$$FeedActivityImplCopyWith<$Res> {
  __$$FeedActivityImplCopyWithImpl(
    _$FeedActivityImpl _value,
    $Res Function(_$FeedActivityImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of FeedActivity
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? source = null,
    Object? userName = null,
    Object? userId = freezed,
    Object? userAvatarUrl = freezed,
    Object? action = null,
    Object? mediaTitle = null,
    Object? mediaPosterUrl = freezed,
    Object? mediaId = freezed,
    Object? createdAt = null,
    Object? likeCount = null,
    Object? replyCount = null,
    Object? isLiked = null,
    Object? isTextActivity = null,
  }) {
    return _then(
      _$FeedActivityImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as MediaKind,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        userId: freezed == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as int?,
        userAvatarUrl: freezed == userAvatarUrl
            ? _value.userAvatarUrl
            : userAvatarUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        action: null == action
            ? _value.action
            : action // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaTitle: null == mediaTitle
            ? _value.mediaTitle
            : mediaTitle // ignore: cast_nullable_to_non_nullable
                  as String,
        mediaPosterUrl: freezed == mediaPosterUrl
            ? _value.mediaPosterUrl
            : mediaPosterUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        mediaId: freezed == mediaId
            ? _value.mediaId
            : mediaId // ignore: cast_nullable_to_non_nullable
                  as int?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        likeCount: null == likeCount
            ? _value.likeCount
            : likeCount // ignore: cast_nullable_to_non_nullable
                  as int,
        replyCount: null == replyCount
            ? _value.replyCount
            : replyCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isLiked: null == isLiked
            ? _value.isLiked
            : isLiked // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTextActivity: null == isTextActivity
            ? _value.isTextActivity
            : isTextActivity // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$FeedActivityImpl implements _FeedActivity {
  const _$FeedActivityImpl({
    required this.id,
    required this.source,
    required this.userName,
    this.userId,
    this.userAvatarUrl,
    required this.action,
    required this.mediaTitle,
    this.mediaPosterUrl,
    this.mediaId,
    required this.createdAt,
    this.likeCount = 0,
    this.replyCount = 0,
    this.isLiked = false,
    this.isTextActivity = false,
  });

  factory _$FeedActivityImpl.fromJson(Map<String, dynamic> json) =>
      _$$FeedActivityImplFromJson(json);

  @override
  final String id;
  @override
  final MediaKind source;
  @override
  final String userName;
  @override
  final int? userId;
  @override
  final String? userAvatarUrl;
  @override
  final String action;
  @override
  final String mediaTitle;
  @override
  final String? mediaPosterUrl;
  @override
  final int? mediaId;
  @override
  final DateTime createdAt;
  @override
  @JsonKey()
  final int likeCount;
  @override
  @JsonKey()
  final int replyCount;
  @override
  @JsonKey()
  final bool isLiked;
  @override
  @JsonKey()
  final bool isTextActivity;

  @override
  String toString() {
    return 'FeedActivity(id: $id, source: $source, userName: $userName, userId: $userId, userAvatarUrl: $userAvatarUrl, action: $action, mediaTitle: $mediaTitle, mediaPosterUrl: $mediaPosterUrl, mediaId: $mediaId, createdAt: $createdAt, likeCount: $likeCount, replyCount: $replyCount, isLiked: $isLiked, isTextActivity: $isTextActivity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FeedActivityImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userAvatarUrl, userAvatarUrl) ||
                other.userAvatarUrl == userAvatarUrl) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.mediaTitle, mediaTitle) ||
                other.mediaTitle == mediaTitle) &&
            (identical(other.mediaPosterUrl, mediaPosterUrl) ||
                other.mediaPosterUrl == mediaPosterUrl) &&
            (identical(other.mediaId, mediaId) || other.mediaId == mediaId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.likeCount, likeCount) ||
                other.likeCount == likeCount) &&
            (identical(other.replyCount, replyCount) ||
                other.replyCount == replyCount) &&
            (identical(other.isLiked, isLiked) || other.isLiked == isLiked) &&
            (identical(other.isTextActivity, isTextActivity) ||
                other.isTextActivity == isTextActivity));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    source,
    userName,
    userId,
    userAvatarUrl,
    action,
    mediaTitle,
    mediaPosterUrl,
    mediaId,
    createdAt,
    likeCount,
    replyCount,
    isLiked,
    isTextActivity,
  );

  /// Create a copy of FeedActivity
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FeedActivityImplCopyWith<_$FeedActivityImpl> get copyWith =>
      __$$FeedActivityImplCopyWithImpl<_$FeedActivityImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FeedActivityImplToJson(this);
  }
}

abstract class _FeedActivity implements FeedActivity {
  const factory _FeedActivity({
    required final String id,
    required final MediaKind source,
    required final String userName,
    final int? userId,
    final String? userAvatarUrl,
    required final String action,
    required final String mediaTitle,
    final String? mediaPosterUrl,
    final int? mediaId,
    required final DateTime createdAt,
    final int likeCount,
    final int replyCount,
    final bool isLiked,
    final bool isTextActivity,
  }) = _$FeedActivityImpl;

  factory _FeedActivity.fromJson(Map<String, dynamic> json) =
      _$FeedActivityImpl.fromJson;

  @override
  String get id;
  @override
  MediaKind get source;
  @override
  String get userName;
  @override
  int? get userId;
  @override
  String? get userAvatarUrl;
  @override
  String get action;
  @override
  String get mediaTitle;
  @override
  String? get mediaPosterUrl;
  @override
  int? get mediaId;
  @override
  DateTime get createdAt;
  @override
  int get likeCount;
  @override
  int get replyCount;
  @override
  bool get isLiked;
  @override
  bool get isTextActivity;

  /// Create a copy of FeedActivity
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FeedActivityImplCopyWith<_$FeedActivityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
