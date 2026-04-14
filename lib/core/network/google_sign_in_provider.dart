import 'package:google_sign_in/google_sign_in.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'google_sign_in_provider.g.dart';

/// Google Sign-In 7.x uses a single [GoogleSignIn.instance]; call
/// `GoogleSignIn.instance.initialize()` in [main] before [runApp].
@Riverpod(keepAlive: true)
GoogleSignIn googleSignIn(GoogleSignInRef ref) {
  return GoogleSignIn.instance;
}
