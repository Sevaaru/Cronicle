import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellNavTabProvider = NotifierProvider<ShellNavTabNotifier, int>(
  ShellNavTabNotifier.new,
);

class ShellNavTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void rememberPrimaryTabFromPath(String path) {
    final i = primaryTabIndexForPath(path);
    if (i != null) state = i;
  }

  int bottomNavIndex(String path) => primaryTabIndexForPath(path) ?? state;
}

int? primaryTabIndexForPath(String path) {
  if (path.startsWith('/library')) return 1;
  if (path.startsWith('/search')) return 2;
  if (path.startsWith('/social')) return 3;
  if (path.startsWith('/settings')) return 4;
  if (path.startsWith('/feed')) return 0;
  return null;
}
