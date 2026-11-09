import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:cronicle/shared/models/media_kind.dart';

part 'media_item.freezed.dart';
part 'media_item.g.dart';

@freezed
class MediaItem with _$MediaItem {
  const factory MediaItem({
    int? localId,
    required MediaKind kind,
    required String externalId,
    required String title,
    String? posterUrl,
    @Default('planning') String status,
    int? score,
    int? progress,
    int? totalEpisodes,
    String? notes,
    DateTime? updatedAt,
  }) = _MediaItem;

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);
}
