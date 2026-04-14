// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'google_sign_in_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$googleSignInHash() => r'51ebfbb1744caa9c238f6029e57cdf6cbbede6a0';

/// Google Sign-In 7.x uses a single [GoogleSignIn.instance]; call
/// `GoogleSignIn.instance.initialize()` in [main] before [runApp].
///
/// Copied from [googleSignIn].
@ProviderFor(googleSignIn)
final googleSignInProvider = Provider<GoogleSignIn>.internal(
  googleSignIn,
  name: r'googleSignInProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$googleSignInHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GoogleSignInRef = ProviderRef<GoogleSignIn>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
