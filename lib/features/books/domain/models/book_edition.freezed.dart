
part of 'book_edition.dart';


T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BookEdition _$BookEditionFromJson(Map<String, dynamic> json) {
  return _BookEdition.fromJson(json);
}

mixin _$BookEdition {
  String get editionKey => throw _privateConstructorUsedError;
  String? get isbn => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  int? get pages => throw _privateConstructorUsedError;
  int? get chapters => throw _privateConstructorUsedError;
  List<String> get publishers => throw _privateConstructorUsedError;
  String? get publishDate => throw _privateConstructorUsedError;
  String? get coverUrl => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  @JsonKey(includeFromJson: false, includeToJson: false)
  $BookEditionCopyWith<BookEdition> get copyWith =>
      throw _privateConstructorUsedError;
}

abstract class $BookEditionCopyWith<$Res> {
  factory $BookEditionCopyWith(
    BookEdition value,
    $Res Function(BookEdition) then,
  ) = _$BookEditionCopyWithImpl<$Res, BookEdition>;
  @useResult
  $Res call({
    String editionKey,
    String? isbn,
    String title,
    int? pages,
    int? chapters,
    List<String> publishers,
    String? publishDate,
    String? coverUrl,
  });
}

class _$BookEditionCopyWithImpl<$Res, $Val extends BookEdition>
    implements $BookEditionCopyWith<$Res> {
  _$BookEditionCopyWithImpl(this._value, this._then);

  final $Val _value;
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? editionKey = null,
    Object? isbn = freezed,
    Object? title = null,
    Object? pages = freezed,
    Object? chapters = freezed,
    Object? publishers = null,
    Object? publishDate = freezed,
    Object? coverUrl = freezed,
  }) {
    return _then(
      _value.copyWith(
            editionKey: null == editionKey
                ? _value.editionKey
                : editionKey // ignore: cast_nullable_to_non_nullable
                      as String,
            isbn: freezed == isbn
                ? _value.isbn
                : isbn // ignore: cast_nullable_to_non_nullable
                      as String?,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            pages: freezed == pages
                ? _value.pages
                : pages // ignore: cast_nullable_to_non_nullable
                      as int?,
            chapters: freezed == chapters
                ? _value.chapters
                : chapters // ignore: cast_nullable_to_non_nullable
                      as int?,
            publishers: null == publishers
                ? _value.publishers
                : publishers // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            publishDate: freezed == publishDate
                ? _value.publishDate
                : publishDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            coverUrl: freezed == coverUrl
                ? _value.coverUrl
                : coverUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

abstract class _$$BookEditionImplCopyWith<$Res>
    implements $BookEditionCopyWith<$Res> {
  factory _$$BookEditionImplCopyWith(
    _$BookEditionImpl value,
    $Res Function(_$BookEditionImpl) then,
  ) = __$$BookEditionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String editionKey,
    String? isbn,
    String title,
    int? pages,
    int? chapters,
    List<String> publishers,
    String? publishDate,
    String? coverUrl,
  });
}

class __$$BookEditionImplCopyWithImpl<$Res>
    extends _$BookEditionCopyWithImpl<$Res, _$BookEditionImpl>
    implements _$$BookEditionImplCopyWith<$Res> {
  __$$BookEditionImplCopyWithImpl(
    _$BookEditionImpl _value,
    $Res Function(_$BookEditionImpl) _then,
  ) : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? editionKey = null,
    Object? isbn = freezed,
    Object? title = null,
    Object? pages = freezed,
    Object? chapters = freezed,
    Object? publishers = null,
    Object? publishDate = freezed,
    Object? coverUrl = freezed,
  }) {
    return _then(
      _$BookEditionImpl(
        editionKey: null == editionKey
            ? _value.editionKey
            : editionKey // ignore: cast_nullable_to_non_nullable
                  as String,
        isbn: freezed == isbn
            ? _value.isbn
            : isbn // ignore: cast_nullable_to_non_nullable
                  as String?,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        pages: freezed == pages
            ? _value.pages
            : pages // ignore: cast_nullable_to_non_nullable
                  as int?,
        chapters: freezed == chapters
            ? _value.chapters
            : chapters // ignore: cast_nullable_to_non_nullable
                  as int?,
        publishers: null == publishers
            ? _value._publishers
            : publishers // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        publishDate: freezed == publishDate
            ? _value.publishDate
            : publishDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        coverUrl: freezed == coverUrl
            ? _value.coverUrl
            : coverUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

@JsonSerializable()
class _$BookEditionImpl implements _BookEdition {
  const _$BookEditionImpl({
    required this.editionKey,
    this.isbn,
    this.title = '',
    this.pages,
    this.chapters,
    final List<String> publishers = const <String>[],
    this.publishDate,
    this.coverUrl,
  }) : _publishers = publishers;

  factory _$BookEditionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BookEditionImplFromJson(json);

  @override
  final String editionKey;
  @override
  final String? isbn;
  @override
  @JsonKey()
  final String title;
  @override
  final int? pages;
  @override
  final int? chapters;
  final List<String> _publishers;
  @override
  @JsonKey()
  List<String> get publishers {
    if (_publishers is EqualUnmodifiableListView) return _publishers;
    return EqualUnmodifiableListView(_publishers);
  }

  @override
  final String? publishDate;
  @override
  final String? coverUrl;

  @override
  String toString() {
    return 'BookEdition(editionKey: $editionKey, isbn: $isbn, title: $title, pages: $pages, chapters: $chapters, publishers: $publishers, publishDate: $publishDate, coverUrl: $coverUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BookEditionImpl &&
            (identical(other.editionKey, editionKey) ||
                other.editionKey == editionKey) &&
            (identical(other.isbn, isbn) || other.isbn == isbn) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.pages, pages) || other.pages == pages) &&
            (identical(other.chapters, chapters) ||
                other.chapters == chapters) &&
            const DeepCollectionEquality().equals(
              other._publishers,
              _publishers,
            ) &&
            (identical(other.publishDate, publishDate) ||
                other.publishDate == publishDate) &&
            (identical(other.coverUrl, coverUrl) ||
                other.coverUrl == coverUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    editionKey,
    isbn,
    title,
    pages,
    chapters,
    const DeepCollectionEquality().hash(_publishers),
    publishDate,
    coverUrl,
  );

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BookEditionImplCopyWith<_$BookEditionImpl> get copyWith =>
      __$$BookEditionImplCopyWithImpl<_$BookEditionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BookEditionImplToJson(this);
  }
}

abstract class _BookEdition implements BookEdition {
  const factory _BookEdition({
    required final String editionKey,
    final String? isbn,
    final String title,
    final int? pages,
    final int? chapters,
    final List<String> publishers,
    final String? publishDate,
    final String? coverUrl,
  }) = _$BookEditionImpl;

  factory _BookEdition.fromJson(Map<String, dynamic> json) =
      _$BookEditionImpl.fromJson;

  @override
  String get editionKey;
  @override
  String? get isbn;
  @override
  String get title;
  @override
  int? get pages;
  @override
  int? get chapters;
  @override
  List<String> get publishers;
  @override
  String? get publishDate;
  @override
  String? get coverUrl;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BookEditionImplCopyWith<_$BookEditionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
