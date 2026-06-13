// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cronicle_auth_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$cronicleAuthServiceHash() =>
    r'009d55e641119af488a10a6033dc06f945e9736e';

/// See also [cronicleAuthService].
@ProviderFor(cronicleAuthService)
final cronicleAuthServiceProvider = Provider<CronicleAuthService>.internal(
  cronicleAuthService,
  name: r'cronicleAuthServiceProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cronicleAuthServiceHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CronicleAuthServiceRef = ProviderRef<CronicleAuthService>;
String _$cronicleAuthSessionHash() =>
    r'fd261c5566ebd013e776046e536b04417f0f234d';

/// See also [cronicleAuthSession].
@ProviderFor(cronicleAuthSession)
final cronicleAuthSessionProvider = StreamProvider<Session?>.internal(
  cronicleAuthSession,
  name: r'cronicleAuthSessionProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$cronicleAuthSessionHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CronicleAuthSessionRef = StreamProviderRef<Session?>;
String _$cronicleMyProfileHash() => r'1b1aad014e74372f7e4251c11497b2cd36cfd2aa';

/// See also [CronicleMyProfile].
@ProviderFor(CronicleMyProfile)
final cronicleMyProfileProvider =
    AsyncNotifierProvider<CronicleMyProfile, CronicleProfileRow?>.internal(
      CronicleMyProfile.new,
      name: r'cronicleMyProfileProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$cronicleMyProfileHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$CronicleMyProfile = AsyncNotifier<CronicleProfileRow?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
