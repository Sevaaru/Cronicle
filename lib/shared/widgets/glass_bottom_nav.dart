import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Total height of the bar's content area (excluding bottom safe inset).
/// Sized to fit the M3-expressive pill with comfortable touch targets.
const kGlassBottomNavContentHeight = 72.0;

/// Material 3 *expressive* style bottom navigation:
///  - Floating pill bar with frosted-glass blur and soft shadow.
///  - Selected item morphs into a horizontal pill (icon + label) using
///    `secondaryContainer`, while unselected items show only their icon.
///  - Smooth animated indicator that slides between destinations.
///  - Light haptic feedback on tap.
class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final barColor = isDark
        ? cs.surfaceContainerHigh.withAlpha(210)
        // In light mode keep the bar lighter than the indicator pill so the
        // selected `secondaryContainer` clearly pops. Soft primary tint over
        // surface preserves the M3 expressive feel without going grey.
        : Color.alphaBlend(
            cs.primaryContainer.withAlpha(70),
            cs.surface,
          );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        4,
        12,
        // Lift the floating bar above the system gesture area.
        bottomInset > 0 ? bottomInset : 10,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: cs.outlineVariant.withAlpha(isDark ? 50 : 70),
                width: 0.6,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 90 : 30),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SizedBox(
              height: kGlassBottomNavContentHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(items.length, (i) {
                    final selected = i == currentIndex;
                    return Expanded(
                      // Selected destination gets noticeably more space so
                      // longer labels (e.g. "Biblioteca", "Búsqueda") fit.
                      flex: selected ? 3 : 1,
                      child: _NavItem(
                        item: items[i],
                        selected: selected,
                        onTap: () {
                          if (!selected) {
                            HapticFeedback.selectionClick();
                          }
                          onTap(i);
                        },
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final GlassNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final indicatorColor = selected
        ? cs.secondaryContainer.withAlpha(isDark ? 230 : 255)
        : Colors.transparent;
    final fgColor = selected ? cs.onSecondaryContainer : cs.onSurfaceVariant;

    return Padding(
      key: item.itemKey,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: cs.primary.withAlpha(30),
          highlightColor: cs.primary.withAlpha(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(
              horizontal: selected ? 12 : 10,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: indicatorColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, anim) => ScaleTransition(
                    scale: Tween<double>(begin: 0.85, end: 1).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: Icon(
                    selected ? item.activeIcon : item.icon,
                    key: ValueKey<bool>(selected),
                    size: 22,
                    color: fgColor,
                  ),
                ),
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.centerLeft,
                    widthFactor: selected ? 1 : 0,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 220),
                          style: TextStyle(
                            color: fgColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                          child: Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            softWrap: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GlassNavItem {
  const GlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.itemKey,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;

  /// Optional key attached to the rendered nav item so external code can
  /// measure its on-screen rect (used e.g. by the library-insert animation).
  final Key? itemKey;
}
