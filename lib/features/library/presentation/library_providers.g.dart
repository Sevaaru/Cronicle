// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$libraryByKindHash() => r'5deadd2a436b74e5a071be4db74577c54a5f9567';

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
  LibraryByKindProvider call(MediaKind kind) {
    return LibraryByKindProvider(kind);
  }

  @override
  LibraryByKindProvider getProviderOverride(
    covariant LibraryByKindProvider provider,
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
  String? get name => r'libraryByKindProvider';
}

/// See also [libraryByKind].
class LibraryByKindProvider
    extends AutoDisposeStreamProvider<List<LibraryEntry>> {
  /// See also [libraryByKind].
  LibraryByKindProvider(MediaKind kind)
    : this._internal(
        (ref) => libraryByKind(ref as LibraryByKindRef, kind),
        from: libraryByKindProvider,
        name: r'libraryByKindProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$libraryByKindHash,
        dependencies: LibraryByKindFamily._dependencies,
        allTransitiveDependencies:
            LibraryByKindFamily._allTransitiveDependencies,
        kind: kind,
      );

  LibraryByKindProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.kind,
  }) : super.internal();

  final MediaKind kind;

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
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<LibraryEntry>> createElement() {
    return _LibraryByKindProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is LibraryByKindProvider && other.kind == kind;
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
mixin LibraryByKindRef on AutoDisposeStreamProviderRef<List<LibraryEntry>> {
  /// The parameter `kind` of this provider.
  MediaKind get kind;
}

class _LibraryByKindProviderElement
    extends AutoDisposeStreamProviderElement<List<LibraryEntry>>
    with LibraryByKindRef {
  _LibraryByKindProviderElement(super.provider);

  @override
  MediaKind get kind => (origin as LibraryByKindProvider).kind;
}

String _$libraryAllHash() => r'e4d718950e1fe053ee5f0c38867406a0be5aaad9';

/// See also [libraryAll].
@ProviderFor(libraryAll)
final libraryAllProvider =
    AutoDisposeStreamProvider<List<LibraryEntry>>.internal(
      libraryAll,
      name: r'libraryAllProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$libraryAllHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef LibraryAllRef = AutoDisposeStreamProviderRef<List<LibraryEntry>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
