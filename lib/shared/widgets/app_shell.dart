import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({
    super.key,
    required this.currentIndex,
    required this.child,
    required this.onTabChanged,
  });

  final int currentIndex;
  final Widget child;
  final ValueChanged<int> onTabChanged;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _prevIndex = -1;

  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex && _prevIndex != widget.currentIndex) {
      _prevIndex = widget.currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final nav = Navigator.of(context);
        nav.popUntil((route) => route is! PopupRoute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final items = [
      GlassNavItem(
        icon: Icons.rss_feed_outlined,
        activeIcon: Icons.rss_feed_rounded,
        label: l10n.navHome,
      ),
      GlassNavItem(
        icon: Icons.collections_bookmark_outlined,
        activeIcon: Icons.collections_bookmark_rounded,
        label: l10n.navLibrary,
      ),
      GlassNavItem(
        icon: Icons.search_outlined,
        activeIcon: Icons.search_rounded,
        label: l10n.navSearch,
      ),
      GlassNavItem(
        icon: Icons.person_outlined,
        activeIcon: Icons.person_rounded,
        label: l10n.navProfile,
      ),
      GlassNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: l10n.navSettings,
      ),
    ];

    return Scaffold(
      body: widget.child,
      extendBody: true,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabChanged,
        items: items,
      ),
    );
  }
}
