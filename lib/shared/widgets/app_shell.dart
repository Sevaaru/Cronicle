import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/features/anime/presentation/anime_providers.dart';
import 'package:cronicle/features/trakt/presentation/trakt_providers.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';

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

class ProfileAvatarButton extends ConsumerStatefulWidget {
  const ProfileAvatarButton({super.key});

  @override
  ConsumerState<ProfileAvatarButton> createState() => _ProfileAvatarButtonState();
}

class _ProfileAvatarButtonState extends ConsumerState<ProfileAvatarButton> {
  final GlobalKey _avatarBoundsKey = GlobalKey();
  bool _hover = false;

  void _openProfile() {
    final box = _avatarBoundsKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? origin;
    if (box != null && box.hasSize) {
      final o = box.localToGlobal(Offset.zero);
      origin = Rect.fromLTWH(o.dx, o.dy, box.size.width, box.size.height);
    }
    context.push('/profile', extra: origin);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    String? avatarUrl;
    final anilistProfile = ref.watch(anilistProfileProvider).valueOrNull;
    if (anilistProfile != null) {
      avatarUrl = (anilistProfile['avatar'] as Map?)?['large'] as String?;
    }
    avatarUrl ??= ref.watch(traktSessionProvider).valueOrNull?.userAvatarUrl;

    final avatarCore = SizedBox(
      key: _avatarBoundsKey,
      width: kProfileLeadingCircleSize,
      height: kProfileLeadingCircleSize,
      child: ClipOval(
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: avatarUrl != null
              ? CachedNetworkImage(
                  imageUrl: avatarUrl,
                  width: kProfileLeadingCircleSize,
                  height: kProfileLeadingCircleSize,
                  fit: BoxFit.cover,
                )
              : Icon(Icons.person, size: 20, color: cs.onSurfaceVariant),
        ),
      ),
    );

    return SizedBox(
      width: kProfileLeadingWidth,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: kProfileLeadingPadding,
          child: MouseRegion(
            onEnter: (_) => setState(() => _hover = true),
            onExit: (_) => setState(() => _hover = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              // Sombra solo en el círculo del avatar (no en el padding del leading).
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: _hover
                    ? [
                        BoxShadow(
                          color: cs.primary.withAlpha(100),
                          blurRadius: 12,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : const [],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: SizedBox(
                  width: kProfileLeadingCircleSize,
                  height: kProfileLeadingCircleSize,
                  child: Material(
                    type: MaterialType.transparency,
                    color: Colors.transparent,
                    clipBehavior: Clip.none,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _openProfile,
                      child: avatarCore,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
