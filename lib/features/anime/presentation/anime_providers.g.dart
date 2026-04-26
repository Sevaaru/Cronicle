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

String _$anilistMediaDetailHash() =>
    r'71041737841188dea5b9c9080ad3ece10c122567';

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

String _$anilistCharacterDetailHash() =>
    r'ab59af2b85761ec4c96d2729bf5c114211ae7c2f';

/// See also [anilistCharacterDetail].
@ProviderFor(anilistCharacterDetail)
const anilistCharacterDetailProvider = AnilistCharacterDetailFamily();

/// See also [anilistCharacterDetail].
class AnilistCharacterDetailFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [anilistCharacterDetail].
  const AnilistCharacterDetailFamily();

  /// See also [anilistCharacterDetail].
  AnilistCharacterDetailProvider call(int characterId) {
    return AnilistCharacterDetailProvider(characterId);
  }

  @override
  AnilistCharacterDetailProvider getProviderOverride(
    covariant AnilistCharacterDetailProvider provider,
  ) {
    return call(provider.characterId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistCharacterDetailProvider';
}

/// See also [anilistCharacterDetail].
class AnilistCharacterDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [anilistCharacterDetail].
  AnilistCharacterDetailProvider(int characterId)
    : this._internal(
        (ref) => anilistCharacterDetail(
          ref as AnilistCharacterDetailRef,
          characterId,
        ),
        from: anilistCharacterDetailProvider,
        name: r'anilistCharacterDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistCharacterDetailHash,
        dependencies: AnilistCharacterDetailFamily._dependencies,
        allTransitiveDependencies:
            AnilistCharacterDetailFamily._allTransitiveDependencies,
        characterId: characterId,
      );

  AnilistCharacterDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.characterId,
  }) : super.internal();

  final int characterId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(AnilistCharacterDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistCharacterDetailProvider._internal(
        (ref) => create(ref as AnilistCharacterDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        characterId: characterId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _AnilistCharacterDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistCharacterDetailProvider &&
        other.characterId == characterId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, characterId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistCharacterDetailRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `characterId` of this provider.
  int get characterId;
}

class _AnilistCharacterDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with AnilistCharacterDetailRef {
  _AnilistCharacterDetailProviderElement(super.provider);

  @override
  int get characterId => (origin as AnilistCharacterDetailProvider).characterId;
}

String _$anilistStaffDetailHash() =>
    r'309379fcb7ad4f707b670661617e5effab87779c';

/// See also [anilistStaffDetail].
@ProviderFor(anilistStaffDetail)
const anilistStaffDetailProvider = AnilistStaffDetailFamily();

/// See also [anilistStaffDetail].
class AnilistStaffDetailFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [anilistStaffDetail].
  const AnilistStaffDetailFamily();

  /// See also [anilistStaffDetail].
  AnilistStaffDetailProvider call(int staffId) {
    return AnilistStaffDetailProvider(staffId);
  }

  @override
  AnilistStaffDetailProvider getProviderOverride(
    covariant AnilistStaffDetailProvider provider,
  ) {
    return call(provider.staffId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistStaffDetailProvider';
}

/// See also [anilistStaffDetail].
class AnilistStaffDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [anilistStaffDetail].
  AnilistStaffDetailProvider(int staffId)
    : this._internal(
        (ref) => anilistStaffDetail(ref as AnilistStaffDetailRef, staffId),
        from: anilistStaffDetailProvider,
        name: r'anilistStaffDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistStaffDetailHash,
        dependencies: AnilistStaffDetailFamily._dependencies,
        allTransitiveDependencies:
            AnilistStaffDetailFamily._allTransitiveDependencies,
        staffId: staffId,
      );

  AnilistStaffDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.staffId,
  }) : super.internal();

  final int staffId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(AnilistStaffDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistStaffDetailProvider._internal(
        (ref) => create(ref as AnilistStaffDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        staffId: staffId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _AnilistStaffDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistStaffDetailProvider && other.staffId == staffId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, staffId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistStaffDetailRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `staffId` of this provider.
  int get staffId;
}

class _AnilistStaffDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with AnilistStaffDetailRef {
  _AnilistStaffDetailProviderElement(super.provider);

  @override
  int get staffId => (origin as AnilistStaffDetailProvider).staffId;
}

String _$anilistMediaThreadsHash() =>
    r'6f074027fec123f8f6dd7e627e89cabd56a8462c';

/// See also [anilistMediaThreads].
@ProviderFor(anilistMediaThreads)
const anilistMediaThreadsProvider = AnilistMediaThreadsFamily();

/// See also [anilistMediaThreads].
class AnilistMediaThreadsFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [anilistMediaThreads].
  const AnilistMediaThreadsFamily();

  /// See also [anilistMediaThreads].
  AnilistMediaThreadsProvider call(int mediaId) {
    return AnilistMediaThreadsProvider(mediaId);
  }

  @override
  AnilistMediaThreadsProvider getProviderOverride(
    covariant AnilistMediaThreadsProvider provider,
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
  String? get name => r'anilistMediaThreadsProvider';
}

/// See also [anilistMediaThreads].
class AnilistMediaThreadsProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [anilistMediaThreads].
  AnilistMediaThreadsProvider(int mediaId)
    : this._internal(
        (ref) => anilistMediaThreads(ref as AnilistMediaThreadsRef, mediaId),
        from: anilistMediaThreadsProvider,
        name: r'anilistMediaThreadsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistMediaThreadsHash,
        dependencies: AnilistMediaThreadsFamily._dependencies,
        allTransitiveDependencies:
            AnilistMediaThreadsFamily._allTransitiveDependencies,
        mediaId: mediaId,
      );

  AnilistMediaThreadsProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(
      AnilistMediaThreadsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistMediaThreadsProvider._internal(
        (ref) => create(ref as AnilistMediaThreadsRef),
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
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _AnilistMediaThreadsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistMediaThreadsProvider && other.mediaId == mediaId;
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
mixin AnilistMediaThreadsRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `mediaId` of this provider.
  int get mediaId;
}

class _AnilistMediaThreadsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with AnilistMediaThreadsRef {
  _AnilistMediaThreadsProviderElement(super.provider);

  @override
  int get mediaId => (origin as AnilistMediaThreadsProvider).mediaId;
}

String _$anilistForumThreadHash() =>
    r'51355df2f8a6e6be2873d4593742f4c47123ec73';

/// See also [anilistForumThread].
@ProviderFor(anilistForumThread)
const anilistForumThreadProvider = AnilistForumThreadFamily();

/// See also [anilistForumThread].
class AnilistForumThreadFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [anilistForumThread].
  const AnilistForumThreadFamily();

  /// See also [anilistForumThread].
  AnilistForumThreadProvider call(int threadId) {
    return AnilistForumThreadProvider(threadId);
  }

  @override
  AnilistForumThreadProvider getProviderOverride(
    covariant AnilistForumThreadProvider provider,
  ) {
    return call(provider.threadId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistForumThreadProvider';
}

/// See also [anilistForumThread].
class AnilistForumThreadProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [anilistForumThread].
  AnilistForumThreadProvider(int threadId)
    : this._internal(
        (ref) => anilistForumThread(ref as AnilistForumThreadRef, threadId),
        from: anilistForumThreadProvider,
        name: r'anilistForumThreadProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistForumThreadHash,
        dependencies: AnilistForumThreadFamily._dependencies,
        allTransitiveDependencies:
            AnilistForumThreadFamily._allTransitiveDependencies,
        threadId: threadId,
      );

  AnilistForumThreadProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.threadId,
  }) : super.internal();

  final int threadId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(AnilistForumThreadRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistForumThreadProvider._internal(
        (ref) => create(ref as AnilistForumThreadRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        threadId: threadId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _AnilistForumThreadProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistForumThreadProvider && other.threadId == threadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, threadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistForumThreadRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `threadId` of this provider.
  int get threadId;
}

class _AnilistForumThreadProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with AnilistForumThreadRef {
  _AnilistForumThreadProviderElement(super.provider);

  @override
  int get threadId => (origin as AnilistForumThreadProvider).threadId;
}

String _$anilistUserProfileHash() =>
    r'29f5301c8cc05e65cff859006d582d441b47bb9f';

/// See also [anilistUserProfile].
@ProviderFor(anilistUserProfile)
const anilistUserProfileProvider = AnilistUserProfileFamily();

/// See also [anilistUserProfile].
class AnilistUserProfileFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [anilistUserProfile].
  const AnilistUserProfileFamily();

  /// See also [anilistUserProfile].
  AnilistUserProfileProvider call(int userId) {
    return AnilistUserProfileProvider(userId);
  }

  @override
  AnilistUserProfileProvider getProviderOverride(
    covariant AnilistUserProfileProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistUserProfileProvider';
}

/// See also [anilistUserProfile].
class AnilistUserProfileProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [anilistUserProfile].
  AnilistUserProfileProvider(int userId)
    : this._internal(
        (ref) => anilistUserProfile(ref as AnilistUserProfileRef, userId),
        from: anilistUserProfileProvider,
        name: r'anilistUserProfileProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistUserProfileHash,
        dependencies: AnilistUserProfileFamily._dependencies,
        allTransitiveDependencies:
            AnilistUserProfileFamily._allTransitiveDependencies,
        userId: userId,
      );

  AnilistUserProfileProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final int userId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(AnilistUserProfileRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistUserProfileProvider._internal(
        (ref) => create(ref as AnilistUserProfileRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _AnilistUserProfileProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistUserProfileProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistUserProfileRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `userId` of this provider.
  int get userId;
}

class _AnilistUserProfileProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with AnilistUserProfileRef {
  _AnilistUserProfileProviderElement(super.provider);

  @override
  int get userId => (origin as AnilistUserProfileProvider).userId;
}

String _$anilistUserActivityHash() =>
    r'b3796d8616fdea66345fa372f58899341c867e37';

/// See also [anilistUserActivity].
@ProviderFor(anilistUserActivity)
const anilistUserActivityProvider = AnilistUserActivityFamily();

/// See also [anilistUserActivity].
class AnilistUserActivityFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [anilistUserActivity].
  const AnilistUserActivityFamily();

  /// See also [anilistUserActivity].
  AnilistUserActivityProvider call(int userId) {
    return AnilistUserActivityProvider(userId);
  }

  @override
  AnilistUserActivityProvider getProviderOverride(
    covariant AnilistUserActivityProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistUserActivityProvider';
}

/// See also [anilistUserActivity].
class AnilistUserActivityProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [anilistUserActivity].
  AnilistUserActivityProvider(int userId)
    : this._internal(
        (ref) => anilistUserActivity(ref as AnilistUserActivityRef, userId),
        from: anilistUserActivityProvider,
        name: r'anilistUserActivityProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistUserActivityHash,
        dependencies: AnilistUserActivityFamily._dependencies,
        allTransitiveDependencies:
            AnilistUserActivityFamily._allTransitiveDependencies,
        userId: userId,
      );

  AnilistUserActivityProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final int userId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      AnilistUserActivityRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistUserActivityProvider._internal(
        (ref) => create(ref as AnilistUserActivityRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _AnilistUserActivityProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistUserActivityProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistUserActivityRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `userId` of this provider.
  int get userId;
}

class _AnilistUserActivityProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with AnilistUserActivityRef {
  _AnilistUserActivityProviderElement(super.provider);

  @override
  int get userId => (origin as AnilistUserActivityProvider).userId;
}

String _$anilistActivityRepliesHash() =>
    r'9635fa46e9891e574dd43e9f1470fe8096bc774b';

/// See also [anilistActivityReplies].
@ProviderFor(anilistActivityReplies)
const anilistActivityRepliesProvider = AnilistActivityRepliesFamily();

/// See also [anilistActivityReplies].
class AnilistActivityRepliesFamily
    extends Family<AsyncValue<Map<String, dynamic>>> {
  /// See also [anilistActivityReplies].
  const AnilistActivityRepliesFamily();

  /// See also [anilistActivityReplies].
  AnilistActivityRepliesProvider call(int activityId) {
    return AnilistActivityRepliesProvider(activityId);
  }

  @override
  AnilistActivityRepliesProvider getProviderOverride(
    covariant AnilistActivityRepliesProvider provider,
  ) {
    return call(provider.activityId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistActivityRepliesProvider';
}

/// See also [anilistActivityReplies].
class AnilistActivityRepliesProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>> {
  /// See also [anilistActivityReplies].
  AnilistActivityRepliesProvider(int activityId)
    : this._internal(
        (ref) => anilistActivityReplies(
          ref as AnilistActivityRepliesRef,
          activityId,
        ),
        from: anilistActivityRepliesProvider,
        name: r'anilistActivityRepliesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistActivityRepliesHash,
        dependencies: AnilistActivityRepliesFamily._dependencies,
        allTransitiveDependencies:
            AnilistActivityRepliesFamily._allTransitiveDependencies,
        activityId: activityId,
      );

  AnilistActivityRepliesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.activityId,
  }) : super.internal();

  final int activityId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>> Function(AnilistActivityRepliesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AnilistActivityRepliesProvider._internal(
        (ref) => create(ref as AnilistActivityRepliesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        activityId: activityId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>> createElement() {
    return _AnilistActivityRepliesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistActivityRepliesProvider &&
        other.activityId == activityId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activityId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistActivityRepliesRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>> {
  /// The parameter `activityId` of this provider.
  int get activityId;
}

class _AnilistActivityRepliesProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>>
    with AnilistActivityRepliesRef {
  _AnilistActivityRepliesProviderElement(super.provider);

  @override
  int get activityId => (origin as AnilistActivityRepliesProvider).activityId;
}

String _$anilistUnreadNotificationCountHash() =>
    r'464c8438f5d759eef0bb0b5fb75e860ad46d8c42';

/// See also [anilistUnreadNotificationCount].
@ProviderFor(anilistUnreadNotificationCount)
final anilistUnreadNotificationCountProvider = FutureProvider<int>.internal(
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
typedef AnilistUnreadNotificationCountRef = FutureProviderRef<int>;
String _$anilistNotificationsListHash() =>
    r'2666be9b10bc0f1172532410c3f7bc7a637c9a6e';

/// See also [anilistNotificationsList].
@ProviderFor(anilistNotificationsList)
final anilistNotificationsListProvider =
    FutureProvider<List<Map<String, dynamic>>>.internal(
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
    FutureProviderRef<List<Map<String, dynamic>>>;
String _$anilistCachedNotificationsHash() =>
    r'ab35825ec14a4ada6361b9ceccdaa62dd4a210e2';

/// Synchronous read of the last persisted notifications batch (up to 20).
/// The notifications page reads this so it can paint instantly on entry
/// instead of staring at a blank spinner while the live request finishes.
///
/// Copied from [anilistCachedNotifications].
@ProviderFor(anilistCachedNotifications)
final anilistCachedNotificationsProvider =
    AutoDisposeProvider<List<Map<String, dynamic>>>.internal(
      anilistCachedNotifications,
      name: r'anilistCachedNotificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistCachedNotificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnilistCachedNotificationsRef =
    AutoDisposeProviderRef<List<Map<String, dynamic>>>;
String _$anilistTokenHash() => r'0fb1ddb38edcc98c4599f8f18c19a60716f7ff58';

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
String _$anilistPopularHash() => r'e5211588e369ab837bc426c8b4d23a02dd979dc3';

abstract class _$AnilistPopular
    extends BuildlessAsyncNotifier<List<Map<String, dynamic>>> {
  late final String type;

  FutureOr<List<Map<String, dynamic>>> build(String type);
}

/// See also [AnilistPopular].
@ProviderFor(AnilistPopular)
const anilistPopularProvider = AnilistPopularFamily();

/// See also [AnilistPopular].
class AnilistPopularFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [AnilistPopular].
  const AnilistPopularFamily();

  /// See also [AnilistPopular].
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

/// See also [AnilistPopular].
class AnilistPopularProvider
    extends
        AsyncNotifierProviderImpl<AnilistPopular, List<Map<String, dynamic>>> {
  /// See also [AnilistPopular].
  AnilistPopularProvider(String type)
    : this._internal(
        () => AnilistPopular()..type = type,
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
  FutureOr<List<Map<String, dynamic>>> runNotifierBuild(
    covariant AnilistPopular notifier,
  ) {
    return notifier.build(type);
  }

  @override
  Override overrideWith(AnilistPopular Function() create) {
    return ProviderOverride(
      origin: this,
      override: AnilistPopularProvider._internal(
        () => create()..type = type,
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
  AsyncNotifierProviderElement<AnilistPopular, List<Map<String, dynamic>>>
  createElement() {
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
mixin AnilistPopularRef
    on AsyncNotifierProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `type` of this provider.
  String get type;
}

class _AnilistPopularProviderElement
    extends
        AsyncNotifierProviderElement<AnilistPopular, List<Map<String, dynamic>>>
    with AnilistPopularRef {
  _AnilistPopularProviderElement(super.provider);

  @override
  String get type => (origin as AnilistPopularProvider).type;
}

String _$anilistBrowseMediaHash() =>
    r'436ac6b2614cbcdb13e8af33fe4a921fe889699b';

abstract class _$AnilistBrowseMedia
    extends BuildlessAsyncNotifier<List<Map<String, dynamic>>> {
  late final String type;
  late final String category;

  FutureOr<List<Map<String, dynamic>>> build(String type, String category);
}

/// See also [AnilistBrowseMedia].
@ProviderFor(AnilistBrowseMedia)
const anilistBrowseMediaProvider = AnilistBrowseMediaFamily();

/// See also [AnilistBrowseMedia].
class AnilistBrowseMediaFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [AnilistBrowseMedia].
  const AnilistBrowseMediaFamily();

  /// See also [AnilistBrowseMedia].
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

/// See also [AnilistBrowseMedia].
class AnilistBrowseMediaProvider
    extends
        AsyncNotifierProviderImpl<
          AnilistBrowseMedia,
          List<Map<String, dynamic>>
        > {
  /// See also [AnilistBrowseMedia].
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
  AsyncNotifierProviderElement<AnilistBrowseMedia, List<Map<String, dynamic>>>
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
    on AsyncNotifierProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `type` of this provider.
  String get type;

  /// The parameter `category` of this provider.
  String get category;
}

class _AnilistBrowseMediaProviderElement
    extends
        AsyncNotifierProviderElement<
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

String _$anilistFeedHash() => r'4354af344e1b0548744d801c87ae506127c0491d';

/// See also [AnilistFeed].
@ProviderFor(AnilistFeed)
final anilistFeedProvider =
    AsyncNotifierProvider<AnilistFeed, List<FeedActivity>>.internal(
      AnilistFeed.new,
      name: r'anilistFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistFeed = AsyncNotifier<List<FeedActivity>>;
String _$anilistFeedByTypeHash() => r'2047a68db596f8b770330e005b107ea8310d7b5b';

abstract class _$AnilistFeedByType
    extends BuildlessAsyncNotifier<List<FeedActivity>> {
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
    extends AsyncNotifierProviderImpl<AnilistFeedByType, List<FeedActivity>> {
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
  AsyncNotifierProviderElement<AnilistFeedByType, List<FeedActivity>>
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
mixin AnilistFeedByTypeRef on AsyncNotifierProviderRef<List<FeedActivity>> {
  /// The parameter `activityType` of this provider.
  String get activityType;
}

class _AnilistFeedByTypeProviderElement
    extends AsyncNotifierProviderElement<AnilistFeedByType, List<FeedActivity>>
    with AnilistFeedByTypeRef {
  _AnilistFeedByTypeProviderElement(super.provider);

  @override
  String get activityType => (origin as AnilistFeedByTypeProvider).activityType;
}

String _$anilistFeedFollowingHash() =>
    r'af4630618dea7cffbd6bc78e8a7886a62db5d894';

/// See also [AnilistFeedFollowing].
@ProviderFor(AnilistFeedFollowing)
final anilistFeedFollowingProvider =
    AsyncNotifierProvider<AnilistFeedFollowing, List<FeedActivity>>.internal(
      AnilistFeedFollowing.new,
      name: r'anilistFeedFollowingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistFeedFollowingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistFeedFollowing = AsyncNotifier<List<FeedActivity>>;
String _$anilistSocialFeedHash() => r'41b61ae6888f5eb66d92786f5da2fb139aa35df3';

abstract class _$AnilistSocialFeed
    extends BuildlessAsyncNotifier<List<FeedActivity>> {
  late final String? activityType;
  late final bool isFollowing;

  FutureOr<List<FeedActivity>> build(String? activityType, bool isFollowing);
}

/// See also [AnilistSocialFeed].
@ProviderFor(AnilistSocialFeed)
const anilistSocialFeedProvider = AnilistSocialFeedFamily();

/// See also [AnilistSocialFeed].
class AnilistSocialFeedFamily extends Family<AsyncValue<List<FeedActivity>>> {
  /// See also [AnilistSocialFeed].
  const AnilistSocialFeedFamily();

  /// See also [AnilistSocialFeed].
  AnilistSocialFeedProvider call(String? activityType, bool isFollowing) {
    return AnilistSocialFeedProvider(activityType, isFollowing);
  }

  @override
  AnilistSocialFeedProvider getProviderOverride(
    covariant AnilistSocialFeedProvider provider,
  ) {
    return call(provider.activityType, provider.isFollowing);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'anilistSocialFeedProvider';
}

/// See also [AnilistSocialFeed].
class AnilistSocialFeedProvider
    extends AsyncNotifierProviderImpl<AnilistSocialFeed, List<FeedActivity>> {
  /// See also [AnilistSocialFeed].
  AnilistSocialFeedProvider(String? activityType, bool isFollowing)
    : this._internal(
        () => AnilistSocialFeed()
          ..activityType = activityType
          ..isFollowing = isFollowing,
        from: anilistSocialFeedProvider,
        name: r'anilistSocialFeedProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$anilistSocialFeedHash,
        dependencies: AnilistSocialFeedFamily._dependencies,
        allTransitiveDependencies:
            AnilistSocialFeedFamily._allTransitiveDependencies,
        activityType: activityType,
        isFollowing: isFollowing,
      );

  AnilistSocialFeedProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.activityType,
    required this.isFollowing,
  }) : super.internal();

  final String? activityType;
  final bool isFollowing;

  @override
  FutureOr<List<FeedActivity>> runNotifierBuild(
    covariant AnilistSocialFeed notifier,
  ) {
    return notifier.build(activityType, isFollowing);
  }

  @override
  Override overrideWith(AnilistSocialFeed Function() create) {
    return ProviderOverride(
      origin: this,
      override: AnilistSocialFeedProvider._internal(
        () => create()
          ..activityType = activityType
          ..isFollowing = isFollowing,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        activityType: activityType,
        isFollowing: isFollowing,
      ),
    );
  }

  @override
  AsyncNotifierProviderElement<AnilistSocialFeed, List<FeedActivity>>
  createElement() {
    return _AnilistSocialFeedProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AnilistSocialFeedProvider &&
        other.activityType == activityType &&
        other.isFollowing == isFollowing;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, activityType.hashCode);
    hash = _SystemHash.combine(hash, isFollowing.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AnilistSocialFeedRef on AsyncNotifierProviderRef<List<FeedActivity>> {
  /// The parameter `activityType` of this provider.
  String? get activityType;

  /// The parameter `isFollowing` of this provider.
  bool get isFollowing;
}

class _AnilistSocialFeedProviderElement
    extends AsyncNotifierProviderElement<AnilistSocialFeed, List<FeedActivity>>
    with AnilistSocialFeedRef {
  _AnilistSocialFeedProviderElement(super.provider);

  @override
  String? get activityType =>
      (origin as AnilistSocialFeedProvider).activityType;
  @override
  bool get isFollowing => (origin as AnilistSocialFeedProvider).isFollowing;
}

String _$anilistGenreTagBrowseHash() =>
    r'c6669feb9fc5fa9154fd62b7dda0281580788269';

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

/// See also [AnilistGenreTagBrowse].
@ProviderFor(AnilistGenreTagBrowse)
const anilistGenreTagBrowseProvider = AnilistGenreTagBrowseFamily();

/// See also [AnilistGenreTagBrowse].
class AnilistGenreTagBrowseFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [AnilistGenreTagBrowse].
  const AnilistGenreTagBrowseFamily();

  /// See also [AnilistGenreTagBrowse].
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

/// See also [AnilistGenreTagBrowse].
class AnilistGenreTagBrowseProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          AnilistGenreTagBrowse,
          List<Map<String, dynamic>>
        > {
  /// See also [AnilistGenreTagBrowse].
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

String _$anilistProfileHash() => r'b4675e001e67c13983b5ffbd42206bac77884217';

/// See also [AnilistProfile].
@ProviderFor(AnilistProfile)
final anilistProfileProvider =
    AsyncNotifierProvider<AnilistProfile, Map<String, dynamic>?>.internal(
      AnilistProfile.new,
      name: r'anilistProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$anilistProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$AnilistProfile = AsyncNotifier<Map<String, dynamic>?>;
String _$favoriteAnilistMediaHash() =>
    r'fedac076ec1b4ddcd61d12f46efc063d9e4452ba';

/// See also [FavoriteAnilistMedia].
@ProviderFor(FavoriteAnilistMedia)
final favoriteAnilistMediaProvider =
    NotifierProvider<FavoriteAnilistMedia, List<Map<String, dynamic>>>.internal(
      FavoriteAnilistMedia.new,
      name: r'favoriteAnilistMediaProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteAnilistMediaHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteAnilistMedia = Notifier<List<Map<String, dynamic>>>;
String _$favoriteAnilistCharactersHash() =>
    r'620b8be140180a1567d48904d1be64d4a4220f63';

/// See also [FavoriteAnilistCharacters].
@ProviderFor(FavoriteAnilistCharacters)
final favoriteAnilistCharactersProvider =
    NotifierProvider<
      FavoriteAnilistCharacters,
      List<Map<String, dynamic>>
    >.internal(
      FavoriteAnilistCharacters.new,
      name: r'favoriteAnilistCharactersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteAnilistCharactersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteAnilistCharacters = Notifier<List<Map<String, dynamic>>>;
String _$favoriteAnilistStaffHash() =>
    r'3cb0ae6476f4d4451a0799170386104844c7078c';

/// See also [FavoriteAnilistStaff].
@ProviderFor(FavoriteAnilistStaff)
final favoriteAnilistStaffProvider =
    NotifierProvider<FavoriteAnilistStaff, List<Map<String, dynamic>>>.internal(
      FavoriteAnilistStaff.new,
      name: r'favoriteAnilistStaffProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteAnilistStaffHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteAnilistStaff = Notifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
