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
      // AniList/Trakt dev consoles register http://localhost:PORT, not 127.0.0.1.
      final port = base.hasPort && base.port != 0 ? base.port : localPort;
      return 'http://localhost:$port';
    }
    return base.origin;
  }
}
