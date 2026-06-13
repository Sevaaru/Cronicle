import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:cronicle/shared/widgets/glass_bottom_nav.dart';
import 'package:cronicle/shared/widgets/profile_leading_circle.dart';

/// Minimum width for the fixed left navigation rail (web).
const double kWebSideNavBreakpoint = 900;

/// Minimum width for the top navigation bar (web, below side-rail breakpoint).
const double kWebTopNavBreakpoint = 600;

const double kWebSideNavWidth = 275;

const double kWebContentMaxWidth = 1280;

enum ShellNavPlacement { bottom, top, side }

/// How the primary shell navigation is rendered for the current viewport.
class ShellLayoutInfo extends InheritedWidget {
  const ShellLayoutInfo({
    required this.placement,
    required super.child,
  });

  final ShellNavPlacement placement;

  static ShellLayoutInfo? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellLayoutInfo>();
  }

  static ShellNavPlacement placementOf(BuildContext context) {
    return maybeOf(context)?.placement ?? ShellNavPlacement.bottom;
  }

  static bool usesBottomNav(BuildContext context) {
    return placementOf(context) == ShellNavPlacement.bottom;
  }

  @override
  bool updateShouldNotify(ShellLayoutInfo oldWidget) {
    return placement != oldWidget.placement;
  }
}

ShellNavPlacement shellNavPlacementForWidth(double width) {
  if (!kIsWeb) return ShellNavPlacement.bottom;
  if (width >= kWebSideNavBreakpoint) return ShellNavPlacement.side;
  if (width >= kWebTopNavBreakpoint) return ShellNavPlacement.top;
  return ShellNavPlacement.bottom;
}

/// Bottom padding for scrollables inside the shell (accounts for floating nav).
double shellScrollBottomPadding(BuildContext context, {double extra = 24}) {
  if (ShellLayoutInfo.usesBottomNav(context)) {
    return kGlassBottomNavContentHeight + extra;
  }
  return extra;
}

/// Whether the main content should be width-clamped (web side/top nav).
bool shellUsesConstrainedContent(BuildContext context) {
  final p = ShellLayoutInfo.placementOf(context);
  return p == ShellNavPlacement.side || p == ShellNavPlacement.top;
}

bool shellUsesConstrainedContentFromPlacement(ShellNavPlacement placement) {
  return placement == ShellNavPlacement.side ||
      placement == ShellNavPlacement.top;
}

/// AppBar leading width: full profile slot on mobile-style nav, tight on web shell.
double shellProfileLeadingWidth(BuildContext context) {
  return ShellLayoutInfo.usesBottomNav(context) ? kProfileLeadingWidth : 16;
}
