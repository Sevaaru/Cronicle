// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$libraryByKindHash() => r'cb37c78deb75ef2411c25c0d9d8090fea8a42cec';

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

/// See also [libraryByKind].
@ProviderFor(libraryByKind)
const libraryByKindProvider = LibraryByKindFamily();

/// See also [libraryByKind].
class LibraryByKindFamily extends Family<AsyncValue<List<LibraryEntry>>> {
  /// See also [libraryByKind].
  const LibraryByKindFamily();

  /// See also [libraryByKind].
  LibraryByKindProvider call(MediaKind kind, {String? status}) {
    return LibraryByKindProvider(kind, status: status);
  }

  @override
  LibraryByKindProvider getProviderOverride(
    covariant LibraryByKindProvider provider,
  ) {
    return call(provider.kind, status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'libraryByKindProvider';
}

/// See also [libraryByKind].
class LibraryByKindProvider
    extends AutoDisposeStreamProvider<List<LibraryEntry>> {
  /// See also [libraryByKind].
  LibraryByKindProvider(MediaKind kind, {String? status})
    : this._internal(
        (ref) => libraryByKind(ref as LibraryByKindRef, kind, status: status),
        from: libraryByKindProvider,
        name: r'libraryByKindProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$libraryByKindHash,
        dependencies: LibraryByKindFamily._dependencies,
        allTransitiveDependencies:
            LibraryByKindFamily._allTransitiveDependencies,
        kind: kind,
        status: status,
      );

  LibraryByKindProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
    required this.status,
  }) : super.internal();

  final MediaKind kind;
  final String? status;

