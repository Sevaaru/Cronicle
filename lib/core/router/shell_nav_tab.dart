import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mantiene el índice del tab inferior cuando la ruta no es uno de los 5 principales
/// (perfil, detalle media, foros, etc.).
final shellNavTabProvider = NotifierProvider<ShellNavTabNotifier, int>(
  ShellNavTabNotifier.new,
);

class ShellNavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// Solo llamar **fuera** de [build] (p. ej. [WidgetsBinding.addPostFrameCallback]).
  /// Persiste el tab cuando la ruta es uno de los 5 principales.
  void rememberPrimaryTabFromPath(String path) {
    final i = primaryTabIndexForPath(path);
    if (i != null) state = i;
  }

  /// Índice a mostrar en [GlassBottomNav] para [path] (solo lectura, seguro en [build]).
  int bottomNavIndex(String path) => primaryTabIndexForPath(path) ?? state;
}

/// `null` si [path] no corresponde a Inicio / Biblioteca / Búsqueda / Social / Ajustes.
int? primaryTabIndexForPath(String path) {
  if (path.startsWith('/library')) return 1;
  if (path.startsWith('/search')) return 2;
  if (path.startsWith('/social')) return 3;
  if (path.startsWith('/settings')) return 4;
  if (path.startsWith('/feed')) return 0;
  return null;
}
