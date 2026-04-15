import 'dart:ui';

import 'package:flutter/material.dart';

const kGlassBottomNavContentHeight = 66.0;

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
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SizedBox(
      height: kGlassBottomNavContentHeight + bottomInset,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? colorScheme.surface.withAlpha(180)
                  : colorScheme.surfaceContainerHighest.withAlpha(200),
              border: Border(
                top: BorderSide(
                  color: colorScheme.outlineVariant.withAlpha(40),
                  width: 0.5,
                ),
              ),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + bottomInset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (i) {
                  final item = items[i];
                  final selected = i == currentIndex;
                  return Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => onTap(i),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? (isDark
                                        ? colorScheme.primaryContainer
                                        : colorScheme.primary.withAlpha(30))
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                selected ? item.activeIcon : item.icon,
                                size: 20,
                                color: selected
                                    ? (isDark
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.primary)
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight:
                                        selected ? FontWeight.w600 : FontWeight.w400,
                                    color: selected
                                        ? (isDark
                                            ? colorScheme.onSurface
                                            : colorScheme.primary)
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
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
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
}
