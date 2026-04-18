import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';

TextStyle pageTitleStyle() => GoogleFonts.inter(
  fontSize: 20,
  fontWeight: FontWeight.w700,
  letterSpacing: 0.5,
);

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
        icon: Icons.forum_outlined,
        activeIcon: Icons.forum_rounded,
        label: l10n.navSocial,
      ),
      GlassNavItem(
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings_rounded,
        label: l10n.navSettings,
      ),
    ];

    return Scaffold(
      body: widget.child,
      extendBody: false,
      bottomNavigationBar: GlassBottomNav(
        currentIndex: widget.currentIndex,
        onTap: widget.onTabChanged,
        items: items,
      ),
    );
  }
}

class ProfileAvatarButton extends ConsumerWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    String? avatarUrl;
    final anilistProfile = ref.watch(anilistProfileProvider).valueOrNull;
    if (anilistProfile != null) {
      avatarUrl = (anilistProfile['avatar'] as Map?)?['large'] as String?;
    }
    avatarUrl ??= ref.watch(traktSessionProvider).valueOrNull?.userAvatarUrl;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.push('/profile'),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, top: 10, bottom: 10, right: 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 28,
              height: 28,
              color: cs.surfaceContainerHighest,
              child: avatarUrl != null
                  ? CachedNetworkImage(
                      imageUrl: avatarUrl,
                      width: 28,
                      height: 28,
                      fit: BoxFit.cover,
                    )
                  : Icon(Icons.person, size: 16, color: cs.onSurfaceVariant),
            ),
          ),
        ),
      ),
    );
  }
}
