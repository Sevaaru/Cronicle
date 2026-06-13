import 'package:flutter/foundation.dart' show kIsWeb;

/// Local Flutter web dev server defaults (see `scripts/run_web.ps1`).
abstract final class WebDevConfig {
  static const int localPort = 60889;
  static const String localOrigin = 'http://localhost:$localPort';

  static bool get isLocalhost {
    if (!kIsWeb) return false;
    final host = Uri.base.host;
    return host == 'localhost' || host == '127.0.0.1';
  }

  static bool get _isLocalhost => isLocalhost;

  /// Same-origin base URL for OAuth redirects on web.
  static String get effectiveOrigin {
    if (!kIsWeb) return '';
    final base = Uri.base;
    if (_isLocalhost) {
      // Use the real browser origin (localhost vs 127.0.0.1, port, etc.).
      if (base.hasScheme && base.host.isNotEmpty) {
        return base.origin;
      }
      return localOrigin;
    }
    return base.origin;
  }
}
