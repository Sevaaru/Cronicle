import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:cronicle/core/storage/shared_preferences_provider.dart';
import 'package:cronicle/l10n/app_localizations.dart';
import 'package:cronicle/shared/profile/profile_avatar_provider.dart';
import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/library_insert_animation.dart';
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

class _AppShellState extends ConsumerState<AppShell>
    with SingleTickerProviderStateMixin {
  int _prevIndex = -1;

  // Cold-start "cartridge" intro for the floating navbar. Plays once per
  // app launch (i.e. every time the user opens the app from a fully closed
  // state) so the navbar feels like it clicks into place each session.
  AnimationController? _cartridgeCtrl;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _cartridgeCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1300),
      );
      setState(() {});
      _cartridgeCtrl!.forward();
    });
  }

  @override
  void dispose() {
    _cartridgeCtrl?.dispose();
    super.dispose();
  }

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
        icon: Icons.home_outlined,
        activeIcon: Icons.home_rounded,
        label: l10n.navHome,
      ),
      GlassNavItem(
        icon: Icons.collections_bookmark_outlined,
        activeIcon: Icons.collections_bookmark_rounded,
        label: l10n.navLibrary,
        itemKey: libraryNavTabKey,
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

    final navBar = GlassBottomNav(
      currentIndex: widget.currentIndex,
      onTap: widget.onTabChanged,
      items: items,
    );

    return Scaffold(
      body: _NavFadeThrough(
        index: widget.currentIndex,
        child: widget.child,
      ),
      // The navbar is a floating pill: let the body paint behind it so the
      // surrounding area shows the page background instead of the scaffold
      // background as opaque rectangles around the rounded corners.
      extendBody: true,
      bottomNavigationBar: _cartridgeCtrl == null
          ? navBar
          : _NavCartridgeIntro(
              controller: _cartridgeCtrl!,
              child: navBar,
            ),
    );
  }
}

/// One-shot Material 3 + Nintendo "cartridge" entrance for the floating
/// navbar after the onboarding completes. The bar slides up from below the
/// screen, briefly squashes wider than its rest size and then settles into
/// place with an emphasized easing curve. A soft primary glow underlines
/// the snap as the cartridge "clicks" home.
class _NavCartridgeIntro extends StatelessWidget {
  const _NavCartridgeIntro({required this.controller, required this.child});

  final AnimationController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Slide from below the screen into place.
    final slide = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: const Interval(0.0, 0.7, curve: Cubic(0.2, 0.0, 0.0, 1.0)),
      ),
    );
    // Slight squash & stretch so it lands like a cartridge clicking in:
    // wider for a beat, then snaps to 1:1.
    final scaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 1.08)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.08, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
    ]).animate(controller);
    final scaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.7, end: 0.92)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 35,
      ),
    ]).animate(controller);
    final fade = CurvedAnimation(
      parent: controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(
            position: slide,
            child: Transform(
              alignment: Alignment.bottomCenter,
              transform: Matrix4.identity()
                ..scale(scaleX.value, scaleY.value),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Material 3 "fade through" page transition used when the user taps a tab in
/// the bottom navigation bar. The outgoing page fades out quickly while the
/// incoming page fades in with a subtle scale-up so it feels like distinct
/// destinations rather than a flat swap.
class _NavFadeThrough extends StatelessWidget {
  const _NavFadeThrough({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        // Outgoing fades faster than the incoming so they don't overlap as
        // muddy crossfade — true M3 fade-through behaviour.
        final fade = CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
          reverseCurve: const Interval(0.0, 0.35, curve: Curves.easeIn),
        );
        final scale = Tween<double>(begin: 0.96, end: 1.0).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: fade,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(index),
        child: child,
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
    final resolvedAvatar = ref.watch(resolvedProfileAvatarProvider);

    final avatarUrl = resolvedAvatar.networkUrl;
    final avatarBytes = resolvedAvatar.memoryBytes;

    final avatarCore = SizedBox(
      key: _avatarBoundsKey,
      width: kProfileLeadingCircleSize,
      height: kProfileLeadingCircleSize,
      child: ClipOval(
        child: ColoredBox(
          color: cs.surfaceContainerHighest,
          child: avatarBytes != null
              ? Image.memory(
                  avatarBytes,
                  width: kProfileLeadingCircleSize,
                  height: kProfileLeadingCircleSize,
                  fit: BoxFit.cover,
                )
              : (avatarUrl != null && avatarUrl.isNotEmpty)
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
