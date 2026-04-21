// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trakt_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$traktAuthHash() => r'eb3d9ecd6a1966740a78f1f7c3a242945d83e95d';

/// See also [traktAuth].
@ProviderFor(traktAuth)
final traktAuthProvider = Provider<TraktAuthDatasource>.internal(
  traktAuth,
  name: r'traktAuthProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$traktAuthHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TraktAuthRef = ProviderRef<TraktAuthDatasource>;
String _$traktApiHash() => r'33752b39dba568c1ea6d75c6061835f2ef9eaa41';

/// See also [traktApi].
@ProviderFor(traktApi)
final traktApiProvider = Provider<TraktApiDatasource>.internal(
  traktApi,
  name: r'traktApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$traktApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TraktApiRef = ProviderRef<TraktApiDatasource>;
String _$traktMoviesHomeHash() => r'11cfb443b8143cd3c9da2d424cc510e3237b4b27';

/// See also [traktMoviesHome].
@ProviderFor(traktMoviesHome)
final traktMoviesHomeProvider =
    AutoDisposeFutureProvider<TraktMoviesHomeData>.internal(
      traktMoviesHome,
      name: r'traktMoviesHomeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$traktMoviesHomeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TraktMoviesHomeRef = AutoDisposeFutureProviderRef<TraktMoviesHomeData>;
String _$traktShowsHomeHash() => r'4ff2dfffbac5d91ecdc1fd55ae4bd48347071e3b';

/// See also [traktShowsHome].
@ProviderFor(traktShowsHome)
final traktShowsHomeProvider =
    AutoDisposeFutureProvider<TraktShowsHomeData>.internal(
      traktShowsHome,
      name: r'traktShowsHomeProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$traktShowsHomeHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TraktShowsHomeRef = AutoDisposeFutureProviderRef<TraktShowsHomeData>;
String _$traktSearchMoviesHash() => r'38c87805a839d4a9de4e5e065ace479ab44117aa';

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

/// See also [traktSearchMovies].
@ProviderFor(traktSearchMovies)
const traktSearchMoviesProvider = TraktSearchMoviesFamily();

/// See also [traktSearchMovies].
class TraktSearchMoviesFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [traktSearchMovies].
  const TraktSearchMoviesFamily();

  /// See also [traktSearchMovies].
  TraktSearchMoviesProvider call(String query) {
    return TraktSearchMoviesProvider(query);
  }

  @override
  TraktSearchMoviesProvider getProviderOverride(
    covariant TraktSearchMoviesProvider provider,
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
  String? get name => r'traktSearchMoviesProvider';
}

/// See also [traktSearchMovies].
class TraktSearchMoviesProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [traktSearchMovies].
  TraktSearchMoviesProvider(String query)
    : this._internal(
        (ref) => traktSearchMovies(ref as TraktSearchMoviesRef, query),
        from: traktSearchMoviesProvider,
        name: r'traktSearchMoviesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$traktSearchMoviesHash,
        dependencies: TraktSearchMoviesFamily._dependencies,
        allTransitiveDependencies:
            TraktSearchMoviesFamily._allTransitiveDependencies,
        query: query,
      );

  TraktSearchMoviesProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(TraktSearchMoviesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TraktSearchMoviesProvider._internal(
        (ref) => create(ref as TraktSearchMoviesRef),
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
    return _TraktSearchMoviesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TraktSearchMoviesProvider && other.query == query;
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
mixin TraktSearchMoviesRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _TraktSearchMoviesProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with TraktSearchMoviesRef {
  _TraktSearchMoviesProviderElement(super.provider);

  @override
  String get query => (origin as TraktSearchMoviesProvider).query;
}

String _$traktSearchShowsHash() => r'420c41f1a04db649525aa74dd94f7bc963676b07';

/// See also [traktSearchShows].
@ProviderFor(traktSearchShows)
const traktSearchShowsProvider = TraktSearchShowsFamily();

/// See also [traktSearchShows].
class TraktSearchShowsFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [traktSearchShows].
  const TraktSearchShowsFamily();

  /// See also [traktSearchShows].
  TraktSearchShowsProvider call(String query) {
    return TraktSearchShowsProvider(query);
  }

  @override
  TraktSearchShowsProvider getProviderOverride(
    covariant TraktSearchShowsProvider provider,
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
  String? get name => r'traktSearchShowsProvider';
}

/// See also [traktSearchShows].
class TraktSearchShowsProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [traktSearchShows].
  TraktSearchShowsProvider(String query)
    : this._internal(
        (ref) => traktSearchShows(ref as TraktSearchShowsRef, query),
        from: traktSearchShowsProvider,
        name: r'traktSearchShowsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$traktSearchShowsHash,
        dependencies: TraktSearchShowsFamily._dependencies,
        allTransitiveDependencies:
            TraktSearchShowsFamily._allTransitiveDependencies,
        query: query,
      );

  TraktSearchShowsProvider._internal(
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
    FutureOr<List<Map<String, dynamic>>> Function(TraktSearchShowsRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TraktSearchShowsProvider._internal(
        (ref) => create(ref as TraktSearchShowsRef),
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
    return _TraktSearchShowsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TraktSearchShowsProvider && other.query == query;
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
mixin TraktSearchShowsRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _TraktSearchShowsProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with TraktSearchShowsRef {
  _TraktSearchShowsProviderElement(super.provider);

  @override
  String get query => (origin as TraktSearchShowsProvider).query;
}

String _$traktMovieDetailHash() => r'04a8f8b7efffc32c4cb00b5025cc13ade394960c';

/// See also [traktMovieDetail].
@ProviderFor(traktMovieDetail)
const traktMovieDetailProvider = TraktMovieDetailFamily();

/// See also [traktMovieDetail].
class TraktMovieDetailFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [traktMovieDetail].
  const TraktMovieDetailFamily();

  /// See also [traktMovieDetail].
  TraktMovieDetailProvider call(int traktId) {
    return TraktMovieDetailProvider(traktId);
  }

  @override
  TraktMovieDetailProvider getProviderOverride(
    covariant TraktMovieDetailProvider provider,
  ) {
    return call(provider.traktId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'traktMovieDetailProvider';
}

/// See also [traktMovieDetail].
class TraktMovieDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [traktMovieDetail].
  TraktMovieDetailProvider(int traktId)
    : this._internal(
        (ref) => traktMovieDetail(ref as TraktMovieDetailRef, traktId),
        from: traktMovieDetailProvider,
        name: r'traktMovieDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$traktMovieDetailHash,
        dependencies: TraktMovieDetailFamily._dependencies,
        allTransitiveDependencies:
            TraktMovieDetailFamily._allTransitiveDependencies,
        traktId: traktId,
      );

  TraktMovieDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.traktId,
  }) : super.internal();

  final int traktId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(TraktMovieDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TraktMovieDetailProvider._internal(
        (ref) => create(ref as TraktMovieDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        traktId: traktId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _TraktMovieDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TraktMovieDetailProvider && other.traktId == traktId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, traktId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TraktMovieDetailRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `traktId` of this provider.
  int get traktId;
}

class _TraktMovieDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with TraktMovieDetailRef {
  _TraktMovieDetailProviderElement(super.provider);

  @override
  int get traktId => (origin as TraktMovieDetailProvider).traktId;
}

String _$traktShowDetailHash() => r'c238a2568634037936a2fd56053ddfba43435f7e';

/// See also [traktShowDetail].
@ProviderFor(traktShowDetail)
const traktShowDetailProvider = TraktShowDetailFamily();

/// See also [traktShowDetail].
class TraktShowDetailFamily extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [traktShowDetail].
  const TraktShowDetailFamily();

  /// See also [traktShowDetail].
  TraktShowDetailProvider call(int traktId) {
    return TraktShowDetailProvider(traktId);
  }

  @override
  TraktShowDetailProvider getProviderOverride(
    covariant TraktShowDetailProvider provider,
  ) {
    return call(provider.traktId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'traktShowDetailProvider';
}

/// See also [traktShowDetail].
class TraktShowDetailProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [traktShowDetail].
  TraktShowDetailProvider(int traktId)
    : this._internal(
        (ref) => traktShowDetail(ref as TraktShowDetailRef, traktId),
        from: traktShowDetailProvider,
        name: r'traktShowDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$traktShowDetailHash,
        dependencies: TraktShowDetailFamily._dependencies,
        allTransitiveDependencies:
            TraktShowDetailFamily._allTransitiveDependencies,
        traktId: traktId,
      );

  TraktShowDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.traktId,
  }) : super.internal();

  final int traktId;

  @override
  Override overrideWith(
    FutureOr<Map<String, dynamic>?> Function(TraktShowDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TraktShowDetailProvider._internal(
        (ref) => create(ref as TraktShowDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        traktId: traktId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _TraktShowDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TraktShowDetailProvider && other.traktId == traktId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, traktId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TraktShowDetailRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `traktId` of this provider.
  int get traktId;
}

class _TraktShowDetailProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with TraktShowDetailRef {
  _TraktShowDetailProviderElement(super.provider);

  @override
  int get traktId => (origin as TraktShowDetailProvider).traktId;
}

String _$traktSessionHash() => r'aa44d26fac4377a52d4cf3b0516161f9bd23ee8e';

/// Sesión Trakt (OAuth opcional).
///
/// Copied from [TraktSession].
@ProviderFor(TraktSession)
final traktSessionProvider =
    AsyncNotifierProvider<TraktSession, TraktSessionState>.internal(
      TraktSession.new,
      name: r'traktSessionProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$traktSessionHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$TraktSession = AsyncNotifier<TraktSessionState>;
String _$favoriteTraktTitlesHash() =>
    r'93edd6043d7f3ba75036de3f18dff5041c128f5a';

/// Películas y series Trakt marcadas como favoritas (solo local, SharedPreferences).
///
/// Copied from [FavoriteTraktTitles].
@ProviderFor(FavoriteTraktTitles)
final favoriteTraktTitlesProvider =
    NotifierProvider<FavoriteTraktTitles, List<Map<String, dynamic>>>.internal(
      FavoriteTraktTitles.new,
      name: r'favoriteTraktTitlesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$favoriteTraktTitlesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$FavoriteTraktTitles = Notifier<List<Map<String, dynamic>>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
