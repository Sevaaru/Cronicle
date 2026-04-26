// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

MediaItem _$MediaItemFromJson(Map<String, dynamic> json) {
  return _MediaItem.fromJson(json);
}

/// @nodoc
mixin _$MediaItem {
  int? get localId => throw _privateConstructorUsedError;
  MediaKind get kind => throw _privateConstructorUsedError;
  String get externalId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get posterUrl => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  int? get score => throw _privateConstructorUsedError;
  int? get progress => throw _privateConstructorUsedError;
  int? get totalEpisodes => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime? get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this MediaItem to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaItemCopyWith<MediaItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaItemCopyWith<$Res> {
  factory $MediaItemCopyWith(MediaItem value, $Res Function(MediaItem) then) =
      _$MediaItemCopyWithImpl<$Res, MediaItem>;
  @useResult
  $Res call({
    int? localId,
    MediaKind kind,
    String externalId,
    String title,
    String? posterUrl,
    String status,
    int? score,
    int? progress,
    int? totalEpisodes,
    String? notes,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$MediaItemCopyWithImpl<$Res, $Val extends MediaItem>
    implements $MediaItemCopyWith<$Res> {
  _$MediaItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localId = freezed,
    Object? kind = null,
    Object? externalId = null,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? status = null,
    Object? score = freezed,
    Object? progress = freezed,
    Object? totalEpisodes = freezed,
    Object? notes = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            localId: freezed == localId
                ? _value.localId
                : localId // ignore: cast_nullable_to_non_nullable
                      as int?,
            kind: null == kind
                ? _value.kind
                : kind // ignore: cast_nullable_to_non_nullable
                      as MediaKind,
            externalId: null == externalId
                ? _value.externalId
                : externalId // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            posterUrl: freezed == posterUrl
                ? _value.posterUrl
                : posterUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as String,
            score: freezed == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int?,
            progress: freezed == progress
                ? _value.progress
                : progress // ignore: cast_nullable_to_non_nullable
                      as int?,
            totalEpisodes: freezed == totalEpisodes
                ? _value.totalEpisodes
                : totalEpisodes // ignore: cast_nullable_to_non_nullable
                      as int?,
            notes: freezed == notes
                ? _value.notes
                : notes // ignore: cast_nullable_to_non_nullable
                      as String?,
            updatedAt: freezed == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MediaItemImplCopyWith<$Res>
    implements $MediaItemCopyWith<$Res> {
  factory _$$MediaItemImplCopyWith(
    _$MediaItemImpl value,
    $Res Function(_$MediaItemImpl) then,
  ) = __$$MediaItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int? localId,
    MediaKind kind,
    String externalId,
    String title,
    String? posterUrl,
    String status,
    int? score,
    int? progress,
    int? totalEpisodes,
    String? notes,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$$MediaItemImplCopyWithImpl<$Res>
    extends _$MediaItemCopyWithImpl<$Res, _$MediaItemImpl>
    implements _$$MediaItemImplCopyWith<$Res> {
  __$$MediaItemImplCopyWithImpl(
    _$MediaItemImpl _value,
    $Res Function(_$MediaItemImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? localId = freezed,
    Object? kind = null,
    Object? externalId = null,
    Object? title = null,
    Object? posterUrl = freezed,
    Object? status = null,
    Object? score = freezed,
    Object? progress = freezed,
    Object? totalEpisodes = freezed,
    Object? notes = freezed,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _$MediaItemImpl(
        localId: freezed == localId
            ? _value.localId
            : localId // ignore: cast_nullable_to_non_nullable
                  as int?,
        kind: null == kind
            ? _value.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as MediaKind,
        externalId: null == externalId
            ? _value.externalId
            : externalId // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        posterUrl: freezed == posterUrl
            ? _value.posterUrl
            : posterUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as String,
        score: freezed == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int?,
        progress: freezed == progress
            ? _value.progress
            : progress // ignore: cast_nullable_to_non_nullable
                  as int?,
        totalEpisodes: freezed == totalEpisodes
            ? _value.totalEpisodes
            : totalEpisodes // ignore: cast_nullable_to_non_nullable
                  as int?,
        notes: freezed == notes
            ? _value.notes
            : notes // ignore: cast_nullable_to_non_nullable
                  as String?,
        updatedAt: freezed == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MediaItemImpl implements _MediaItem {
  const _$MediaItemImpl({
    this.localId,
    required this.kind,
    required this.externalId,
    required this.title,
    this.posterUrl,
    this.status = 'planning',
    this.score,
    this.progress,
    this.totalEpisodes,
    this.notes,
    this.updatedAt,
  });

  factory _$MediaItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaItemImplFromJson(json);

  @override
  final int? localId;
  @override
  final MediaKind kind;
  @override
  final String externalId;
  @override
  final String title;
  @override
  final String? posterUrl;
  @override
  @JsonKey()
  final String status;
  @override
  final int? score;
  @override
  final int? progress;
  @override
  final int? totalEpisodes;
  @override
  final String? notes;
  @override
  final DateTime? updatedAt;

  @override
  String toString() {
    return 'MediaItem(localId: $localId, kind: $kind, externalId: $externalId, title: $title, posterUrl: $posterUrl, status: $status, score: $score, progress: $progress, totalEpisodes: $totalEpisodes, notes: $notes, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaItemImpl &&
            (identical(other.localId, localId) || other.localId == localId) &&
            (identical(other.kind, kind) || other.kind == kind) &&
            (identical(other.externalId, externalId) ||
                other.externalId == externalId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.posterUrl, posterUrl) ||
                other.posterUrl == posterUrl) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.totalEpisodes, totalEpisodes) ||
                other.totalEpisodes == totalEpisodes) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    localId,
    kind,
    externalId,
    title,
    posterUrl,
    status,
    score,
    progress,
    totalEpisodes,
    notes,
    updatedAt,
  );

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaItemImplCopyWith<_$MediaItemImpl> get copyWith =>
      __$$MediaItemImplCopyWithImpl<_$MediaItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaItemImplToJson(this);
  }
}

abstract class _MediaItem implements MediaItem {
  const factory _MediaItem({
    final int? localId,
    required final MediaKind kind,
    required final String externalId,
    required final String title,
    final String? posterUrl,
    final String status,
    final int? score,
    final int? progress,
    final int? totalEpisodes,
    final String? notes,
    final DateTime? updatedAt,
  }) = _$MediaItemImpl;

  factory _MediaItem.fromJson(Map<String, dynamic> json) =
      _$MediaItemImpl.fromJson;

  @override
  int? get localId;
  @override
  MediaKind get kind;
  @override
  String get externalId;
  @override
  String get title;
  @override
  String? get posterUrl;
  @override
  String get status;
  @override
  int? get score;
  @override
  int? get progress;
  @override
  int? get totalEpisodes;
  @override
  String? get notes;
  @override
  DateTime? get updatedAt;

  /// Create a copy of MediaItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaItemImplCopyWith<_$MediaItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
