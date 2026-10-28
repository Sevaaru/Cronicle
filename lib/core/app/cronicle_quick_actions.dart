import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';

import 'package:cronicle/core/router/app_router.dart';

/// Identificadores de los App Shortcuts (Quick Actions) de Android/iOS.
///
/// Los IDs viajan desde el sistema operativo a la app intactos, así que
/// los usamos también como ruta destino para mantener todo en un solo
/// sitio.
class CronicleQuickActionType {
  static const String library = 'shortcut_library';
  static const String discover = 'shortcut_discover';
  static const String explore = 'shortcut_explore';
  static const String social = 'shortcut_social';
}

/// Mapa Quick Action → ruta GoRouter.
const Map<String, String> _kRoutes = {
  CronicleQuickActionType.library: '/library',
  CronicleQuickActionType.discover: '/feed',
  CronicleQuickActionType.explore: '/search',
  CronicleQuickActionType.social: '/social',
};

/// Inicializa los Quick Actions del sistema y conecta el handler para que
/// al pulsar uno (cold start o warm start) la app navegue a la ruta
/// adecuada.
///
/// Debe llamarse una sola vez tras crear el [GoRouter], normalmente desde
/// `initState` del root widget de la app.
class CronicleQuickActions {
  CronicleQuickActions._();

  static final QuickActions _quickActions = const QuickActions();
  static bool _initialized = false;

  /// Pendiente: si el usuario abre la app por un shortcut antes de que el
  /// router esté listo, guardamos la ruta y la consumimos al primer
  /// [bindRouter].
  static String? _pendingRoute;
  static GoRouter? _router;

  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Sólo Android e iOS soportan Quick Actions. En otras plataformas el
    // plugin es un no-op pero evitamos el coste de inicialización.
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }

    _quickActions.initialize((shortcutType) {
      final route = _kRoutes[shortcutType];
      if (route == null) return;
      final router = _router;
      if (router == null) {
        // El router aún no está disponible (cold start). Lo guardamos
        // para que [bindRouter] lo procese cuando el árbol esté listo.
        _pendingRoute = route;
      } else {
        router.go(route);
      }
    });

    await _quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: CronicleQuickActionType.library,
        localizedTitle: 'Library',
        // Iconos: deben existir como recursos drawable en Android
        // (`android/app/src/main/res/drawable/ic_shortcut_*.png`/xml) y
        // como assets para iOS. Si el icono no existe, Android usa el
        // icono de la app.
        icon: 'ic_shortcut_library',
      ),
      const ShortcutItem(
        type: CronicleQuickActionType.discover,
        localizedTitle: 'Discover',
        icon: 'ic_shortcut_discover',
      ),
      const ShortcutItem(
        type: CronicleQuickActionType.explore,
        localizedTitle: 'Explore',
        icon: 'ic_shortcut_explore',
      ),
      const ShortcutItem(
        type: CronicleQuickActionType.social,
        localizedTitle: 'Social',
        icon: 'ic_shortcut_social',
      ),
    ]);
  }

  /// Asocia el [GoRouter] vivo y consume cualquier shortcut pendiente
  /// (cold start).
  static void bindRouter(GoRouter router) {
    _router = router;
    final pending = _pendingRoute;
    if (pending != null) {
      _pendingRoute = null;
      router.go(pending);
    }
  }
}
