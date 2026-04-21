// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'opencritic_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$openCriticApiHash() => r'c43f58af0abf45959fd009ed6161e4b762b1f8d0';

/// See also [openCriticApi].
@ProviderFor(openCriticApi)
final openCriticApiProvider = Provider<OpenCriticApiDatasource>.internal(
  openCriticApi,
  name: r'openCriticApiProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$openCriticApiHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef OpenCriticApiRef = ProviderRef<OpenCriticApiDatasource>;
String _$openCriticGameInsightsHash() =>
    r'b7964f9932f8399dc555996a3747af170a1678e0';

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

/// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
///
/// Copied from [openCriticGameInsights].
@ProviderFor(openCriticGameInsights)
const openCriticGameInsightsProvider = OpenCriticGameInsightsFamily();

/// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
///
/// Copied from [openCriticGameInsights].
class OpenCriticGameInsightsFamily
    extends Family<AsyncValue<OpenCriticGameInsights?>> {
  /// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
  ///
  /// Copied from [openCriticGameInsights].
  const OpenCriticGameInsightsFamily();

  /// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
  ///
  /// Copied from [openCriticGameInsights].
  OpenCriticGameInsightsProvider call(int igdbGameId) {
    return OpenCriticGameInsightsProvider(igdbGameId);
  }

  @override
  OpenCriticGameInsightsProvider getProviderOverride(
    covariant OpenCriticGameInsightsProvider provider,
  ) {
    return call(provider.igdbGameId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'openCriticGameInsightsProvider';
}

/// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
///
/// Copied from [openCriticGameInsights].
class OpenCriticGameInsightsProvider
    extends AutoDisposeFutureProvider<OpenCriticGameInsights?> {
  /// Críticos OpenCritic alineados al título IGDB cargado en [igdbGameDetail].
  ///
  /// Copied from [openCriticGameInsights].
  OpenCriticGameInsightsProvider(int igdbGameId)
    : this._internal(
        (ref) => openCriticGameInsights(
          ref as OpenCriticGameInsightsRef,
          igdbGameId,
        ),
        from: openCriticGameInsightsProvider,
        name: r'openCriticGameInsightsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$openCriticGameInsightsHash,
        dependencies: OpenCriticGameInsightsFamily._dependencies,
        allTransitiveDependencies:
            OpenCriticGameInsightsFamily._allTransitiveDependencies,
        igdbGameId: igdbGameId,
      );

  OpenCriticGameInsightsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.igdbGameId,
  }) : super.internal();

  final int igdbGameId;

  @override
  Override overrideWith(
    FutureOr<OpenCriticGameInsights?> Function(
      OpenCriticGameInsightsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OpenCriticGameInsightsProvider._internal(
        (ref) => create(ref as OpenCriticGameInsightsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        igdbGameId: igdbGameId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<OpenCriticGameInsights?> createElement() {
    return _OpenCriticGameInsightsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OpenCriticGameInsightsProvider &&
        other.igdbGameId == igdbGameId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, igdbGameId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OpenCriticGameInsightsRef
    on AutoDisposeFutureProviderRef<OpenCriticGameInsights?> {
  /// The parameter `igdbGameId` of this provider.
  int get igdbGameId;
}

class _OpenCriticGameInsightsProviderElement
    extends AutoDisposeFutureProviderElement<OpenCriticGameInsights?>
    with OpenCriticGameInsightsRef {
  _OpenCriticGameInsightsProviderElement(super.provider);

  @override
  int get igdbGameId => (origin as OpenCriticGameInsightsProvider).igdbGameId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