  @override
  Override overrideWith(
    Stream<List<LibraryEntry>> Function(LibraryByKindRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LibraryByKindProvider._internal(
        (ref) => create(ref as LibraryByKindRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LibraryEntry>> createElement() {
    return _LibraryByKindProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryByKindProvider &&
        other.kind == kind &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LibraryByKindRef on AutoDisposeStreamProviderRef<List<LibraryEntry>> {
  /// The parameter `kind` of this provider.
  MediaKind get kind;

  /// The parameter `status` of this provider.
  String? get status;
}

class _LibraryByKindProviderElement
    extends AutoDisposeStreamProviderElement<List<LibraryEntry>>
    with LibraryByKindRef {
  _LibraryByKindProviderElement(super.provider);

  @override
  MediaKind get kind => (origin as LibraryByKindProvider).kind;
  @override
  String? get status => (origin as LibraryByKindProvider).status;
}

String _$libraryAllHash() => r'26a55144f980d5222643e2725962e19a7869e9dd';

/// See also [libraryAll].
@ProviderFor(libraryAll)
const libraryAllProvider = LibraryAllFamily();

/// See also [libraryAll].
class LibraryAllFamily extends Family<AsyncValue<List<LibraryEntry>>> {
  /// See also [libraryAll].
  const LibraryAllFamily();

  /// See also [libraryAll].
  LibraryAllProvider call({String? status}) {
    return LibraryAllProvider(status: status);
  }

  @override
  LibraryAllProvider getProviderOverride(
    covariant LibraryAllProvider provider,
  ) {
    return call(status: provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'libraryAllProvider';
}

/// See also [libraryAll].
class LibraryAllProvider extends AutoDisposeStreamProvider<List<LibraryEntry>> {
  /// See also [libraryAll].
  LibraryAllProvider({String? status})
    : this._internal(
        (ref) => libraryAll(ref as LibraryAllRef, status: status),
        from: libraryAllProvider,
        name: r'libraryAllProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$libraryAllHash,
        dependencies: LibraryAllFamily._dependencies,
        allTransitiveDependencies: LibraryAllFamily._allTransitiveDependencies,
        status: status,
      );

  LibraryAllProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.status,
  }) : super.internal();

  final String? status;

  @override
  Override overrideWith(
    Stream<List<LibraryEntry>> Function(LibraryAllRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LibraryAllProvider._internal(
        (ref) => create(ref as LibraryAllRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LibraryEntry>> createElement() {
    return _LibraryAllProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryAllProvider && other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LibraryAllRef on AutoDisposeStreamProviderRef<List<LibraryEntry>> {
  /// The parameter `status` of this provider.
  String? get status;
}

class _LibraryAllProviderElement
    extends AutoDisposeStreamProviderElement<List<LibraryEntry>>
    with LibraryAllRef {
  _LibraryAllProviderElement(super.provider);

  @override
  String? get status => (origin as LibraryAllProvider).status;
}

String _$libraryFilteredHash() => r'292cf50ec6bb843d7b2a4f528ee2d6437c898362';

/// See also [libraryFiltered].
@ProviderFor(libraryFiltered)
const libraryFilteredProvider = LibraryFilteredFamily();

/// See also [libraryFiltered].
class LibraryFilteredFamily extends Family<AsyncValue<List<LibraryEntry>>> {
  /// See also [libraryFiltered].
  const LibraryFilteredFamily();

  /// See also [libraryFiltered].
  LibraryFilteredProvider call(MediaKind? kind, String? status) {
    return LibraryFilteredProvider(kind, status);
  }

  @override
  LibraryFilteredProvider getProviderOverride(
    covariant LibraryFilteredProvider provider,
  ) {
    return call(provider.kind, provider.status);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'libraryFilteredProvider';
}

/// See also [libraryFiltered].
class LibraryFilteredProvider
    extends AutoDisposeStreamProvider<List<LibraryEntry>> {
  /// See also [libraryFiltered].
  LibraryFilteredProvider(MediaKind? kind, String? status)
    : this._internal(
        (ref) => libraryFiltered(ref as LibraryFilteredRef, kind, status),
        from: libraryFilteredProvider,
        name: r'libraryFilteredProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$libraryFilteredHash,
        dependencies: LibraryFilteredFamily._dependencies,
        allTransitiveDependencies:
            LibraryFilteredFamily._allTransitiveDependencies,
        kind: kind,
        status: status,
      );

  LibraryFilteredProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
    required this.status,
  }) : super.internal();

  final MediaKind? kind;
  final String? status;

  @override
  Override overrideWith(
    Stream<List<LibraryEntry>> Function(LibraryFilteredRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: LibraryFilteredProvider._internal(
        (ref) => create(ref as LibraryFilteredRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        kind: kind,
        status: status,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LibraryEntry>> createElement() {
    return _LibraryFilteredProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryFilteredProvider &&
        other.kind == kind &&
        other.status == status;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, kind.hashCode);
    hash = _SystemHash.combine(hash, status.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin LibraryFilteredRef on AutoDisposeStreamProviderRef<List<LibraryEntry>> {
  /// The parameter `kind` of this provider.
  MediaKind? get kind;

  /// The parameter `status` of this provider.
  String? get status;
}

class _LibraryFilteredProviderElement
    extends AutoDisposeStreamProviderElement<List<LibraryEntry>>
    with LibraryFilteredRef {
  _LibraryFilteredProviderElement(super.provider);

  @override
  MediaKind? get kind => (origin as LibraryFilteredProvider).kind;
  @override
  String? get status => (origin as LibraryFilteredProvider).status;
}

String _$defaultLibraryFilterHash() =>
    r'3927bc801ac465380f89278b6c30d96e5844f810';

/// Default status filter for the library (stored in SharedPreferences).
///
/// Copied from [DefaultLibraryFilter].
@ProviderFor(DefaultLibraryFilter)
final defaultLibraryFilterProvider =
    AutoDisposeNotifierProvider<DefaultLibraryFilter, String>.internal(
      DefaultLibraryFilter.new,
      name: r'defaultLibraryFilterProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$defaultLibraryFilterHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$DefaultLibraryFilter = AutoDisposeNotifier<String>;
String _$paginatedLibraryHash() => r'6f34ef14dc8467cf20ec58e2f10ebe29b0249327';

abstract class _$PaginatedLibrary
    extends BuildlessAutoDisposeAsyncNotifier<List<LibraryEntry>> {
  late final LibraryPageParams params;

  FutureOr<List<LibraryEntry>> build(LibraryPageParams params);
}

/// See also [PaginatedLibrary].
@ProviderFor(PaginatedLibrary)
const paginatedLibraryProvider = PaginatedLibraryFamily();

/// See also [PaginatedLibrary].
class PaginatedLibraryFamily extends Family<AsyncValue<List<LibraryEntry>>> {
  /// See also [PaginatedLibrary].
  const PaginatedLibraryFamily();

  /// See also [PaginatedLibrary].
  PaginatedLibraryProvider call(LibraryPageParams params) {
    return PaginatedLibraryProvider(params);
  }

  @override
  PaginatedLibraryProvider getProviderOverride(
    covariant PaginatedLibraryProvider provider,
  ) {
    return call(provider.params);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'paginatedLibraryProvider';
}

/// See also [PaginatedLibrary].
class PaginatedLibraryProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<
          PaginatedLibrary,
          List<LibraryEntry>
        > {
  /// See also [PaginatedLibrary].
  PaginatedLibraryProvider(LibraryPageParams params)
    : this._internal(
        () => PaginatedLibrary()..params = params,
        from: paginatedLibraryProvider,
        name: r'paginatedLibraryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$paginatedLibraryHash,
        dependencies: PaginatedLibraryFamily._dependencies,
        allTransitiveDependencies:
            PaginatedLibraryFamily._allTransitiveDependencies,
        params: params,
      );

  PaginatedLibraryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final LibraryPageParams params;

  @override
  FutureOr<List<LibraryEntry>> runNotifierBuild(
    covariant PaginatedLibrary notifier,
  ) {
    return notifier.build(params);
  }

  @override
  Override overrideWith(PaginatedLibrary Function() create) {
    return ProviderOverride(
      origin: this,
      override: PaginatedLibraryProvider._internal(
        () => create()..params = params,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        params: params,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<PaginatedLibrary, List<LibraryEntry>>
  createElement() {
    return _PaginatedLibraryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is PaginatedLibraryProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin PaginatedLibraryRef
    on AutoDisposeAsyncNotifierProviderRef<List<LibraryEntry>> {
  /// The parameter `params` of this provider.
  LibraryPageParams get params;
}

class _PaginatedLibraryProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<
          PaginatedLibrary,
          List<LibraryEntry>
        >
    with PaginatedLibraryRef {
  _PaginatedLibraryProviderElement(super.provider);

  @override
  LibraryPageParams get params => (origin as PaginatedLibraryProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
