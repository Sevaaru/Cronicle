import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:cronicle/core/config/env_config.dart';
import 'package:cronicle/core/supabase/supabase_bootstrap.dart';

class EmailConfirmationRequired implements Exception {
  const EmailConfirmationRequired();
}

class CronicleProfileRow {
  const CronicleProfileRow({
    required this.id,
    required this.username,
    required this.displayName,
    required this.needsUsernameSetup,
    this.avatarUrl,
  });

  factory CronicleProfileRow.fromJson(Map<String, dynamic> json) {
    return CronicleProfileRow(
      id: json['id'] as String,
      username: json['username'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      needsUsernameSetup: json['needs_username_setup'] as bool? ?? false,
    );
  }

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool needsUsernameSetup;
}

class CronicleAuthService {
  CronicleAuthService(this._googleSignIn);

  final GoogleSignIn _googleSignIn;

  SupabaseClient get _client {
    final c = cronicleSupabaseClient;
    if (c == null) {
      throw StateError('supabase_not_configured');
    }
    return c;
  }

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      throw UnsupportedError('google_web_use_render_button');
    }

    const scopes = ['email', 'profile'];
    final googleUser = await _googleSignIn.authenticate();
    await _completeGoogleSignIn(googleUser, scopes);
  }

  /// Web: after [renderButton] + [GoogleSignInAuthenticationEventSignIn].
  Future<void> signInWithGoogleAccount(GoogleSignInAccount account) async {
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('No Google ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<void> _completeGoogleSignIn(
    GoogleSignInAccount googleUser,
    List<String> scopes,
  ) async {
    final authorization =
        await googleUser.authorizationClient.authorizationForScopes(scopes) ??
            await googleUser.authorizationClient.authorizeScopes(scopes);
    final idToken = googleUser.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const AuthException('No Google ID token.');
    }

    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: authorization.accessToken,
    );
  }

  Future<void> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signUpWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (response.session == null) {
      throw const EmailConfirmationRequired();
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
    }
  }

  Future<CronicleProfileRow?> fetchMyProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final row = await _client
        .from('profiles')
        .select(
          'id, username, display_name, avatar_url, needs_username_setup',
        )
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return CronicleProfileRow.fromJson(row);
  }

  Future<bool> isUsernameAvailable(String candidate) async {
    final trimmed = candidate.trim();
    if (trimmed.length < 3) return false;
    final result = await _client.rpc(
      'is_username_available',
      params: {'candidate': trimmed},
    );
    return result == true;
  }

  Future<void> claimUsername(String username) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthException('Not signed in.');

    final trimmed = username.trim().toLowerCase();
    if (!_isValidUsername(trimmed)) {
      throw ArgumentError('invalid_username');
    }

    final available = await isUsernameAvailable(trimmed);
    if (!available) throw StateError('username_taken');

    await _client.from('profiles').update({
      'username': trimmed,
      'needs_username_setup': false,
    }).eq('id', userId);
  }

  static bool _isValidUsername(String value) {
    if (value.length < 3 || value.length > 24) return false;
    return RegExp(r'^[a-z0-9_]+$').hasMatch(value);
  }

  static bool get isConfigured => EnvConfig.hasSupabase;
}
