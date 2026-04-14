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

String _$anilistFeedHash() => r'66233ac73459ccf49be28ed2efd96a6f31b48842';

/// See also [anilistFeed].
@ProviderFor(anilistFeed)
final anilistFeedProvider =
    AutoDisposeFutureProvider<List<FeedActivity>>.internal(
      anilistFeed,
      name: r'anilistFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistFeedRef = AutoDisposeFutureProviderRef<List<FeedActivity>>;
String _$anilistTokenHash() => r'1dac5649107efbd1e0acae1952c5cc1b05dd6e10';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
