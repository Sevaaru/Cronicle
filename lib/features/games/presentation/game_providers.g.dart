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

String _$igdbPopularHash() => r'9bc7223bded62419f913a461ce4c5d6185bf8236';

/// Popular (PopScore + mismo listado que el carrusel “Popular ahora”).
///
/// Copied from [igdbPopular].
@ProviderFor(igdbPopular)
final igdbPopularProvider = FutureProvider<List<Map<String, dynamic>>>.internal(
  igdbPopular,
  name: r'igdbPopularProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$igdbPopularHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IgdbPopularRef = FutureProviderRef<List<Map<String, dynamic>>>;
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

String _$igdbHomeGameRailHash() => r'596c9699b6c814ffc0be1d7d30b77941742db896';

/// One horizontal game rail for the games home feed; failures stay isolated.
///
/// Copied from [igdbHomeGameRail].
@ProviderFor(igdbHomeGameRail)
const igdbHomeGameRailProvider = IgdbHomeGameRailFamily();

/// One horizontal game rail for the games home feed; failures stay isolated.
///
/// Copied from [igdbHomeGameRail].
class IgdbHomeGameRailFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// One horizontal game rail for the games home feed; failures stay isolated.
  ///
  /// Copied from [igdbHomeGameRail].
  const IgdbHomeGameRailFamily();

  /// One horizontal game rail for the games home feed; failures stay isolated.
  ///
  /// Copied from [igdbHomeGameRail].
  IgdbHomeGameRailProvider call(String section) {
    return IgdbHomeGameRailProvider(section);
  }

  @override
  IgdbHomeGameRailProvider getProviderOverride(
    covariant IgdbHomeGameRailProvider provider,
  ) {
    return call(provider.section);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'igdbHomeGameRailProvider';
}

/// One horizontal game rail for the games home feed; failures stay isolated.
///
/// Copied from [igdbHomeGameRail].
class IgdbHomeGameRailProvider
    extends FutureProvider<List<Map<String, dynamic>>> {
  /// One horizontal game rail for the games home feed; failures stay isolated.
  ///
  /// Copied from [igdbHomeGameRail].
  IgdbHomeGameRailProvider(String section)
    : this._internal(
        (ref) => igdbHomeGameRail(ref as IgdbHomeGameRailRef, section),
        from: igdbHomeGameRailProvider,
        name: r'igdbHomeGameRailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbHomeGameRailHash,
        dependencies: IgdbHomeGameRailFamily._dependencies,
        allTransitiveDependencies:
            IgdbHomeGameRailFamily._allTransitiveDependencies,
        section: section,
      );

  IgdbHomeGameRailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.section,
  }) : super.internal();

  final String section;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(IgdbHomeGameRailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbHomeGameRailProvider._internal(
        (ref) => create(ref as IgdbHomeGameRailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        section: section,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _IgdbHomeGameRailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbHomeGameRailProvider && other.section == section;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, section.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IgdbHomeGameRailRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `section` of this provider.
  String get section;
}

class _IgdbHomeGameRailProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with IgdbHomeGameRailRef {
  _IgdbHomeGameRailProviderElement(super.provider);

  @override
  String get section => (origin as IgdbHomeGameRailProvider).section;
}

String _$igdbHomeReviewRailHash() =>
    r'56e34ec28e9f3b5c16b2192fc79061a78002f3cf';

/// Review list for the games home (`kind`: `recent` | `critics`).
///
/// Copied from [igdbHomeReviewRail].
@ProviderFor(igdbHomeReviewRail)
const igdbHomeReviewRailProvider = IgdbHomeReviewRailFamily();

/// Review list for the games home (`kind`: `recent` | `critics`).
///
/// Copied from [igdbHomeReviewRail].
class IgdbHomeReviewRailFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Review list for the games home (`kind`: `recent` | `critics`).
  ///
  /// Copied from [igdbHomeReviewRail].
  const IgdbHomeReviewRailFamily();

  /// Review list for the games home (`kind`: `recent` | `critics`).
  ///
  /// Copied from [igdbHomeReviewRail].
  IgdbHomeReviewRailProvider call(String kind) {
    return IgdbHomeReviewRailProvider(kind);
  }

  @override
  IgdbHomeReviewRailProvider getProviderOverride(
    covariant IgdbHomeReviewRailProvider provider,
  ) {
    return call(provider.kind);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'igdbHomeReviewRailProvider';
}

/// Review list for the games home (`kind`: `recent` | `critics`).
///
/// Copied from [igdbHomeReviewRail].
class IgdbHomeReviewRailProvider
    extends FutureProvider<List<Map<String, dynamic>>> {
  /// Review list for the games home (`kind`: `recent` | `critics`).
  ///
  /// Copied from [igdbHomeReviewRail].
  IgdbHomeReviewRailProvider(String kind)
    : this._internal(
        (ref) => igdbHomeReviewRail(ref as IgdbHomeReviewRailRef, kind),
        from: igdbHomeReviewRailProvider,
        name: r'igdbHomeReviewRailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$igdbHomeReviewRailHash,
        dependencies: IgdbHomeReviewRailFamily._dependencies,
        allTransitiveDependencies:
            IgdbHomeReviewRailFamily._allTransitiveDependencies,
        kind: kind,
      );

  IgdbHomeReviewRailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
  }) : super.internal();

  final String kind;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      IgdbHomeReviewRailRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: IgdbHomeReviewRailProvider._internal(
        (ref) => create(ref as IgdbHomeReviewRailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
      ),
    );
  }

  @override
  FutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _IgdbHomeReviewRailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is IgdbHomeReviewRailProvider && other.kind == kind;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin IgdbHomeReviewRailRef on FutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `kind` of this provider.
  String get kind;
}

class _IgdbHomeReviewRailProviderElement
    extends FutureProviderElement<List<Map<String, dynamic>>>
    with IgdbHomeReviewRailRef {
  _IgdbHomeReviewRailProviderElement(super.provider);

  @override
  String get kind => (origin as IgdbHomeReviewRailProvider).kind;
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
    r'1f127f4d21f3ef6c671f023603a77d7aa76faf58';

/// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
///
/// Copied from [igdbGamesSectionList].
@ProviderFor(igdbGamesSectionList)
const igdbGamesSectionListProvider = IgdbGamesSectionListFamily();

/// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
///
/// Copied from [igdbGamesSectionList].
class IgdbGamesSectionListFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
  ///
  /// Copied from [igdbGamesSectionList].
  const IgdbGamesSectionListFamily();

  /// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
  ///
  /// Copied from [igdbGamesSectionList].
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

/// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
///
/// Copied from [igdbGamesSectionList].
class IgdbGamesSectionListProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// Listado extendido para la pantalla `/games/section/:slug` (más ítems que el carrusel del home).
  ///
  /// Copied from [igdbGamesSectionList].
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

String _$favoriteGamesHash() => r'96ace829105b3d07cdda862470dea07b4784e682';

/// Juegos marcados como favoritos (solo local, SharedPreferences).
///
/// Copied from [FavoriteGames].
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
