import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cronicle/core/network/google_sign_in_provider.dart';
import 'package:cronicle/features/identity/data/cronicle_auth_service.dart';

part 'cronicle_auth_providers.g.dart';

@Riverpod(keepAlive: true)
CronicleAuthService cronicleAuthService(CronicleAuthServiceRef ref) {
  return CronicleAuthService(ref.watch(googleSignInProvider));
}

@Riverpod(keepAlive: true)
Stream<Session?> cronicleAuthSession(CronicleAuthSessionRef ref) {
  final auth = ref.watch(cronicleAuthServiceProvider);
  if (!CronicleAuthService.isConfigured) {
    return Stream<Session?>.value(null);
  }
  return auth.authStateChanges.map((event) => event.session);
}

@Riverpod(keepAlive: true)
class CronicleMyProfile extends _$CronicleMyProfile {
  @override
  Future<CronicleProfileRow?> build() async {
    if (!CronicleAuthService.isConfigured) return null;

    ref.watch(cronicleAuthSessionProvider);
    final auth = ref.read(cronicleAuthServiceProvider);
    if (auth.currentSession == null) return null;
    return auth.fetchMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final auth = ref.read(cronicleAuthServiceProvider);
      if (auth.currentSession == null) return null;
      return auth.fetchMyProfile();
    });
  }
}
