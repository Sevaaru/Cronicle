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
String _$igdbSearchHash() => r'aaf86b5aef3f53a8ff442b40e18b67979255b3e5';

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
class IgdbSearchProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
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
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
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
mixin IgdbSearchRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _IgdbSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with IgdbSearchRef {
  _IgdbSearchProviderElement(super.provider);

  @override
  String get query => (origin as IgdbSearchProvider).query;
}

String _$igdbPopularHash() => r'fe785cc06485dea68626fe6d2a18a30067d09a61';

/// See also [igdbPopular].
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
String _$igdbGameDetailHash() => r'f3f10de2831354ea0adb731808ccc606f37233ba';

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

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
