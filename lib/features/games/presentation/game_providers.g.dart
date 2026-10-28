// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$igdbAuthHash() => r'86b03390007574d673920743259401857c07ebc9';

/// See also [igdbAuth].
@ProviderFor(igdbAuth)
final igdbAuthProvider = Provider<IgdbAuthDatasource>.internal(
  igdbAuth,
  name: r'igdbAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$igdbAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IgdbAuthRef = ProviderRef<IgdbAuthDatasource>;
String _$igdbApiHash() => r'e9d3013c02920dff78ba7063f9e1eff7ab4ff656';

/// See also [igdbApi].
@ProviderFor(igdbApi)
final igdbApiProvider = Provider<IgdbApiDatasource>.internal(
  igdbApi,
  name: r'igdbApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$igdbApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IgdbApiRef = ProviderRef<IgdbApiDatasource>;
String _$igdbSearchHash() => r'055bb28ec91b36fa333bb56d61d076744f99150c';

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

/// See also [igdbSearch].
@ProviderFor(igdbSearch)
const igdbSearchProvider = IgdbSearchFamily();

/// See also [igdbSearch].
class IgdbSearchFamily extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [igdbSearch].
  const IgdbSearchFamily();

  /// See also [igdbSearch].
  IgdbSearchProvider call(String query) {
    return IgdbSearchProvider(query);
  }

  @override
  IgdbSearchProvider getProviderOverride(
    covariant IgdbSearchProvider provider,
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
  String? get name => r'igdbSearchProvider';
}

/// See also [igdbSearch].
class IgdbSearchProvider extends FutureProvider<List<Map<String, dynamic>>> {
  /// See also [igdbSearch].
  IgdbSearchProvider(String query)
    : this._internal(
        (ref) => igdbSearch(ref as IgdbSearchRef, query),
        from: igdbSearchProvider,
        name: r'igdbSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbSearchHash,
        dependencies: IgdbSearchFamily._dependencies,
        allTransitiveDependencies: IgdbSearchFamily._allTransitiveDependencies,
        query: query,
      );

  IgdbSearchProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(IgdbSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbSearchProvider._internal(
        (ref) => create(ref as IgdbSearchRef),
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
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _IgdbSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbSearchProvider && other.query == query;
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
mixin IgdbSearchRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _IgdbSearchProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with IgdbSearchRef {
  _IgdbSearchProviderElement(super.provider);

  @override
  String get query => (origin as IgdbSearchProvider).query;
}

String _$igdbGameDetailHash() => r'9b69004832c56422fd93b0280465d42917485448';

/// See also [igdbGameDetail].
@ProviderFor(igdbGameDetail)
const igdbGameDetailProvider = IgdbGameDetailFamily();

/// See also [igdbGameDetail].
class IgdbGameDetailFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [igdbGameDetail].
  const IgdbGameDetailFamily();

  /// See also [igdbGameDetail].
  IgdbGameDetailProvider call(int gameId) {
    return IgdbGameDetailProvider(gameId);
  }

  @override
  IgdbGameDetailProvider getProviderOverride(
    covariant IgdbGameDetailProvider provider,
  ) {
    return call(provider.gameId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'igdbGameDetailProvider';
}

/// See also [igdbGameDetail].
class IgdbGameDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [igdbGameDetail].
  IgdbGameDetailProvider(int gameId)
    : this._internal(
        (ref) => igdbGameDetail(ref as IgdbGameDetailRef, gameId),
        from: igdbGameDetailProvider,
        name: r'igdbGameDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbGameDetailHash,
        dependencies: IgdbGameDetailFamily._dependencies,
        allTransitiveDependencies:
            IgdbGameDetailFamily._allTransitiveDependencies,
        gameId: gameId,
      );

  IgdbGameDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.gameId,
  }) : super.internal();

  final int gameId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(IgdbGameDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbGameDetailProvider._internal(
        (ref) => create(ref as IgdbGameDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        gameId: gameId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _IgdbGameDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbGameDetailProvider && other.gameId == gameId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, gameId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IgdbGameDetailRef on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `gameId` of this provider.
  int get gameId;
}

class _IgdbGameDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with IgdbGameDetailRef {
  _IgdbGameDetailProviderElement(super.provider);

  @override
  int get gameId => (origin as IgdbGameDetailProvider).gameId;
}

String _$igdbReviewByIdHash() => r'27406cd579ea483b124241346a5d521a7d513ebb';

/// See also [igdbReviewById].
@ProviderFor(igdbReviewById)
const igdbReviewByIdProvider = IgdbReviewByIdFamily();

/// See also [igdbReviewById].
class IgdbReviewByIdFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [igdbReviewById].
  const IgdbReviewByIdFamily();

  /// See also [igdbReviewById].
  IgdbReviewByIdProvider call(int reviewId) {
    return IgdbReviewByIdProvider(reviewId);
  }

  @override
  IgdbReviewByIdProvider getProviderOverride(
    covariant IgdbReviewByIdProvider provider,
  ) {
    return call(provider.reviewId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'igdbReviewByIdProvider';
}

/// See also [igdbReviewById].
class IgdbReviewByIdProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [igdbReviewById].
  IgdbReviewByIdProvider(int reviewId)
    : this._internal(
        (ref) => igdbReviewById(ref as IgdbReviewByIdRef, reviewId),
        from: igdbReviewByIdProvider,
        name: r'igdbReviewByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbReviewByIdHash,
        dependencies: IgdbReviewByIdFamily._dependencies,
        allTransitiveDependencies:
            IgdbReviewByIdFamily._allTransitiveDependencies,
        reviewId: reviewId,
      );

  IgdbReviewByIdProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.reviewId,
  }) : super.internal();

  final int reviewId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(IgdbReviewByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbReviewByIdProvider._internal(
        (ref) => create(ref as IgdbReviewByIdRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        reviewId: reviewId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _IgdbReviewByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbReviewByIdProvider && other.reviewId == reviewId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, reviewId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IgdbReviewByIdRef on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `reviewId` of this provider.
  int get reviewId;
}

class _IgdbReviewByIdProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with IgdbReviewByIdRef {
  _IgdbReviewByIdProviderElement(super.provider);

  @override
  int get reviewId => (origin as IgdbReviewByIdProvider).reviewId;
}

String _$igdbGamesSectionListHash() =>
    r'8cae765d404d9ee4cd1f5b20d60611d9fbfbd3e3';

/// See also [igdbGamesSectionList].
@ProviderFor(igdbGamesSectionList)
const igdbGamesSectionListProvider = IgdbGamesSectionListFamily();

/// See also [igdbGamesSectionList].
class IgdbGamesSectionListFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [igdbGamesSectionList].
  const IgdbGamesSectionListFamily();

  /// See also [igdbGamesSectionList].
  IgdbGamesSectionListProvider call(String slug) {
    return IgdbGamesSectionListProvider(slug);
  }

  @override
  IgdbGamesSectionListProvider getProviderOverride(
    covariant IgdbGamesSectionListProvider provider,
  ) {
    return call(provider.slug);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'igdbGamesSectionListProvider';
}

/// See also [igdbGamesSectionList].
class IgdbGamesSectionListProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [igdbGamesSectionList].
  IgdbGamesSectionListProvider(String slug)
    : this._internal(
        (ref) => igdbGamesSectionList(ref as IgdbGamesSectionListRef, slug),
        from: igdbGamesSectionListProvider,
        name: r'igdbGamesSectionListProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbGamesSectionListHash,
        dependencies: IgdbGamesSectionListFamily._dependencies,
        allTransitiveDependencies:
            IgdbGamesSectionListFamily._allTransitiveDependencies,
        slug: slug,
      );

  IgdbGamesSectionListProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.slug,
  }) : super.internal();

  final String slug;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      IgdbGamesSectionListRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbGamesSectionListProvider._internal(
        (ref) => create(ref as IgdbGamesSectionListRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        slug: slug,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _IgdbGamesSectionListProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbGamesSectionListProvider && other.slug == slug;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, slug.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IgdbGamesSectionListRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `slug` of this provider.
  String get slug;
}

class _IgdbGamesSectionListProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with IgdbGamesSectionListRef {
  _IgdbGamesSectionListProviderElement(super.provider);

  @override
  String get slug => (origin as IgdbGamesSectionListProvider).slug;
}

String _$igdbPopularHash() => r'088bfa10bfe316d34765f26c079586f884159fdd';

/// See also [IgdbPopular].
@ProviderFor(IgdbPopular)
final igdbPopularProvider =
    AsyncNotifierProvider<IgdbPopular, List<Map<String, dynamic>>>.internal(
      IgdbPopular.new,
      name: r'igdbPopularProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$igdbPopularHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IgdbPopular = AsyncNotifier<List<Map<String, dynamic>>>;
String _$igdbGamesHomeFeedHash() => r'ef18ee0c8022ceb2a2d033b29c4f401c2fdc6149';

/// See also [IgdbGamesHomeFeed].
@ProviderFor(IgdbGamesHomeFeed)
final igdbGamesHomeFeedProvider =
    AsyncNotifierProvider<IgdbGamesHomeFeed, IgdbGamesHomeFeedData>.internal(
      IgdbGamesHomeFeed.new,
      name: r'igdbGamesHomeFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$igdbGamesHomeFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$IgdbGamesHomeFeed = AsyncNotifier<IgdbGamesHomeFeedData>;
String _$favoriteGamesHash() => r'cb3e3c95e458d1cee78f9554237fd619a0d801ad';

/// See also [FavoriteGames].
@ProviderFor(FavoriteGames)
final favoriteGamesProvider =
    NotifierProvider<FavoriteGames, List<Map<String, dynamic>>>.internal(
      FavoriteGames.new,
      name: r'favoriteGamesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteGamesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteGames = Notifier<List<Map<String, dynamic>>>;
String _$twitchIgdbAccountHash() => r'5da183d69d19f61ca3353574c2b7e1b6b828fd83';

/// See also [TwitchIgdbAccount].
@ProviderFor(TwitchIgdbAccount)
final twitchIgdbAccountProvider =
    AsyncNotifierProvider<TwitchIgdbAccount, TwitchIgdbAccountState>.internal(
      TwitchIgdbAccount.new,
      name: r'twitchIgdbAccountProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$twitchIgdbAccountHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TwitchIgdbAccount = AsyncNotifier<TwitchIgdbAccountState>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
