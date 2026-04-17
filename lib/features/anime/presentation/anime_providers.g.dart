// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'anime_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$anilistAuthHash() => r'fe69bd0b0f85c72543958c7c0f23a9ab3deb428c';

/// See also [anilistAuth].
@ProviderFor(anilistAuth)
final anilistAuthProvider = Provider<AnilistAuthDatasource>.internal(
  anilistAuth,
  name: r'anilistAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$anilistAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistAuthRef = ProviderRef<AnilistAuthDatasource>;
String _$anilistGraphqlHash() => r'45f28e1dbe1377212646c12a5b7285ad89b186f6';

/// See also [anilistGraphql].
@ProviderFor(anilistGraphql)
final anilistGraphqlProvider = Provider<AnilistGraphqlDatasource>.internal(
  anilistGraphql,
  name: r'anilistGraphqlProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$anilistGraphqlHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistGraphqlRef = ProviderRef<AnilistGraphqlDatasource>;
String _$animeSearchHash() => r'35e00ce2ac0e3e4e146bbf1994e894cb8943adaa';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [animeSearch].
@ProviderFor(animeSearch)
const animeSearchProvider = AnimeSearchFamily();

/// See also [animeSearch].
class AnimeSearchFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [animeSearch].
  const AnimeSearchFamily();

  /// See also [animeSearch].
  AnimeSearchProvider call(String query) {
    return AnimeSearchProvider(query);
  }

  @override
  AnimeSearchProvider getProviderOverride(
    covariant AnimeSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'animeSearchProvider';
}

/// See also [animeSearch].
class AnimeSearchProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [animeSearch].
  AnimeSearchProvider(String query)
    : this._internal(
        (ref) => animeSearch(ref as AnimeSearchRef, query),
        from: animeSearchProvider,
        name: r'animeSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$animeSearchHash,
        dependencies: AnimeSearchFamily._dependencies,
        allTransitiveDependencies: AnimeSearchFamily._allTransitiveDependencies,
        query: query,
      );

  AnimeSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(AnimeSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnimeSearchProvider._internal(
        (ref) => create(ref as AnimeSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _AnimeSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnimeSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnimeSearchRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _AnimeSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with AnimeSearchRef {
  _AnimeSearchProviderElement(super.provider);

  @override
  String get query => (origin as AnimeSearchProvider).query;
}

String _$anilistSearchHash() => r'8114907a7f51a16d9a3d620e5cdde20321d83f21';

/// See also [anilistSearch].
@ProviderFor(anilistSearch)
const anilistSearchProvider = AnilistSearchFamily();

/// See also [anilistSearch].
class AnilistSearchFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [anilistSearch].
  const AnilistSearchFamily();

  /// See also [anilistSearch].
  AnilistSearchProvider call(String query, String type) {
    return AnilistSearchProvider(query, type);
  }

  @override
  AnilistSearchProvider getProviderOverride(
    covariant AnilistSearchProvider provider,
  ) {
    return call(provider.query, provider.type);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistSearchProvider';
}

/// See also [anilistSearch].
class AnilistSearchProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [anilistSearch].
  AnilistSearchProvider(String query, String type)
    : this._internal(
        (ref) => anilistSearch(ref as AnilistSearchRef, query, type),
        from: anilistSearchProvider,
        name: r'anilistSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistSearchHash,
        dependencies: AnilistSearchFamily._dependencies,
        allTransitiveDependencies:
            AnilistSearchFamily._allTransitiveDependencies,
        query: query,
        type: type,
      );

  AnilistSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
    required this.type,
  }) : super.internal();

  final String query;
  final String type;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(AnilistSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistSearchProvider._internal(
        (ref) => create(ref as AnilistSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
        type: type,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _AnilistSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistSearchProvider &&
        other.query == query &&
        other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistSearchRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;

  /// The parameter `type` of this provider.
  String get type;
}

class _AnilistSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with AnilistSearchRef {
  _AnilistSearchProviderElement(super.provider);

  @override
  String get query => (origin as AnilistSearchProvider).query;
  @override
  String get type => (origin as AnilistSearchProvider).type;
}

String _$anilistPopularHash() => r'826a57452f2eb04036eb7332ccb7b8bef546f60f';

/// See also [anilistPopular].
@ProviderFor(anilistPopular)
const anilistPopularProvider = AnilistPopularFamily();

/// See also [anilistPopular].
class AnilistPopularFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [anilistPopular].
  const AnilistPopularFamily();

  /// See also [anilistPopular].
  AnilistPopularProvider call(String type) {
    return AnilistPopularProvider(type);
  }

  @override
  AnilistPopularProvider getProviderOverride(
    covariant AnilistPopularProvider provider,
  ) {
    return call(provider.type);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistPopularProvider';
}

/// See also [anilistPopular].
class AnilistPopularProvider
    extends FutureProvider<List<Map<String, dynamic>>> {
  /// See also [anilistPopular].
  AnilistPopularProvider(String type)
    : this._internal(
        (ref) => anilistPopular(ref as AnilistPopularRef, type),
        from: anilistPopularProvider,
        name: r'anilistPopularProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistPopularHash,
        dependencies: AnilistPopularFamily._dependencies,
        allTransitiveDependencies:
            AnilistPopularFamily._allTransitiveDependencies,
        type: type,
      );

  AnilistPopularProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
  }) : super.internal();

  final String type;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(AnilistPopularRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistPopularProvider._internal(
        (ref) => create(ref as AnilistPopularRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _AnilistPopularProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistPopularProvider && other.type == type;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistPopularRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `type` of this provider.
  String get type;
}

class _AnilistPopularProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with AnilistPopularRef {
  _AnilistPopularProviderElement(super.provider);

  @override
  String get type => (origin as AnilistPopularProvider).type;
}

String _$anilistMediaDetailHash() =>
    r'a8ddcfd22e60e5fc9e3a305b002fb2b2da212f03';

/// See also [anilistMediaDetail].
@ProviderFor(anilistMediaDetail)
const anilistMediaDetailProvider = AnilistMediaDetailFamily();

/// See also [anilistMediaDetail].
class AnilistMediaDetailFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [anilistMediaDetail].
  const AnilistMediaDetailFamily();

  /// See also [anilistMediaDetail].
  AnilistMediaDetailProvider call(int mediaId) {
    return AnilistMediaDetailProvider(mediaId);
  }

  @override
  AnilistMediaDetailProvider getProviderOverride(
    covariant AnilistMediaDetailProvider provider,
  ) {
    return call(provider.mediaId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistMediaDetailProvider';
}

/// See also [anilistMediaDetail].
class AnilistMediaDetailProvider extends FutureProvider<Map<String, dynamic>?> {
  /// See also [anilistMediaDetail].
  AnilistMediaDetailProvider(int mediaId)
    : this._internal(
        (ref) => anilistMediaDetail(ref as AnilistMediaDetailRef, mediaId),
        from: anilistMediaDetailProvider,
        name: r'anilistMediaDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistMediaDetailHash,
        dependencies: AnilistMediaDetailFamily._dependencies,
        allTransitiveDependencies:
            AnilistMediaDetailFamily._allTransitiveDependencies,
        mediaId: mediaId,
      );

  AnilistMediaDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mediaId,
  }) : super.internal();

  final int mediaId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(AnilistMediaDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistMediaDetailProvider._internal(
        (ref) => create(ref as AnilistMediaDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mediaId: mediaId,
      ),
    );
  }

  @override
  FutureProviderElement<Map<String, dynamic>?> createElement() {
    return _AnilistMediaDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistMediaDetailProvider && other.mediaId == mediaId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mediaId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistMediaDetailRef on FutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `mediaId` of this provider.
  int get mediaId;
}

class _AnilistMediaDetailProviderElement
    extends FutureProviderElement<Map<String, dynamic>?>
    with AnilistMediaDetailRef {
  _AnilistMediaDetailProviderElement(super.provider);

  @override
  int get mediaId => (origin as AnilistMediaDetailProvider).mediaId;
}

String _$anilistProfileHash() => r'5db6478c90720d03d1a8f9d9dec4c26f09733e9c';

/// Full Anilist user profile with statistics (requires auth).
///
/// Copied from [anilistProfile].
@ProviderFor(anilistProfile)
final anilistProfileProvider =
    AutoDisposeFutureProvider<Map<String, dynamic>?>.internal(
      anilistProfile,
      name: r'anilistProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistProfileRef = AutoDisposeFutureProviderRef<Map<String, dynamic>?>;
String _$anilistUnreadNotificationCountHash() =>
    r'cdbb49ad2a1a7302397663a5190b7950278a241a';

/// Unread Anilist notification count (0 if not logged in).
///
/// Copied from [anilistUnreadNotificationCount].
@ProviderFor(anilistUnreadNotificationCount)
final anilistUnreadNotificationCountProvider =
    AutoDisposeFutureProvider<int>.internal(
      anilistUnreadNotificationCount,
      name: r'anilistUnreadNotificationCountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistUnreadNotificationCountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistUnreadNotificationCountRef = AutoDisposeFutureProviderRef<int>;
String _$anilistNotificationsListHash() =>
    r'6b1ba8f56841a07785f91c44bacf28011bd215b2';

/// First page of Anilist notifications; [resetNotificationCount] clears unread on Anilist.
///
/// Copied from [anilistNotificationsList].
@ProviderFor(anilistNotificationsList)
final anilistNotificationsListProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      anilistNotificationsList,
      name: r'anilistNotificationsListProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistNotificationsListHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistNotificationsListRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$anilistTokenHash() => r'13285f73bea2cef67a42d2e5eefee55a6f6a2352';

/// See also [AnilistToken].
@ProviderFor(AnilistToken)
final anilistTokenProvider =
    AutoDisposeAsyncNotifierProvider<AnilistToken, String?>.internal(
      AnilistToken.new,
      name: r'anilistTokenProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistTokenHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistToken = AutoDisposeAsyncNotifier<String?>;
String _$anilistBrowseMediaHash() =>
    r'106e55779cd632b571dd364038ab5f7ca604caad';

abstract class _$AnilistBrowseMedia
    extends BuildlessAutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  late final String type;
  late final String category;

  FutureOr<List<Map<String, dynamic>>> build(String type, String category);
}

/// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
///
/// Copied from [AnilistBrowseMedia].
@ProviderFor(AnilistBrowseMedia)
const anilistBrowseMediaProvider = AnilistBrowseMediaFamily();

/// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
///
/// Copied from [AnilistBrowseMedia].
class AnilistBrowseMediaFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
  ///
  /// Copied from [AnilistBrowseMedia].
  const AnilistBrowseMediaFamily();

  /// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
  ///
  /// Copied from [AnilistBrowseMedia].
  AnilistBrowseMediaProvider call(String type, String category) {
    return AnilistBrowseMediaProvider(type, category);
  }

  @override
  AnilistBrowseMediaProvider getProviderOverride(
    covariant AnilistBrowseMediaProvider provider,
  ) {
    return call(provider.type, provider.category);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistBrowseMediaProvider';
}

/// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
///
/// Copied from [AnilistBrowseMedia].
class AnilistBrowseMediaProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AnilistBrowseMedia,
          List<Map<String, dynamic>>
        > {
  /// Anilist home browse: [type] `ANIME`/`MANGA`, [category] `seasonal`/`top_rated`/`upcoming`/`recently_released`.
  ///
  /// Copied from [AnilistBrowseMedia].
  AnilistBrowseMediaProvider(String type, String category)
    : this._internal(
        () => AnilistBrowseMedia()
          ..type = type
          ..category = category,
        from: anilistBrowseMediaProvider,
        name: r'anilistBrowseMediaProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistBrowseMediaHash,
        dependencies: AnilistBrowseMediaFamily._dependencies,
        allTransitiveDependencies:
            AnilistBrowseMediaFamily._allTransitiveDependencies,
        type: type,
        category: category,
      );

  AnilistBrowseMediaProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
    required this.category,
  }) : super.internal();

  final String type;
  final String category;

  @override
  FutureOr<List<Map<String, dynamic>>> runNotifierBuild(
    covariant AnilistBrowseMedia notifier,
  ) {
    return notifier.build(type, category);
  }

  @override
  Override overrideWith(AnilistBrowseMedia Function() create) {
    return ProviderOverride(
      origin: this,
      override: AnilistBrowseMediaProvider._internal(
        () => create()
          ..type = type
          ..category = category,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
        category: category,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    AnilistBrowseMedia,
    List<Map<String, dynamic>>
  >
  createElement() {
    return _AnilistBrowseMediaProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistBrowseMediaProvider &&
        other.type == type &&
        other.category == category;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, category.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistBrowseMediaRef
    on AutoDisposeAsyncNotifierProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `type` of this provider.
  String get type;

  /// The parameter `category` of this provider.
  String get category;
}

class _AnilistBrowseMediaProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AnilistBrowseMedia,
          List<Map<String, dynamic>>
        >
    with AnilistBrowseMediaRef {
  _AnilistBrowseMediaProviderElement(super.provider);

  @override
  String get type => (origin as AnilistBrowseMediaProvider).type;
  @override
  String get category => (origin as AnilistBrowseMediaProvider).category;
}

String _$anilistFeedHash() => r'a8c3e289db092b15bb49b8116d5135ff3695b381';

/// See also [AnilistFeed].
@ProviderFor(AnilistFeed)
final anilistFeedProvider =
    AutoDisposeAsyncNotifierProvider<AnilistFeed, List<FeedActivity>>.internal(
      AnilistFeed.new,
      name: r'anilistFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistFeed = AutoDisposeAsyncNotifier<List<FeedActivity>>;
String _$anilistFeedByTypeHash() => r'7e5640fd3b35f3c38f878c76331b629c158c907f';

abstract class _$AnilistFeedByType
    extends BuildlessAutoDisposeAsyncNotifier<List<FeedActivity>> {
  late final String activityType;

  FutureOr<List<FeedActivity>> build(String activityType);
}

/// See also [AnilistFeedByType].
@ProviderFor(AnilistFeedByType)
const anilistFeedByTypeProvider = AnilistFeedByTypeFamily();

/// See also [AnilistFeedByType].
class AnilistFeedByTypeFamily extends Family<AsyncValue<List<FeedActivity>>> {
  /// See also [AnilistFeedByType].
  const AnilistFeedByTypeFamily();

  /// See also [AnilistFeedByType].
  AnilistFeedByTypeProvider call(String activityType) {
    return AnilistFeedByTypeProvider(activityType);
  }

  @override
  AnilistFeedByTypeProvider getProviderOverride(
    covariant AnilistFeedByTypeProvider provider,
  ) {
    return call(provider.activityType);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistFeedByTypeProvider';
}

/// See also [AnilistFeedByType].
class AnilistFeedByTypeProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AnilistFeedByType,
          List<FeedActivity>
        > {
  /// See also [AnilistFeedByType].
  AnilistFeedByTypeProvider(String activityType)
    : this._internal(
        () => AnilistFeedByType()..activityType = activityType,
        from: anilistFeedByTypeProvider,
        name: r'anilistFeedByTypeProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistFeedByTypeHash,
        dependencies: AnilistFeedByTypeFamily._dependencies,
        allTransitiveDependencies:
            AnilistFeedByTypeFamily._allTransitiveDependencies,
        activityType: activityType,
      );

  AnilistFeedByTypeProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.activityType,
  }) : super.internal();

  final String activityType;

  @override
  FutureOr<List<FeedActivity>> runNotifierBuild(
    covariant AnilistFeedByType notifier,
  ) {
    return notifier.build(activityType);
  }

  @override
  Override overrideWith(AnilistFeedByType Function() create) {
    return ProviderOverride(
      origin: this,
      override: AnilistFeedByTypeProvider._internal(
        () => create()..activityType = activityType,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        activityType: activityType,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AnilistFeedByType, List<FeedActivity>>
  createElement() {
    return _AnilistFeedByTypeProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistFeedByTypeProvider &&
        other.activityType == activityType;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activityType.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistFeedByTypeRef
    on AutoDisposeAsyncNotifierProviderRef<List<FeedActivity>> {
  /// The parameter `activityType` of this provider.
  String get activityType;
}

class _AnilistFeedByTypeProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AnilistFeedByType,
          List<FeedActivity>
        >
    with AnilistFeedByTypeRef {
  _AnilistFeedByTypeProviderElement(super.provider);

  @override
  String get activityType => (origin as AnilistFeedByTypeProvider).activityType;
}

String _$anilistFeedFollowingHash() =>
    r'a28c31d1d06ba0414b12ec5998b40a958b101657';

/// See also [AnilistFeedFollowing].
@ProviderFor(AnilistFeedFollowing)
final anilistFeedFollowingProvider =
    AutoDisposeAsyncNotifierProvider<
      AnilistFeedFollowing,
      List<FeedActivity>
    >.internal(
      AnilistFeedFollowing.new,
      name: r'anilistFeedFollowingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistFeedFollowingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistFeedFollowing = AutoDisposeAsyncNotifier<List<FeedActivity>>;
String _$anilistGenreTagBrowseHash() =>
    r'852d6d158b5f3fa26afeba8af4ca8474cd730902';

abstract class _$AnilistGenreTagBrowse
    extends BuildlessAutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  late final String mediaType;
  late final String sortKey;
  late final String genrePart;
  late final String tagPart;

  FutureOr<List<Map<String, dynamic>>> build(
    String mediaType,
    String sortKey,
    String genrePart,
    String tagPart,
  );
}

/// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
///
/// Copied from [AnilistGenreTagBrowse].
@ProviderFor(AnilistGenreTagBrowse)
const anilistGenreTagBrowseProvider = AnilistGenreTagBrowseFamily();

/// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
///
/// Copied from [AnilistGenreTagBrowse].
class AnilistGenreTagBrowseFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
  ///
  /// Copied from [AnilistGenreTagBrowse].
  const AnilistGenreTagBrowseFamily();

  /// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
  ///
  /// Copied from [AnilistGenreTagBrowse].
  AnilistGenreTagBrowseProvider call(
    String mediaType,
    String sortKey,
    String genrePart,
    String tagPart,
  ) {
    return AnilistGenreTagBrowseProvider(
      mediaType,
      sortKey,
      genrePart,
      tagPart,
    );
  }

  @override
  AnilistGenreTagBrowseProvider getProviderOverride(
    covariant AnilistGenreTagBrowseProvider provider,
  ) {
    return call(
      provider.mediaType,
      provider.sortKey,
      provider.genrePart,
      provider.tagPart,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistGenreTagBrowseProvider';
}

/// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
///
/// Copied from [AnilistGenreTagBrowse].
class AnilistGenreTagBrowseProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AnilistGenreTagBrowse,
          List<Map<String, dynamic>>
        > {
  /// Listado por género o etiqueta (Anilist); [genrePart] / [tagPart] vacíos = sin filtro.
  ///
  /// Copied from [AnilistGenreTagBrowse].
  AnilistGenreTagBrowseProvider(
    String mediaType,
    String sortKey,
    String genrePart,
    String tagPart,
  ) : this._internal(
        () => AnilistGenreTagBrowse()
          ..mediaType = mediaType
          ..sortKey = sortKey
          ..genrePart = genrePart
          ..tagPart = tagPart,
        from: anilistGenreTagBrowseProvider,
        name: r'anilistGenreTagBrowseProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistGenreTagBrowseHash,
        dependencies: AnilistGenreTagBrowseFamily._dependencies,
        allTransitiveDependencies:
            AnilistGenreTagBrowseFamily._allTransitiveDependencies,
        mediaType: mediaType,
        sortKey: sortKey,
        genrePart: genrePart,
        tagPart: tagPart,
      );

  AnilistGenreTagBrowseProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.mediaType,
    required this.sortKey,
    required this.genrePart,
    required this.tagPart,
  }) : super.internal();

  final String mediaType;
  final String sortKey;
  final String genrePart;
  final String tagPart;

  @override
  FutureOr<List<Map<String, dynamic>>> runNotifierBuild(
    covariant AnilistGenreTagBrowse notifier,
  ) {
    return notifier.build(mediaType, sortKey, genrePart, tagPart);
  }

  @override
  Override overrideWith(AnilistGenreTagBrowse Function() create) {
    return ProviderOverride(
      origin: this,
      override: AnilistGenreTagBrowseProvider._internal(
        () => create()
          ..mediaType = mediaType
          ..sortKey = sortKey
          ..genrePart = genrePart
          ..tagPart = tagPart,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        mediaType: mediaType,
        sortKey: sortKey,
        genrePart: genrePart,
        tagPart: tagPart,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<
    AnilistGenreTagBrowse,
    List<Map<String, dynamic>>
  >
  createElement() {
    return _AnilistGenreTagBrowseProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistGenreTagBrowseProvider &&
        other.mediaType == mediaType &&
        other.sortKey == sortKey &&
        other.genrePart == genrePart &&
        other.tagPart == tagPart;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, mediaType.hashCode);
    hash = _SystemHash.combine(hash, sortKey.hashCode);
    hash = _SystemHash.combine(hash, genrePart.hashCode);
    hash = _SystemHash.combine(hash, tagPart.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistGenreTagBrowseRef
    on AutoDisposeAsyncNotifierProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `mediaType` of this provider.
  String get mediaType;

  /// The parameter `sortKey` of this provider.
  String get sortKey;

  /// The parameter `genrePart` of this provider.
  String get genrePart;

  /// The parameter `tagPart` of this provider.
  String get tagPart;
}

class _AnilistGenreTagBrowseProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          AnilistGenreTagBrowse,
          List<Map<String, dynamic>>
        >
    with AnilistGenreTagBrowseRef {
  _AnilistGenreTagBrowseProviderElement(super.provider);

  @override
  String get mediaType => (origin as AnilistGenreTagBrowseProvider).mediaType;
  @override
  String get sortKey => (origin as AnilistGenreTagBrowseProvider).sortKey;
  @override
  String get genrePart => (origin as AnilistGenreTagBrowseProvider).genrePart;
  @override
  String get tagPart => (origin as AnilistGenreTagBrowseProvider).tagPart;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
